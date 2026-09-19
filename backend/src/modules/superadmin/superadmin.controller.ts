import type { Request, Response, NextFunction } from "express";
import { superadminService } from "./superadmin.service.js";
import { sendSuccess } from "../../utils/response.js";

export class SuperadminController {
  async getOverview(_req: Request, res: Response, next: NextFunction) {
    try {
      const data = await superadminService.getOverview();
      sendSuccess(res, data, "Overview telemetry retrieved");
    } catch (err) {
      next(err);
    }
  }

  async getShops(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await superadminService.getShops({
        search: req.query.search as string,
        status: req.query.status as string,
        planCode: req.query.planCode as string,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
      });
      sendSuccess(res, data, "Shops retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  async getShopById(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await superadminService.getShopById(req.params.id);
      sendSuccess(res, data, "Shop details retrieved");
    } catch (err) {
      next(err);
    }
  }

  async updateShopStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const { status, reason } = req.body;
      const data = await superadminService.updateShopStatus(
        req.params.id,
        status,
        reason,
        req.user?.id
      );
      sendSuccess(res, data, `Shop status updated to ${status}`);
    } catch (err) {
      next(err);
    }
  }

  async updateShopSubscription(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await superadminService.updateShopSubscription(
        req.params.id,
        req.body,
        req.user?.id
      );
      sendSuccess(res, data, "Shop subscription updated");
    } catch (err) {
      next(err);
    }
  }

  async getPlans(_req: Request, res: Response, next: NextFunction) {
    try {
      const data = await superadminService.getPlans();
      sendSuccess(res, data, "Subscription plans retrieved");
    } catch (err) {
      next(err);
    }
  }

  async updatePlan(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await superadminService.updatePlan(req.params.id, req.body);
      sendSuccess(res, data, "Subscription plan updated successfully");
    } catch (err) {
      next(err);
    }
  }

  async getUsers(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await superadminService.getUsers({
        search: req.query.search as string,
        role: req.query.role as string,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 25,
      });
      sendSuccess(res, data, "Users directory retrieved");
    } catch (err) {
      next(err);
    }
  }

  async updateUserRole(req: Request, res: Response, next: NextFunction) {
    try {
      const { roleName, action } = req.body;
      const data = await superadminService.updateUserRole(
        req.params.id,
        roleName,
        action || "ADD"
      );
      sendSuccess(res, data, data.message);
    } catch (err) {
      next(err);
    }
  }

  async getAuditLogs(req: Request, res: Response, next: NextFunction) {
    try {
      const data = await superadminService.getAuditLogs({
        search: req.query.search as string,
        action: req.query.action as string,
        entityType: req.query.entityType as string,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 30,
      });
      sendSuccess(res, data, "Audit logs retrieved");
    } catch (err) {
      next(err);
    }
  }

  async getSystemHealth(_req: Request, res: Response, next: NextFunction) {
    try {
      const data = await superadminService.getSystemHealth();
      sendSuccess(res, data, "System health retrieved");
    } catch (err) {
      next(err);
    }
  }
}

export const superadminController = new SuperadminController();
