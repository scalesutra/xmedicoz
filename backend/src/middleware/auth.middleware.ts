import type { Request, Response, NextFunction } from "express";
import { KeycloakAuthService } from "../infrastructure/keycloak/keycloak-auth.service.js";
import { prisma } from "../infrastructure/database/prisma.client.js";
import { redis } from "../infrastructure/redis/redis.client.js";
import { CACHE_KEYS, ERROR_CODES } from "../config/constants.js";
import { AppError } from "../utils/errors.js";
import { logger } from "../utils/logger.js";

export interface AuthenticatedUser {
  id: string;
  keycloakId: string;
  email: string;
  phone: string | null;
  firstName: string;
  lastName: string;
  roles: string[];
  permissions: string[];
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

export async function authenticateKeycloakJwt(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    next(AppError.unauthorized("Missing or malformed Authorization Bearer header"));
    return;
  }

  const token = authHeader.substring(7).trim();
  if (!token) {
    next(AppError.unauthorized("Token is empty"));
    return;
  }

  try {
    const payload = await KeycloakAuthService.verifyToken(token);
    const keycloakId = payload.sub;

    // Check Redis cache for user context
    const cacheKey = CACHE_KEYS.userProfile(keycloakId);
    const cached = await redis.get(cacheKey);

    if (cached) {
      req.user = JSON.parse(cached) as AuthenticatedUser;
      next();
      return;
    }

    // Lookup in database, or sync automatically on first login
    let user = await prisma.user.findFirst({
      where: {
        OR: [
          { keycloakId },
          ...(keycloakId.includes("@") ? [{ email: keycloakId }] : []),
          ...(payload.email ? [{ email: payload.email }] : []),
        ],
      },
      include: {
        userRoles: {
          include: {
            role: {
              include: {
                rolePermissions: {
                  include: { permission: true },
                },
              },
            },
          },
        },
      },
    });

    if (!user) {
      // Sync user into PostgreSQL from Keycloak payload
      const email = payload.email || (keycloakId.includes("@") ? keycloakId : `${keycloakId}@medicalcrm.local`);
      const firstName = payload.given_name || payload.name?.split(" ")[0] || "User";
      const lastName = payload.family_name || payload.name?.split(" ")[1] || "";
      const phone = payload.phone_number || null;

      user = await prisma.user.upsert({
        where: { email },
        update: { keycloakId },
        create: {
          keycloakId,
          email,
          phone,
          firstName,
          lastName,
          emailVerified: payload.email_verified === true,
          phoneVerified: false,
        },
        include: {
          userRoles: {
            include: {
              role: {
                include: {
                  rolePermissions: {
                    include: { permission: true },
                  },
                },
              },
            },
          },
        },
      });
    }

    // Extract roles from Keycloak JWT payload & DB
    const realmRoles = payload.realm_access?.roles || [];
    const dbRoles = user.userRoles.map((ur) => ur.role.name);
    const combinedRoles = Array.from(new Set([...realmRoles, ...dbRoles]));

    // Extract fine-grained permissions
    const permissions = new Set<string>();
    for (const ur of user.userRoles) {
      for (const rp of ur.role.rolePermissions) {
        permissions.add(rp.permission.code);
      }
    }

    // Admins automatically get all permissions
    if (combinedRoles.includes("Admin")) {
      permissions.add("*");
    }

    const userContext: AuthenticatedUser = {
      id: user.id,
      keycloakId: user.keycloakId,
      email: user.email,
      phone: user.phone,
      firstName: user.firstName,
      lastName: user.lastName,
      roles: combinedRoles,
      permissions: Array.from(permissions),
    };

    // Cache user profile in Redis for 10 minutes
    await redis.set(cacheKey, JSON.stringify(userContext), "EX", 600);

    req.user = userContext;
    next();
  } catch (err) {
    if (err instanceof AppError) {
      next(err);
      return;
    }
    logger.debug({ err }, "Authentication failed");
    next(AppError.unauthorized("Authentication failed", ERROR_CODES.UNAUTHORIZED));
  }
}
