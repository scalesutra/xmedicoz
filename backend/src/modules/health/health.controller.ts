import type { Request, Response } from "express";
import { prisma } from "../../infrastructure/database/prisma.client.js";
import { redis } from "../../infrastructure/redis/redis.client.js";
import { env } from "../../config/env.config.js";
import { sendSuccess, sendError } from "../../utils/response.js";

export class HealthController {
  static getLiveness(_req: Request, res: Response): void {
    sendSuccess(
      res,
      {
        status: "UP",
        uptimeSeconds: Math.floor(process.uptime()),
        timestamp: new Date().toISOString(),
      },
      "Application is live"
    );
  }

  static async getReadiness(_req: Request, res: Response): Promise<void> {
    const checks: Record<string, "UP" | "DOWN"> = {
      database: "DOWN",
      redis: "DOWN",
      keycloak: "DOWN",
    };

    // 1. Database Check
    try {
      await prisma.$queryRaw`SELECT 1`;
      checks.database = "UP";
    } catch {
      checks.database = "DOWN";
    }

    // 2. Redis Check
    try {
      const ping = await redis.ping();
      if (ping === "PONG") checks.redis = "UP";
    } catch {
      checks.redis = "DOWN";
    }

    // 3. Keycloak Check
    try {
      const kcRes = await fetch(`${env.KEYCLOAK_BASE_URL}/realms/${env.KEYCLOAK_REALM}`, {
        method: "HEAD",
      });
      if (kcRes.ok) checks.keycloak = "UP";
    } catch {
      checks.keycloak = "DOWN";
    }

    const isReady = Object.values(checks).every((status) => status === "UP");

    if (isReady) {
      sendSuccess(res, { status: "READY", checks }, "All services operational");
    } else {
      sendError(res, "SERVICE_DEGRADED", "One or more infrastructure services are degraded", 503, checks);
    }
  }
}
