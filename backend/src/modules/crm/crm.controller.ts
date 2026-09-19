import type { Request, Response, NextFunction } from "express";
import { crmService } from "./crm.service.js";
import { sendSuccess } from "../../utils/response.js";

export class CrmController {
  static async getCustomerHistory(req: Request, res: Response, next: NextFunction) {
    try {
      const history = await crmService.getCustomerPurchaseHistory(req.shopId!, req.params.id);
      sendSuccess(res, history, "Customer medicine purchase history retrieved successfully");
    } catch (err) {
      next(err);
    }
  }
  static async createRefillRule(req: Request, res: Response, next: NextFunction) {
    try {
      const rule = await crmService.createRefillRule(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, rule, "Customer refill rule created successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async updateRefillRule(req: Request, res: Response, next: NextFunction) {
    try {
      const rule = await crmService.updateRefillRule(req.shopId!, req.params.id, req.body);
      sendSuccess(res, rule, "Refill rule updated successfully");
    } catch (err) {
      next(err);
    }
  }

  static async listRefillRules(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await crmService.listRefillRules(req.shopId!, req.query as never);
      sendSuccess(res, result, "Refill rules retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async listDueRefills(req: Request, res: Response, next: NextFunction) {
    try {
      const days = Number(req.query.days) || 7;
      const result = await crmService.listDueRefills(req.shopId!, days);
      sendSuccess(res, result, `Due refills for next ${days} days retrieved successfully`);
    } catch (err) {
      next(err);
    }
  }

  static async triggerReminder(req: Request, res: Response, next: NextFunction) {
    try {
      const log = await crmService.triggerReminder(req.shopId!, req.params.ruleId, req.body, req.user?.id);
      sendSuccess(res, log, "Refill reminder dispatched successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async listNotifications(req: Request, res: Response, next: NextFunction) {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 20;
      const result = await crmService.listNotifications(req.shopId!, page, limit);
      sendSuccess(res, result, "Notification logs retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async createFollowUp(req: Request, res: Response, next: NextFunction) {
    try {
      const followUp = await crmService.createFollowUp(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, followUp, "Follow-up created successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async listFollowUps(req: Request, res: Response, next: NextFunction) {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 20;
      const result = await crmService.listFollowUps(req.shopId!, page, limit);
      sendSuccess(res, result, "Follow-ups retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async updateFollowUp(req: Request, res: Response, next: NextFunction) {
    try {
      const updated = await crmService.updateFollowUp(req.shopId!, req.params.id, req.body);
      sendSuccess(res, updated, "Follow-up updated successfully");
    } catch (err) {
      next(err);
    }
  }
}
