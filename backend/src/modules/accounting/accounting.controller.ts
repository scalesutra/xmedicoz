import type { Request, Response, NextFunction } from "express";
import { accountingService } from "./accounting.service.js";
import { sendSuccess } from "../../utils/response.js";

export class AccountingController {
  static async seedChartOfAccounts(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await accountingService.seedStandardChartOfAccounts(req.shopId!);
      sendSuccess(res, result, "Standard Chart of Accounts initialization completed");
    } catch (err) {
      next(err);
    }
  }

  static async listAccounts(req: Request, res: Response, next: NextFunction) {
    try {
      const accounts = await accountingService.listAccounts(req.shopId!, req.query as never);
      sendSuccess(res, accounts, "Chart of accounts fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async createAccount(req: Request, res: Response, next: NextFunction) {
    try {
      const account = await accountingService.createAccount(req.shopId!, req.body);
      sendSuccess(res, account, "Account created successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async createJournalEntry(req: Request, res: Response, next: NextFunction) {
    try {
      const entry = await accountingService.createJournalEntry(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, entry, "Double-entry journal posted successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async listJournalEntries(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await accountingService.listJournalEntries(req.shopId!, req.query as never);
      sendSuccess(res, result, "Journal entries retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getGeneralLedger(req: Request, res: Response, next: NextFunction) {
    try {
      const { accountId } = req.params;
      const { startDate, endDate } = req.query as Record<string, string>;
      const ledger = await accountingService.getGeneralLedger(req.shopId!, accountId, startDate, endDate);
      sendSuccess(res, ledger, "General ledger statement retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getTrialBalance(req: Request, res: Response, next: NextFunction) {
    try {
      const { asOfDate } = req.query as Record<string, string>;
      const trialBalance = await accountingService.getTrialBalance(req.shopId!, asOfDate);
      sendSuccess(res, trialBalance, "Trial balance generated successfully");
    } catch (err) {
      next(err);
    }
  }

  static async createExpense(req: Request, res: Response, next: NextFunction) {
    try {
      const expense = await accountingService.createExpense(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, expense, "Expense voucher recorded and posted successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async listExpenses(req: Request, res: Response, next: NextFunction) {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 20;
      const result = await accountingService.listExpenses(req.shopId!, page, limit);
      sendSuccess(res, result, "Expenses fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getCustomerReceivablesAging(req: Request, res: Response, next: NextFunction) {
    try {
      const ar = await accountingService.getCustomerReceivablesAging(req.shopId!);
      sendSuccess(res, ar, "Accounts Receivable (AR) Aging fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getSupplierPayablesAging(req: Request, res: Response, next: NextFunction) {
    try {
      const ap = await accountingService.getSupplierPayablesAging(req.shopId!);
      sendSuccess(res, ap, "Accounts Payable (AP) Aging fetched successfully");
    } catch (err) {
      next(err);
    }
  }

  static async recordCustomerPayment(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await accountingService.recordCustomerPayment(req.shopId!, req.body, req.user?.id);
      sendSuccess(res, result, "Customer debt receipt recorded and settled successfully", 201);
    } catch (err) {
      next(err);
    }
  }

  static async getDaybook(req: Request, res: Response, next: NextFunction) {
    try {
      const { date } = req.query as Record<string, string>;
      const daybook = await accountingService.getDaybook(req.shopId!, date);
      sendSuccess(res, daybook, "Cash & Bank Daybook fetched successfully");
    } catch (err) {
      next(err);
    }
  }
}
