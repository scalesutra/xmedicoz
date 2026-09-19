import { prisma } from "../../../infrastructure/database/prisma.client.js";
import { AppError } from "../../../utils/errors.js";

export class MedicineService {
  static async listMedicines(
    shopId: string,
    query: {
      page: number;
      limit: number;
      search?: string;
      categoryId?: string;
      manufacturerId?: string;
      status?: string;
      prescriptionRequired?: boolean;
    }
  ) {
    const { page, limit, search, categoryId, manufacturerId, status, prescriptionRequired } = query;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { shopId };

    if (status) {
      where.status = status;
    }

    if (categoryId) {
      where.categoryId = categoryId;
    }

    if (manufacturerId) {
      where.manufacturerId = manufacturerId;
    }

    if (prescriptionRequired !== undefined) {
      where.prescriptionRequired = prescriptionRequired;
    }

    if (search && search.trim()) {
      const searchTerm = search.trim();
      where.OR = [
        { name: { contains: searchTerm, mode: "insensitive" } },
        { genericName: { contains: searchTerm, mode: "insensitive" } },
        { brand: { contains: searchTerm, mode: "insensitive" } },
        { hsnCode: { contains: searchTerm, mode: "insensitive" } },
      ];
    }

    const [total, medicines] = await Promise.all([
      prisma.medicine.count({ where }),
      prisma.medicine.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: "asc" },
        include: {
          category: { select: { id: true, name: true } },
          manufacturer: { select: { id: true, name: true } },
          unit: { select: { id: true, name: true, abbreviation: true } },
        },
      }),
    ]);

    return {
      items: medicines,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  static async getMedicineById(shopId: string, id: string) {
    const medicine = await prisma.medicine.findFirst({
      where: { id, shopId },
      include: {
        category: true,
        manufacturer: true,
        unit: true,
      },
    });

    if (!medicine) {
      throw AppError.notFound("Medicine not found in your store");
    }

    return medicine;
  }

  static async createMedicine(
    shopId: string,
    data: {
      name: string;
      genericName: string;
      brand?: string;
      dosageForm: string;
      strength?: string;
      hsnCode?: string;
      gstRate?: number;
      mrp: number;
      purchaseRate?: number;
      sellingPrice: number;
      reorderLevel?: number;
      prescriptionRequired?: boolean;
      categoryId?: string | null;
      manufacturerId?: string | null;
      unitId?: string | null;
      rack?: string | null;
      shelf?: string | null;
      box?: string | null;
      symptoms?: string | null;
      saltComposition?: string | null;
      otcFlag?: boolean;
    }
  ) {
    return await prisma.medicine.create({
      data: {
        shopId,
        name: data.name,
        genericName: data.genericName,
        brand: data.brand,
        dosageForm: data.dosageForm,
        strength: data.strength,
        hsnCode: data.hsnCode,
        gstRate: data.gstRate ?? 0,
        mrp: data.mrp,
        purchaseRate: data.purchaseRate ?? 0,
        sellingPrice: data.sellingPrice,
        reorderLevel: data.reorderLevel ?? 10,
        prescriptionRequired: data.prescriptionRequired ?? false,
        categoryId: data.categoryId,
        manufacturerId: data.manufacturerId,
        unitId: data.unitId,
        rack: data.rack,
        shelf: data.shelf,
        box: data.box,
        symptoms: data.symptoms,
        saltComposition: data.saltComposition,
        otcFlag: data.otcFlag ?? false,
        status: "ACTIVE",
      },
      include: {
        category: true,
        manufacturer: true,
        unit: true,
      },
    });
  }

  static async updateMedicine(
    shopId: string,
    id: string,
    data: {
      name?: string;
      genericName?: string;
      brand?: string;
      dosageForm?: string;
      strength?: string;
      hsnCode?: string;
      gstRate?: number;
      mrp?: number;
      purchaseRate?: number;
      sellingPrice?: number;
      reorderLevel?: number;
      prescriptionRequired?: boolean;
      status?: string;
      categoryId?: string | null;
      manufacturerId?: string | null;
      unitId?: string | null;
      rack?: string | null;
      shelf?: string | null;
      box?: string | null;
      symptoms?: string | null;
      saltComposition?: string | null;
      otcFlag?: boolean;
    }
  ) {
    await this.getMedicineById(shopId, id);

    return await prisma.medicine.update({
      where: { id },
      data,
      include: {
        category: true,
        manufacturer: true,
        unit: true,
      },
    });
  }

  static async deleteMedicine(shopId: string, id: string) {
    await this.getMedicineById(shopId, id);

    return await prisma.medicine.update({
      where: { id },
      data: { status: "INACTIVE" },
    });
  }
}
