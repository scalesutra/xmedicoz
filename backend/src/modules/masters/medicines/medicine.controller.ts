import type { Request, Response, NextFunction } from "express";
import { MedicineService } from "./medicine.service.js";
import { sendSuccess } from "../../../utils/response.js";

export class MedicineController {
  static async list(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await MedicineService.listMedicines(req.shopId!, req.query as never);
      sendSuccess(res, result, "Medicines fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const medicine = await MedicineService.getMedicineById(req.shopId!, req.params.id);
      sendSuccess(res, medicine, "Medicine details fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const medicine = await MedicineService.createMedicine(req.shopId!, req.body);
      sendSuccess(res, medicine, "Medicine created successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const medicine = await MedicineService.updateMedicine(req.shopId!, req.params.id, req.body);
      sendSuccess(res, medicine, "Medicine updated successfully");
    } catch (err) {
      next(err);
    }
  }

  static async delete(req: Request, res: Response, next: NextFunction) {
    try {
      await MedicineService.deleteMedicine(req.shopId!, req.params.id);
      sendSuccess(res, null, "Medicine deactivated successfully");
    } catch (err) {
      next(err);
    }
  }
}
