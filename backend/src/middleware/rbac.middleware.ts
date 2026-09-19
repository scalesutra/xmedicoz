import type { Request, Response, NextFunction } from "express";
import { AppError } from "../utils/errors.js";

/**
 * Enforce required role(s) on protected routes
 */
export function requireRole(...allowedRoles: string[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      next(AppError.unauthorized());
      return;
    }

    const isSystemAdmin = req.user.roles.some(
      (r) => r.toLowerCase() === "admin" || r.toLowerCase() === "superadmin"
    );
    const isShopOwner = req.shopRole === "OWNER";
    const hasRole =
      req.user.roles.some((r) =>
        allowedRoles.some((allowed) => allowed.toLowerCase() === r.toLowerCase())
      ) ||
      Boolean(
        req.shopRole &&
          allowedRoles.some(
            (allowed) => allowed.toLowerCase() === req.shopRole?.toLowerCase()
          )
      );

    if (!isSystemAdmin && !isShopOwner && !hasRole) {
      next(AppError.forbidden(`Access requires one of roles: ${allowedRoles.join(", ")}`));
      return;
    }

    next();
  };
}

/**
 * Enforce fine-grained permission(s) on protected routes
 */
export function requirePermission(...requiredPermissions: string[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      next(AppError.unauthorized());
      return;
    }

    // Superadmin wildcard check
    if (req.user.permissions.includes("*")) {
      next();
      return;
    }

    const hasAllPermissions = requiredPermissions.every((p) => req.user?.permissions.includes(p));
    if (!hasAllPermissions) {
      next(AppError.forbidden(`Missing required permission: ${requiredPermissions.join(", ")}`));
      return;
    }

    next();
  };
}
