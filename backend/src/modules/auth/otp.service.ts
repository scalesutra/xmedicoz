import { redis } from "../../infrastructure/redis/redis.client.js";
import { env } from "../../config/env.config.js";
import { CACHE_KEYS, ERROR_CODES } from "../../config/constants.js";
import { generateNumericOtp, normalizeEmail, normalizePhoneNumber } from "../../utils/otp.utils.js";
import { AppError } from "../../utils/errors.js";
import { logger } from "../../utils/logger.js";

export type OtpChannel = "EMAIL" | "PHONE";
export type OtpPurpose = "LOGIN" | "RESET_PASSWORD" | "VERIFY_ACCOUNT";

interface StoredOtpData {
  code: string;
  attempts: number;
  purpose: OtpPurpose;
  createdAt: number;
}

export class OtpService {
  /**
   * Request an OTP for email or phone
   */
  static async requestOtp(
    identifier: string,
    channel: OtpChannel,
    purpose: OtpPurpose
  ): Promise<{ expiresInSeconds: number; otp?: string }> {
    const normalizedIdentifier = channel === "EMAIL" ? normalizeEmail(identifier) : normalizePhoneNumber(identifier);

    // 1. Rate Limiting: Max requests per window (enforced strictly in production)
    const rateLimitKey = CACHE_KEYS.otpRateLimit(channel, normalizedIdentifier);
    const requestCount = await redis.incr(rateLimitKey);
    if (requestCount === 1) {
      await redis.expire(rateLimitKey, env.OTP_RATE_LIMIT_WINDOW_SECONDS);
    } else if (env.NODE_ENV === "production" && requestCount > env.OTP_RATE_LIMIT_MAX) {
      const ttl = await redis.ttl(rateLimitKey);
      throw AppError.rateLimited(`Too many OTP requests. Please wait ${ttl > 0 ? ttl : 60} seconds before requesting again.`);
    }

    // 2. Generate 4-digit OTP
    const code = generateNumericOtp(4);
    const otpKey = CACHE_KEYS.otp(channel, normalizedIdentifier);

    const otpData: StoredOtpData = {
      code,
      attempts: 0,
      purpose,
      createdAt: Date.now(),
    };

    // 3. Store in Redis with TTL (default 300s / 5 mins)
    await redis.set(otpKey, JSON.stringify(otpData), "EX", env.OTP_EXPIRY_SECONDS);

    // 4. Dispatch OTP via SMS or Email provider
    await this.dispatchOtp(normalizedIdentifier, code, channel, purpose);

    return {
      expiresInSeconds: env.OTP_EXPIRY_SECONDS,
      // For development/testing environments, return the OTP directly in response for fast manual & automated testing
      ...(env.NODE_ENV !== "production" ? { otp: code } : {}),
    };
  }

  /**
   * Verify an OTP for email or phone
   */
  static async verifyOtp(
    identifier: string,
    code: string,
    channel: OtpChannel,
    purpose?: OtpPurpose
  ): Promise<boolean> {
    const normalizedIdentifier = channel === "EMAIL" ? normalizeEmail(identifier) : normalizePhoneNumber(identifier);
    const otpKey = CACHE_KEYS.otp(channel, normalizedIdentifier);

    const rawData = await redis.get(otpKey);
    if (!rawData) {
      throw AppError.badRequest("OTP has expired or was not requested", ERROR_CODES.OTP_EXPIRED);
    }

    const otpData = JSON.parse(rawData) as StoredOtpData;

    // Verify Purpose if provided
    if (purpose && otpData.purpose !== purpose) {
      throw AppError.badRequest("Invalid OTP purpose", ERROR_CODES.INVALID_OTP);
    }

    // Check attempts
    if (otpData.attempts >= env.OTP_MAX_ATTEMPTS) {
      await redis.del(otpKey);
      throw AppError.badRequest("Maximum OTP verification attempts exceeded. Please request a new OTP.", ERROR_CODES.OTP_ATTEMPTS_EXCEEDED);
    }

    // Check code: match exact generated code OR test master OTP '1234' in non-production
    const isMasterTestOtp = env.NODE_ENV !== "production" && code.trim() === "1234";
    if (otpData.code !== code.trim() && !isMasterTestOtp) {
      otpData.attempts += 1;
      const ttl = await redis.ttl(otpKey);
      if (ttl > 0) {
        await redis.set(otpKey, JSON.stringify(otpData), "EX", ttl);
      }
      throw AppError.badRequest("Invalid OTP code. Please check and try again.", ERROR_CODES.INVALID_OTP);
    }

    // Success: Delete OTP key so it cannot be reused
    await redis.del(otpKey);
    logger.info({ identifier: normalizedIdentifier, channel, purpose: otpData.purpose }, "OTP verified successfully");
    return true;
  }

  /**
   * Dispatch OTP message to user via configured provider (Mock in development/test)
   */
  private static async dispatchOtp(
    identifier: string,
    code: string,
    channel: OtpChannel,
    purpose: OtpPurpose
  ): Promise<void> {
    const message = `Your Medical CRM verification code is: ${code}. Valid for 5 minutes. Do not share this code.`;

    if (channel === "PHONE") {
      logger.info(
        {
          channel: "SMS",
          to: identifier,
          purpose,
          // In development/mock mode, display OTP in logs for easy testing
          devOtpCode: env.NODE_ENV !== "production" ? code : undefined,
        },
        `[SMS Dispatch] ${message}`
      );
      // Integration with Fast2SMS / Twilio / MSG91 would be called here via BullMQ worker
    } else {
      logger.info(
        {
          channel: "EMAIL",
          to: identifier,
          purpose,
          // In development/mock mode, display OTP in logs for easy testing
          devOtpCode: env.NODE_ENV !== "production" ? code : undefined,
        },
        `[Email Dispatch] ${message}`
      );
      // Integration with SMTP / Resend / SES would be called here via BullMQ worker
    }
  }
}
