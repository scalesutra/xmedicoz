import { Router } from "express";
import { LookupController } from "./lookup.controller.js";
import { validate } from "../../../middleware/validation.middleware.js";
import { authenticateKeycloakJwt } from "../../../middleware/auth.middleware.js";
import { requireRole } from "../../../middleware/rbac.middleware.js";
import { ROLES } from "../../../config/constants.js";
import {
  CreateCategorySchema,
  UpdateCategorySchema,
  CreateManufacturerSchema,
  UpdateManufacturerSchema,
  CreateUnitSchema,
  UpdateUnitSchema,
  CreateTaxSchema,
  UpdateTaxSchema,
} from "./lookup.schema.js";

export const lookupRouter = Router();

// All lookup endpoints require authentication
lookupRouter.use(authenticateKeycloakJwt);

// Categories
lookupRouter.get("/categories", LookupController.getCategories);
lookupRouter.post(
  "/categories",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreateCategorySchema),
  LookupController.createCategory
);
lookupRouter.patch(
  "/categories/:id",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(UpdateCategorySchema),
  LookupController.updateCategory
);
lookupRouter.delete("/categories/:id", requireRole(ROLES.ADMIN), LookupController.deleteCategory);

// Manufacturers
lookupRouter.get("/manufacturers", LookupController.getManufacturers);
lookupRouter.post(
  "/manufacturers",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreateManufacturerSchema),
  LookupController.createManufacturer
);
lookupRouter.patch(
  "/manufacturers/:id",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(UpdateManufacturerSchema),
  LookupController.updateManufacturer
);
lookupRouter.delete("/manufacturers/:id", requireRole(ROLES.ADMIN), LookupController.deleteManufacturer);

// Units
lookupRouter.get("/units", LookupController.getUnits);
lookupRouter.post(
  "/units",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreateUnitSchema),
  LookupController.createUnit
);
lookupRouter.patch(
  "/units/:id",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(UpdateUnitSchema),
  LookupController.updateUnit
);

// Taxes
lookupRouter.get("/taxes", LookupController.getTaxes);
lookupRouter.post(
  "/taxes",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreateTaxSchema),
  LookupController.createTax
);
lookupRouter.patch(
  "/taxes/:id",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(UpdateTaxSchema),
  LookupController.updateTax
);
