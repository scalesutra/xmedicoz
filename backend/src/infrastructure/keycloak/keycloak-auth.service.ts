import * as jose from "jose";
import { env } from "../../config/env.config.js";
import { logger } from "../../utils/logger.js";
import { AppError } from "../../utils/errors.js";
import { ERROR_CODES } from "../../config/constants.js";

export interface TokenResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  refreshExpiresIn: number;
  tokenType: string;
}

export interface VerifiedJwtPayload {
  sub: string;
  email?: string;
  preferred_username?: string;
  name?: string;
  given_name?: string;
  family_name?: string;
  realm_access?: {
    roles: string[];
  };
  resource_access?: Record<string, { roles: string[] }>;
  phone_number?: string;
  [key: string]: unknown;
}

export class KeycloakAuthService {
  private static jwksCache: jose.JWTVerifyGetKey | null = null;

  /**
   * Lazily initializes and caches JWKS remote keyset
   */
  private static getJwks() {
    if (!this.jwksCache) {
      const jwksUrl = new URL(
        `${env.KEYCLOAK_BASE_URL}/realms/${env.KEYCLOAK_REALM}/protocol/openid-connect/certs`
      );
      this.jwksCache = jose.createRemoteJWKSet(jwksUrl, {
        cooldownDuration: 30000,
        cacheMaxAge: 600000,
      });
    }
    return this.jwksCache;
  }

  /**
   * Authenticate with username/email and password against Keycloak Direct Access Grant
   */
  static async loginWithPassword(usernameOrEmail: string, password: string): Promise<TokenResponse> {
    const body = new URLSearchParams({
      grant_type: "password",
      client_id: env.KEYCLOAK_CLIENT_ID,
      client_secret: env.KEYCLOAK_CLIENT_SECRET,
      username: usernameOrEmail,
      password: password,
      scope: "openid profile email",
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
      const errorData = (await res.json().catch(() => ({}))) as { error?: string; error_description?: string };
      logger.warn({ usernameOrEmail, error: errorData.error }, "Failed login attempt");
      throw AppError.badRequest("Invalid username, email, or password", ERROR_CODES.INVALID_CREDENTIALS);
    }

    const data = (await res.json()) as {
      access_token: string;
      refresh_token: string;
      expires_in: number;
      refresh_expires_in: number;
      token_type: string;
    };

    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      expiresIn: data.expires_in,
      refreshExpiresIn: data.refresh_expires_in,
      tokenType: data.token_type,
    };
  }

  /**
   * Issue tokens for a verified user (used after successful OTP verification).
   * Generates tokens via direct token exchange or grant.
   */
  static async issueTokensForUser(username: string): Promise<TokenResponse> {
    // When OTP is verified, authenticate via direct grant or service-account token exchange
    // If Keycloak direct access grant requires password, we can generate a temporary grant or use service account token exchange
    const body = new URLSearchParams({
      grant_type: "password",
      client_id: env.KEYCLOAK_CLIENT_ID,
      client_secret: env.KEYCLOAK_CLIENT_SECRET,
      username: username,
      // For verified OTP, if user has standard password, or we use token exchange
      scope: "openid profile email",
    });

    const res = await fetch(
      `${env.KEYCLOAK_BASE_URL}/realms/${env.KEYCLOAK_REALM}/protocol/openid-connect/token`,
      {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: body.toString(),
      }
    );

    if (res.ok) {
      const data = (await res.json()) as {
        access_token: string;
        refresh_token: string;
        expires_in: number;
        refresh_expires_in: number;
        token_type: string;
      };
      return {
        accessToken: data.access_token,
        refreshToken: data.refresh_token,
        expiresIn: data.expires_in,
        refreshExpiresIn: data.refresh_expires_in,
        tokenType: data.token_type,
      };
    }

    // If direct grant without password requires token exchange:
    // Fallback: Use service account client credentials with impersonation / custom signed JWT
    return await this.mintInternalTokenForUser(username);
  }

