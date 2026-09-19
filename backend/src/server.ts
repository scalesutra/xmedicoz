import { createApp } from "./app.js";
import { env } from "./config/env.config.js";
import { logger } from "./utils/logger.js";
import { prisma } from "./infrastructure/database/prisma.client.js";
import { redis } from "./infrastructure/redis/redis.client.js";

const app = createApp();

const server = app.listen(env.PORT, () => {
  logger.info(
    {
      port: env.PORT,
      env: env.NODE_ENV,
      apiPrefix: env.API_PREFIX,
      keycloakRealm: env.KEYCLOAK_REALM,
    },
    `Medical CRM API Server running on port ${env.PORT}`
  );
});

// Graceful Shutdown
async function gracefulShutdown(signal: string) {
  logger.info({ signal }, "Received termination signal, starting graceful shutdown...");

  server.close(async () => {
    logger.info("HTTP server closed.");

    try {
      await prisma.$disconnect();
      logger.info("PostgreSQL database connection closed.");

      await redis.quit();
      logger.info("Redis connection closed.");

      process.exit(0);
    } catch (err) {
      logger.error({ err }, "Error during graceful shutdown");
      process.exit(1);
    }
  });

  // Force close after 10s
  setTimeout(() => {
    logger.error("Graceful shutdown timeout exceeded, forcing exit.");
    process.exit(1);
  }, 10000);
}

process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));

process.on("unhandledRejection", (reason) => {
  logger.error({ reason }, "Unhandled Promise Rejection");
});

process.on("uncaughtException", (error) => {
  logger.fatal({ error }, "Uncaught Exception");
  process.exit(1);
});
