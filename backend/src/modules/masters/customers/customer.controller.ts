import type { Request, Response, NextFunction } from "express";
import { CustomerService } from "./customer.service.js";
import { sendSuccess } from "../../../utils/response.js";

export class CustomerController {
  static async list(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await CustomerService.listCustomers(req.shopId!, req.query as never);
      sendSuccess(res, result, "Customers fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const customer = await CustomerService.getCustomerById(req.shopId!, req.params.id);
      sendSuccess(res, customer, "Customer details fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getByMobile(req: Request, res: Response, next: NextFunction) {
    try {
      const customer = await CustomerService.getCustomerByMobile(req.shopId!, req.params.mobile);
      sendSuccess(res, customer, "Customer fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const customer = await CustomerService.createCustomer(req.shopId!, req.body);
      sendSuccess(res, customer, "Customer registered successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const customer = await CustomerService.updateCustomer(req.shopId!, req.params.id, req.body);
      sendSuccess(res, customer, "Customer updated successfully");
    } catch (err) {
      next(err);
    }
  }
}
