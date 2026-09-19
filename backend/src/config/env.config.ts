import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z.object({
  PORT: z.coerce.number().default(5095),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  API_PREFIX: z.string().default("/api/v1"),
  CORS_ORIGIN: z.string().default("*"),

  DATABASE_URL: z.string().min(1, "DATABASE_URL is required"),

  REDIS_HOST: z.string().default("localhost"),
  REDIS_PORT: z.coerce.number().default(6379),
  REDIS_PASSWORD: z.string().optional().default(""),
  REDIS_DB: z.coerce.number().default(3),
  REDIS_KEY_PREFIX: z.string().default("mcrm:"),

  KEYCLOAK_BASE_URL: z.string().default("http://localhost:8081"),
  KEYCLOAK_PUBLIC_URL: z.string().default("https://identity.cognoflux.com"),
  KEYCLOAK_REALM: z.string().default("medicalcrm"),
  KEYCLOAK_CLIENT_ID: z.string().default("medicalcrm-api"),
  KEYCLOAK_CLIENT_SECRET: z.string().default("medicalcrm_api_secret_change_me"),
  KEYCLOAK_WEB_CLIENT_ID: z.string().default("medicalcrm-web"),

  KEYCLOAK_ADMIN_USER: z.string().default("admin"),
  KEYCLOAK_ADMIN_PASSWORD: z.string().default(""),

  OTP_EXPIRY_SECONDS: z.coerce.number().default(300),
  OTP_MAX_ATTEMPTS: z.coerce.number().default(5),
  OTP_RATE_LIMIT_MAX: z.coerce.number().default(3),
  OTP_RATE_LIMIT_WINDOW_SECONDS: z.coerce.number().default(600),
  OTP_DIGITS: z.coerce.number().default(6),

  SMS_PROVIDER: z.string().default("mock"),
  EMAIL_PROVIDER: z.string().default("mock"),
  MSG91_AUTH_KEY: z.string().optional().default(""),
  MSG91_OTP_TEMPLATE_ID: z.string().optional().default(""),
});

export const env = envSchema.parse(process.env);
