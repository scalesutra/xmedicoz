import { Router } from "express";
import { AccountingController } from "./accounting.controller.js";
import { validate } from "../../middleware/validation.middleware.js";
import { authenticateKeycloakJwt } from "../../middleware/auth.middleware.js";
import {
  CreateAccountSchema,
  CreateJournalEntrySchema,
  CreateExpenseSchema,
  CustomerPaymentReceiptSchema,
  QueryAccountsSchema,
  QueryJournalsSchema,
  QueryDaybookSchema,
} from "./accounting.schema.js";

import { tenantMiddleware } from "../../middleware/tenant.middleware.js";

export const accountingRouter = Router();

// All accounting routes require authentication and shop context
accountingRouter.use(authenticateKeycloakJwt, tenantMiddleware);

// 1. Chart of Accounts
accountingRouter.post("/accounts/seed", AccountingController.seedChartOfAccounts);
accountingRouter.get("/accounts", validate(QueryAccountsSchema, "query"), AccountingController.listAccounts);
accountingRouter.post("/accounts", validate(CreateAccountSchema), AccountingController.createAccount);

// 2. Double-Entry Journal Entries
accountingRouter.get("/journals", validate(QueryJournalsSchema, "query"), AccountingController.listJournalEntries);
accountingRouter.post("/journals", validate(CreateJournalEntrySchema), AccountingController.createJournalEntry);

// 3. General Ledger & Trial Balance
accountingRouter.get("/ledger/:accountId", AccountingController.getGeneralLedger);
accountingRouter.get("/reports/trial-balance", AccountingController.getTrialBalance);

// 4. Store Operating Expenses
accountingRouter.get("/expenses", AccountingController.listExpenses);
accountingRouter.post("/expenses", validate(CreateExpenseSchema), AccountingController.createExpense);

// 5. Receivables & Payables Aging
accountingRouter.get("/receivables/aging", AccountingController.getCustomerReceivablesAging);
accountingRouter.post("/receivables/payment", validate(CustomerPaymentReceiptSchema), AccountingController.recordCustomerPayment);
accountingRouter.get("/payables/aging", AccountingController.getSupplierPayablesAging);

// 6. Cash & Bank Daybook
accountingRouter.get("/daybook", validate(QueryDaybookSchema, "query"), AccountingController.getDaybook);
