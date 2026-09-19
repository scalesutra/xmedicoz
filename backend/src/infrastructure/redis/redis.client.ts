import { Redis } from "ioredis";
import { env } from "../../config/env.config.js";
import { logger } from "../../utils/logger.js";

export const redis = new Redis({
  host: env.REDIS_HOST,
  port: env.REDIS_PORT,
  password: env.REDIS_PASSWORD || undefined,
  db: env.REDIS_DB,
  keyPrefix: env.REDIS_KEY_PREFIX,
  retryStrategy(times) {
    const delay = Math.min(times * 100, 3000);
    return delay;
  },
  maxRetriesPerRequest: null,
});

redis.on("connect", () => {
  logger.info({ db: env.REDIS_DB, prefix: env.REDIS_KEY_PREFIX }, "Connected to isolated Redis");
});

redis.on("error", (err) => {
  logger.error({ err }, "Redis connection error");
});
