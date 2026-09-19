import { prisma } from "../../infrastructure/database/prisma.client.js";
import { redis } from "../../infrastructure/redis/redis.client.js";
import { AppError } from "../../utils/errors.js";
import { ERROR_CODES } from "../../config/constants.js";
import os from "node:os";

export class SuperadminService {
  /**
   * Executive SaaS Platform Overview & Telemetry
   */
  async getOverview() {
    const now = new Date();
    const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const [
      totalShops,
      activeShops,
      suspendedShops,
      subscriptions,
      expiringTrials,
      totalUsers,
      totalMedicines,
      salesStats,
      recentShops,
      recentAuditLogs,
    ] = await Promise.all([
      prisma.shop.count(),
      prisma.shop.count({ where: { status: "ACTIVE" } }),
      prisma.shop.count({ where: { status: "SUSPENDED" } }),
      prisma.shopSubscription.findMany({
        include: { plan: true },
      }),
      prisma.shopSubscription.count({
        where: {
          status: "TRIAL",
          endDate: { lte: in7Days, gte: now },
        },
      }),
      prisma.user.count(),
      prisma.medicine.count(),
      prisma.salesInvoice.aggregate({
        _count: { id: true },
        _sum: { totalAmount: true },
      }),
      prisma.shop.findMany({
        take: 6,
        orderBy: { createdAt: "desc" },
        include: {
          subscription: { include: { plan: true } },
          _count: { select: { members: true, medicines: true, salesInvoices: true } },
        },
      }),
      prisma.auditLog.findMany({
        take: 8,
        orderBy: { createdAt: "desc" },
        include: {
          user: { select: { firstName: true, lastName: true, email: true } },
          shop: { select: { name: true } },
        },
      }),
    ]);

    // Compute active subscriptions count & estimated MRR
    let totalMRR = 0;
    const planBreakdown: Record<string, number> = {};
    let activeSubscriptionsCount = 0;
    let trialSubscriptionsCount = 0;

    for (const sub of subscriptions) {
      const planCode = sub.plan?.code || "TRIAL";
      planBreakdown[planCode] = (planBreakdown[planCode] || 0) + 1;

      if (sub.status === "ACTIVE") {
        activeSubscriptionsCount++;
        totalMRR += Number(sub.plan?.priceMonthly || 0);
      } else if (sub.status === "TRIAL") {
        trialSubscriptionsCount++;
      }
    }

    return {
      metrics: {
        totalShops,
        activeShops,
        suspendedShops,
        activeSubscriptions: activeSubscriptionsCount,
        trialSubscriptions: trialSubscriptionsCount,
        expiringTrials7Days: expiringTrials,
        estimatedMRR: totalMRR,
        totalUsers,
        totalMedicines,
        totalInvoices: salesStats._count.id || 0,
        totalSalesVolume: Number(salesStats._sum.totalAmount || 0),
      },
      planBreakdown,
      recentShops,
      recentAuditLogs,
    };
  }

