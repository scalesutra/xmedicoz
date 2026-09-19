import { prisma } from "../../../infrastructure/database/prisma.client.js";
import { AppError } from "../../../utils/errors.js";
import { STOCK_TRANSACTION_TYPE, BATCH_STATUS } from "../../../config/constants.js";
import type {
  CreateRackInput,
  UpdateRackInput,
  QueryRackInput,
  CreateShelfInput,
  UpdateShelfInput,
  AssignMedicineRackInput,
  TransferRackInput,
} from "./rack.schema.js";

export class RackService {
  /**
   * List all Racks for the current shop with capacity & medicine counts
   */
  static async listRacks(shopId: string, query: QueryRackInput) {
    const { zone, storageType, status, search } = query;
    const where: Record<string, unknown> = { shopId };

    if (zone) where.zone = zone;
    if (storageType) where.storageType = storageType;
    if (status) where.status = status;
    if (search && search.trim()) {
      const term = search.trim();
      where.OR = [
        { code: { contains: term, mode: "insensitive" } },
        { name: { contains: term, mode: "insensitive" } },
        { description: { contains: term, mode: "insensitive" } },
      ];
    }

    const racks = await prisma.rack.findMany({
      where,
      orderBy: [{ zone: "asc" }, { code: "asc" }],
      include: {
        _count: {
          select: {
            medicines: true,
            shelves: true,
          },
        },
        shelves: {
          orderBy: { shelfNumber: "asc" },
          select: {
            id: true,
            shelfNumber: true,
            shelfLabel: true,
            maxCapacity: true,
            barcode: true,
            temperature: true,
          },
        },
      },
    });

    // Fetch active medicines for shop to accurately count items assigned by either rackId or rack code
    const shopMedicines = await prisma.medicine.findMany({
      where: { shopId, status: "ACTIVE" },
      select: { id: true, rackId: true, rack: true },
    });

    return racks.map((rack) => {
      const totalEstimatedCapacity = rack.shelves.reduce(
        (sum, s) => sum + (s.maxCapacity || 100),
        0
      );

      const assignedCount = shopMedicines.filter(
        (m) =>
          m.rackId === rack.id ||
          (m.rack && m.rack.trim().toUpperCase() === rack.code.trim().toUpperCase())
      ).length;

      const occupancyPercentage =
        totalEstimatedCapacity > 0
          ? Math.min(100, Math.round((assignedCount / totalEstimatedCapacity) * 100))
          : 0;

      return {
        ...rack,
        activeMedicinesCount: assignedCount,
        totalCapacity: totalEstimatedCapacity,
        occupancyPercentage,
      };
    });
  }

  /**
   * Get single Rack by ID with detailed shelf contents & medicines
   */
  static async getRackDetails(shopId: string, rackId: string) {
    const rack = await prisma.rack.findFirst({
      where: { id: rackId, shopId },
      include: {
        shelves: {
          orderBy: { shelfNumber: "asc" },
          include: {
            bins: {
              orderBy: { binCode: "asc" },
            },
          },
        },
      },
    });

    if (!rack) {
      throw AppError.notFound("Rack not found in this shop");
    }

    // Fetch all active medicines mapped to this rack by rackId OR rack code
    const medicines = await prisma.medicine.findMany({
      where: {
        shopId,
        status: "ACTIVE",
        OR: [
          { rackId: rack.id },
          { rack: { equals: rack.code, mode: "insensitive" } },
        ],
      },
      orderBy: [{ shelf: "asc" }, { box: "asc" }, { name: "asc" }],
      select: {
        id: true,
        name: true,
        genericName: true,
        dosageForm: true,
        strength: true,
        mrp: true,
        sellingPrice: true,
        reorderLevel: true,
        rack: true,
        rackId: true,
        shelf: true,
        box: true,
        batches: {
          where: { currentQuantity: { gt: 0 } },
          select: {
            id: true,
            batchNumber: true,
            expiryDate: true,
            currentQuantity: true,
            status: true,
          },
        },
      },
    });

    // Group medicines by shelf
    const medicinesByShelf: Record<string, typeof medicines> = {};
    for (const med of medicines) {
      const shelfKey = med.shelf ? String(med.shelf).trim() : "1";
      if (!medicinesByShelf[shelfKey]) {
        medicinesByShelf[shelfKey] = [];
      }
      medicinesByShelf[shelfKey].push(med);
    }

    return {
      ...rack,
      medicines,
      totalMedicines: medicines.length,
      activeMedicinesCount: medicines.length,
      medicinesByShelf,
    };
  }

