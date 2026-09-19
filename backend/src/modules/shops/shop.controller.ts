import type { Request, Response, NextFunction } from "express";
import { shopService } from "./shop.service.js";
import {
  CreateShopSchema,
  UpdateShopSchema,
  SubscribePlanSchema,
  AddMemberSchema,
} from "./shop.schema.js";
import { sendSuccess } from "../../utils/response.js";

export class ShopController {
  async listUserShops(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user!;
      const isAdmin = user.roles.includes("Admin");
      const shops = await shopService.listUserShops(user.id, isAdmin);
      sendSuccess(res, shops, "Shops retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  async getShopById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user!;
      const shopId = req.params.id;
      const isAdmin = user.roles.includes("Admin");
      const shop = await shopService.getShopById(shopId, user.id, isAdmin);
      sendSuccess(res, shop, "Shop details retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  async createShop(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = req.user!;
      const input = CreateShopSchema.parse(req.body);
      const shop = await shopService.createShop(input, user.id);
      sendSuccess(res, shop, "Medical store registered and initialized successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  async updateShop(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const shopId = req.params.id;
      const input = UpdateShopSchema.parse(req.body);
      const shop = await shopService.updateShop(shopId, input);
      sendSuccess(res, shop, "Shop updated successfully");
    } catch (err) {
      next(err);
    }
  }

  async listSubscriptionPlans(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const plans = await shopService.listSubscriptionPlans();
      sendSuccess(res, plans, "Subscription plans retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  async subscribePlan(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const shopId = req.params.id;
      const { planCode, billingCycle } = SubscribePlanSchema.parse(req.body);
      const subscription = await shopService.subscribePlan(shopId, planCode, billingCycle);
      sendSuccess(res, subscription, `Successfully subscribed to ${planCode} plan`);
    } catch (err) {
      next(err);
    }
  }

  async listMembers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const shopId = req.params.id;
      const members = await shopService.listMembers(shopId);
      sendSuccess(res, members, "Shop members retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  async addMember(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const shopId = req.params.id;
      const input = AddMemberSchema.parse(req.body);
      const member = await shopService.addMember(shopId, input);
      sendSuccess(res, member, "Staff member added successfully", 201);
    } catch (err) {
      next(err);
    }
  }
}

export const shopController = new ShopController();
