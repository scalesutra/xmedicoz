import type { Request, Response, NextFunction } from "express";
import { InventoryService } from "./inventory.service.js";
import { sendSuccess } from "../../utils/response.js";

export class InventoryController {
  static async listBatches(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await InventoryService.listBatches(req.shopId!, req.query as never);
      sendSuccess(res, result, "Batches fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getEligibleBatches(req: Request, res: Response, next: NextFunction) {
    try {
      const batches = await InventoryService.getEligibleBatchesForMedicine(req.shopId!, req.params.medicineId);
      sendSuccess(res, batches, "Eligible sale batches fetched successfully (FEFO ordered)");
    } catch (err) {
      next(err);
    }
  }

  static async createBatch(req: Request, res: Response, next: NextFunction) {
    try {
      const batch = await InventoryService.createBatch(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, batch, "Medicine batch created successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async adjustStock(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await InventoryService.adjustStock(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, result, "Stock adjusted successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getNearExpiry(req: Request, res: Response, next: NextFunction) {
    try {
      const days = Number(req.query.days) || 90;
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 20;

      const result = await InventoryService.getNearExpiryBatches(req.shopId!, days, page, limit);
      sendSuccess(res, result, `Batches expiring within ${days} days fetched successfully`);
    } catch (err) {
      next(err);
    }
  }

  static async getLowStock(req: Request, res: Response, next: NextFunction) {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 20;

      const result = await InventoryService.getLowStockMedicines(req.shopId!, page, limit);
      sendSuccess(res, result, "Low stock medicines fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getLedger(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await InventoryService.getStockLedger(req.shopId!, req.query as never);
      sendSuccess(res, result, "Stock ledger fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getValuation(req: Request, res: Response, next: NextFunction) {
    try {
      const valuation = await InventoryService.getStockValuation(req.shopId!);
      sendSuccess(res, valuation, "Stock valuation calculated successfully");
    } catch (err) {
      next(err);
    }
  }
}
