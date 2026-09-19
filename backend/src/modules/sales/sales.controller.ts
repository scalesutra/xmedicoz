import type { Request, Response, NextFunction } from "express";
import { salesService } from "./sales.service.js";
import { sendSuccess } from "../../utils/response.js";

export class SalesController {
  static async createInvoice(req: Request, res: Response, next: NextFunction) {
    try {
      const invoice = await salesService.createInvoice(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, invoice, "Sales invoice generated and stock deducted successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async listInvoices(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await salesService.listInvoices(req.shopId!, req.query as never);
      sendSuccess(res, result, "Sales invoices retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getInvoice(req: Request, res: Response, next: NextFunction) {
    try {
      const invoice = await salesService.getInvoiceById(req.shopId!, req.params.id);
      sendSuccess(res, invoice, "Sales invoice retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async createReturn(req: Request, res: Response, next: NextFunction) {
    try {
      const body = {
        ...req.body,
        salesInvoiceId: req.params.id || req.body.salesInvoiceId,
      };
      const salesReturn = await salesService.createSalesReturn(req.shopId!, body, req.user?.id);
      sendSuccess(res, salesReturn, "Sales return processed and stock restored successfully", 201);
    } catch (err) {
      next(err);
    }
  }
}