  /**
   * Create a new Rack and automatically initialize child shelves
   */
  static async createRack(shopId: string, input: CreateRackInput) {
    const existing = await prisma.rack.findUnique({
      where: {
        shopId_code: {
          shopId,
          code: input.code,
        },
      },
    });

    if (existing) {
      throw AppError.conflict(`Rack with code "${input.code}" already exists in this shop`);
    }

    const qrCode = `RACK:${input.code}:${shopId.slice(0, 8)}`;

    return await prisma.$transaction(async (tx) => {
      const rack = await tx.rack.create({
        data: {
          shopId,
          code: input.code,
          name: input.name,
          zone: input.zone,
          storageType: input.storageType,
          description: input.description,
          totalShelves: input.totalShelves,
          rowNumber: input.rowNumber,
          columnNumber: input.columnNumber,
          qrCode,
        },
      });

      // Auto-create initial shelves (Shelf 1 through N)
      const shelvesData = [];
      for (let i = 1; i <= input.totalShelves; i++) {
        shelvesData.push({
          shopId,
          rackId: rack.id,
          shelfNumber: i,
          shelfLabel: `Shelf ${i}`,
          barcode: `${rack.code}-S${i}`,
          maxCapacity: 100,
        });
      }

      await tx.rackShelf.createMany({
        data: shelvesData,
      });

      return tx.rack.findUnique({
        where: { id: rack.id },
        include: {
          shelves: {
            orderBy: { shelfNumber: "asc" },
          },
        },
      });
    });
  }

  /**
   * Update Rack metadata and adjust shelves count if needed
   */
  static async updateRack(shopId: string, rackId: string, input: UpdateRackInput) {
    const rack = await prisma.rack.findFirst({
      where: { id: rackId, shopId },
      include: { shelves: true },
    });

    if (!rack) {
      throw AppError.notFound("Rack not found in this shop");
    }

    if (input.code && input.code !== rack.code) {
      const duplicate = await prisma.rack.findUnique({
        where: {
          shopId_code: {
            shopId,
            code: input.code,
          },
        },
      });
      if (duplicate) {
        throw AppError.conflict(`Rack with code "${input.code}" already exists`);
      }
    }

    return await prisma.$transaction(async (tx) => {
      // If totalShelves was increased, add missing shelves
      if (input.totalShelves && input.totalShelves > rack.totalShelves) {
        const currentHighest = Math.max(...rack.shelves.map((s) => s.shelfNumber), 0);
        const newShelves = [];
        for (let i = currentHighest + 1; i <= input.totalShelves; i++) {
          newShelves.push({
            shopId,
            rackId: rack.id,
            shelfNumber: i,
            shelfLabel: `Shelf ${i}`,
            barcode: `${input.code || rack.code}-S${i}`,
            maxCapacity: 100,
          });
        }
        if (newShelves.length > 0) {
          await tx.rackShelf.createMany({ data: newShelves });
        }
      }

      const updated = await tx.rack.update({
        where: { id: rackId },
        data: {
          code: input.code,
          name: input.name,
          zone: input.zone,
          storageType: input.storageType,
          description: input.description,
          totalShelves: input.totalShelves,
          rowNumber: input.rowNumber,
          columnNumber: input.columnNumber,
          status: input.status,
        },
        include: {
          shelves: {
            orderBy: { shelfNumber: "asc" },
          },
        },
      });

      // If code was changed, update denormalized rack string on medicines attached to it
      if (input.code && input.code !== rack.code) {
        await tx.medicine.updateMany({
          where: { rackId: rack.id },
          data: { rack: input.code },
        });
      }

      return updated;
    });
  }

