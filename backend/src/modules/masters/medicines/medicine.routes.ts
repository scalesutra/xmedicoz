import { Router } from "express";
import { MedicineController } from "./medicine.controller.js";
import { validate } from "../../../middleware/validation.middleware.js";
import { authenticateKeycloakJwt } from "../../../middleware/auth.middleware.js";
import { requireRole } from "../../../middleware/rbac.middleware.js";
import { ROLES } from "../../../config/constants.js";
import {
  CreateMedicineSchema,
  UpdateMedicineSchema,
  QueryMedicineSchema,
} from "./medicine.schema.js";

export const medicineRouter = Router();

// All medicine routes require authentication
medicineRouter.use(authenticateKeycloakJwt);

medicineRouter.get("/", validate(QueryMedicineSchema, "query"), MedicineController.list);
medicineRouter.get("/:id", MedicineController.getById);

medicineRouter.post(
  "/",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreateMedicineSchema),
  MedicineController.create
);

medicineRouter.patch(
  "/:id",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(UpdateMedicineSchema),
  MedicineController.update
);

medicineRouter.delete(
  "/:id",
  requireRole(ROLES.ADMIN),
  MedicineController.delete
);
