import { z } from "zod";
import {
  ACCOUNT_TYPE,
  JOURNAL_ENTRY_STATUS,
  JOURNAL_LINE_TYPE,
  JOURNAL_REF_TYPE,
  PAYMENT_MODE,
} from "../../config/constants.js";

export const CreateAccountGroupSchema = z.object({
  code: z.string().trim().min(2).max(50),
  name: z.string().trim().min(2).max(100),
  type: z.enum([
    ACCOUNT_TYPE.ASSET,
    ACCOUNT_TYPE.LIABILITY,
    ACCOUNT_TYPE.EQUITY,
    ACCOUNT_TYPE.REVENUE,
    ACCOUNT_TYPE.EXPENSE,
  ]),
  description: z.string().max(500).optional(),
});

export type CreateAccountGroupInput = z.infer<typeof CreateAccountGroupSchema>;

export const CreateAccountSchema = z.object({
  code: z.string().trim().min(1).max(20),
  name: z.string().trim().min(2).max(150),
  type: z.enum([
    ACCOUNT_TYPE.ASSET,
    ACCOUNT_TYPE.LIABILITY,
    ACCOUNT_TYPE.EQUITY,
    ACCOUNT_TYPE.REVENUE,
    ACCOUNT_TYPE.EXPENSE,
  ]),
  groupId: z.string().uuid("Invalid Account Group ID"),
  description: z.string().max(500).optional(),
});

export type CreateAccountInput = z.infer<typeof CreateAccountSchema>;

export const JournalLineSchema = z.object({
  accountId: z.string().uuid("Invalid Account ID"),
  type: z.enum([JOURNAL_LINE_TYPE.DEBIT, JOURNAL_LINE_TYPE.CREDIT]),
  amount: z.number().positive("Amount must be greater than 0"),
  narration: z.string().max(255).optional(),
});

export const CreateJournalEntrySchema = z.object({
  entryDate: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
  referenceType: z
    .enum([
      JOURNAL_REF_TYPE.SALES_INVOICE,
      JOURNAL_REF_TYPE.PURCHASE_INVOICE,
      JOURNAL_REF_TYPE.CUSTOMER_PAYMENT,
      JOURNAL_REF_TYPE.SUPPLIER_PAYMENT,
      JOURNAL_REF_TYPE.SALES_RETURN,
      JOURNAL_REF_TYPE.PURCHASE_RETURN,
      JOURNAL_REF_TYPE.EXPENSE,
      JOURNAL_REF_TYPE.MANUAL,
      JOURNAL_REF_TYPE.OPENING_BALANCE,
    ])
    .default(JOURNAL_REF_TYPE.MANUAL),
  referenceId: z.string().optional(),
  narration: z.string().trim().min(2, "Narration is required").max(500),
  lines: z
    .array(JournalLineSchema)
    .min(2, "A journal entry must contain at least 2 lines (debit and credit)"),
});

export type CreateJournalEntryInput = z.infer<typeof CreateJournalEntrySchema>;

export const CreateExpenseSchema = z.object({
  expenseDate: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
  accountId: z.string().uuid("Invalid Expense Account ID"),
  paidFromAccountId: z.string().uuid("Invalid Cash/Bank Account ID"),
  amount: z.number().positive("Expense amount must be greater than 0"),
  paymentMode: z
    .enum([PAYMENT_MODE.CASH, PAYMENT_MODE.BANK_TRANSFER, PAYMENT_MODE.UPI, PAYMENT_MODE.CHEQUE])
    .default(PAYMENT_MODE.CASH),
  referenceNumber: z.string().max(100).optional(),
  payee: z.string().max(150).optional(),
  description: z.string().trim().min(2, "Description is required").max(500),
});

export type CreateExpenseInput = z.infer<typeof CreateExpenseSchema>;

export const CustomerPaymentReceiptSchema = z.object({
  customerId: z.string().uuid("Invalid Customer ID"),
  amount: z.number().positive("Payment amount must be greater than 0"),
  paymentMode: z
    .enum([PAYMENT_MODE.CASH, PAYMENT_MODE.BANK_TRANSFER, PAYMENT_MODE.UPI, PAYMENT_MODE.CHEQUE])
    .default(PAYMENT_MODE.CASH),
  paidIntoAccountId: z.string().uuid().optional(),
  referenceNumber: z.string().max(100).optional(),
  notes: z.string().max(500).optional(),
});

export type CustomerPaymentReceiptInput = z.infer<typeof CustomerPaymentReceiptSchema>;

export const QueryAccountsSchema = z.object({
  type: z
    .enum([
      ACCOUNT_TYPE.ASSET,
      ACCOUNT_TYPE.LIABILITY,
      ACCOUNT_TYPE.EQUITY,
      ACCOUNT_TYPE.REVENUE,
      ACCOUNT_TYPE.EXPENSE,
    ])
    .optional(),
  groupId: z.string().uuid().optional(),
});

export type QueryAccountsInput = z.infer<typeof QueryAccountsSchema>;

export const QueryJournalsSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  referenceType: z.string().optional(),
  status: z.enum([JOURNAL_ENTRY_STATUS.DRAFT, JOURNAL_ENTRY_STATUS.POSTED, JOURNAL_ENTRY_STATUS.VOID]).optional(),
});

export type QueryJournalsInput = z.infer<typeof QueryJournalsSchema>;

export const QueryGeneralLedgerSchema = z.object({
  accountId: z.string().uuid("Invalid Account ID"),
  startDate: z.string().optional(),
  endDate: z.string().optional(),
});

export type QueryGeneralLedgerInput = z.infer<typeof QueryGeneralLedgerSchema>;

export const QueryDaybookSchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Date must be YYYY-MM-DD").optional(),
});

export type QueryDaybookInput = z.infer<typeof QueryDaybookSchema>;