  /**
   * Delete Rack if no active medicines are assigned
   */
  static async deleteRack(shopId: string, rackId: string) {
    const rack = await prisma.rack.findFirst({
      where: { id: rackId, shopId },
      include: {
        _count: {
          select: { medicines: true },
        },
      },
    });

    if (!rack) {
      throw AppError.notFound("Rack not found in this shop");
    }

    if (rack._count.medicines > 0) {
      throw AppError.badRequest(
        `Cannot delete Rack "${rack.code}": ${rack._count.medicines} medicines are currently assigned to it. Please reassign them first.`
      );
    }

    await prisma.rack.delete({
      where: { id: rackId },
    });

    return { message: `Rack "${rack.code}" deleted successfully` };
  }

  /**
   * Shelf CRUD
   */
  static async createShelf(shopId: string, rackId: string, input: CreateShelfInput) {
    const rack = await prisma.rack.findFirst({
      where: { id: rackId, shopId },
    });
    if (!rack) throw AppError.notFound("Rack not found in this shop");

    const existing = await prisma.rackShelf.findUnique({
      where: {
        rackId_shelfNumber: {
          rackId,
          shelfNumber: input.shelfNumber,
        },
      },
    });
    if (existing) {
      throw AppError.conflict(`Shelf #${input.shelfNumber} already exists on Rack ${rack.code}`);
    }

    return await prisma.rackShelf.create({
      data: {
        shopId,
        rackId,
        shelfNumber: input.shelfNumber,
        shelfLabel: input.shelfLabel || `Shelf ${input.shelfNumber}`,
        barcode: input.barcode || `${rack.code}-S${input.shelfNumber}`,
        maxCapacity: input.maxCapacity ?? 100,
        temperature: input.temperature,
      },
    });
  }

  static async updateShelf(
    shopId: string,
    rackId: string,
    shelfId: string,
    input: UpdateShelfInput
  ) {
    const shelf = await prisma.rackShelf.findFirst({
      where: { id: shelfId, rackId, shopId },
    });
    if (!shelf) throw AppError.notFound("Shelf not found");

    return await prisma.rackShelf.update({
      where: { id: shelfId },
      data: {
        shelfNumber: input.shelfNumber,
        shelfLabel: input.shelfLabel,
        barcode: input.barcode,
        maxCapacity: input.maxCapacity,
        temperature: input.temperature,
      },
    });
  }

  static async deleteShelf(shopId: string, rackId: string, shelfId: string) {
    const shelf = await prisma.rackShelf.findFirst({
      where: { id: shelfId, rackId, shopId },
      include: { rack: true },
    });
    if (!shelf) throw AppError.notFound("Shelf not found");

    const occupiedCount = await prisma.medicine.count({
      where: {
        shopId,
        rackId,
        shelf: String(shelf.shelfNumber),
      },
    });

    if (occupiedCount > 0) {
      throw AppError.badRequest(
        `Cannot delete Shelf #${shelf.shelfNumber}: ${occupiedCount} medicines are currently located here.`
      );
    }

    await prisma.rackShelf.delete({ where: { id: shelfId } });
    return { message: `Shelf #${shelf.shelfNumber} deleted successfully` };
  }

  /**
   * Assign a Medicine to a Rack / Shelf / Box location
   */
  static async assignMedicine(shopId: string, input: AssignMedicineRackInput) {
    const medicine = await prisma.medicine.findFirst({
      where: { id: input.medicineId, shopId },
    });
    if (!medicine) throw AppError.notFound("Medicine not found in this shop");

    let rack = null;
    if (input.rackId) {
      rack = await prisma.rack.findFirst({
        where: { id: input.rackId, shopId },
      });
    } else if (input.rackCode) {
      rack = await prisma.rack.findFirst({
        where: { code: input.rackCode.trim().toUpperCase(), shopId },
      });
    }

    if (!rack) {
      throw AppError.notFound("Specified rack does not exist in this shop");
    }

    const shelfStr = input.shelfNumber ? String(input.shelfNumber) : "1";
    const boxStr = input.boxCode ? String(input.boxCode) : null;

    const updated = await prisma.medicine.update({
      where: { id: input.medicineId },
      data: {
        rackId: rack.id,
        rack: rack.code,
        shelf: shelfStr,
        box: boxStr,
      },
      select: {
        id: true,
        name: true,
        genericName: true,
        rackId: true,
        rack: true,
        shelf: true,
        box: true,
      },
    });

    return {
      ...updated,
      locationFormatted: `Rack ${rack.code} • Shelf ${shelfStr}${boxStr ? ` • Box ${boxStr}` : ""}`,
    };
  }

