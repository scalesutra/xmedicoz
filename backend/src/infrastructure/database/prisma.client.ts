import { PrismaClient } from "@prisma/client";
import { logger } from "../../utils/logger.js";
import { env } from "../../config/env.config.js";

declare global {
  // eslint-disable-next-line no-var
  var prismaGlobal: PrismaClient | undefined;
}

// Export singleton PrismaClient instance
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const prisma = (globalThis.prismaGlobal ??
  new PrismaClient({
    log:
      env.NODE_ENV === "development"
        ? [
            { emit: "event", level: "query" },
            { emit: "event", level: "error" },
            { emit: "event", level: "warn" },
          ]
        : [{ emit: "event", level: "error" }],
  })) as PrismaClient & { [key: string]: any };

if (env.NODE_ENV !== "production") {
  globalThis.prismaGlobal = prisma;
}

// Log queries in debug mode
if (env.NODE_ENV === "development") {
  // @ts-expect-error - prisma event typing
  prisma.$on("query", (e: { query: string; duration: number }) => {
    logger.debug({ query: e.query, durationMs: e.duration }, "Database Query");
  });
}

// @ts-expect-error - prisma event typing
prisma.$on("error", (e: { message: string }) => {
  logger.error({ err: e.message }, "Prisma Database Error");
});
