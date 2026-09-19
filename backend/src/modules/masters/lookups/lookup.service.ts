import { prisma } from "../../../infrastructure/database/prisma.client.js";
import { redis } from "../../../infrastructure/redis/redis.client.js";
import { AppError } from "../../../utils/errors.js";
import { Prisma } from "@prisma/client";

const CACHE_TTL = 3600; // 1 hour

export class LookupService {
  // ================= Categories =================
  static async getCategories(shopId: string) {
    const cacheKey = `masters:categories:${shopId}`;
    const cached = await redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const categories = await prisma.category.findMany({
      where: { shopId, status: "ACTIVE" },
      orderBy: { name: "asc" },
    });
    await redis.set(cacheKey, JSON.stringify(categories), "EX", CACHE_TTL);
    return categories;
  }

  static async createCategory(shopId: string, data: { name: string; description?: string }) {
    const existing = await prisma.category.findUnique({
      where: { shopId_name: { shopId, name: data.name } },
    });
    if (existing) throw AppError.conflict("Category with this name already exists in your store");

    const category = await prisma.category.create({
      data: {
        shopId,
        name: data.name,
        description: data.description,
      },
    });
    await redis.del(`masters:categories:${shopId}`);
    return category;
  }

  static async updateCategory(shopId: string, id: string, data: { name?: string; description?: string }) {
    const category = await prisma.category.update({
      where: { id },
      data,
    });
    await redis.del(`masters:categories:${shopId}`);
    return category;
  }

  static async deleteCategory(shopId: string, id: string) {
    const category = await prisma.category.update({
      where: { id },
      data: { status: "INACTIVE" },
    });
    await redis.del(`masters:categories:${shopId}`);
    return category;
  }

  // ================= Manufacturers =================
  static async getManufacturers(shopId: string) {
    const cacheKey = `masters:manufacturers:${shopId}`;
    const cached = await redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const manufacturers = await prisma.manufacturer.findMany({
      where: { shopId, status: "ACTIVE" },
      orderBy: { name: "asc" },
    });
    await redis.set(cacheKey, JSON.stringify(manufacturers), "EX", CACHE_TTL);
    return manufacturers;
  }

  static async createManufacturer(
    shopId: string,
    data: {
      name: string;
      contactPerson?: string;
      email?: string;
      phone?: string;
      address?: string;
    }
  ) {
    const existing = await prisma.manufacturer.findUnique({
      where: { shopId_name: { shopId, name: data.name } },
    });
    if (existing) throw AppError.conflict("Manufacturer with this name already exists in your store");

    const manufacturer = await prisma.manufacturer.create({
      data: {
        shopId,
        ...data,
      },
    });
    await redis.del(`masters:manufacturers:${shopId}`);
    return manufacturer;
  }

  static async updateManufacturer(
    shopId: string,
    id: string,
    data: { name?: string; contactPerson?: string; email?: string; phone?: string; address?: string }
  ) {
    const manufacturer = await prisma.manufacturer.update({ where: { id }, data });
    await redis.del(`masters:manufacturers:${shopId}`);
    return manufacturer;
  }

  static async deleteManufacturer(shopId: string, id: string) {
    const manufacturer = await prisma.manufacturer.update({ where: { id }, data: { status: "INACTIVE" } });
    await redis.del(`masters:manufacturers:${shopId}`);
    return manufacturer;
  }

  // ================= Units =================
  static async getUnits(shopId: string) {
    const cacheKey = `masters:units:${shopId}`;
    const cached = await redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const units = await prisma.unit.findMany({
      where: { shopId, status: "ACTIVE" },
      orderBy: { name: "asc" },
    });
    await redis.set(cacheKey, JSON.stringify(units), "EX", CACHE_TTL);
    return units;
  }

  static async createUnit(shopId: string, data: { name: string; abbreviation?: string }) {
    const existing = await prisma.unit.findUnique({
      where: { shopId_name: { shopId, name: data.name } },
    });
    if (existing) throw AppError.conflict("Unit with this name already exists in your store");

    const unit = await prisma.unit.create({
      data: {
        shopId,
        ...data,
      },
    });
    await redis.del(`masters:units:${shopId}`);
    return unit;
  }

  static async updateUnit(shopId: string, id: string, data: { name?: string; abbreviation?: string }) {
    const unit = await prisma.unit.update({ where: { id }, data });
    await redis.del(`masters:units:${shopId}`);
    return unit;
  }

  // ================= Taxes =================
  static async getTaxes(shopId: string) {
    const cacheKey = `masters:taxes:${shopId}`;
    const cached = await redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const taxes = await prisma.tax.findMany({
      where: { shopId, status: "ACTIVE" },
      orderBy: { rate: "asc" },
    });
    await redis.set(cacheKey, JSON.stringify(taxes), "EX", CACHE_TTL);
    return taxes;
  }

  static async createTax(
    shopId: string,
    data: { name: string; rate: number; cgst?: number; sgst?: number; igst?: number }
  ) {
    const existing = await prisma.tax.findUnique({
      where: { shopId_name: { shopId, name: data.name } },
    });
    if (existing) throw AppError.conflict("Tax slab with this name already exists in your store");

    const rate = data.rate;
    const cgst = data.cgst ?? rate / 2;
    const sgst = data.sgst ?? rate / 2;
    const igst = data.igst ?? rate;

    const tax = await prisma.tax.create({
      data: {
        shopId,
        name: data.name,
        rate: new Prisma.Decimal(rate),
        cgst: new Prisma.Decimal(cgst),
        sgst: new Prisma.Decimal(sgst),
        igst: new Prisma.Decimal(igst),
      },
    });
    await redis.del(`masters:taxes:${shopId}`);
    return tax;
  }

  static async updateTax(
    shopId: string,
    id: string,
    data: { name?: string; rate?: number; cgst?: number; sgst?: number; igst?: number }
  ) {
    const tax = await prisma.tax.update({ where: { id }, data });
    await redis.del(`masters:taxes:${shopId}`);
    return tax;
  }
}
