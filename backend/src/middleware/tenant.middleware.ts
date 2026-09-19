import type { Request, Response, NextFunction } from "express";
import { prisma } from "../infrastructure/database/prisma.client.js";
import { ERROR_CODES, SUBSCRIPTION_STATUS } from "../config/constants.js";
import { AppError } from "../utils/errors.js";

declare global {
  namespace Express {
    interface Request {
      shopId?: string;
      shopRole?: string;
      shop?: {
        id: string;
        name: string;
        slug: string;
        drugLicenseNo: string | null;
        gstin: string | null;
        invoicePrefix: string;
        subscription?: {
          status: string;
          endDate: Date;
          plan: {
            code: string;
            name: string;
            maxUsers: number;
            maxMedicines: number;
            maxInvoicesPerMonth: number;
          };
        } | null;
      };
    }
  }
}

/**
 * Multi-Tenant Shop Context Middleware
 * Enforces strict tenant data isolation per medical shop & verifies subscription status.
 */
export async function tenantMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const user = req.user;
  if (!user) {
    next(AppError.unauthorized("User must be authenticated"));
    return;
  }

  // 1. Resolve requested shop ID from header or query
  const rawShopHeader = (req.headers["x-shop-id"] as string) || (req.query.shopId as string);
  let requestedShopId: string | undefined = undefined;

  // Ignore invalid / empty string / "null" / "undefined" / non-UUID header values (common in mobile clients)
  const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (
    rawShopHeader &&
    typeof rawShopHeader === "string" &&
    rawShopHeader.trim() !== "" &&
    rawShopHeader !== "null" &&
    rawShopHeader !== "undefined" &&
    rawShopHeader !== "[object Object]" &&
    UUID_REGEX.test(rawShopHeader.trim())
  ) {
    requestedShopId = rawShopHeader.trim();
  }

  // Helper to fetch shop with subscription & membership details
  const fetchShopWithDetails = async (id: string) => {
    return await prisma.shop.findUnique({
      where: { id },
      include: {
        subscription: {
          include: {
            plan: true,
          },
        },
        members: {
          where: { userId: user.id, status: "ACTIVE" },
        },
      },
    });
  };

  let shop = null;

  // Try loading requested shop if provided
  if (requestedShopId) {
    shop = await fetchShopWithDetails(requestedShopId);
  }

  // Fallback: If no shopId requested, or requested shop not found / inaccessible,
  // automatically fallback to the user's primary active store membership
  if (!shop || shop.status !== "ACTIVE" || (shop.members.length === 0 && !user.roles.includes("Admin"))) {
    const membership = await prisma.shopMember.findFirst({
      where: { userId: user.id, status: "ACTIVE" },
      orderBy: { createdAt: "asc" },
      select: { shopId: true },
    });

    if (membership) {
      shop = await fetchShopWithDetails(membership.shopId);
    } else if (user.roles.includes("Admin")) {
      const anyShop = await prisma.shop.findFirst({
        where: { status: "ACTIVE" },
        select: { id: true },
      });
      if (anyShop) {
        shop = await fetchShopWithDetails(anyShop.id);
      }
    }
  }

  if (!shop || shop.status !== "ACTIVE") {
    next(AppError.notFound("Medical store not found or suspended", ERROR_CODES.SHOP_NOT_FOUND));
    return;
  }

  // 3. Authorization: Must be a ShopMember or System Admin
  const isShopMember = shop.members.length > 0;
  const isSystemAdmin = user.roles.includes("Admin");

  if (!isShopMember && !isSystemAdmin) {
    next(
      AppError.forbidden(
        "You do not have permission to access this medical store",
        ERROR_CODES.SHOP_ACCESS_DENIED
      )
    );
    return;
  }

  const memberRole = shop.members[0]?.role || (isSystemAdmin ? "OWNER" : "STAFF");

  // 4. Subscription Status Check
  if (shop.subscription) {
    const isExpired =
      shop.subscription.status === SUBSCRIPTION_STATUS.EXPIRED ||
      new Date(shop.subscription.endDate) < new Date();

    // Block write operations if subscription is expired
    if (isExpired && !["GET", "HEAD", "OPTIONS"].includes(req.method)) {
      next(
        AppError.forbidden(
          `Your medical store subscription (${shop.subscription.plan.name}) has expired. Please renew or upgrade your plan to perform billing and updates.`,
          ERROR_CODES.SUBSCRIPTION_EXPIRED
        )
      );
      return;
    }
  }

  // 5. Attach shop context to request
  req.shopId = shop.id;
  req.shopRole = memberRole;
  req.shop = {
    id: shop.id,
    name: shop.name,
    slug: shop.slug,
    drugLicenseNo: shop.drugLicenseNo,
    gstin: shop.gstin,
    invoicePrefix: shop.invoicePrefix,
    subscription: shop.subscription
      ? {
          status: shop.subscription.status,
          endDate: shop.subscription.endDate,
          plan: {
            code: shop.subscription.plan.code,
            name: shop.subscription.plan.name,
            maxUsers: shop.subscription.plan.maxUsers,
            maxMedicines: shop.subscription.plan.maxMedicines,
            maxInvoicesPerMonth: shop.subscription.plan.maxInvoicesPerMonth,
          },
        }
      : null,
  };

  next();
}
