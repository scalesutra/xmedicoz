import { Prisma } from "@prisma/client";
import { Decimal } from "@prisma/client/runtime/library";
import { prisma } from "../../infrastructure/database/prisma.client.js";
import { AppError } from "../../utils/errors.js";
import {
  PURCHASE_ORDER_STATUS,
  PURCHASE_PAYMENT_STATUS,
  STOCK_TRANSACTION_TYPE,
} from "../../config/constants.js";
import type {
  CreatePurchaseOrderInput,
  CreatePurchaseReturnInput,
  RecordSupplierPaymentInput,
  QueryPurchasesInput,
} from "./purchases.schema.js";

function getSequenceNumber(prefix: string, count: number): string {
  const year = new Date().getFullYear();
  const seq = String(count + 1).padStart(4, "0");
  return `${prefix}-${year}-${seq}`;
}

export class PurchasesService {
  /**
   * Create Purchase Order (Scoped to shop)
   */
  async createPurchaseOrder(shopId: string, data: CreatePurchaseOrderInput, userId?: string) {
    const supplier = await prisma.supplier.findFirst({
      where: { id: data.supplierId, shopId },
    });

    if (!supplier) {
      throw AppError.notFound("Supplier not found in your store");
    }

    const count = await prisma.purchaseOrder.count({ where: { shopId } });
    const orderNumber = getSequenceNumber("PO", count);

    let totalAmount = 0;
    const itemsData = data.items.map((item) => {
      const lineTotal = item.quantity * item.expectedRate;
      totalAmount += lineTotal;
      return {
        medicineId: item.medicineId,
        quantity: item.quantity,
        expectedRate: new Decimal(item.expectedRate),
        totalAmount: new Decimal(lineTotal),
      };
    });

    const purchaseOrder = await prisma.purchaseOrder.create({
      data: {
        shopId,
        orderNumber,
        supplierId: data.supplierId,
        expectedDate: data.expectedDate ? new Date(data.expectedDate) : null,
        status: PURCHASE_ORDER_STATUS.PLACED,
        totalAmount: new Decimal(totalAmount),
        notes: data.notes,
        createdById: userId,
        items: {
          create: itemsData,
        },
      },
      include: {
        supplier: { select: { id: true, name: true, mobile: true } },
        items: {
          include: {
            medicine: { select: { id: true, name: true, genericName: true } },
          },
        },
      },
    });

    return purchaseOrder;
  }

