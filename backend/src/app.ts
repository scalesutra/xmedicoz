import express, { type Application } from "express";
import cors from "cors";
import helmet from "helmet";
import { env } from "./config/env.config.js";
import { requestIdMiddleware } from "./middleware/request-id.middleware.js";
import { centralErrorHandler } from "./middleware/error.middleware.js";
import { authRouter } from "./modules/auth/auth.routes.js";
import { healthRouter } from "./modules/health/health.routes.js";
import { mastersRouter } from "./modules/masters/masters.routes.js";
import { inventoryRouter } from "./modules/inventory/inventory.routes.js";
import { purchasesRouter } from "./modules/purchases/purchases.routes.js";
import { salesRouter } from "./modules/sales/sales.routes.js";
import { crmRouter } from "./modules/crm/crm.routes.js";
import { accountingRouter } from "./modules/accounting/accounting.routes.js";
import { shopRouter } from "./modules/shops/shop.routes.js";
import { ocrRouter } from "./modules/ocr/ocr.routes.js";
import { superadminRouter } from "./modules/superadmin/superadmin.routes.js";
import { sendError } from "./utils/response.js";
import { ERROR_CODES } from "./config/constants.js";

export function createApp(): Application {
  const app = express();

  // Security & Utility Middlewares
  app.use(helmet());
  app.use(
    cors({
      origin: env.CORS_ORIGIN === "*" ? true : env.CORS_ORIGIN.split(","),
      credentials: true,
    })
  );
  app.use(express.json({ limit: "25mb" }));
  app.use(express.urlencoded({ extended: true, limit: "25mb" }));
  app.use(requestIdMiddleware);

  // Root Health / Liveness
  app.use("/", healthRouter);

  // API V1 Routes
  const apiV1Router = express.Router();
  apiV1Router.use("/auth", authRouter);
  apiV1Router.use("/masters", mastersRouter);
  apiV1Router.use("/inventory", inventoryRouter);
  apiV1Router.use("/purchases", purchasesRouter);
  apiV1Router.use("/sales", salesRouter);
  apiV1Router.use("/crm", crmRouter);
  apiV1Router.use("/accounting", accountingRouter);
  apiV1Router.use("/shops", shopRouter);
  apiV1Router.use("/ocr", ocrRouter);
  apiV1Router.use("/superadmin", superadminRouter);

  app.use(env.API_PREFIX, apiV1Router);

  // 404 Handler
  app.use((req, res) => {
    sendError(res, ERROR_CODES.NOT_FOUND, `Route not found: ${req.method} ${req.originalUrl}`, 404);
  });

  // Centralized Error Handling
  app.use(centralErrorHandler);

  return app;
}
