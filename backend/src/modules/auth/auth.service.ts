import { KeycloakAuthService, type TokenResponse } from "../../infrastructure/keycloak/keycloak-auth.service.js";
import { KeycloakAdminService } from "../../infrastructure/keycloak/keycloak-admin.service.js";
import { OtpService, type OtpChannel, type OtpPurpose } from "./otp.service.js";
import { prisma } from "../../infrastructure/database/prisma.client.js";
import { redis } from "../../infrastructure/redis/redis.client.js";
import { CACHE_KEYS, ERROR_CODES, ROLES } from "../../config/constants.js";
import { normalizeEmail, normalizePhoneNumber } from "../../utils/otp.utils.js";
import { AppError } from "../../utils/errors.js";
import { logger } from "../../utils/logger.js";

export class AuthService {
  /**
   * Login with email or phone + password
   */
  static async login(
    identifier: string,
    password: string
  ): Promise<{ tokens: TokenResponse; user: unknown; shops?: unknown[]; activeShop?: unknown }> {
    let usernameToAuth = identifier.trim();
    const isEmail = identifier.includes("@");

    if (isEmail) {
      usernameToAuth = normalizeEmail(identifier);
    } else {
      // Find Keycloak user by phone attribute
      const normalizedPhone = normalizePhoneNumber(identifier);
      const kcUser = await KeycloakAdminService.findUserByPhone(normalizedPhone);
      if (kcUser) {
        usernameToAuth = kcUser.username;
      } else {
        usernameToAuth = normalizedPhone;
      }
    }

    // Authenticate against Keycloak
    const tokens = await KeycloakAuthService.loginWithPassword(usernameToAuth, password);

    // Verify token to get subject / identity
    const payload = await KeycloakAuthService.verifyToken(tokens.accessToken);
    const keycloakId = payload.sub;

    // Retrieve or synchronize database profile
    let user = await prisma.user.findUnique({
      where: { keycloakId },
      include: { userRoles: { include: { role: true } } },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          keycloakId,
          email: payload.email || `${keycloakId}@medicalcrm.local`,
          phone: payload.phone_number || (isEmail ? null : normalizePhoneNumber(identifier)),
          firstName: payload.given_name || "User",
          lastName: payload.family_name || "",
          emailVerified: payload.email_verified === true,
        },
        include: { userRoles: { include: { role: true } } },
      });
    }

    // Fetch user's active shops & active store context
    const memberships = await prisma.shopMember.findMany({
      where: { userId: user.id, status: "ACTIVE" },
      include: {
        shop: {
          include: {
            subscription: {
              include: { plan: true },
            },
          },
        },
      },
      orderBy: { createdAt: "asc" },
    });

    const shops = memberships.map((m) => ({
      id: m.shop.id,
      name: m.shop.name,
      slug: m.shop.slug,
      role: m.role,
      drugLicenseNo: m.shop.drugLicenseNo,
      gstin: m.shop.gstin,
      invoicePrefix: m.shop.invoicePrefix,
      status: m.shop.status,
      subscription: m.shop.subscription
        ? {
            status: m.shop.subscription.status,
            endDate: m.shop.subscription.endDate,
            plan: {
              code: m.shop.subscription.plan.code,
              name: m.shop.subscription.plan.name,
            },
          }
        : null,
    }));

    // Record Audit Event
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        shopId: shops[0]?.id || null,
        action: "LOGIN",
        entityType: "User",
        entityId: user.id,
        newValue: { email: user.email, method: "PASSWORD" },
      },
    }).catch(() => {});

    return {
      tokens,
      user: {
        id: user.id,
        email: user.email,
        phone: user.phone,
        firstName: user.firstName,
        lastName: user.lastName,
        roles: user.userRoles.map((r) => r.role.name),
      },
      shops,
      activeShop: shops[0] || null,
    };
  }

  /**
   * Request OTP for email or phone
   */
  static async requestOtp(identifier: string, channel: OtpChannel, purpose: OtpPurpose) {
    return await OtpService.requestOtp(identifier, channel, purpose);
  }

  /**
   * Verify OTP and authenticate / register user
   */
  static async verifyOtp(
    identifier: string,
    code: string,
    channel: OtpChannel,
    purpose: OtpPurpose = "LOGIN"
  ): Promise<{ tokens: TokenResponse; user: unknown }> {
    // 1. Verify code
    await OtpService.verifyOtp(identifier, code, channel, purpose);

    const isEmail = channel === "EMAIL";
    const normalizedIdentifier = isEmail ? normalizeEmail(identifier) : normalizePhoneNumber(identifier);

    // 2. Lookup or Provision Keycloak user
    let kcUser = isEmail
      ? await KeycloakAdminService.findUserByEmail(normalizedIdentifier)
      : await KeycloakAdminService.findUserByPhone(normalizedIdentifier);

    if (!kcUser) {
      // Auto-provision user in Keycloak
      logger.info({ identifier: normalizedIdentifier, channel }, "Provisioning new user via verified OTP");
      const newUsername = normalizedIdentifier;
      const keycloakId = await KeycloakAdminService.createUser({
        username: newUsername,
        email: isEmail ? normalizedIdentifier : `${normalizedIdentifier.replace(/\+/g, "")}@medicalcrm.local`,
        firstName: isEmail ? normalizedIdentifier.split("@")[0] : "Customer",
        lastName: "User",
        enabled: true,
        emailVerified: isEmail,
        attributes: {
          phone_number: [isEmail ? "" : normalizedIdentifier],
          is_phone_verified: [isEmail ? "false" : "true"],
          is_email_verified: [isEmail ? "true" : "false"],
        },
      });

      // Assign default Staff role
      await KeycloakAdminService.assignRole(keycloakId, ROLES.STAFF);

      kcUser = {
        id: keycloakId,
        username: newUsername,
        email: isEmail ? normalizedIdentifier : undefined,
      };
    }

    // 3. Issue Tokens
    const tokens = await KeycloakAuthService.issueTokensForUser(kcUser.username);

    // 4. Synchronize into PostgreSQL
    let user = await prisma.user.findFirst({
      where: isEmail ? { email: normalizedIdentifier } : { phone: normalizedIdentifier },
      include: { userRoles: { include: { role: true } } },
    });

    if (!user) {
      const staffRole = await prisma.role.findUnique({ where: { name: ROLES.STAFF } });
      user = await prisma.user.create({
        data: {
          keycloakId: kcUser.id || kcUser.username,
          email: kcUser.email || `${kcUser.username}@medicalcrm.local`,
          phone: isEmail ? null : normalizedIdentifier,
          firstName: kcUser.firstName || "User",
          lastName: kcUser.lastName || "",
          emailVerified: isEmail,
          phoneVerified: !isEmail,
          ...(staffRole
            ? {
                userRoles: {
                  create: {
                    roleId: staffRole.id,
                  },
                },
              }
            : {}),
        },
        include: { userRoles: { include: { role: true } } },
      });
    } else {
      // Update verification flag
      user = await prisma.user.update({
        where: { id: user.id },
        data: isEmail ? { emailVerified: true } : { phoneVerified: true },
        include: { userRoles: { include: { role: true } } },
      });

      if (user.userRoles.length === 0) {
        const staffRole = await prisma.role.findUnique({ where: { name: ROLES.STAFF } });
        if (staffRole) {
          await prisma.userRole.upsert({
            where: { userId_roleId: { userId: user.id, roleId: staffRole.id } },
            create: { userId: user.id, roleId: staffRole.id },
            update: {},
          });
          user = (await prisma.user.findUnique({
            where: { id: user.id },
            include: { userRoles: { include: { role: true } } },
          }))!;
        }
      }
    }

    return {
      tokens,
      user: {
        id: user.id,
        email: user.email,
        phone: user.phone,
        firstName: user.firstName,
        lastName: user.lastName,
        roles: user.userRoles.map((r) => r.role.name),
      },
    };
  }

  /**
   * Refresh Token
   */
  static async refreshTokens(refreshToken: string): Promise<TokenResponse> {
    return await KeycloakAuthService.refreshToken(refreshToken);
  }

  /**
   * Reset Password with verified OTP
   */
  static async resetPassword(
    identifier: string,
    code: string,
    channel: OtpChannel,
    newPassword: string
  ): Promise<{ message: string }> {
    // 1. Verify OTP with RESET_PASSWORD purpose
    await OtpService.verifyOtp(identifier, code, channel, "RESET_PASSWORD");

    const isEmail = channel === "EMAIL";
    const normalizedIdentifier = isEmail ? normalizeEmail(identifier) : normalizePhoneNumber(identifier);

    // 2. Find Keycloak user
    const kcUser = isEmail
      ? await KeycloakAdminService.findUserByEmail(normalizedIdentifier)
      : await KeycloakAdminService.findUserByPhone(normalizedIdentifier);

    if (!kcUser || !kcUser.id) {
      throw AppError.notFound("No account found matching this identifier", ERROR_CODES.USER_NOT_FOUND);
    }

    // 3. Update password in Keycloak
    await KeycloakAdminService.resetPassword(kcUser.id, newPassword, false);

    logger.info({ identifier: normalizedIdentifier }, "Password successfully reset via OTP");
    return { message: "Password has been successfully updated. Please login with your new password." };
  }

  /**
   * Get Current User Profile
   */
  static async getProfile(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
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
      throw AppError.notFound("User not found", ERROR_CODES.USER_NOT_FOUND);
    }

    const roles = user.userRoles.map((ur) => ur.role.name);
    const permissions = new Set<string>();
    for (const ur of user.userRoles) {
      for (const rp of ur.role.rolePermissions) {
        permissions.add(rp.permission.code);
      }
    }
    if (roles.includes("Admin")) {
      permissions.add("*");
    }

    return {
      id: user.id,
      email: user.email,
      phone: user.phone,
      firstName: user.firstName,
      lastName: user.lastName,
      status: user.status,
      emailVerified: user.emailVerified,
      phoneVerified: user.phoneVerified,
      avatarUrl: user.avatarUrl,
      roles,
      permissions: Array.from(permissions),
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  /**
   * Update Profile Details
   */
  static async updateProfile(
    userId: string,
    data: { firstName?: string; lastName?: string; phone?: string; email?: string; avatarUrl?: string | null }
  ) {
    const existing = await prisma.user.findUnique({ where: { id: userId } });
    if (!existing) {
      throw AppError.notFound("User not found", ERROR_CODES.USER_NOT_FOUND);
    }

    // Update in database
    const updated = await prisma.user.update({
      where: { id: userId },
      data: {
        firstName: data.firstName ?? existing.firstName,
        lastName: data.lastName ?? existing.lastName,
        phone: data.phone ? normalizePhoneNumber(data.phone) : existing.phone,
        email: data.email ? normalizeEmail(data.email) : existing.email,
        avatarUrl: data.avatarUrl !== undefined ? data.avatarUrl : existing.avatarUrl,
      },
    });

    // Synchronize to Keycloak asynchronously
    if (existing.keycloakId) {
      KeycloakAdminService.updateUser(existing.keycloakId, {
        firstName: updated.firstName,
        lastName: updated.lastName,
        email: updated.email,
        attributes: updated.phone ? { phone_number: [updated.phone] } : undefined,
      }).catch((err) => {
        logger.warn({ err, userId }, "Failed to sync profile update to Keycloak");
      });

      // Invalidate Redis profile cache
      await redis.del(CACHE_KEYS.userProfile(existing.keycloakId));
    }

    return {
      id: updated.id,
      email: updated.email,
      phone: updated.phone,
      firstName: updated.firstName,
      lastName: updated.lastName,
      avatarUrl: updated.avatarUrl,
      updatedAt: updated.updatedAt,
    };
  }

  /**
   * Change Password (while authenticated)
   */
  static async changePassword(keycloakId: string, currentPassword: string, newPassword: string): Promise<void> {
    const kcUser = await KeycloakAdminService.findUserById(keycloakId);
    if (!kcUser) {
      throw AppError.notFound("User identity not found in Keycloak", ERROR_CODES.USER_NOT_FOUND);
    }

    // Verify current password by attempting login
    try {
      await KeycloakAuthService.loginWithPassword(kcUser.username, currentPassword);
    } catch {
      throw AppError.badRequest("Current password is incorrect", ERROR_CODES.INVALID_CREDENTIALS);
    }

    // Set new password
    await KeycloakAdminService.resetPassword(keycloakId, newPassword, false);
    logger.info({ keycloakId }, "User changed password successfully");
  }
}
