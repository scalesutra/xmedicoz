import crypto from "node:crypto";

/**
 * Generate a cryptographically secure numeric OTP (default 6 digits).
 */
export function generateNumericOtp(digits: number = 6): string {
  const min = Math.pow(10, digits - 1);
  const max = Math.pow(10, digits) - 1;
  return crypto.randomInt(min, max + 1).toString();
}

/**
 * Normalize phone number to E.164 standard (e.g. +919876543210).
 */
export function normalizePhoneNumber(phone: string): string {
  const cleaned = phone.replace(/[\s\-\(\)]/g, "");
  if (cleaned.startsWith("+")) {
    return cleaned;
  }
  // Default to India +91 if 10 digits
  if (cleaned.length === 10) {
    return `+91${cleaned}`;
  }
  return `+${cleaned}`;
}

/**
 * Normalize email to lowercase and trimmed.
 */
export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}
