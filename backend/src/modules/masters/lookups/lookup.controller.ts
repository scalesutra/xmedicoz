import type { Request, Response, NextFunction } from "express";
import { LookupService } from "./lookup.service.js";
import { sendSuccess } from "../../../utils/response.js";

export class LookupController {
  // Categories
  static async getCategories(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.getCategories(req.shopId!);
      sendSuccess(res, data, "Categories fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async createCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.createCategory(req.shopId!, req.body);
      sendSuccess(res, data, "Category created successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async updateCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.updateCategory(req.shopId!, req.params.id, req.body);
      sendSuccess(res, data, "Category updated successfully");
    } catch (err) {
      next(err);
    }
  }

  static async deleteCategory(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.deleteCategory(req.shopId!, req.params.id);
      sendSuccess(res, data, "Category deactivated successfully");
    } catch (err) {
      next(err);
    }
  }

  // Manufacturers
  static async getManufacturers(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.getManufacturers(req.shopId!);
      sendSuccess(res, data, "Manufacturers fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async createManufacturer(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.createManufacturer(req.shopId!, req.body);
      sendSuccess(res, data, "Manufacturer created successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async updateManufacturer(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.updateManufacturer(req.shopId!, req.params.id, req.body);
      sendSuccess(res, data, "Manufacturer updated successfully");
    } catch (err) {
      next(err);
    }
  }

  static async deleteManufacturer(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.deleteManufacturer(req.shopId!, req.params.id);
      sendSuccess(res, data, "Manufacturer deactivated successfully");
    } catch (err) {
      next(err);
    }
  }

  // Units
  static async getUnits(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.getUnits(req.shopId!);
      sendSuccess(res, data, "Units fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async createUnit(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.createUnit(req.shopId!, req.body);
      sendSuccess(res, data, "Unit created successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async updateUnit(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.updateUnit(req.shopId!, req.params.id, req.body);
      sendSuccess(res, data, "Unit updated successfully");
    } catch (err) {
      next(err);
    }
  }

  // Taxes
  static async getTaxes(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.getTaxes(req.shopId!);
      sendSuccess(res, data, "Taxes fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async createTax(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.createTax(req.shopId!, req.body);
      sendSuccess(res, data, "Tax slab created successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async updateTax(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await LookupService.updateTax(req.shopId!, req.params.id, req.body);
      sendSuccess(res, data, "Tax slab updated successfully");
    } catch (err) {
      next(err);
    }
  }
}