  /**
   * Refresh Keycloak tokens (handles both Keycloak OAuth sessions and internal OTP tokens)
   */
  static async refreshToken(refreshToken: string): Promise<TokenResponse> {
    // 1. Check if token is an internal fallback HMAC refresh token
    try {
      const secret = new TextEncoder().encode(env.KEYCLOAK_CLIENT_SECRET);
      const { payload } = await jose.jwtVerify(refreshToken, secret, {
        algorithms: ["HS256"],
      });
      if (payload.sub && payload.type === "refresh") {
        return await this.mintInternalTokenForUser(payload.sub);
      }
    } catch {
      // Not an internal HMAC token, proceed with Keycloak standard refresh grant
    }

    // 2. Standard Keycloak OAuth2 refresh grant
    const body = new URLSearchParams({
      grant_type: "refresh_token",
      client_id: env.KEYCLOAK_CLIENT_ID,
      client_secret: env.KEYCLOAK_CLIENT_SECRET,
      refresh_token: refreshToken,
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
      throw AppError.unauthorized("Refresh token is invalid or has expired", ERROR_CODES.UNAUTHORIZED);
    }

    const data = (await res.json()) as {
      access_token: string;
      refresh_token: string;
      expires_in: number;
      refresh_expires_in: number;
      token_type: string;
    };

    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      expiresIn: data.expires_in,
      refreshExpiresIn: data.refresh_expires_in,
      tokenType: data.token_type,
    };
  }

  /**
   * Revoke session / Logout from Keycloak
   */
  static async logout(refreshToken: string): Promise<void> {
    const body = new URLSearchParams({
      client_id: env.KEYCLOAK_CLIENT_ID,
      client_secret: env.KEYCLOAK_CLIENT_SECRET,
      refresh_token: refreshToken,
    });

    await fetch(`${env.KEYCLOAK_BASE_URL}/realms/${env.KEYCLOAK_REALM}/protocol/openid-connect/logout`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: body.toString(),
    }).catch((err) => {
      logger.warn({ err }, "Keycloak logout request failed");
    });
  }

  /**
   * Verify JWT Bearer token using Keycloak JWKS with HS256 internal fallback
   */
  static async verifyToken(token: string): Promise<VerifiedJwtPayload> {
    try {
      const JWKS = this.getJwks();
      const { payload } = await jose.jwtVerify(token, JWKS, {
        // Accept both internal and public Keycloak issuers
      });

      return payload as VerifiedJwtPayload;
    } catch (err) {
      // Fallback: Check if token was minted internally using HS256 and KEYCLOAK_CLIENT_SECRET
      try {
        const secret = new TextEncoder().encode(env.KEYCLOAK_CLIENT_SECRET);
        const { payload } = await jose.jwtVerify(token, secret, {
          algorithms: ["HS256"],
        });
        return payload as VerifiedJwtPayload;
      } catch (innerErr) {
        logger.debug({ err, innerErr }, "Token verification failed against Keycloak JWKS and HMAC secret");
        throw AppError.unauthorized("Invalid or expired authorization token", ERROR_CODES.UNAUTHORIZED);
      }
    }
  }

  /**
   * Internal token fallback when user signs in via verified OTP without password
   */
  private static async mintInternalTokenForUser(username: string): Promise<TokenResponse> {
    // Mint signed token using secret
    const secret = new TextEncoder().encode(env.KEYCLOAK_CLIENT_SECRET);
    const now = Math.floor(Date.now() / 1000);
    const expiresIn = 3600;

    const accessToken = await new jose.SignJWT({
      sub: username,
      preferred_username: username,
      realm_access: { roles: ["Staff"] },
    })
      .setProtectedHeader({ alg: "HS256" })
      .setIssuedAt(now)
      .setExpirationTime(now + expiresIn)
      .setIssuer(`${env.KEYCLOAK_PUBLIC_URL}/realms/${env.KEYCLOAK_REALM}`)
      .sign(secret);

    const refreshToken = await new jose.SignJWT({ sub: username, type: "refresh" })
      .setProtectedHeader({ alg: "HS256" })
      .setIssuedAt(now)
      .setExpirationTime(now + 86400 * 7)
      .sign(secret);

    return {
      accessToken,
      refreshToken,
      expiresIn,
      refreshExpiresIn: 86400 * 7,
      tokenType: "Bearer",
    };
  }
}
