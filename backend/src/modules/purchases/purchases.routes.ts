import { Router } from "express";
import { PurchasesController } from "./purchases.controller.js";
import { validate } from "../../middleware/validation.middleware.js";
import { authenticateKeycloakJwt } from "../../middleware/auth.middleware.js";
import { requireRole } from "../../middleware/rbac.middleware.js";
import { ROLES } from "../../config/constants.js";
import {
  CreatePurchaseOrderSchema,
  CreatePurchaseInvoiceSchema,
  CreatePurchaseReturnSchema,
  RecordSupplierPaymentSchema,
  QueryPurchasesSchema,
} from "./purchases.schema.js";

import { tenantMiddleware } from "../../middleware/tenant.middleware.js";

export const purchasesRouter = Router();

// All purchases routes require authentication and shop context
purchasesRouter.use(authenticateKeycloakJwt, tenantMiddleware);

// Purchase Orders
purchasesRouter.get("/orders", PurchasesController.listOrders);
purchasesRouter.post(
  "/orders",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreatePurchaseOrderSchema),
  PurchasesController.createOrder
);

// Supplier Payments
purchasesRouter.post(
  "/payments",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(RecordSupplierPaymentSchema),
  PurchasesController.recordPayment
);

// Purchase Returns (standalone or against a specific bill)
purchasesRouter.post(
  "/returns",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreatePurchaseReturnSchema),
  PurchasesController.createReturn
);
purchasesRouter.post(
  "/:id/return",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreatePurchaseReturnSchema),
  PurchasesController.createReturn
);

// Purchase Invoices (Bills)
purchasesRouter.get(
  "/",
  validate(QueryPurchasesSchema, "query"),
  PurchasesController.listInvoices
);
purchasesRouter.get(
  "/invoices",
  validate(QueryPurchasesSchema, "query"),
  PurchasesController.listInvoices
);
purchasesRouter.post(
  "/",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreatePurchaseInvoiceSchema),
  PurchasesController.createInvoice
);
purchasesRouter.post(
  "/invoices",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreatePurchaseInvoiceSchema),
  PurchasesController.createInvoice
);
purchasesRouter.get("/invoices/:id", PurchasesController.getInvoice);
purchasesRouter.get("/:id", PurchasesController.getInvoice);
