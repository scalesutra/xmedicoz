import type { Request, Response, NextFunction } from "express";
import { SupplierService } from "./supplier.service.js";
import { sendSuccess } from "../../../utils/response.js";

export class SupplierController {
  static async list(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await SupplierService.listSuppliers(req.shopId!, req.query as never);
      sendSuccess(res, result, "Suppliers fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const supplier = await SupplierService.getSupplierById(req.shopId!, req.params.id);
      sendSuccess(res, supplier, "Supplier details fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const supplier = await SupplierService.createSupplier(req.shopId!, req.body);
      sendSuccess(res, supplier, "Supplier registered successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const supplier = await SupplierService.updateSupplier(req.shopId!, req.params.id, req.body);
      sendSuccess(res, supplier, "Supplier updated successfully");
    } catch (err) {
      next(err);
    }
  }

  static async delete(req: Request, res: Response, next: NextFunction) {
    try {
      await SupplierService.deleteSupplier(req.shopId!, req.params.id);
      sendSuccess(res, null, "Supplier deactivated successfully");
    } catch (err) {
      next(err);
    }
  }
}
