import { z } from "zod";

export const LoginSchema = z.object({
  identifier: z.string().min(3, "Identifier (email or phone) is required"),
  password: z.string().min(6, "Password must be at least 6 characters"),
});

export const RequestOtpSchema = z
  .object({
    identifier: z.string().min(3, "Email or phone number is required"),
    channel: z.enum(["EMAIL", "PHONE"]).optional(),
    purpose: z.enum(["LOGIN", "RESET_PASSWORD", "VERIFY_ACCOUNT"]).default("LOGIN"),
  })
  .transform((data) => ({
    ...data,
    channel: (data.channel || (data.identifier.includes("@") ? "EMAIL" : "PHONE")) as "EMAIL" | "PHONE",
  }));

export const VerifyOtpSchema = z
  .object({
    identifier: z.string().min(3, "Identifier is required"),
    code: z.string().length(4, "OTP must be exactly 4 digits"),
    channel: z.enum(["EMAIL", "PHONE"]).optional(),
    purpose: z.enum(["LOGIN", "RESET_PASSWORD", "VERIFY_ACCOUNT"]).optional(),
  })
  .transform((data) => ({
    ...data,
    channel: (data.channel || (data.identifier.includes("@") ? "EMAIL" : "PHONE")) as "EMAIL" | "PHONE",
  }));

export const RefreshTokenSchema = z.object({
  refreshToken: z.string().min(1, "Refresh token is required"),
});

export const ResetPasswordSchema = z.object({
  identifier: z.string().min(3, "Identifier is required"),
  code: z.string().length(4, "OTP must be exactly 4 digits"),
  channel: z.enum(["EMAIL", "PHONE"]),
  newPassword: z.string().min(8, "New password must be at least 8 characters"),
});

export const UpdateProfileSchema = z.object({
  firstName: z.string().min(1, "First name cannot be empty").optional(),
  lastName: z.string().optional(),
  phone: z.string().min(8, "Invalid phone number format").optional(),
  email: z.string().email("Invalid email address").optional(),
  avatarUrl: z.string().url("Invalid avatar URL").optional().nullable(),
});

export const ChangePasswordSchema = z.object({
  currentPassword: z.string().min(1, "Current password is required"),
  newPassword: z.string().min(8, "New password must be at least 8 characters"),
});
