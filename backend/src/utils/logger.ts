import pino from "pino";
import { env } from "../config/env.config.js";

export const logger = pino({
  level: env.NODE_ENV === "production" ? "info" : "debug",
  redact: {
    paths: [
      "req.headers.authorization",
      "req.headers.cookie",
      "password",
      "newPassword",
      "oldPassword",
      "token",
      "accessToken",
      "refreshToken",
      "secret",
      "clientSecret",
      "otp",
      "code",
    ],
    remove: true,
  },
  timestamp: pino.stdTimeFunctions.isoTime,
});
