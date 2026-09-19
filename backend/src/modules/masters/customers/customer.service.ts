import { prisma } from "../../../infrastructure/database/prisma.client.js";
import { normalizePhoneNumber, normalizeEmail } from "../../../utils/otp.utils.js";
import { AppError } from "../../../utils/errors.js";

export class CustomerService {
  static async listCustomers(
    shopId: string,
    query: {
      page: number;
      limit: number;
      search?: string;
      customerType?: string;
      isPermanent?: boolean;
      status?: string;
    }
  ) {
    const { page, limit, search, customerType, isPermanent, status } = query;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { shopId };

    if (status) {
      where.status = status;
    }

    if (customerType) {
      where.customerType = customerType;
    }

    if (isPermanent !== undefined) {
      where.isPermanent = isPermanent;
    }

    if (search && search.trim()) {
      const term = search.trim();
      where.OR = [
        { name: { contains: term, mode: "insensitive" } },
        { mobile: { contains: term } },
        { email: { contains: term, mode: "insensitive" } },
      ];
    }

    const [total, customers] = await Promise.all([
      prisma.customer.count({ where }),
      prisma.customer.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: "asc" },
      }),
    ]);

    return {
      items: customers,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  static async getCustomerById(shopId: string, id: string) {
    const customer = await prisma.customer.findFirst({ where: { id, shopId } });
    if (!customer) {
      throw AppError.notFound("Customer not found in your store");
    }
    return customer;
  }

  static async getCustomerByMobile(shopId: string, mobile: string) {
    const normalizedMobile = normalizePhoneNumber(mobile);
    const customer = await prisma.customer.findUnique({
      where: { shopId_mobile: { shopId, mobile: normalizedMobile } },
    });
    return customer;
  }

  static async createCustomer(
    shopId: string,
    data: {
      name: string;
      mobile: string;
      email?: string;
      address?: string;
      dob?: string | null;
      customerType?: string;
      isPermanent?: boolean;
      creditLimit?: number;
      notificationOptOut?: boolean;
    }
  ) {
    const normalizedMobile = normalizePhoneNumber(data.mobile);

    const existing = await prisma.customer.findUnique({
      where: { shopId_mobile: { shopId, mobile: normalizedMobile } },
    });
    if (existing) {
      throw AppError.conflict("Customer with this mobile number already exists in your store");
    }

    const isPermanent = data.isPermanent || data.customerType === "PERMANENT";
    const customerType = isPermanent ? "PERMANENT" : data.customerType || "REGULAR";

    return await prisma.customer.create({
      data: {
        shopId,
        name: data.name,
        mobile: normalizedMobile,
        email: data.email ? normalizeEmail(data.email) : null,
        address: data.address,
        dob: data.dob ? new Date(data.dob) : null,
        customerType,
        isPermanent,
        creditLimit: data.creditLimit ?? 0,
        notificationOptOut: data.notificationOptOut ?? false,
      },
    });
  }

  static async updateCustomer(
    shopId: string,
    id: string,
    data: {
      name?: string;
      mobile?: string;
      email?: string;
      address?: string;
      dob?: string | null;
      customerType?: string;
      isPermanent?: boolean;
      creditLimit?: number;
      notificationOptOut?: boolean;
      status?: string;
    }
  ) {
    await this.getCustomerById(shopId, id);

    let normalizedMobile = undefined;
    if (data.mobile) {
      normalizedMobile = normalizePhoneNumber(data.mobile);
      const existing = await prisma.customer.findUnique({
        where: { shopId_mobile: { shopId, mobile: normalizedMobile } },
      });
      if (existing && existing.id !== id) {
        throw AppError.conflict("Another customer already has this mobile number");
      }
    }

    return await prisma.customer.update({
      where: { id },
      data: {
        ...data,
        mobile: normalizedMobile,
        email: data.email ? normalizeEmail(data.email) : undefined,
        dob: data.dob ? new Date(data.dob) : undefined,
      },
    });
  }

  static async deleteCustomer(shopId: string, id: string) {
    await this.getCustomerById(shopId, id);
    return await prisma.customer.update({
      where: { id },
      data: { status: "INACTIVE" },
    });
  }
}
