import { Router } from "express";
import { InventoryController } from "./inventory.controller.js";
import { SmartSearchController } from "./smart-search.controller.js";
import { validate } from "../../middleware/validation.middleware.js";
import { authenticateKeycloakJwt } from "../../middleware/auth.middleware.js";
import { requireRole } from "../../middleware/rbac.middleware.js";
import { ROLES } from "../../config/constants.js";
import {
  CreateBatchSchema,
  StockAdjustmentSchema,
  QueryBatchSchema,
  QueryExpirySchema,
  QueryLedgerSchema,
} from "./inventory.schema.js";
import {
  QuerySmartSearchSchema,
  LogShortageSchema,
  UpdateShortageSchema,
} from "./smart-search.schema.js";

import { tenantMiddleware } from "../../middleware/tenant.middleware.js";
import { rackRouter } from "./racks/rack.routes.js";

export const inventoryRouter = Router();

// All inventory endpoints require authentication and shop context
inventoryRouter.use(authenticateKeycloakJwt, tenantMiddleware);

// Physical Rack & Storage Management
inventoryRouter.use("/racks", rackRouter);

// Smart Search & Margin Badges (Symptom-based + high-profit ranking)
inventoryRouter.get(
  "/smart-search",
  validate(QuerySmartSearchSchema, "query"),
  SmartSearchController.search
);

// Instant Salt-Equivalent Engine (Substitute lookup for out-of-stock items)
inventoryRouter.get(
  "/substitutes/:medicineId",
  SmartSearchController.getSubstitutes
);

// Shortage Diary (Kami Register / Want Book)
inventoryRouter.get("/shortage-diary", SmartSearchController.listShortageDiary);
inventoryRouter.post(
  "/shortage-diary/log",
  validate(LogShortageSchema),
  SmartSearchController.logShortage
);
inventoryRouter.patch(
  "/shortage-diary/:id",
  validate(UpdateShortageSchema),
  SmartSearchController.updateShortageItem
);

// Batches List & FEFO Sales Eligibility
inventoryRouter.get("/batches", validate(QueryBatchSchema, "query"), InventoryController.listBatches);
inventoryRouter.get("/medicine/:medicineId/eligible-batches", InventoryController.getEligibleBatches);

// Create Initial Batch (Admin, Pharmacist)
inventoryRouter.post(
  "/batches",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreateBatchSchema),
  InventoryController.createBatch
);

// Stock Adjustment (Add, Subtract, Damage)
inventoryRouter.post(
  "/adjustments",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(StockAdjustmentSchema),
  InventoryController.adjustStock
);

// Expiry & Low Stock Reports
inventoryRouter.get("/near-expiry", validate(QueryExpirySchema, "query"), InventoryController.getNearExpiry);
inventoryRouter.get("/low-stock", InventoryController.getLowStock);

// Stock Audit Ledger & Valuation
inventoryRouter.get("/ledger", validate(QueryLedgerSchema, "query"), InventoryController.getLedger);
inventoryRouter.get("/valuation", InventoryController.getValuation);