  /**
   * Search & List Tenants / Medical Stores
   */
  async getShops(params: {
    search?: string;
    status?: string;
    planCode?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Math.max(1, Number(params.page || 1));
    const limit = Math.max(1, Math.min(100, Number(params.limit || 20)));
    const skip = (page - 1) * limit;

    const where: any = {};

    if (params.status && params.status !== "ALL") {
      where.status = params.status;
    }

    if (params.planCode && params.planCode !== "ALL") {
      where.subscription = {
        plan: {
          code: params.planCode,
        },
      };
    }

    if (params.search && params.search.trim() !== "") {
      const q = params.search.trim();
      where.OR = [
        { name: { contains: q, mode: "insensitive" } },
        { slug: { contains: q, mode: "insensitive" } },
        { ownerName: { contains: q, mode: "insensitive" } },
        { phone: { contains: q, mode: "insensitive" } },
        { drugLicenseNo: { contains: q, mode: "insensitive" } },
        { city: { contains: q, mode: "insensitive" } },
      ];
    }

    const [total, shops] = await Promise.all([
      prisma.shop.count({ where }),
      prisma.shop.findMany({
        where,
        skip,
        take: limit,
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
      }),
    ]);

    return {
      items: shops,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Deep Dive Single Shop
   */
  async getShopById(shopId: string) {
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
            purchaseInvoices: true,
            customers: true,
            suppliers: true,
          },
        },
      },
    });

    if (!shop) {
      throw AppError.notFound("Medical store not found", ERROR_CODES.SHOP_NOT_FOUND);
    }

    return shop;
  }

  /**
   * Suspend or Reactivate a Pharmacy Store
   */
  async updateShopStatus(shopId: string, status: "ACTIVE" | "SUSPENDED", reason?: string, adminUserId?: string) {
    const existing = await prisma.shop.findUnique({ where: { id: shopId } });
    if (!existing) {
      throw AppError.notFound("Medical store not found", ERROR_CODES.SHOP_NOT_FOUND);
    }

    const updated = await prisma.shop.update({
      where: { id: shopId },
      data: { status },
    });

    // Record audit event
    await prisma.auditLog.create({
      data: {
        shopId,
        userId: adminUserId,
        action: status === "SUSPENDED" ? "SHOP_SUSPENDED" : "SHOP_ACTIVATED",
        entityType: "Shop",
        entityId: shopId,
        oldValue: { status: existing.status },
        newValue: { status, reason: reason || null },
      },
    });

    return updated;
  }

  /**
   * Override / Extend Shop Subscription
   */
  async updateShopSubscription(
    shopId: string,
    data: {
      planCode?: string;
      status?: string;
      extendDays?: number;
      endDate?: string;
      autoRenew?: boolean;
    },
    adminUserId?: string
  ) {
    const shop = await prisma.shop.findUnique({
      where: { id: shopId },
      include: { subscription: true },
    });

    if (!shop) {
      throw AppError.notFound("Medical store not found", ERROR_CODES.SHOP_NOT_FOUND);
    }

    let planId = shop.subscription?.planId;
    if (data.planCode) {
      const plan = await prisma.subscriptionPlan.findUnique({
        where: { code: data.planCode },
      });
      if (!plan) {
        throw AppError.badRequest(`Plan ${data.planCode} does not exist`);
      }
      planId = plan.id;
    }

    let newEndDate = shop.subscription?.endDate ? new Date(shop.subscription.endDate) : new Date();
    if (data.endDate) {
      newEndDate = new Date(data.endDate);
    } else if (data.extendDays && data.extendDays > 0) {
      const base = newEndDate > new Date() ? newEndDate : new Date();
      newEndDate = new Date(base.getTime() + data.extendDays * 24 * 60 * 60 * 1000);
    }

    const updatedSub = await prisma.shopSubscription.upsert({
      where: { shopId },
      update: {
        ...(planId ? { planId } : {}),
        ...(data.status ? { status: data.status } : {}),
        endDate: newEndDate,
        ...(data.autoRenew !== undefined ? { autoRenew: data.autoRenew } : {}),
      },
      create: {
        shopId,
        planId: planId!,
        status: data.status || "ACTIVE",
        endDate: newEndDate,
        autoRenew: data.autoRenew ?? true,
      },
      include: { plan: true },
    });

    await prisma.auditLog.create({
      data: {
        shopId,
        userId: adminUserId,
        action: "SUBSCRIPTION_OVERRIDE",
        entityType: "ShopSubscription",
        entityId: updatedSub.id,
        newValue: {
          planCode: updatedSub.plan.code,
          status: updatedSub.status,
          endDate: updatedSub.endDate,
        },
      },
    });

    return updatedSub;
  }

  /**
   * List SaaS Subscription Plans
   */
  async getPlans() {
    const plans = await prisma.subscriptionPlan.findMany({
      orderBy: { priceMonthly: "asc" },
      include: {
        _count: {
          select: { subscriptions: true },
        },
      },
    });

    return plans.map((p) => ({
      ...p,
      priceMonthly: Number(p.priceMonthly),
      priceYearly: Number(p.priceYearly),
      activeSubscribers: p._count.subscriptions,
    }));
  }

  /**
   * Update Subscription Plan Limits & Pricing
   */
  async updatePlan(
    planId: string,
    data: {
      name?: string;
      priceMonthly?: number;
      priceYearly?: number;
      maxUsers?: number;
      maxMedicines?: number;
      maxInvoicesPerMonth?: number;
      features?: any;
      isActive?: boolean;
    }
  ) {
    const existing = await prisma.subscriptionPlan.findUnique({
      where: { id: planId },
    });
    if (!existing) {
      throw AppError.notFound("Subscription plan not found");
    }

    const updated = await prisma.subscriptionPlan.update({
      where: { id: planId },
      data: {
        ...(data.name ? { name: data.name } : {}),
        ...(data.priceMonthly !== undefined ? { priceMonthly: data.priceMonthly } : {}),
        ...(data.priceYearly !== undefined ? { priceYearly: data.priceYearly } : {}),
        ...(data.maxUsers !== undefined ? { maxUsers: data.maxUsers } : {}),
        ...(data.maxMedicines !== undefined ? { maxMedicines: data.maxMedicines } : {}),
        ...(data.maxInvoicesPerMonth !== undefined ? { maxInvoicesPerMonth: data.maxInvoicesPerMonth } : {}),
        ...(data.features !== undefined ? { features: data.features } : {}),
        ...(data.isActive !== undefined ? { isActive: data.isActive } : {}),
      },
    });

    return {
      ...updated,
      priceMonthly: Number(updated.priceMonthly),
      priceYearly: Number(updated.priceYearly),
    };
  }

  /**
   * Global User Directory Across All Stores
   */
  async getUsers(params: { search?: string; role?: string; page?: number; limit?: number }) {
    const page = Math.max(1, Number(params.page || 1));
    const limit = Math.max(1, Math.min(100, Number(params.limit || 25)));
    const skip = (page - 1) * limit;

    const where: any = {};

    if (params.search && params.search.trim() !== "") {
      const q = params.search.trim();
      where.OR = [
        { email: { contains: q, mode: "insensitive" } },
        { firstName: { contains: q, mode: "insensitive" } },
        { lastName: { contains: q, mode: "insensitive" } },
        { phone: { contains: q, mode: "insensitive" } },
      ];
    }

    if (params.role && params.role !== "ALL") {
      where.userRoles = {
        some: {
          role: { name: params.role },
        },
      };
    }

    const [total, users] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          userRoles: {
            include: { role: true },
          },
          shopMemberships: {
            include: {
              shop: {
                select: { id: true, name: true, slug: true, status: true },
              },
            },
          },
        },
      }),
    ]);

    const formatted = users.map((u) => ({
      id: u.id,
      email: u.email,
      phone: u.phone,
      firstName: u.firstName,
      lastName: u.lastName,
      status: u.status,
      emailVerified: u.emailVerified,
      createdAt: u.createdAt,
      roles: u.userRoles.map((ur) => ur.role.name),
      shops: u.shopMemberships.map((sm) => ({
        shopId: sm.shop.id,
        shopName: sm.shop.name,
        slug: sm.shop.slug,
        role: sm.role,
        status: sm.status,
      })),
    }));

    return {
      items: formatted,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Promote / Demote System Roles (e.g. Admin)
   */
  async updateUserRole(userId: string, roleName: string, action: "ADD" | "REMOVE") {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw AppError.notFound("User not found");
    }

    const role = await prisma.role.findUnique({ where: { name: roleName } });
    if (!role) {
      throw AppError.notFound(`Role ${roleName} not found`);
    }

    if (action === "ADD") {
      await prisma.userRole.upsert({
        where: { userId_roleId: { userId, roleId: role.id } },
        create: { userId, roleId: role.id },
        update: {},
      });
    } else {
      await prisma.userRole.deleteMany({
        where: { userId, roleId: role.id },
      });
    }

    return { success: true, message: `Role ${roleName} ${action === "ADD" ? "assigned" : "removed"}` };
  }

  /**
   * Cross-Tenant Audit Logs
   */
  async getAuditLogs(params: {
    search?: string;
    action?: string;
    entityType?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Math.max(1, Number(params.page || 1));
    const limit = Math.max(1, Math.min(100, Number(params.limit || 30)));
    const skip = (page - 1) * limit;

    const where: any = {};
    if (params.action && params.action !== "ALL") {
      where.action = params.action;
    }
    if (params.entityType && params.entityType !== "ALL") {
      where.entityType = params.entityType;
    }
    if (params.search && params.search.trim() !== "") {
      const q = params.search.trim();
      where.OR = [
        { action: { contains: q, mode: "insensitive" } },
        { entityType: { contains: q, mode: "insensitive" } },
        { entityId: { contains: q, mode: "insensitive" } },
        { user: { email: { contains: q, mode: "insensitive" } } },
      ];
    }

    const [total, logs] = await Promise.all([
      prisma.auditLog.count({ where }),
      prisma.auditLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          user: {
            select: { id: true, email: true, firstName: true, lastName: true },
          },
          shop: {
            select: { id: true, name: true, slug: true },
          },
        },
      }),
    ]);

    return {
      items: logs,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * System Health Telemetry & Diagnostic Probes
   */
  async getSystemHealth() {
    const startDb = Date.now();
    let dbStatus = "HEALTHY";
    let dbLatencyMs = 0;
    try {
      await prisma.$queryRaw`SELECT 1`;
      dbLatencyMs = Date.now() - startDb;
    } catch (e: any) {
      dbStatus = "UNHEALTHY";
      dbLatencyMs = Date.now() - startDb;
    }

    const startRedis = Date.now();
    let redisStatus = "HEALTHY";
    let redisLatencyMs = 0;
    try {
      await redis.ping();
      redisLatencyMs = Date.now() - startRedis;
    } catch (e: any) {
      redisStatus = "UNHEALTHY";
      redisLatencyMs = Date.now() - startRedis;
    }

    const memoryUsage = process.memoryUsage();
    const systemMemory = {
      totalBytes: os.totalmem(),
      freeBytes: os.freemem(),
      usedBytes: os.totalmem() - os.freemem(),
      processHeapUsed: memoryUsage.heapUsed,
      processRss: memoryUsage.rss,
    };

    return {
      status: dbStatus === "HEALTHY" && redisStatus === "HEALTHY" ? "HEALTHY" : "DEGRADED",
      timestamp: new Date().toISOString(),
      uptimeSeconds: Math.floor(process.uptime()),
      nodeVersion: process.version,
      platform: os.platform(),
      cpus: os.cpus().length,
      database: {
        status: dbStatus,
        latencyMs: dbLatencyMs,
        provider: "PostgreSQL 16",
      },
      redis: {
        status: redisStatus,
        latencyMs: redisLatencyMs,
      },
      memory: systemMemory,
    };
  }
}

export const superadminService = new SuperadminService();