  /**
   * Bulk assign multiple medicines to racks
   */
  static async bulkAssign(shopId: string, assignments: AssignMedicineRackInput[]) {
    const results = {
      assignedCount: 0,
      failedCount: 0,
      errors: [] as { medicineId: string; error: string }[],
    };

    for (const item of assignments) {
      try {
        await this.assignMedicine(shopId, item);
        results.assignedCount++;
      } catch (err: any) {
        results.failedCount++;
        results.errors.push({
          medicineId: item.medicineId,
          error: err.message || "Failed to assign",
        });
      }
    }

    return results;
  }

  /**
   * Transfer / Move medicines from one rack/shelf to another
   */
  static async transferMedicines(shopId: string, input: TransferRackInput) {
    let targetRack = null;
    if (input.targetRackId) {
      targetRack = await prisma.rack.findFirst({
        where: { id: input.targetRackId, shopId },
      });
    } else if (input.targetRackCode) {
      targetRack = await prisma.rack.findFirst({
        where: { code: input.targetRackCode.trim().toUpperCase(), shopId },
      });
    }

    if (!targetRack) {
      throw AppError.notFound("Target rack does not exist in this shop");
    }

    const shelfStr = input.targetShelfNumber ? String(input.targetShelfNumber) : "1";
    const boxStr = input.targetBoxCode ? String(input.targetBoxCode) : null;

    const updateResult = await prisma.medicine.updateMany({
      where: {
        id: { in: input.medicineIds },
        shopId,
      },
      data: {
        rackId: targetRack.id,
        rack: targetRack.code,
        shelf: shelfStr,
        box: boxStr,
      },
    });

    return {
      transferredCount: updateResult.count,
      targetRackCode: targetRack.code,
      targetShelf: shelfStr,
      targetBox: boxStr,
      reason: input.reason || "Physical reorganization",
    };
  }

