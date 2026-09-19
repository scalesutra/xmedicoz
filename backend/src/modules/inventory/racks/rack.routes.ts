import { Router } from "express";
import { RackController } from "./rack.controller.js";
import { validate } from "../../../middleware/validation.middleware.js";
import { requireRole } from "../../../middleware/rbac.middleware.js";
import { ROLES } from "../../../config/constants.js";
import {
  CreateRackSchema,
  UpdateRackSchema,
  QueryRackSchema,
  CreateShelfSchema,
  UpdateShelfSchema,
  AssignMedicineRackSchema,
  BulkAssignRackSchema,
  TransferRackSchema,
  AuditVerifySchema,
} from "./rack.schema.js";

export const rackRouter = Router();

// 1. Specific / Query endpoints (must come before /:id)
rackRouter.get("/", validate(QueryRackSchema, "query"), RackController.list);
rackRouter.get("/unassigned", RackController.getUnassigned);
rackRouter.get("/locate/:medicineId", RackController.locateMedicine);

// 2. Allocation & movement operations
rackRouter.post(
  "/assign",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(AssignMedicineRackSchema),
  RackController.assignMedicine
);

rackRouter.post(
  "/bulk-assign",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(BulkAssignRackSchema),
  RackController.bulkAssign
);

rackRouter.post(
  "/transfer",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(TransferRackSchema),
  RackController.transferMedicines
);

// 3. Rack entity CRUD
rackRouter.post(
  "/",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreateRackSchema),
  RackController.create
);

rackRouter.get("/:id", RackController.getById);

rackRouter.patch(
  "/:id",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(UpdateRackSchema),
  RackController.update
);

rackRouter.put(
  "/:id",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(UpdateRackSchema),
  RackController.update
);

rackRouter.delete(
  "/:id",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  RackController.delete
);

// 4. Shelf-level management
rackRouter.post(
  "/:rackId/shelves",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(CreateShelfSchema),
  RackController.createShelf
);

rackRouter.patch(
  "/:rackId/shelves/:shelfId",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(UpdateShelfSchema),
  RackController.updateShelf
);

rackRouter.delete(
  "/:rackId/shelves/:shelfId",
  requireRole(ROLES.ADMIN),
  RackController.deleteShelf
);

// 5. Physical Stock Audit per Rack
rackRouter.get(
  "/:id/audit-sheet",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  RackController.getAuditSheet
);

rackRouter.post(
  "/:id/audit-verify",
  requireRole(ROLES.ADMIN, ROLES.PHARMACIST),
  validate(AuditVerifySchema),
  RackController.submitAudit
);
