import { prisma } from "../../../infrastructure/database/prisma.client.js";
import { normalizePhoneNumber, normalizeEmail } from "../../../utils/otp.utils.js";
import { AppError } from "../../../utils/errors.js";

export class SupplierService {
  static async listSuppliers(
    shopId: string,
    query: {
      page: number;
      limit: number;
      search?: string;
      status?: string;
    }
  ) {
    const { page, limit, search, status } = query;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { shopId };

    if (status) {
      where.status = status;
    }

    if (search && search.trim()) {
      const term = search.trim();
      where.OR = [
        { name: { contains: term, mode: "insensitive" } },
        { gstin: { contains: term, mode: "insensitive" } },
        { mobile: { contains: term } },
        { contactPerson: { contains: term, mode: "insensitive" } },
      ];
    }

    const [total, suppliers] = await Promise.all([
      prisma.supplier.count({ where }),
      prisma.supplier.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: "asc" },
      }),
    ]);

    return {
      items: suppliers,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  static async getSupplierById(shopId: string, id: string) {
    const supplier = await prisma.supplier.findFirst({ where: { id, shopId } });
    if (!supplier) {
      throw AppError.notFound("Supplier not found in your store");
    }
    return supplier;
  }

  static async createSupplier(
    shopId: string,
    data: {
      name: string;
      contactPerson?: string;
      mobile: string;
      email?: string;
      gstin?: string;
      dlNumber?: string;
      address?: string;
      paymentTermsDays?: number;
    }
  ) {
    const normalizedMobile = normalizePhoneNumber(data.mobile);

    return await prisma.supplier.create({
      data: {
        shopId,
        name: data.name,
        contactPerson: data.contactPerson,
        mobile: normalizedMobile,
        email: data.email ? normalizeEmail(data.email) : null,
        gstin: data.gstin ? data.gstin.trim().toUpperCase() : null,
        dlNumber: data.dlNumber ? data.dlNumber.trim().toUpperCase() : null,
        address: data.address,
        paymentTermsDays: data.paymentTermsDays ?? 30,
        status: "ACTIVE",
      },
    });
  }

  static async updateSupplier(
    shopId: string,
    id: string,
    data: {
      name?: string;
      contactPerson?: string;
      mobile?: string;
      email?: string;
      gstin?: string;
      dlNumber?: string;
      address?: string;
      paymentTermsDays?: number;
      status?: string;
    }
  ) {
    await this.getSupplierById(shopId, id);

    return await prisma.supplier.update({
      where: { id },
      data: {
        ...data,
        mobile: data.mobile ? normalizePhoneNumber(data.mobile) : undefined,
        email: data.email ? normalizeEmail(data.email) : undefined,
        gstin: data.gstin ? data.gstin.trim().toUpperCase() : undefined,
        dlNumber: data.dlNumber ? data.dlNumber.trim().toUpperCase() : undefined,
      },
    });
  }

  static async deleteSupplier(shopId: string, id: string) {
    await this.getSupplierById(shopId, id);
    return await prisma.supplier.update({
      where: { id },
      data: { status: "INACTIVE" },
    });
  }
}