  /**
   * List medicines that do not have a rack assigned yet
   */
  static async getUnassignedMedicines(
    shopId: string,
    page: number = 1,
    limit: number = 20,
    search?: string
  ) {
    const skip = (page - 1) * limit;
    const where: Record<string, unknown> = {
      shopId,
      status: "ACTIVE",
      OR: [{ rackId: null }, { rack: null }, { rack: "" }],
    };

    if (search && search.trim()) {
      const term = search.trim();
      where.AND = [
        {
          OR: [
            { name: { contains: term, mode: "insensitive" } },
            { genericName: { contains: term, mode: "insensitive" } },
          ],
        },
      ];
    }

    const [total, medicines] = await Promise.all([
      prisma.medicine.count({ where }),
      prisma.medicine.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: "asc" },
        select: {
          id: true,
          name: true,
          genericName: true,
          dosageForm: true,
          strength: true,
          mrp: true,
          reorderLevel: true,
          category: { select: { name: true } },
          manufacturer: { select: { name: true } },
        },
      }),
    ]);

    return {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      medicines,
    };
  }

  /**
   * Fast Counter Locator (for POS Sales & SmartSearch)
   */
  static async locateMedicine(shopId: string, medicineId: string) {
    const medicine = await prisma.medicine.findFirst({
      where: { id: medicineId, shopId },
      include: {
        rackRef: true,
        batches: {
          where: { currentQuantity: { gt: 0 } },
          orderBy: { expiryDate: "asc" },
          select: {
            id: true,
            batchNumber: true,
            expiryDate: true,
            currentQuantity: true,
            status: true,
          },
        },
      },
    });

    if (!medicine) throw AppError.notFound("Medicine not found");

    const rackCode = medicine.rackRef?.code || medicine.rack || "UNASSIGNED";
    const shelfNum = medicine.shelf || "1";
    const boxNum = medicine.box;

    const totalStock = medicine.batches.reduce((sum, b) => sum + b.currentQuantity, 0);

    return {
      medicineId: medicine.id,
      name: medicine.name,
      genericName: medicine.genericName,
      coordinates: {
        rackId: medicine.rackId,
        rackCode,
        rackName: medicine.rackRef?.name || null,
        zone: medicine.rackRef?.zone || "GENERAL",
        storageType: medicine.rackRef?.storageType || "STANDARD",
        shelf: shelfNum,
        box: boxNum,
        formatted: `Rack ${rackCode} • Shelf ${shelfNum}${boxNum ? ` • Box ${boxNum}` : ""}`,
      },
      stock: {
        totalStock,
        batchesCount: medicine.batches.length,
        batches: medicine.batches,
      },
    };
  }

  /**
   * Generate Physical Stocktake Checklist for a Rack
   */
  static async generateAuditSheet(shopId: string, rackId: string) {
    const rack = await prisma.rack.findFirst({
      where: { id: rackId, shopId },
      include: {
        shelves: { orderBy: { shelfNumber: "asc" } },
        medicines: {
          where: { status: "ACTIVE" },
          orderBy: [{ shelf: "asc" }, { name: "asc" }],
          include: {
            batches: {
              where: { currentQuantity: { gt: 0 } },
              orderBy: { expiryDate: "asc" },
              select: {
                id: true,
                batchNumber: true,
                expiryDate: true,
                currentQuantity: true,
                mrp: true,
              },
            },
          },
        },
      },
    });

    if (!rack) throw AppError.notFound("Rack not found in this shop");

    const checklistItems = [];
    for (const med of rack.medicines) {
      for (const batch of med.batches) {
        checklistItems.push({
          medicineId: med.id,
          medicineName: med.name,
          genericName: med.genericName,
          shelf: med.shelf || "1",
          box: med.box || "-",
          batchId: batch.id,
          batchNumber: batch.batchNumber,
          expiryDate: batch.expiryDate,
          mrp: batch.mrp,
          systemStock: batch.currentQuantity,
        });
      }
    }

    return {
      rackId: rack.id,
      rackCode: rack.code,
      rackName: rack.name,
      zone: rack.zone,
      generatedAt: new Date().toISOString(),
      totalBatchesToCheck: checklistItems.length,
      items: checklistItems,
    };
  }

  /**
   * Submit Physical Stock Verification & Log Adjustments
   */
  static async submitAuditVerification(
    shopId: string,
    userId: string | null,
    rackId: string,
    auditItems: {
      batchId: string;
      physicalCount: number;
      systemCount: number;
      notes?: string | null;
    }[]
  ) {
    const rack = await prisma.rack.findFirst({
      where: { id: rackId, shopId },
    });
    if (!rack) throw AppError.notFound("Rack not found in this shop");

    let adjustmentsCount = 0;

    await prisma.$transaction(async (tx) => {
      for (const item of auditItems) {
        const delta = item.physicalCount - item.systemCount;
        if (delta === 0) continue; // In sync, no adjustment needed

        const batch = await tx.medicineBatch.findFirst({
          where: { id: item.batchId, shopId },
        });
        if (!batch) continue;

        const newQuantity = Math.max(0, item.physicalCount);
        const transactionType =
          delta > 0
            ? STOCK_TRANSACTION_TYPE.ADJUSTMENT_ADD
            : STOCK_TRANSACTION_TYPE.ADJUSTMENT_SUB;

        await tx.medicineBatch.update({
          where: { id: batch.id },
          data: {
            currentQuantity: newQuantity,
            status:
              newQuantity === 0
                ? BATCH_STATUS.EXPIRED
                : batch.status,
          },
        });

        await tx.stockTransaction.create({
          data: {
            shopId,
            batchId: batch.id,
            medicineId: batch.medicineId,
            transactionType,
            quantityDelta: delta,
            balanceAfter: newQuantity,
            referenceType: "RACK_AUDIT",
            referenceId: rack.id,
            notes:
              item.notes ||
              `Physical count verified during audit of Rack ${rack.code}`,
            performedById: userId,
          },
        });

        adjustmentsCount++;
      }
    });

    return {
      rackCode: rack.code,
      totalItemsAudited: auditItems.length,
      adjustmentsRecorded: adjustmentsCount,
      status: "COMPLETED",
    };
  }
}
