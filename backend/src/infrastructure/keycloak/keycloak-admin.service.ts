import { env } from "../../config/env.config.js";
import { logger } from "../../utils/logger.js";
import { AppError } from "../../utils/errors.js";
import { ERROR_CODES } from "../../config/constants.js";

interface KeycloakUserRepresentation {
  id?: string;
  username: string;
  email?: string;
  firstName?: string;
  lastName?: string;
  enabled?: boolean;
  emailVerified?: boolean;
  attributes?: Record<string, string[]>;
  credentials?: Array<{
    type: string;
    value: string;
    temporary: boolean;
  }>;
}

export class KeycloakAdminService {
  private static serviceToken: string | null = null;
  private static tokenExpiresAt: number = 0;

  /**
   * Obtain Service Account token for medicalcrm-api client.
   * Caches token until near expiration.
   */
  private static async getServiceAccountToken(): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    if (this.serviceToken && this.tokenExpiresAt > now + 30) {
      return this.serviceToken;
    }

    try {
      const body = new URLSearchParams({
        grant_type: "client_credentials",
        client_id: env.KEYCLOAK_CLIENT_ID,
        client_secret: env.KEYCLOAK_CLIENT_SECRET,
      });

      const res = await fetch(
        `${env.KEYCLOAK_BASE_URL}/realms/${env.KEYCLOAK_REALM}/protocol/openid-connect/token`,
        {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          body: body.toString(),
        }
      );

      if (!res.ok) {
        // Fallback to master admin if service-account credentials need bootstrap
        return await this.getMasterAdminToken();
      }

      const data = (await res.json()) as { access_token: string; expires_in: number };
      this.serviceToken = data.access_token;
      this.tokenExpiresAt = now + data.expires_in;
      return this.serviceToken;
    } catch (err) {
      logger.warn({ err }, "Service account token failed, falling back to master admin");
      return await this.getMasterAdminToken();
    }
  }

  /**
   * Fallback to master admin token if service-account isn't ready
   */
  private static async getMasterAdminToken(): Promise<string> {
    const body = new URLSearchParams({
      grant_type: "password",
      client_id: "admin-cli",
      username: env.KEYCLOAK_ADMIN_USER,
      password: env.KEYCLOAK_ADMIN_PASSWORD,
    });

    const res = await fetch(`${env.KEYCLOAK_BASE_URL}/realms/master/protocol/openid-connect/token`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: body.toString(),
    });

    if (!res.ok) {
      const text = await res.text();
      logger.error({ status: res.status, text }, "Failed to get Keycloak master admin token");
      throw AppError.internal("Identity provider authentication unavailable");
    }

    const data = (await res.json()) as { access_token: string; expires_in: number };
    return data.access_token;
  }

  private static async adminFetch(path: string, options: RequestInit = {}): Promise<Response> {
    const token = await this.getServiceAccountToken();
    const url = `${env.KEYCLOAK_BASE_URL}/admin/realms/${env.KEYCLOAK_REALM}${path}`;
    const headers = {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      ...(options.headers || {}),
    };

    const res = await fetch(url, { ...options, headers });
    return res;
  }

  /**
   * Find Keycloak user by email
   */
  static async findUserByEmail(email: string): Promise<KeycloakUserRepresentation | null> {
    try {
      const res = await this.adminFetch(`/users?email=${encodeURIComponent(email)}&exact=true`);
      if (!res.ok) return null;
      const users = (await res.json()) as KeycloakUserRepresentation[];
      return users.length > 0 ? users[0] : null;
    } catch (err) {
      logger.error({ err, email }, "Failed to find Keycloak user by email");
      return null;
    }
  }

  /**
   * Find Keycloak user by phone number attribute
   */
  static async findUserByPhone(phone: string): Promise<KeycloakUserRepresentation | null> {
    try {
      // Query users with q parameter or search attribute
      const res = await this.adminFetch(`/users?q=phone_number:${encodeURIComponent(phone)}`);
      if (res.ok) {
        const users = (await res.json()) as KeycloakUserRepresentation[];
        if (users.length > 0) return users[0];
      }

      // Also search by username in case username is the phone number
      const userRes = await this.adminFetch(`/users?username=${encodeURIComponent(phone)}&exact=true`);
      if (userRes.ok) {
        const users = (await userRes.json()) as KeycloakUserRepresentation[];
        if (users.length > 0) return users[0];
      }

      return null;
    } catch (err) {
      logger.error({ err, phone }, "Failed to find Keycloak user by phone");
      return null;
    }
  }

  /**
   * Find Keycloak user by Keycloak ID
   */
  static async findUserById(id: string): Promise<KeycloakUserRepresentation | null> {
    try {
      const res = await this.adminFetch(`/users/${id}`);
      if (!res.ok) return null;
      return (await res.json()) as KeycloakUserRepresentation;
    } catch (err) {
      logger.error({ err, id }, "Failed to find Keycloak user by ID");
      return null;
    }
  }

  /**
   * Create a new user in Keycloak
   */
  static async createUser(userData: KeycloakUserRepresentation): Promise<string> {
    const res = await this.adminFetch(`/users`, {
      method: "POST",
      body: JSON.stringify(userData),
    });

    if (res.status === 409) {
      throw AppError.conflict("A user with this email or phone already exists", ERROR_CODES.CONFLICT);
    }

    if (!res.ok) {
      const text = await res.text();
      logger.error({ status: res.status, text }, "Failed to create user in Keycloak");
      throw AppError.internal("Failed to create user in identity provider");
    }

    // Keycloak returns user ID in Location header: .../users/{id}
    const location = res.headers.get("location");
    if (location) {
      const parts = location.split("/");
      return parts[parts.length - 1];
    }

    // If Location header not present, lookup by username
    const lookup = await this.adminFetch(`/users?username=${encodeURIComponent(userData.username)}&exact=true`);
    if (lookup.ok) {
      const users = (await lookup.json()) as KeycloakUserRepresentation[];
      if (users[0]?.id) return users[0].id;
    }

    throw AppError.internal("User created in Keycloak but failed to resolve ID");
  }

  /**
   * Update user details in Keycloak
   */
  static async updateUser(id: string, updates: Partial<KeycloakUserRepresentation>): Promise<void> {
    const res = await this.adminFetch(`/users/${id}`, {
      method: "PUT",
      body: JSON.stringify(updates),
    });

    if (!res.ok) {
      const text = await res.text();
      logger.error({ status: res.status, text, id }, "Failed to update user in Keycloak");
      throw AppError.internal("Failed to update user profile in identity provider");
    }
  }

  /**
   * Reset / Update user password
   */
  static async resetPassword(id: string, newPassword: string, temporary: boolean = false): Promise<void> {
    const res = await this.adminFetch(`/users/${id}/reset-password`, {
      method: "PUT",
      body: JSON.stringify({
        type: "password",
        value: newPassword,
        temporary,
      }),
    });

    if (!res.ok) {
      const text = await res.text();
      logger.error({ status: res.status, text, id }, "Failed to reset password in Keycloak");
      throw AppError.internal("Failed to update password");
    }
  }

  /**
   * Assign realm role to user
   */
  static async assignRole(userId: string, roleName: string): Promise<void> {
    // Get role representation
    const roleRes = await this.adminFetch(`/roles/${encodeURIComponent(roleName)}`);
    if (!roleRes.ok) {
      logger.warn({ roleName }, "Role not found in Keycloak realm");
      return;
    }
    const role = await roleRes.json();

    const assignRes = await this.adminFetch(`/users/${userId}/role-mappings/realm`, {
      method: "POST",
      body: JSON.stringify([role]),
    });

    if (!assignRes.ok) {
      logger.warn({ userId, roleName }, "Failed to assign role to user in Keycloak");
    }
  }
}
