import { Prisma } from "@prisma/client";
import { prisma } from "../../infrastructure/database/prisma.client.js";
import { AppError } from "../../utils/errors.js";
import { BATCH_STATUS, STOCK_TRANSACTION_TYPE } from "../../config/constants.js";

export class InventoryService {
  /**
   * List Batches with filters and search (Scoped to active shop)
   */
  static async listBatches(
    shopId: string,
    query: {
      page: number;
      limit: number;
      search?: string;
      medicineId?: string;
      status?: string;
      inStockOnly?: boolean;
    }
  ) {
    const { page, limit, search, medicineId, status, inStockOnly } = query;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { shopId };

    if (status) {
      where.status = status;
    }

    if (medicineId) {
      where.medicineId = medicineId;
    }

    if (inStockOnly) {
      where.currentQuantity = { gt: 0 };
    }

    if (search && search.trim()) {
      const term = search.trim();
      where.OR = [
        { batchNumber: { contains: term, mode: "insensitive" } },
        { medicine: { name: { contains: term, mode: "insensitive" } } },
        { medicine: { genericName: { contains: term, mode: "insensitive" } } },
      ];
    }

    const [total, batches] = await Promise.all([
      prisma.medicineBatch.count({ where }),
      prisma.medicineBatch.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ expiryDate: "asc" }, { batchNumber: "asc" }],
        include: {
          medicine: {
            select: {
              id: true,
              name: true,
              genericName: true,
              brand: true,
              dosageForm: true,
              unit: { select: { name: true, abbreviation: true } },
            },
          },
          supplier: {
            select: { id: true, name: true, contactPerson: true, mobile: true },
          },
        },
      }),
    ]);

    return {
      items: batches,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get eligible batches for FEFO-based sales checkout
   */
  static async getEligibleBatchesForMedicine(shopId: string, medicineId: string) {
    const today = new Date();

    const batches = await prisma.medicineBatch.findMany({
      where: {
        shopId,
        medicineId,
        status: BATCH_STATUS.ACTIVE,
        currentQuantity: { gt: 0 },
        expiryDate: { gt: today },
      },
      orderBy: { expiryDate: "asc" },
      select: {
        id: true,
        batchNumber: true,
        expiryDate: true,
        currentQuantity: true,
        mrp: true,
        sellingPrice: true,
        purchaseRate: true,
      },
    });

    return batches;
  }

  /**
   * Create New Batch with Opening Stock Transaction in an atomic transaction
   */
  static async createBatch(
    shopId: string,
    data: {
      medicineId: string;
      supplierId?: string | null;
      batchNumber: string;
      manufacturingDate?: string | null;
      expiryDate: string;
      mrp: number;
      purchaseRate: number;
      sellingPrice: number;
      initialQuantity?: number;
      notes?: string;
    },
    userId?: string
  ) {
    // Check if batch number already exists for this medicine in this shop
    const existing = await prisma.medicineBatch.findUnique({
      where: {
        shopId_medicineId_batchNumber: {
          shopId,
          medicineId: data.medicineId,
          batchNumber: data.batchNumber.trim().toUpperCase(),
        },
      },
    });

    if (existing) {
      throw AppError.conflict(
        `Batch number '${data.batchNumber}' already exists for this medicine in your store. Use stock adjustment to add quantity.`
      );
    }

    const expiry = new Date(data.expiryDate);
    const isExpired = expiry <= new Date();
    const status = isExpired ? BATCH_STATUS.EXPIRED : BATCH_STATUS.ACTIVE;
    const initialQty = data.initialQuantity ?? 0;

    return await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      // 1. Create Batch
      const batch = await tx.medicineBatch.create({
        data: {
          shopId,
          medicineId: data.medicineId,
          supplierId: data.supplierId,
          batchNumber: data.batchNumber.trim().toUpperCase(),
          manufacturingDate: data.manufacturingDate ? new Date(data.manufacturingDate) : null,
          expiryDate: expiry,
          mrp: data.mrp,
          purchaseRate: data.purchaseRate,
          sellingPrice: data.sellingPrice,
          currentQuantity: initialQty,
          status,
        },
        include: {
          medicine: { select: { name: true } },
        },
      });

      // 2. If opening stock provided, record opening StockTransaction
      if (initialQty > 0) {
        await tx.stockTransaction.create({
          data: {
            shopId,
            batchId: batch.id,
            medicineId: batch.medicineId,
            transactionType: STOCK_TRANSACTION_TYPE.OPENING,
            quantityDelta: initialQty,
            balanceAfter: initialQty,
            referenceType: "OPENING",
            notes: data.notes || "Initial Opening Stock Entry",
            performedById: userId,
          },
        });
      }

      return batch;
    });
  }

  /**
   * Adjust Stock with Row-Level Locking (SELECT ... FOR UPDATE) and Immutable Ledger
   */
  static async adjustStock(
    shopId: string,
    data: {
      batchId: string;
      type: string; // ADJUSTMENT_ADD, ADJUSTMENT_SUB, DAMAGE
      quantity: number;
      reason: string;
      notes?: string;
    },
    userId?: string
  ) {
    return await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      // 1. Lock batch row with raw SQL FOR UPDATE to eliminate race conditions
      const lockedBatches = await tx.$queryRaw<
        Array<{ id: string; shop_id: string; current_quantity: number; medicine_id: string; batch_number: string }>
      >`SELECT id, shop_id, current_quantity, medicine_id, batch_number FROM medicine_batches WHERE id = ${data.batchId} AND shop_id = ${shopId} FOR UPDATE`;

      if (!lockedBatches || lockedBatches.length === 0) {
        throw AppError.notFound("Medicine batch not found in your store");
      }

      const batch = lockedBatches[0];
      const currentQty = batch.current_quantity;
      const isDeduction =
        data.type === STOCK_TRANSACTION_TYPE.ADJUSTMENT_SUB || data.type === STOCK_TRANSACTION_TYPE.DAMAGE;
      const quantityDelta = isDeduction ? -data.quantity : data.quantity;
      const newQuantity = currentQty + quantityDelta;

      if (newQuantity < 0) {
        throw AppError.badRequest(
          `Cannot deduct ${data.quantity} units. Available batch quantity is only ${currentQty}.`
        );
      }

      // 2. Update Batch Quantity
      const updatedBatch = await tx.medicineBatch.update({
        where: { id: data.batchId },
        data: { currentQuantity: newQuantity },
      });

      // 3. Append Immutable Audit Ledger Record
      await tx.stockTransaction.create({
        data: {
          shopId,
          batchId: batch.id,
          medicineId: batch.medicine_id,
          transactionType: data.type,
          quantityDelta,
          balanceAfter: newQuantity,
          referenceType: "ADJUSTMENT",
          notes: `${data.reason}${data.notes ? ` - ${data.notes}` : ""}`,
          performedById: userId,
        },
      });

      return {
        batchId: updatedBatch.id,
        batchNumber: batch.batch_number,
        previousQuantity: currentQty,
        quantityDelta,
        currentQuantity: newQuantity,
      };
    });
  }

  /**
   * Near Expiry & Expired Stock Report (Scoped to shop)
   */
  static async getNearExpiryBatches(shopId: string, daysThreshold: number = 90, page: number = 1, limit: number = 20) {
    const today = new Date();
    const thresholdDate = new Date();
    thresholdDate.setDate(thresholdDate.getDate() + daysThreshold);

    const skip = (page - 1) * limit;

    const where = {
      shopId,
      expiryDate: { lte: thresholdDate },
      currentQuantity: { gt: 0 },
    };

    const [total, batches] = await Promise.all([
      prisma.medicineBatch.count({ where }),
      prisma.medicineBatch.findMany({
        where,
        skip,
        take: limit,
        orderBy: { expiryDate: "asc" },
        include: {
          medicine: {
            select: { id: true, name: true, genericName: true, unit: true },
          },
        },
      }),
    ]);

    const enriched = (batches as Array<any>).map((b: any) => {
      const isExpired = b.expiryDate <= today;
      const diffMs = b.expiryDate.getTime() - today.getTime();
      const daysRemaining = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

      return {
        ...b,
        isExpired,
        daysRemaining: isExpired ? 0 : daysRemaining,
        condition: isExpired ? "EXPIRED" : "NEAR_EXPIRY",
      };
    });

    return {
      items: enriched,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Low Stock Medicines Alert (Scoped to shop)
   */
  static async getLowStockMedicines(shopId: string, page: number = 1, limit: number = 20) {
    const skip = (page - 1) * limit;

    const medicines = await prisma.medicine.findMany({
      where: { shopId, status: "ACTIVE" },
      include: {
        batches: {
          where: { status: BATCH_STATUS.ACTIVE },
          select: { currentQuantity: true },
        },
        unit: { select: { name: true, abbreviation: true } },
        category: { select: { name: true } },
      },
    });

    const lowStockItems = (medicines as Array<any>)
      .map((m: any) => {
        const totalStock = m.batches.reduce((sum: number, b: any) => sum + b.currentQuantity, 0);
        return {
          id: m.id,
          name: m.name,
          genericName: m.genericName,
          dosageForm: m.dosageForm,
          unit: m.unit?.name,
          category: m.category?.name,
          reorderLevel: m.reorderLevel,
          totalStock,
          isLowStock: totalStock <= m.reorderLevel,
          deficit: m.reorderLevel - totalStock > 0 ? m.reorderLevel - totalStock : 0,
        };
      })
      .filter((m: any) => m.isLowStock);

    const total = lowStockItems.length;
    const paginatedItems = lowStockItems.slice(skip, skip + limit);

    return {
      items: paginatedItems,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Stock Transaction Ledger (Scoped to shop)
   */
  static async getStockLedger(
    shopId: string,
    query: {
      page: number;
      limit: number;
      batchId?: string;
      medicineId?: string;
      transactionType?: string;
    }
  ) {
    const { page, limit, batchId, medicineId, transactionType } = query;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { shopId };
    if (batchId) where.batchId = batchId;
    if (medicineId) where.medicineId = medicineId;
    if (transactionType) where.transactionType = transactionType;

    const [total, transactions] = await Promise.all([
      prisma.stockTransaction.count({ where }),
      prisma.stockTransaction.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          batch: { select: { batchNumber: true, expiryDate: true } },
          medicine: { select: { name: true, genericName: true } },
          performedBy: { select: { firstName: true, lastName: true, email: true } },
        },
      }),
    ]);

    return {
      items: transactions,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Stock Valuation Summary (Scoped to shop)
   */
  static async getStockValuation(shopId: string) {
    const batches = await prisma.medicineBatch.findMany({
      where: { shopId, currentQuantity: { gt: 0 } },
      select: {
        currentQuantity: true,
        purchaseRate: true,
        sellingPrice: true,
        mrp: true,
      },
    });

    let totalQuantity = 0;
    let totalCostValue = 0;
    let totalRetailValue = 0;
    let totalMrpValue = 0;

    for (const b of batches) {
      const qty = b.currentQuantity;
      totalQuantity += qty;
      totalCostValue += Number(b.purchaseRate) * qty;
      totalRetailValue += Number(b.sellingPrice) * qty;
      totalMrpValue += Number(b.mrp) * qty;
    }

    const potentialMargin = totalRetailValue - totalCostValue;
    const marginPercentage = totalCostValue > 0 ? (potentialMargin / totalCostValue) * 100 : 0;

    return {
      totalBatchesWithStock: batches.length,
      totalUnitsInStock: totalQuantity,
      totalCostValue: Number(totalCostValue.toFixed(2)),
      totalRetailValue: Number(totalRetailValue.toFixed(2)),
      totalMrpValue: Number(totalMrpValue.toFixed(2)),
      potentialProfitMargin: Number(potentialMargin.toFixed(2)),
      marginPercentage: Number(marginPercentage.toFixed(2)),
    };
  }
}
