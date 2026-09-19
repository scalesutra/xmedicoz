import { Router } from "express";
import { SalesController } from "./sales.controller.js";
import { validate } from "../../middleware/validation.middleware.js";
import { authenticateKeycloakJwt } from "../../middleware/auth.middleware.js";
import { requireRole } from "../../middleware/rbac.middleware.js";
import { ROLES } from "../../config/constants.js";
import {
  CreateSalesInvoiceSchema,
  CreateSalesReturnSchema,
  QuerySalesSchema,
} from "./sales.schema.js";

import { tenantMiddleware } from "../../middleware/tenant.middleware.js";

export const salesRouter = Router();

// All sales routes require authentication and shop context
salesRouter.use(authenticateKeycloakJwt, tenantMiddleware);

// Sales Invoices
salesRouter.get("/", validate(QuerySalesSchema, "query"), SalesController.listInvoices);
salesRouter.post(
  "/",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST, ROLES.CASHIER),
  validate(CreateSalesInvoiceSchema),
  SalesController.createInvoice
);

// Sales Returns
salesRouter.post(
  "/returns",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST, ROLES.CASHIER),
  validate(CreateSalesReturnSchema),
  SalesController.createReturn
);
salesRouter.post(
  "/:id/return",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST, ROLES.CASHIER),
  validate(CreateSalesReturnSchema),
  SalesController.createReturn
);

// Get Single Sales Invoice
salesRouter.get("/:id", SalesController.getInvoice);
