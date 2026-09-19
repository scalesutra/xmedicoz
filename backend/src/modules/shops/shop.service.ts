import { prisma } from "../../infrastructure/database/prisma.client.js";
import { AppError } from "../../utils/errors.js";
import { ERROR_CODES, SUBSCRIPTION_STATUS } from "../../config/constants.js";
import { Prisma } from "@prisma/client";
import type { CreateShopInput, UpdateShopInput, AddMemberInput } from "./shop.schema.js";

function slugify(text: string): string {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, "")
    .replace(/[\s_-]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export class ShopService {
  /**
   * List all shops accessible by the user (or all if admin)
   */
  async listUserShops(userId: string, isAdmin: boolean) {
    if (isAdmin) {
      const shops = await prisma.shop.findMany({
        orderBy: { createdAt: "desc" },
        include: {
          subscription: {
            include: { plan: true },
          },
          _count: {
            select: {
              medicines: true,
              salesInvoices: true,
              customers: true,
              members: true,
            },
          },
        },
      });

      return shops.map((s) => ({
        ...s,
        role: "OWNER",
        userRole: "OWNER",
      }));
    }

    const memberships = await prisma.shopMember.findMany({
      where: { userId, status: "ACTIVE" },
      include: {
        shop: {
          include: {
            subscription: {
              include: { plan: true },
            },
            _count: {
              select: {
                medicines: true,
                salesInvoices: true,
                customers: true,
                members: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: "asc" },
    });

    return memberships.map((m) => ({
      ...m.shop,
      role: m.role,
      userRole: m.role,
    }));
  }

  /**
   * Get single shop with full subscription & analytics summary
   */
  async getShopById(shopId: string, _userId: string, _isAdmin: boolean) {
    const shop = await prisma.shop.findUnique({
      where: { id: shopId },
      include: {
        subscription: {
          include: { plan: true },
        },
        members: {
          include: {
            user: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                email: true,
                phone: true,
              },
            },
          },
        },
        _count: {
          select: {
            medicines: true,
            salesInvoices: true,
            customers: true,
            suppliers: true,
            purchaseInvoices: true,
          },
        },
      },
    });

    if (!shop) {
      throw AppError.notFound("Medical store not found", ERROR_CODES.SHOP_NOT_FOUND);
    }

    // Monthly invoice usage
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const invoicesThisMonth = await prisma.salesInvoice.count({
      where: {
        shopId,
        createdAt: { gte: startOfMonth },
      },
    });

    return {
      ...shop,
      usage: {
        invoicesThisMonth,
        maxInvoicesPerMonth: shop.subscription?.plan?.maxInvoicesPerMonth ?? 1000,
        medicinesCount: shop._count.medicines,
        maxMedicines: shop.subscription?.plan?.maxMedicines ?? 500,
        membersCount: shop.members.length,
        maxUsers: shop.subscription?.plan?.maxUsers ?? 2,
      },
    };
  }

  /**
   * Register / Onboard a new Medical Store
   * Fully automated SaaS initialization with 14-day free trial or chosen tier.
   */
  async createShop(data: CreateShopInput, userId: string) {
    const baseSlug = slugify(data.name) || "medical-store";
    let slug = baseSlug;
    let counter = 1;

    while (await prisma.shop.findUnique({ where: { slug } })) {
      slug = `${baseSlug}-${counter++}`;
    }

    const planCode = data.planCode || "TRIAL";
    const plan = await prisma.subscriptionPlan.findUnique({
      where: { code: planCode },
    });

    if (!plan) {
      throw AppError.badRequest(`Invalid subscription plan code: ${planCode}`);
    }

    const trialDays = planCode === "TRIAL" ? 14 : 30;
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + trialDays);

    const result = await prisma.$transaction(async (tx) => {
      // 1. Create Shop
      const shop = await tx.shop.create({
        data: {
          name: data.name,
          slug,
          ownerName: data.ownerName,
          phone: data.phone,
          email: data.email,
          drugLicenseNo: data.drugLicenseNo,
          gstin: data.gstin,
          address: data.address,
          city: data.city,
          state: data.state,
          pincode: data.pincode,
          invoicePrefix: (data.invoicePrefix || "INV").toUpperCase(),
          status: "ACTIVE",
        },
      });

      // 2. Link creator as OWNER
      await tx.shopMember.create({
        data: {
          shopId: shop.id,
          userId,
          role: "OWNER",
          status: "ACTIVE",
        },
      });

      // 3. Create Subscription
      await tx.shopSubscription.create({
        data: {
          shopId: shop.id,
          planId: plan.id,
          status: planCode === "TRIAL" ? SUBSCRIPTION_STATUS.TRIAL : SUBSCRIPTION_STATUS.ACTIVE,
          startDate: new Date(),
          endDate,
          autoRenew: planCode !== "TRIAL",
        },
      });

      // 4. Seed Standard Master Data for Pharmacy
      const defaultCategories = [
        "Antibiotics",
        "Analgesics & Pain Relief",
        "Cardiology",
        "Diabetic Care",
        "Dermatology",
        "Gastroenterology",
        "Vitamins & Supplements",
      ];
      for (const cat of defaultCategories) {
        await tx.category.create({
          data: {
            shopId: shop.id,
            name: cat,
            status: "ACTIVE",
          },
        });
      }

      const defaultUnits = [
        { name: "Strip (10 Tablets)", abbreviation: "STRIP" },
        { name: "Strip (15 Tablets)", abbreviation: "STRIP-15" },
        { name: "Bottle (100ml)", abbreviation: "BTL-100" },
        { name: "Bottle (200ml)", abbreviation: "BTL-200" },
        { name: "Tube (30g)", abbreviation: "TUBE" },
        { name: "Vial / Injection", abbreviation: "VIAL" },
        { name: "Box", abbreviation: "BOX" },
      ];
      for (const u of defaultUnits) {
        await tx.unit.create({
          data: {
            shopId: shop.id,
            name: u.name,
            abbreviation: u.abbreviation,
            status: "ACTIVE",
          },
        });
      }

      const defaultTaxes = [
        { name: "GST 0%", rate: 0, cgst: 0, sgst: 0, igst: 0 },
        { name: "GST 5%", rate: 5, cgst: 2.5, sgst: 2.5, igst: 5 },
        { name: "GST 12%", rate: 12, cgst: 6, sgst: 6, igst: 12 },
        { name: "GST 18%", rate: 18, cgst: 9, sgst: 9, igst: 18 },
      ];
      for (const t of defaultTaxes) {
        await tx.tax.create({
          data: {
            shopId: shop.id,
            name: t.name,
            rate: new Prisma.Decimal(t.rate),
            cgst: new Prisma.Decimal(t.cgst),
            sgst: new Prisma.Decimal(t.sgst),
            igst: new Prisma.Decimal(t.igst),
            status: "ACTIVE",
          },
        });
      }


      return shop;
    });

    return this.getShopById(result.id, userId, true);
  }

  /**
   * Update Shop Profile / Settings
   */
  async updateShop(shopId: string, data: UpdateShopInput) {
    const shop = await prisma.shop.update({
      where: { id: shopId },
      data: {
        name: data.name,
        ownerName: data.ownerName,
        phone: data.phone,
        email: data.email,
        drugLicenseNo: data.drugLicenseNo,
        gstin: data.gstin,
        address: data.address,
        city: data.city,
        state: data.state,
        pincode: data.pincode,
        invoicePrefix: data.invoicePrefix?.toUpperCase(),
      },
    });

    return shop;
  }

  /**
   * List Public SaaS Plans
   */
  async listSubscriptionPlans() {
    return prisma.subscriptionPlan.findMany({
      where: { isActive: true },
      orderBy: { priceMonthly: "asc" },
    });
  }

  /**
   * Upgrade or Change Subscription Plan
   */
  async subscribePlan(shopId: string, planCode: string, billingCycle: "MONTHLY" | "YEARLY") {
    const plan = await prisma.subscriptionPlan.findUnique({
      where: { code: planCode },
    });

    if (!plan) {
      throw AppError.notFound(`Subscription plan ${planCode} not found`);
    }

    const durationDays = billingCycle === "YEARLY" ? 365 : 30;
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + durationDays);

    const subscription = await prisma.shopSubscription.upsert({
      where: { shopId },
      update: {
        planId: plan.id,
        status: SUBSCRIPTION_STATUS.ACTIVE,
        billingCycle,
        startDate: new Date(),
        endDate,
        autoRenew: true,
      },
      create: {
        shopId,
        planId: plan.id,
        status: SUBSCRIPTION_STATUS.ACTIVE,
        billingCycle,
        startDate: new Date(),
        endDate,
        autoRenew: true,
      },
      include: {
        plan: true,
      },
    });

    return subscription;
  }

  /**
   * List staff members of a shop
   */
  async listMembers(shopId: string) {
    return prisma.shopMember.findMany({
      where: { shopId, status: "ACTIVE" },
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
          },
        },
      },
      orderBy: { createdAt: "asc" },
    });
  }

  /**
   * Add a staff member (Pharmacist, Cashier) to the medical store
   */
  async addMember(shopId: string, data: AddMemberInput) {
    // Check shop user limits
    const shop = await prisma.shop.findUnique({
      where: { id: shopId },
      include: {
        subscription: { include: { plan: true } },
        members: { where: { status: "ACTIVE" } },
      },
    });

    if (!shop) {
      throw AppError.notFound("Shop not found");
    }

    const maxUsers = shop.subscription?.plan?.maxUsers ?? 2;
    if (shop.members.length >= maxUsers) {
      throw AppError.forbidden(
        `Staff user limit reached for your plan (${shop.subscription?.plan?.name}: max ${maxUsers} users). Upgrade plan to add more staff.`,
        ERROR_CODES.SUBSCRIPTION_LIMIT_EXCEEDED
      );
    }

    // Find or create User
    let user = await prisma.user.findUnique({
      where: { email: data.email },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          keycloakId: `user-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
          email: data.email,
          firstName: data.firstName,
          lastName: data.lastName || "",
          status: "ACTIVE",
          emailVerified: false,
        },
      });
    }

    const member = await prisma.shopMember.upsert({
      where: { shopId_userId: { shopId, userId: user.id } },
      update: {
        role: data.role,
        status: "ACTIVE",
      },
      create: {
        shopId,
        userId: user.id,
        role: data.role,
        status: "ACTIVE",
      },
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
          },
        },
      },
    });

    return member;
  }
}

export const shopService = new ShopService();