  /**
   * List Purchase Orders (Scoped to shop)
   */
  async listPurchaseOrders(shopId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      prisma.purchaseOrder.findMany({
        where: { shopId },
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          supplier: { select: { id: true, name: true, mobile: true } },
          _count: { select: { items: true } },
        },
      }),
      prisma.purchaseOrder.count({ where: { shopId } }),
    ]);

    return {
      items,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Create Purchase Invoice (Supplier Bill Entry) & Atomically Ingest Stock (Scoped to shop)
   */
  async createPurchaseInvoice(shopId: string, data: any, userId?: string) {
    // 1. Resolve Supplier — auto-create if supplierId not provided
    let supplierId = data.supplierId;

    if (!supplierId && data.supplier?.name) {
      // Search by name first (case-insensitive)
      const existing = await prisma.supplier.findFirst({
        where: { shopId, name: { equals: data.supplier.name, mode: "insensitive" } },
      });

      if (existing) {
        supplierId = existing.id;
      } else {
        const newSupplier = await prisma.supplier.create({
          data: {
            shopId,
            name: data.supplier.name,
            contactPerson: data.supplier.contactPerson || null,
            mobile: data.supplier.mobile || "0000000000",
            gstin: data.supplier.gstin || null,
            dlNumber: data.supplier.dlNumber || null,
            address: data.supplier.address || null,
            paymentTermsDays: data.supplier.paymentTermsDays || 30,
          },
        });
        supplierId = newSupplier.id;
      }
    }

    if (!supplierId) {
      throw AppError.badRequest("Either supplierId or supplier.name is required");
    }

    const supplier = await prisma.supplier.findFirst({
      where: { id: supplierId, shopId },
    });

    if (!supplier) {
      throw AppError.notFound("Supplier not found in your store");
    }

    // Check duplicate supplier invoice number in this shop
    const existingBill = await prisma.purchaseInvoice.findUnique({
      where: {
        shopId_supplierId_invoiceNumber: {
          shopId,
          supplierId,
          invoiceNumber: data.invoiceNumber,
        },
      },
    });

    if (existingBill) {
      throw AppError.badRequest(
        `Invoice number '${data.invoiceNumber}' already exists for this supplier in your store`
      );
    }

    // Compute line totals and resolve medicines
    let subtotal = 0;
    let totalDiscount = 0;
    let totalTax = 0;

    const processedItems: Array<{
      medicineId: string;
      batchNumber: string;
      manufacturingDate?: Date | null;
      expiryDate: Date;
      quantity: number;
      freeQuantity: number;
      purchaseRate: number;
      mrp: number;
      sellingPrice: number;
      discountPercent: number;
      taxRate: number;
      lineTotal: number;
    }> = [];

    for (const item of data.items) {
      // 2. Resolve Medicine — auto-create if medicineId not provided
      let medicineId = item.medicineId;

      if (!medicineId && item.medicineName) {
        // Search by name in this shop
        const existing = await prisma.medicine.findFirst({
          where: { shopId, name: { equals: item.medicineName, mode: "insensitive" } },
        });

        if (existing) {
          medicineId = existing.id;
        } else {
          // Auto-create medicine with OCR data
          const newMedicine = await prisma.medicine.create({
            data: {
              shopId,
              name: item.medicineName,
              genericName: item.medicineName,
              dosageForm: "Tablet",
              hsnCode: item.hsnCode || "3004",
              gstRate: item.taxRate || 0,
              mrp: item.mrp,
              purchaseRate: item.purchaseRate,
              sellingPrice: item.sellingPrice || item.mrp,
              reorderLevel: 10,
            },
          });
          medicineId = newMedicine.id;
        }
      }

      if (!medicineId) {
        throw AppError.badRequest(`Either medicineId or medicineName is required for each item`);
      }

      const medicine = await prisma.medicine.findFirst({
        where: { id: medicineId, shopId },
      });

      if (!medicine) {
        throw AppError.notFound(`Medicine not found in your store: ${medicineId}`);
      }

      const effectiveSellingPrice = item.sellingPrice || item.mrp;
      const gross = item.quantity * item.purchaseRate;
      const discount = gross * ((item.discountPercent || 0) / 100);
      const taxable = gross - discount;
      const tax = taxable * ((item.taxRate || 0) / 100);
      const lineTotal = taxable + tax;

      subtotal += gross;
      totalDiscount += discount;
      totalTax += tax;

      processedItems.push({
        medicineId,
        batchNumber: item.batchNumber.trim().toUpperCase(),
        manufacturingDate: item.manufacturingDate ? new Date(item.manufacturingDate) : null,
        expiryDate: new Date(item.expiryDate),
        quantity: item.quantity,
        freeQuantity: item.freeQuantity || 0,
        purchaseRate: item.purchaseRate,
        mrp: item.mrp,
        sellingPrice: effectiveSellingPrice,
        discountPercent: item.discountPercent || 0,
        taxRate: item.taxRate || 0,
        lineTotal,
      });
    }

    const finalTotal = subtotal - totalDiscount + totalTax;

    const invoiceCount = await prisma.purchaseInvoice.count({ where: { shopId } });
    const internalNumber = getSequenceNumber("PI", invoiceCount);

    const invoiceDate = new Date(data.invoiceDate);
    const dueDate = new Date(invoiceDate);
    dueDate.setDate(dueDate.getDate() + data.paymentTermsDays);

    const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      // 1. Create Purchase Invoice record
      const invoice = await tx.purchaseInvoice.create({
        data: {
          shopId,
          invoiceNumber: data.invoiceNumber,
          internalNumber,
          supplierId,
          purchaseOrderId: data.purchaseOrderId,
          invoiceDate,
          paymentTermsDays: data.paymentTermsDays,
          dueDate,
          subtotal: new Decimal(subtotal),
          discountAmount: new Decimal(totalDiscount),
          taxAmount: new Decimal(totalTax),
          totalAmount: new Decimal(finalTotal),
          paidAmount: new Decimal(0),
          balanceAmount: new Decimal(finalTotal),
          paymentStatus: PURCHASE_PAYMENT_STATUS.UNPAID,
          status: "RECEIVED",
          notes: data.notes,
          receivedById: userId,
        },
      });

      // 2. Process each item: Upsert batch, create stock ledger entry, update medicine price
      for (const item of processedItems) {
        const totalReceivedQty = item.quantity + item.freeQuantity;

        // Upsert batch for this shop
        const existingBatch = await tx.medicineBatch.findUnique({
          where: {
            shopId_medicineId_batchNumber: {
              shopId,
              medicineId: item.medicineId,
              batchNumber: item.batchNumber,
            },
          },
        });

        let batchId: string;
        let balanceAfter: number;

        if (existingBatch) {
          const updated = await tx.medicineBatch.update({
            where: { id: existingBatch.id },
            data: {
              currentQuantity: { increment: totalReceivedQty },
              purchaseRate: new Decimal(item.purchaseRate),
              mrp: new Decimal(item.mrp),
              sellingPrice: new Decimal(item.sellingPrice),
              expiryDate: item.expiryDate,
              status: "ACTIVE",
            },
          });
          batchId = updated.id;
          balanceAfter = updated.currentQuantity;
        } else {
          const created = await tx.medicineBatch.create({
            data: {
              shopId,
              medicineId: item.medicineId,
              supplierId,
              batchNumber: item.batchNumber,
              manufacturingDate: item.manufacturingDate,
              expiryDate: item.expiryDate,
              mrp: new Decimal(item.mrp),
              purchaseRate: new Decimal(item.purchaseRate),
              sellingPrice: new Decimal(item.sellingPrice),
              currentQuantity: totalReceivedQty,
              status: "ACTIVE",
            },
          });
          batchId = created.id;
          balanceAfter = created.currentQuantity;
        }

        // Create immutable StockTransaction ledger entry
        await tx.stockTransaction.create({
          data: {
            shopId,
            batchId,
            medicineId: item.medicineId,
            transactionType: STOCK_TRANSACTION_TYPE.PURCHASE,
            quantityDelta: totalReceivedQty,
            balanceAfter,
            referenceType: "PURCHASE_INVOICE",
            referenceId: invoice.id,
            notes: `Purchase Bill ${data.invoiceNumber} (${item.quantity} + ${item.freeQuantity} free)`,
            performedById: userId,
          },
        });

        // Update medicine master rates
        await tx.medicine.update({
          where: { id: item.medicineId },
          data: {
            purchaseRate: new Decimal(item.purchaseRate),
            mrp: new Decimal(item.mrp),
            sellingPrice: new Decimal(item.sellingPrice),
          },
        });

        // Create line item record
        await tx.purchaseInvoiceItem.create({
          data: {
            purchaseInvoiceId: invoice.id,
            medicineId: item.medicineId,
            batchId,
            batchNumber: item.batchNumber,
            expiryDate: item.expiryDate,
            quantity: item.quantity,
            freeQuantity: item.freeQuantity,
            purchaseRate: new Decimal(item.purchaseRate),
            mrp: new Decimal(item.mrp),
            sellingPrice: new Decimal(item.sellingPrice),
            discountPercent: new Decimal(item.discountPercent),
            taxRate: new Decimal(item.taxRate),
            totalAmount: new Decimal(item.lineTotal),
          },
        });
      }

      // 3. Increment supplier outstanding balance
      await tx.supplier.update({
        where: { id: supplierId },
        data: {
          outstandingBalance: { increment: new Decimal(finalTotal) },
        },
      });

      // 4. If linked to Purchase Order, mark order as COMPLETED
      if (data.purchaseOrderId) {
        await tx.purchaseOrder.update({
          where: { id: data.purchaseOrderId },
          data: { status: PURCHASE_ORDER_STATUS.COMPLETED },
        });
      }

      return invoice;
    });

    return this.getInvoiceById(shopId, result.id);
  }

  /**
   * List Purchase Invoices with Filters & Pagination (Scoped to shop)
   */
  async listInvoices(shopId: string, query: QueryPurchasesInput) {
    const { supplierId, search, paymentStatus, page, limit } = query;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { shopId };

    if (supplierId) where.supplierId = supplierId;
    if (paymentStatus) where.paymentStatus = paymentStatus;
    if (search) {
      where.OR = [
        { invoiceNumber: { contains: search, mode: "insensitive" } },
        { internalNumber: { contains: search, mode: "insensitive" } },
        { supplier: { name: { contains: search, mode: "insensitive" } } },
      ];
    }

    const [items, total] = await Promise.all([
      prisma.purchaseInvoice.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          supplier: {
            select: { id: true, name: true, mobile: true, gstin: true },
          },
          _count: { select: { items: true } },
        },
      }),
      prisma.purchaseInvoice.count({ where }),
    ]);

    return {
      items,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get Single Purchase Invoice by ID (Scoped to shop)
   */
  async getInvoiceById(shopId: string, id: string) {
    const invoice = await prisma.purchaseInvoice.findFirst({
      where: { id, shopId },
      include: {
        supplier: true,
        items: {
          include: {
            medicine: { select: { id: true, name: true, genericName: true, dosageForm: true } },
            batch: { select: { id: true, currentQuantity: true, status: true } },
          },
        },
        payments: {
          orderBy: { paymentDate: "desc" },
        },
        returns: {
          include: { items: true },
        },
      },
    });

    if (!invoice) {
      throw AppError.notFound("Purchase invoice not found in your store");
    }

    return invoice;
  }

  /**
   * Process Purchase Return (Stock Deduction, Scoped to shop)
   */
  async createPurchaseReturn(shopId: string, data: CreatePurchaseReturnInput, userId?: string) {
    const supplier = await prisma.supplier.findFirst({
      where: { id: data.supplierId, shopId },
    });

    if (!supplier) {
      throw AppError.notFound("Supplier not found in your store");
    }

    const returnCount = await prisma.purchaseReturn.count({ where: { shopId } });
    const returnNumber = getSequenceNumber("PR", returnCount);

    const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      let returnTotal = 0;
      const processedReturnItems: Array<{
        batchId: string;
        medicineId: string;
        quantity: number;
        returnRate: number;
        lineTotal: number;
      }> = [];

      for (const item of data.items) {
        const lockedBatches: Array<{
          id: string;
          medicine_id: string;
          current_quantity: number;
          batch_number: string;
        }> = await tx.$queryRaw`
          SELECT id, medicine_id, current_quantity, batch_number 
          FROM medicine_batches 
          WHERE id = ${item.batchId} AND shop_id = ${shopId}
          FOR UPDATE
        `;

        if (!lockedBatches || lockedBatches.length === 0) {
          throw AppError.notFound(`Batch not found in your store: ${item.batchId}`);
        }

        const batch = lockedBatches[0];

        if (batch.current_quantity < item.quantity) {
          throw AppError.badRequest(
            `Insufficient stock in batch ${batch.batch_number} to return. Available: ${batch.current_quantity}, Requested: ${item.quantity}`
          );
        }

        const lineTotal = item.quantity * item.returnRate;
        returnTotal += lineTotal;

        const newBalance = batch.current_quantity - item.quantity;

        // Decrement batch stock
        await tx.medicineBatch.update({
          where: { id: item.batchId },
          data: { currentQuantity: newBalance },
        });

        // Immutable ledger entry
        await tx.stockTransaction.create({
          data: {
            shopId,
            batchId: item.batchId,
            medicineId: batch.medicine_id,
            transactionType: STOCK_TRANSACTION_TYPE.RETURN_OUT,
            quantityDelta: -item.quantity,
            balanceAfter: newBalance,
            referenceType: "PURCHASE_RETURN",
            notes: `Return to supplier: ${supplier.name} (${data.reason})`,
            performedById: userId,
          },
        });

        processedReturnItems.push({
          batchId: item.batchId,
          medicineId: batch.medicine_id,
          quantity: item.quantity,
          returnRate: item.returnRate,
          lineTotal,
        });
      }

      // Create return record
      const purchaseReturn = await tx.purchaseReturn.create({
        data: {
          shopId,
          returnNumber,
          supplierId: data.supplierId,
          purchaseInvoiceId: data.purchaseInvoiceId,
          reason: data.reason,
          totalAmount: new Decimal(returnTotal),
          status: "CONFIRMED",
          createdById: userId,
          items: {
            create: processedReturnItems.map((p) => ({
              medicineId: p.medicineId,
              batchId: p.batchId,
              quantity: p.quantity,
              returnRate: new Decimal(p.returnRate),
              totalAmount: new Decimal(p.lineTotal),
            })),
          },
        },
        include: {
          items: true,
        },
      });

      // Decrement supplier outstanding debt
      await tx.supplier.update({
        where: { id: data.supplierId },
        data: {
          outstandingBalance: { decrement: new Decimal(returnTotal) },
        },
      });

      return purchaseReturn;
    });

    return result;
  }

  /**
   * Record Supplier Payment & Settle Invoice Balance (Scoped to shop)
   */
  async recordSupplierPayment(shopId: string, data: RecordSupplierPaymentInput, userId?: string) {
    const supplier = await prisma.supplier.findFirst({
      where: { id: data.supplierId, shopId },
    });

    if (!supplier) {
      throw AppError.notFound("Supplier not found in your store");
    }

    const payCount = await prisma.supplierPayment.count({ where: { shopId } });
    const paymentNumber = getSequenceNumber("SP", payCount);

    const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const payment = await tx.supplierPayment.create({
        data: {
          shopId,
          paymentNumber,
          supplierId: data.supplierId,
          purchaseInvoiceId: data.purchaseInvoiceId,
          amount: new Decimal(data.amount),
          paymentMode: data.paymentMode,
          referenceNumber: data.referenceNumber,
          notes: data.notes,
          createdById: userId,
        },
      });

      if (data.purchaseInvoiceId) {
        const invoice = await tx.purchaseInvoice.findFirst({
          where: { id: data.purchaseInvoiceId, shopId },
        });

        if (invoice) {
          const newPaid = Number(invoice.paidAmount) + data.amount;
          const newBalance = Math.max(0, Number(invoice.totalAmount) - newPaid);
          const newStatus =
            newBalance <= 0
              ? PURCHASE_PAYMENT_STATUS.PAID
              : PURCHASE_PAYMENT_STATUS.PARTIALLY_PAID;

          await tx.purchaseInvoice.update({
            where: { id: data.purchaseInvoiceId },
            data: {
              paidAmount: new Decimal(newPaid),
              balanceAmount: new Decimal(newBalance),
              paymentStatus: newStatus,
            },
          });
        }
      }

      await tx.supplier.update({
        where: { id: data.supplierId },
        data: {
          outstandingBalance: { decrement: new Decimal(data.amount) },
        },
      });

      return payment;
    });

    return result;
  }
}

export const purchasesService = new PurchasesService();
