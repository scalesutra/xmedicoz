import { Router } from "express";
import { SupplierController } from "./supplier.controller.js";
import { validate } from "../../../middleware/validation.middleware.js";
import { authenticateKeycloakJwt } from "../../../middleware/auth.middleware.js";
import { requireRole } from "../../../middleware/rbac.middleware.js";
import { ROLES } from "../../../config/constants.js";
import {
  CreateSupplierSchema,
  UpdateSupplierSchema,
  QuerySupplierSchema,
} from "./supplier.schema.js";

export const supplierRouter = Router();

// All supplier routes require authentication
supplierRouter.use(authenticateKeycloakJwt);

supplierRouter.get("/", validate(QuerySupplierSchema, "query"), SupplierController.list);
supplierRouter.get("/:id", SupplierController.getById);

supplierRouter.post(
  "/",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreateSupplierSchema),
  SupplierController.create
);

supplierRouter.patch(
  "/:id",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(UpdateSupplierSchema),
  SupplierController.update
);

supplierRouter.delete("/:id", requireRole(ROLES.ADMIN), SupplierController.delete);
