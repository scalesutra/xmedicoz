import type { Request, Response, NextFunction } from "express";
import { RackService } from "./rack.service.js";
import { sendSuccess } from "../../../utils/response.js";

export class RackController {
  static async list(req: Request, res: Response, next: NextFunction) {
    try {
      const racks = await RackService.listRacks(req.shopId!, req.query as never);
      sendSuccess(res, racks, "Racks retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const rack = await RackService.getRackDetails(req.shopId!, req.params.id);
      sendSuccess(res, rack, "Rack details retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const rack = await RackService.createRack(req.shopId!, req.body);
      sendSuccess(res, rack, "Rack created successfully with initial shelves", 201);
    } catch (err) {
      next(err);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const rack = await RackService.updateRack(req.shopId!, req.params.id, req.body);
      sendSuccess(res, rack, "Rack updated successfully");
    } catch (err) {
      next(err);
    }
  }

  static async delete(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await RackService.deleteRack(req.shopId!, req.params.id);
      sendSuccess(res, result, "Rack deleted successfully");
    } catch (err) {
      next(err);
    }
  }

  // Shelf handlers
  static async createShelf(req: Request, res: Response, next: NextFunction) {
    try {
      const shelf = await RackService.createShelf(req.shopId!, req.params.rackId, req.body);
      sendSuccess(res, shelf, "Shelf created successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async updateShelf(req: Request, res: Response, next: NextFunction) {
    try {
      const shelf = await RackService.updateShelf(
        req.shopId!,
        req.params.rackId,
        req.params.shelfId,
        req.body
      );
      sendSuccess(res, shelf, "Shelf updated successfully");
    } catch (err) {
      next(err);
    }
  }

  static async deleteShelf(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await RackService.deleteShelf(
        req.shopId!,
        req.params.rackId,
        req.params.shelfId
      );
      sendSuccess(res, result, "Shelf deleted successfully");
    } catch (err) {
      next(err);
    }
  }

  // Allocation handlers
  static async assignMedicine(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await RackService.assignMedicine(req.shopId!, req.body);
      sendSuccess(res, result, "Medicine assigned to rack location successfully");
    } catch (err) {
      next(err);
    }
  }

  static async bulkAssign(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await RackService.bulkAssign(req.shopId!, req.body.assignments);
      sendSuccess(res, result, `Bulk assigned ${result.assignedCount} medicines successfully`);
    } catch (err) {
      next(err);
    }
  }

  static async transferMedicines(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await RackService.transferMedicines(req.shopId!, req.body);
      sendSuccess(res, result, "Medicines transferred to target rack successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getUnassigned(req: Request, res: Response, next: NextFunction) {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 20;
      const search = req.query.search as string | undefined;

      const result = await RackService.getUnassignedMedicines(req.shopId!, page, limit, search);
      sendSuccess(res, result, "Unassigned medicines retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  // Fast Locator
  static async locateMedicine(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await RackService.locateMedicine(req.shopId!, req.params.medicineId);
      sendSuccess(res, result, "Medicine coordinates located successfully");
    } catch (err) {
      next(err);
    }
  }

  // Physical Audit
  static async getAuditSheet(req: Request, res: Response, next: NextFunction) {
    try {
      const sheet = await RackService.generateAuditSheet(req.shopId!, req.params.id);
      sendSuccess(res, sheet, "Rack audit sheet generated successfully");
    } catch (err) {
      next(err);
    }
  }

  static async submitAudit(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await RackService.submitAuditVerification(
        req.shopId!,
        req.user?.id || null,
        req.params.id,
        req.body.auditItems
      );
      sendSuccess(res, result, "Physical stock verification submitted and reconciled");
    } catch (err) {
      next(err);
    }
  }
}
