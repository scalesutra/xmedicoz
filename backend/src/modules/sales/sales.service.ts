import { Prisma } from "@prisma/client";
import { Decimal } from "@prisma/client/runtime/library";
import { prisma } from "../../infrastructure/database/prisma.client.js";
import { AppError } from "../../utils/errors.js";
import {
  STOCK_TRANSACTION_TYPE,
  SALES_PAYMENT_STATUS,
  PAYMENT_MODE,
  ERROR_CODES,
} from "../../config/constants.js";
import type {
  CreateSalesInvoiceInput,
  CreateSalesReturnInput,
  QuerySalesInput,
} from "./sales.schema.js";

function getSequenceNumber(prefix: string, count: number): string {
  const year = new Date().getFullYear();
  const seq = String(count + 1).padStart(5, "0");
  return `${prefix}-${year}-${seq}`;
}

export class SalesService {
  /**
   * High-Speed Counter Checkout & Atomic POS Invoicing (Scoped to active shop)
   */
  async createInvoice(shopId: string, data: CreateSalesInvoiceInput, cashierId?: string) {
    // 1. Verify shop & subscription limits
    const shop = await prisma.shop.findUnique({
      where: { id: shopId },
      include: { subscription: { include: { plan: true } } },
    });

    if (!shop) {
      throw AppError.notFound("Medical store not found", ERROR_CODES.SHOP_NOT_FOUND);
    }

    // Check monthly invoice quota
    if (shop.subscription) {
      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      const invoicesThisMonth = await prisma.salesInvoice.count({
        where: { shopId, createdAt: { gte: startOfMonth } },
      });

      const maxInvoices = shop.subscription.plan.maxInvoicesPerMonth;
      if (invoicesThisMonth >= maxInvoices) {
        throw AppError.forbidden(
          `Monthly invoice limit (${maxInvoices}) reached for plan '${shop.subscription.plan.name}'. Please upgrade your subscription.`,
          ERROR_CODES.SUBSCRIPTION_LIMIT_EXCEEDED
        );
      }
    }

    let customer = null;
    if (data.customerId) {
      customer = await prisma.customer.findFirst({
        where: { id: data.customerId, shopId },
      });
      if (!customer) {
        throw AppError.notFound("Customer not found in your store");
      }
    }

    const count = await prisma.salesInvoice.count({ where: { shopId } });
    const invoicePrefix = shop.invoicePrefix || "INV";
    const invoiceNumber = getSequenceNumber(invoicePrefix, count);

    const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      let subtotal = 0;
      let totalDiscount = 0;
      let totalTax = 0;

      const processedItems: Array<{
        medicineId: string;
        batchId: string;
        batchNumber: string;
        quantity: number;
        unitPrice: number;
        mrp: number;
        discountAmount: number;
        taxRate: number;
        taxAmount: number;
        lineTotal: number;
        newBatchBalance: number;
      }> = [];

      // 1. Process and lock each candidate batch using row-level locking
      for (const item of data.items) {
        const lockedBatches: Array<{
          id: string;
          shop_id: string;
          medicine_id: string;
          current_quantity: number;
          batch_number: string;
          mrp: Decimal | number | string;
          selling_price: Decimal | number | string;
          expiry_date: Date;
          status: string;
        }> = await tx.$queryRaw`
          SELECT id, shop_id, medicine_id, current_quantity, batch_number, mrp, selling_price, expiry_date, status
          FROM medicine_batches
          WHERE id = ${item.batchId} AND shop_id = ${shopId}
          FOR UPDATE
        `;

        if (!lockedBatches || lockedBatches.length === 0) {
          throw AppError.notFound(`Batch not found in your store: ${item.batchId}`);
        }

        const batch = lockedBatches[0];

        if (batch.medicine_id !== item.medicineId) {
          throw AppError.badRequest(
            `Batch ${batch.batch_number} does not belong to the specified medicine`
          );
        }

        // Validate expiry
        const now = new Date();
        if (batch.status === "EXPIRED" || new Date(batch.expiry_date) <= now) {
          throw AppError.badRequest(
            `Batch ${batch.batch_number} is expired and cannot be sold`
          );
        }

        // Validate sufficient quantity
        if (batch.current_quantity < item.quantity) {
          throw AppError.badRequest(
            `Insufficient stock for batch ${batch.batch_number}. Available: ${batch.current_quantity}, Requested: ${item.quantity}`
          );
        }

        const mrp = Number(batch.mrp);
        const unitPrice = item.unitPrice ?? Number(batch.selling_price);
        const gross = unitPrice * item.quantity;
        const discount = item.discountAmount || 0;
        const taxable = Math.max(0, gross - discount);
        const tax = taxable * (item.taxRate / 100);
        const lineTotal = taxable + tax;

        subtotal += gross;
        totalDiscount += discount;
        totalTax += tax;

        const newBatchBalance = batch.current_quantity - item.quantity;

        // Decrement batch inventory
        await tx.medicineBatch.update({
          where: { id: item.batchId },
          data: {
            currentQuantity: newBatchBalance,
          },
        });

        processedItems.push({
          medicineId: item.medicineId,
          batchId: item.batchId,
          batchNumber: batch.batch_number,
          quantity: item.quantity,
          unitPrice,
          mrp,
          discountAmount: discount,
          taxRate: item.taxRate,
          taxAmount: tax,
          lineTotal,
          newBatchBalance,
        });
      }

      const totalBillAmount = subtotal - totalDiscount + totalTax;

      // Handle automatic payment resolution
      for (const p of data.payments) {
        if (!p.amount || p.amount <= 0) {
          p.amount = totalBillAmount;
        }
      }

      // If payments is completely empty and no customer is provided, default to full CASH payment
      if (data.payments.length === 0 && !data.customerId) {
        data.payments.push({
          amount: totalBillAmount,
          paymentMode: PAYMENT_MODE.CASH,
        });
      }

      // 2. Validate Payment Breakdown & Credit Limits
      const totalPaidAmount = data.payments.reduce((acc, p) => acc + p.amount, 0);
      const balanceAmount = Math.max(0, totalBillAmount - totalPaidAmount);

      let paymentStatus: string = SALES_PAYMENT_STATUS.PAID;
      if (balanceAmount > 0) {
        if (!data.customerId) {
          throw AppError.badRequest(
            "Customer registration is required for credit / partial balance sales"
          );
        }
        paymentStatus =
          totalPaidAmount === 0
            ? SALES_PAYMENT_STATUS.UNPAID
            : SALES_PAYMENT_STATUS.PARTIALLY_PAID;

        // Check customer credit limit
        if (customer) {
          const currentBal = Number(customer.currentBalance);
          const limit = Number(customer.creditLimit);
          if (limit > 0 && currentBal + balanceAmount > limit) {
            throw AppError.badRequest(
              `Credit limit exceeded. Limit: ${limit}, Current Debt: ${currentBal}, New Balance: ${balanceAmount}`
            );
          }
        }
      }

      // 3. Create Sales Invoice
      const invoice = await tx.salesInvoice.create({
        data: {
          shopId,
          invoiceNumber,
          customerId: data.customerId,
          customerName: data.customerName || customer?.name,
          customerMobile: data.customerMobile || customer?.mobile,
          invoiceDate: new Date(),
          subtotal: new Decimal(subtotal),
          discountAmount: new Decimal(totalDiscount),
          taxAmount: new Decimal(totalTax),
          totalAmount: new Decimal(totalBillAmount),
          paidAmount: new Decimal(totalPaidAmount),
          balanceAmount: new Decimal(balanceAmount),
          paymentStatus,
          doctorName: data.doctorName,
          doctorRegNo: data.doctorRegNo,
          notes: data.notes,
          status: "COMPLETED",
          cashierId,
        },
      });

      // 4. Create Items & Stock Ledger Entries
      for (const item of processedItems) {
        await tx.salesInvoiceItem.create({
          data: {
            salesInvoiceId: invoice.id,
            medicineId: item.medicineId,
            batchId: item.batchId,
            batchNumber: item.batchNumber,
            quantity: item.quantity,
            unitPrice: new Decimal(item.unitPrice),
            mrp: new Decimal(item.mrp),
            discountAmount: new Decimal(item.discountAmount),
            taxRate: new Decimal(item.taxRate),
            taxAmount: new Decimal(item.taxAmount),
            totalAmount: new Decimal(item.lineTotal),
          },
        });

        // Immutable stock ledger
        await tx.stockTransaction.create({
          data: {
            shopId,
            batchId: item.batchId,
            medicineId: item.medicineId,
            transactionType: STOCK_TRANSACTION_TYPE.SALE,
            quantityDelta: -item.quantity,
            balanceAfter: item.newBatchBalance,
            referenceType: "SALES_INVOICE",
            referenceId: invoice.id,
            notes: `Counter Sale ${invoiceNumber}`,
            performedById: cashierId,
          },
        });
      }

      // 5. Create Payment records
      for (const p of data.payments) {
        if (p.amount > 0 && p.paymentMode !== PAYMENT_MODE.CREDIT) {
          await tx.salesPayment.create({
            data: {
              salesInvoiceId: invoice.id,
              amount: new Decimal(p.amount),
              paymentMode: p.paymentMode,
              referenceNumber: p.referenceNumber,
            },
          });
        }
      }

      // 6. If balance unpaid or credit payment, update customer's current balance
      if (balanceAmount > 0 && data.customerId) {
        await tx.customer.update({
          where: { id: data.customerId },
          data: {
            currentBalance: { increment: new Decimal(balanceAmount) },
          },
        });
      }

      return invoice;
    });

    return this.getInvoiceById(shopId, result.id);
  }

  /**
   * List Sales Invoices with Filters & Pagination (Scoped to active shop)
   */
  async listInvoices(shopId: string, query: QuerySalesInput) {
    const { customerId, paymentStatus, search, startDate, endDate, page, limit } = query;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { shopId };

    if (customerId) where.customerId = customerId;
    if (paymentStatus) where.paymentStatus = paymentStatus;

    if (startDate || endDate) {
      where.invoiceDate = {};
      if (startDate) (where.invoiceDate as Record<string, unknown>).gte = new Date(startDate);
      if (endDate) (where.invoiceDate as Record<string, unknown>).lte = new Date(endDate);
    }

    if (search) {
      where.OR = [
        { invoiceNumber: { contains: search, mode: "insensitive" } },
        { customerName: { contains: search, mode: "insensitive" } },
        { customerMobile: { contains: search, mode: "insensitive" } },
      ];
    }

    const [items, total] = await Promise.all([
      prisma.salesInvoice.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          customer: { select: { id: true, name: true, mobile: true, isPermanent: true } },
          cashier: { select: { id: true, firstName: true, lastName: true } },
          _count: { select: { items: true, payments: true } },
        },
      }),
      prisma.salesInvoice.count({ where }),
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
   * Get Single Sales Invoice by ID (Scoped to active shop)
   */
  async getInvoiceById(shopId: string, id: string) {
    const invoice = await prisma.salesInvoice.findFirst({
      where: { id, shopId },
      include: {
        customer: true,
        cashier: { select: { id: true, firstName: true, lastName: true, email: true } },
        items: {
          include: {
            medicine: { select: { id: true, name: true, genericName: true, dosageForm: true } },
            batch: { select: { id: true, batchNumber: true, expiryDate: true, currentQuantity: true } },
          },
        },
        payments: true,
        returns: {
          include: { items: true },
        },
      },
    });

    if (!invoice) {
      throw AppError.notFound("Sales invoice not found in your store");
    }

    return invoice;
  }

  /**
   * Process Sales Return & Automatic Restock (Scoped to active shop)
   */
  async createSalesReturn(shopId: string, data: CreateSalesReturnInput, cashierId?: string) {
    const invoice = await prisma.salesInvoice.findFirst({
      where: { id: data.salesInvoiceId, shopId },
      include: { items: true },
    });

    if (!invoice) {
      throw AppError.notFound("Sales invoice not found in your store");
    }

    const returnCount = await prisma.salesReturn.count({ where: { shopId } });
    const returnNumber = getSequenceNumber("CN", returnCount);

    const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      let totalReturnAmount = 0;
      const processedReturnItems: Array<{
        medicineId: string;
        batchId: string;
        quantity: number;
        refundRate: number;
        lineTotal: number;
      }> = [];

      for (const item of data.items) {
        const soldItem = invoice.items.find((i: { id: string }) => i.id === item.salesItemId);
        if (!soldItem) {
          throw AppError.badRequest(`Item not found in the original invoice: ${item.salesItemId}`);
        }

        if (item.quantity > soldItem.quantity) {
          throw AppError.badRequest(
            `Return quantity (${item.quantity}) cannot exceed purchased quantity (${soldItem.quantity})`
          );
        }

        const refundRate = item.refundRate ?? Number(soldItem.unitPrice);
        const lineTotal = item.quantity * refundRate;
        totalReturnAmount += lineTotal;

        // Lock batch to restock safely
        const lockedBatches: Array<{
          id: string;
          current_quantity: number;
        }> = await tx.$queryRaw`
          SELECT id, current_quantity
          FROM medicine_batches
          WHERE id = ${soldItem.batchId} AND shop_id = ${shopId}
          FOR UPDATE
        `;

        const currentBatchQty = lockedBatches[0]?.current_quantity ?? 0;
        const restoredBalance = currentBatchQty + item.quantity;

        // Restock batch
        await tx.medicineBatch.update({
          where: { id: soldItem.batchId },
          data: {
            currentQuantity: restoredBalance,
          },
        });

        // Immutable ledger entry: RETURN_IN
        await tx.stockTransaction.create({
          data: {
            shopId,
            batchId: soldItem.batchId,
            medicineId: soldItem.medicineId,
            transactionType: STOCK_TRANSACTION_TYPE.RETURN_IN,
            quantityDelta: item.quantity,
            balanceAfter: restoredBalance,
            referenceType: "SALES_RETURN",
            notes: `Sales Return Credit Note ${returnNumber} for Invoice ${invoice.invoiceNumber}`,
            performedById: cashierId,
          },
        });

        processedReturnItems.push({
          medicineId: soldItem.medicineId,
          batchId: soldItem.batchId,
          quantity: item.quantity,
          refundRate,
          lineTotal,
        });
      }

      // Create Sales Return record
      const salesReturn = await tx.salesReturn.create({
        data: {
          shopId,
          returnNumber,
          salesInvoiceId: invoice.id,
          customerId: invoice.customerId,
          refundMode: data.refundMode,
          reason: data.reason,
          totalAmount: new Decimal(totalReturnAmount),
          createdById: cashierId,
          items: {
            create: processedReturnItems.map((p) => ({
              medicineId: p.medicineId,
              batchId: p.batchId,
              quantity: p.quantity,
              refundRate: new Decimal(p.refundRate),
              totalAmount: new Decimal(p.lineTotal),
            })),
          },
        },
        include: {
          items: true,
        },
      });

      // If original invoice was a credit sale or customer has outstanding balance and refund is CREDIT_NOTE
      if (invoice.customerId && (data.refundMode === "CREDIT_NOTE" || Number(invoice.balanceAmount) > 0)) {
        await tx.customer.update({
          where: { id: invoice.customerId },
          data: {
            currentBalance: { decrement: new Decimal(totalReturnAmount) },
          },
        });
      }

      return salesReturn;
    });

    return result;
  }
}

export const salesService = new SalesService();
