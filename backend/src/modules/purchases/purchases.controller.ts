import type { Request, Response, NextFunction } from "express";
import { purchasesService } from "./purchases.service.js";
import { sendSuccess } from "../../utils/response.js";

export class PurchasesController {
  static async createOrder(req: Request, res: Response, next: NextFunction) {
    try {
      const order = await purchasesService.createPurchaseOrder(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, order, "Purchase order created successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async listOrders(req: Request, res: Response, next: NextFunction) {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 20;
      const result = await purchasesService.listPurchaseOrders(req.shopId!, page, limit);
      sendSuccess(res, result, "Purchase orders retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async createInvoice(req: Request, res: Response, next: NextFunction) {
    try {
      const invoice = await purchasesService.createPurchaseInvoice(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, invoice, "Purchase invoice created and stock ingested successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async listInvoices(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await purchasesService.listInvoices(req.shopId!, req.query as never);
      sendSuccess(res, result, "Purchase invoices retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getInvoice(req: Request, res: Response, next: NextFunction) {
    try {
      const invoice = await purchasesService.getInvoiceById(req.shopId!, req.params.id);
      sendSuccess(res, invoice, "Purchase invoice retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async createReturn(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await purchasesService.createPurchaseReturn(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, result, "Purchase return processed and stock deducted successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async recordPayment(req: Request, res: Response, next: NextFunction) {
    try {
      const payment = await purchasesService.recordSupplierPayment(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, payment, "Supplier payment recorded successfully", 201);
    } catch (err) {
      next(err);
    }
  }
}
