import { Decimal } from "@prisma/client/runtime/library";
import { prisma } from "../../infrastructure/database/prisma.client.js";
import { AppError } from "../../utils/errors.js";
import {
  ACCOUNT_TYPE,
  JOURNAL_ENTRY_STATUS,
  JOURNAL_LINE_TYPE,
  JOURNAL_REF_TYPE,
  PAYMENT_MODE,
} from "../../config/constants.js";
import type {
  CreateAccountInput,
  CreateJournalEntryInput,
  CreateExpenseInput,
  CustomerPaymentReceiptInput,
  QueryAccountsInput,
  QueryJournalsInput,
} from "./accounting.schema.js";

export class AccountingService {
  /**
   * Seed Standard Pharmacy Chart of Accounts (COA) for a shop
   */
  async seedStandardChartOfAccounts(shopId: string) {
    const existingGroup = await prisma.accountGroup.findFirst({ where: { shopId } });
    if (existingGroup) {
      return { seeded: false, message: "Chart of Accounts is already initialized for your store" };
    }

    await prisma.$transaction(async (tx: any) => {
      // 1. Create Groups
      const assetGroup = await tx.accountGroup.create({
        data: {
          shopId,
          code: "ASSETS",
          name: "Assets",
          type: ACCOUNT_TYPE.ASSET,
          description: "Economic resources owned by pharmacy",
        },
      });

      const liabGroup = await tx.accountGroup.create({
        data: {
          shopId,
          code: "LIABILITIES",
          name: "Liabilities",
          type: ACCOUNT_TYPE.LIABILITY,
          description: "Debts and financial obligations",
        },
      });

      const equityGroup = await tx.accountGroup.create({
        data: {
          shopId,
          code: "EQUITY",
          name: "Equity",
          type: ACCOUNT_TYPE.EQUITY,
          description: "Owner capital and retained earnings",
        },
      });

      const revGroup = await tx.accountGroup.create({
        data: {
          shopId,
          code: "REVENUE",
          name: "Revenue",
          type: ACCOUNT_TYPE.REVENUE,
          description: "Income generated from pharmacy operations",
        },
      });

      const expGroup = await tx.accountGroup.create({
        data: {
          shopId,
          code: "EXPENSES",
          name: "Expenses",
          type: ACCOUNT_TYPE.EXPENSE,
          description: "Costs incurred to run pharmacy operations",
        },
      });

      // 2. Create 24 Standard Accounts
      const accounts = [
        // Assets (1000)
        { shopId, code: "1010", name: "Cash on Hand (Drawer)", type: ACCOUNT_TYPE.ASSET, groupId: assetGroup.id, isSystem: true },
        { shopId, code: "1020", name: "Bank Current Account", type: ACCOUNT_TYPE.ASSET, groupId: assetGroup.id, isSystem: true },
        { shopId, code: "1030", name: "Accounts Receivable (Customer Debt)", type: ACCOUNT_TYPE.ASSET, groupId: assetGroup.id, isSystem: true },
        { shopId, code: "1040", name: "Pharmacy Medicine Inventory", type: ACCOUNT_TYPE.ASSET, groupId: assetGroup.id, isSystem: true },
        { shopId, code: "1050", name: "Undeposited Funds (UPI/Card Clearing)", type: ACCOUNT_TYPE.ASSET, groupId: assetGroup.id, isSystem: false },
        { shopId, code: "1060", name: "Store Equipment & Refrigeration", type: ACCOUNT_TYPE.ASSET, groupId: assetGroup.id, isSystem: false },

        // Liabilities (2000)
        { shopId, code: "2010", name: "Accounts Payable (Supplier Debt)", type: ACCOUNT_TYPE.LIABILITY, groupId: liabGroup.id, isSystem: true },
        { shopId, code: "2020", name: "GST Output CGST Payable", type: ACCOUNT_TYPE.LIABILITY, groupId: liabGroup.id, isSystem: true },
        { shopId, code: "2030", name: "GST Output SGST Payable", type: ACCOUNT_TYPE.LIABILITY, groupId: liabGroup.id, isSystem: true },
        { shopId, code: "2040", name: "GST Output IGST Payable", type: ACCOUNT_TYPE.LIABILITY, groupId: liabGroup.id, isSystem: true },
        { shopId, code: "2050", name: "Accrued Expenses & Utilities", type: ACCOUNT_TYPE.LIABILITY, groupId: liabGroup.id, isSystem: false },

        // Equity (3000)
        { shopId, code: "3010", name: "Owner Capital / Investment", type: ACCOUNT_TYPE.EQUITY, groupId: equityGroup.id, isSystem: true },
        { shopId, code: "3020", name: "Owner Drawings", type: ACCOUNT_TYPE.EQUITY, groupId: equityGroup.id, isSystem: false },
        { shopId, code: "3030", name: "Retained Earnings", type: ACCOUNT_TYPE.EQUITY, groupId: equityGroup.id, isSystem: true },

        // Revenue (4000)
        { shopId, code: "4010", name: "Pharmacy Sales Revenue", type: ACCOUNT_TYPE.REVENUE, groupId: revGroup.id, isSystem: true },
        { shopId, code: "4020", name: "Other Operating Income", type: ACCOUNT_TYPE.REVENUE, groupId: revGroup.id, isSystem: false },
        { shopId, code: "4030", name: "Sales Discounts Allowed (Contra)", type: ACCOUNT_TYPE.REVENUE, groupId: revGroup.id, isSystem: false },

        // Expenses (5000)
        { shopId, code: "5010", name: "Cost of Goods Sold (COGS)", type: ACCOUNT_TYPE.EXPENSE, groupId: expGroup.id, isSystem: true },
        { shopId, code: "5020", name: "Store Rent Expense", type: ACCOUNT_TYPE.EXPENSE, groupId: expGroup.id, isSystem: false },
        { shopId, code: "5030", name: "Electricity & Utilities Expense", type: ACCOUNT_TYPE.EXPENSE, groupId: expGroup.id, isSystem: false },
        { shopId, code: "5040", name: "Staff Salaries & Wages", type: ACCOUNT_TYPE.EXPENSE, groupId: expGroup.id, isSystem: false },
        { shopId, code: "5050", name: "Packaging & Store Supplies", type: ACCOUNT_TYPE.EXPENSE, groupId: expGroup.id, isSystem: false },
        { shopId, code: "5060", name: "Damaged & Expired Stock Loss", type: ACCOUNT_TYPE.EXPENSE, groupId: expGroup.id, isSystem: true },
        { shopId, code: "5070", name: "General & Miscellaneous Expenses", type: ACCOUNT_TYPE.EXPENSE, groupId: expGroup.id, isSystem: false },
      ];

      for (const acc of accounts) {
        await tx.account.create({ data: acc });
      }
    });

    return { seeded: true, message: "Standard Chart of Accounts seeded successfully" };
  }

  /**
   * Helper: Generate Sequential Journal Entry Number
   */
  private async getNextJournalNumber(tx: any, shopId: string): Promise<string> {
    const year = new Date().getFullYear();
    const prefix = `JE-${year}-`;
    const count = await tx.journalEntry.count({
      where: {
        shopId,
        entryNumber: { startsWith: prefix },
      },
    });
    const nextSeq = (count + 1).toString().padStart(5, "0");
    return `${prefix}${nextSeq}`;
  }

  /**
   * Helper: Generate Sequential Expense Number
   */
  private async getNextExpenseNumber(tx: any, shopId: string): Promise<string> {
    const year = new Date().getFullYear();
    const prefix = `EXP-${year}-`;
    const count = await tx.expense.count({
      where: {
        shopId,
        expenseNumber: { startsWith: prefix },
      },
    });
    const nextSeq = (count + 1).toString().padStart(5, "0");
    return `${prefix}${nextSeq}`;
  }

  /**
   * List All Accounts in Chart of Accounts (Scoped to shop)
   */
  async listAccounts(shopId: string, filter: QueryAccountsInput) {
    const where: Record<string, unknown> = { shopId };
    if (filter.type) where.type = filter.type;
    if (filter.groupId) where.groupId = filter.groupId;

    const accounts = await prisma.account.findMany({
      where,
      orderBy: { code: "asc" },
      include: {
        group: { select: { id: true, name: true, code: true, type: true } },
      },
    });

    return accounts;
  }

  /**
   * Create a Custom Account in Chart of Accounts (Scoped to shop)
   */
  async createAccount(shopId: string, data: CreateAccountInput) {
    const existing = await prisma.account.findUnique({
      where: { shopId_code: { shopId, code: data.code } },
    });
    if (existing) {
      throw AppError.conflict(`Account with code ${data.code} already exists in your store`);
    }

    const group = await prisma.accountGroup.findFirst({
      where: { id: data.groupId, shopId },
    });
    if (!group) throw AppError.notFound("Account group not found in your store");

    const account = await prisma.account.create({
      data: {
        shopId,
        code: data.code,
        name: data.name,
        type: data.type,
        groupId: data.groupId,
        description: data.description,
        isSystem: false,
      },
      include: {
        group: true,
      },
    });

    return account;
  }

  /**
   * Post Double-Entry Journal Entry (Scoped to shop)
   */
  async createJournalEntry(shopId: string, data: CreateJournalEntryInput, userId?: string) {
    let totalDebit = 0;
    let totalCredit = 0;

    for (const line of data.lines) {
      if (line.type === JOURNAL_LINE_TYPE.DEBIT) {
        totalDebit += Number(line.amount);
      } else if (line.type === JOURNAL_LINE_TYPE.CREDIT) {
        totalCredit += Number(line.amount);
      }
    }

    const diff = Math.abs(totalDebit - totalCredit);
    if (diff > 0.01) {
      throw AppError.badRequest(
        `Journal entry is unbalanced. Total Debit (${totalDebit.toFixed(2)}) must equal Total Credit (${totalCredit.toFixed(2)}).`
      );
    }

    const accountIds = Array.from(new Set(data.lines.map((l) => l.accountId)));
    const accounts = await prisma.account.findMany({
      where: { id: { in: accountIds }, shopId },
    });

    if (accounts.length !== accountIds.length) {
      throw AppError.notFound("One or more referenced accounts do not exist in your store");
    }

    const accountMap = new Map<string, (typeof accounts)[0]>();
    for (const acc of accounts) {
      accountMap.set(acc.id, acc);
    }

    const result = await prisma.$transaction(async (tx: any) => {
      const entryNumber = await this.getNextJournalNumber(tx, shopId);
      const entryDate = data.entryDate ? new Date(data.entryDate) : new Date();

      const journalEntry = await tx.journalEntry.create({
        data: {
          shopId,
          entryNumber,
          entryDate,
          referenceType: data.referenceType,
          referenceId: data.referenceId,
          narration: data.narration,
          status: JOURNAL_ENTRY_STATUS.POSTED,
          totalDebit: new Decimal(totalDebit),
          totalCredit: new Decimal(totalCredit),
          createdById: userId,
          lines: {
            create: data.lines.map((line) => ({
              accountId: line.accountId,
              type: line.type,
              amount: new Decimal(line.amount),
              narration: line.narration,
            })),
          },
        },
        include: {
          lines: {
            include: {
              account: { select: { id: true, code: true, name: true, type: true } },
            },
          },
        },
      });

      for (const line of data.lines) {
        const acc = accountMap.get(line.accountId);
        if (!acc) continue;

        let delta = 0;
        if (acc.type === ACCOUNT_TYPE.ASSET || acc.type === ACCOUNT_TYPE.EXPENSE) {
          delta = line.type === JOURNAL_LINE_TYPE.DEBIT ? line.amount : -line.amount;
        } else {
          delta = line.type === JOURNAL_LINE_TYPE.CREDIT ? line.amount : -line.amount;
        }

        await tx.account.update({
          where: { id: line.accountId },
          data: {
            currentBalance: { increment: delta },
          },
        });
      }

      return journalEntry;
    });

    return result;
  }

  /**
   * List Journal Entries (Scoped to shop)
   */
  async listJournalEntries(shopId: string, filter: QueryJournalsInput) {
    const skip = (filter.page - 1) * filter.limit;
    const where: Record<string, unknown> = { shopId };

    if (filter.status) where.status = filter.status;
    if (filter.referenceType) where.referenceType = filter.referenceType;
    if (filter.startDate || filter.endDate) {
      where.entryDate = {
        ...(filter.startDate ? { gte: new Date(filter.startDate) } : {}),
        ...(filter.endDate ? { lte: new Date(filter.endDate) } : {}),
      };
    }

    const [items, total] = await Promise.all([
      prisma.journalEntry.findMany({
        where,
        skip,
        take: filter.limit,
        orderBy: { entryDate: "desc" },
        include: {
          lines: {
            include: {
              account: { select: { id: true, code: true, name: true, type: true } },
            },
          },
        },
      }),
      prisma.journalEntry.count({ where }),
    ]);

    return {
      items,
      pagination: {
        total,
        page: filter.page,
        limit: filter.limit,
        totalPages: Math.ceil(total / filter.limit),
      },
    };
  }

  /**
   * General Ledger: Account Statement & Running Balance (Scoped to shop)
   */
  async getGeneralLedger(shopId: string, accountId: string, startDate?: string, endDate?: string) {
    const account = await prisma.account.findFirst({
      where: { id: accountId, shopId },
      include: { group: true },
    });
    if (!account) throw AppError.notFound("Account not found in your store");

    const lineWhere: Record<string, unknown> = {
      accountId,
      journalEntry: {
        shopId,
        status: JOURNAL_ENTRY_STATUS.POSTED,
        ...(startDate || endDate
          ? {
              entryDate: {
                ...(startDate ? { gte: new Date(startDate) } : {}),
                ...(endDate ? { lte: new Date(endDate) } : {}),
              },
            }
          : {}),
      },
    };

    const lines = await prisma.journalLine.findMany({
      where: lineWhere,
      orderBy: { journalEntry: { entryDate: "asc" } },
      include: {
        journalEntry: {
          select: { id: true, entryNumber: true, entryDate: true, referenceType: true, narration: true },
        },
      },
    });

    let runningBalance = 0;
    const isNormalDebit = account.type === ACCOUNT_TYPE.ASSET || account.type === ACCOUNT_TYPE.EXPENSE;

    const statement = lines.map((l: any) => {
      const amt = Number(l.amount);
      if (isNormalDebit) {
        runningBalance += l.type === JOURNAL_LINE_TYPE.DEBIT ? amt : -amt;
      } else {
        runningBalance += l.type === JOURNAL_LINE_TYPE.CREDIT ? amt : -amt;
      }

      return {
        id: l.id,
        date: l.journalEntry.entryDate,
        entryNumber: l.journalEntry.entryNumber,
        referenceType: l.journalEntry.referenceType,
        narration: l.narration || l.journalEntry.narration,
        debit: l.type === JOURNAL_LINE_TYPE.DEBIT ? amt : 0,
        credit: l.type === JOURNAL_LINE_TYPE.CREDIT ? amt : 0,
        balance: Number(runningBalance.toFixed(2)),
      };
    });

    return {
      account: {
        id: account.id,
        code: account.code,
        name: account.name,
        type: account.type,
        currentBalance: Number(account.currentBalance),
      },
      transactions: statement,
    };
  }

  /**
   * Trial Balance Report (Scoped to shop)
   */
  async getTrialBalance(shopId: string, _asOfDate?: string) {
    const accounts = await prisma.account.findMany({
      where: { shopId },
      include: { group: true },
      orderBy: { code: "asc" },
    });

    let totalDebit = 0;
    let totalCredit = 0;

    const rows = accounts.map((acc) => {
      const bal = Number(acc.currentBalance);
      let debit = 0;
      let credit = 0;

      if (acc.type === ACCOUNT_TYPE.ASSET || acc.type === ACCOUNT_TYPE.EXPENSE) {
        if (bal >= 0) debit = bal;
        else credit = Math.abs(bal);
      } else {
        if (bal >= 0) credit = bal;
        else debit = Math.abs(bal);
      }

      totalDebit += debit;
      totalCredit += credit;

      return {
        id: acc.id,
        code: acc.code,
        name: acc.name,
        type: acc.type,
        group: acc.group.name,
        debit: Number(debit.toFixed(2)),
        credit: Number(credit.toFixed(2)),
      };
    });

    const diff = Math.abs(totalDebit - totalCredit);
    const isBalanced = diff < 0.01;

    return {
      accounts: rows,
      totalDebit: Number(totalDebit.toFixed(2)),
      totalCredit: Number(totalCredit.toFixed(2)),
      difference: Number(diff.toFixed(2)),
      isBalanced,
    };
  }

  /**
   * Record Store Operating Expense (Scoped to shop)
   */
  async createExpense(shopId: string, data: CreateExpenseInput, userId?: string) {
    const expenseAccount = await prisma.account.findFirst({ where: { id: data.accountId, shopId } });
    if (!expenseAccount) throw AppError.notFound("Expense account not found in your store");
    if (expenseAccount.type !== ACCOUNT_TYPE.EXPENSE) {
      throw AppError.badRequest("Selected account is not an Expense account");
    }

    const paidFromAccount = await prisma.account.findFirst({ where: { id: data.paidFromAccountId, shopId } });
    if (!paidFromAccount) throw AppError.notFound("Payment source account not found in your store");
    if (paidFromAccount.type !== ACCOUNT_TYPE.ASSET) {
      throw AppError.badRequest("Payment source must be an Asset account (Cash or Bank)");
    }

    const expenseDate = data.expenseDate ? new Date(data.expenseDate) : new Date();

    const expense = await prisma.$transaction(async (tx: any) => {
      const expenseNumber = await this.getNextExpenseNumber(tx, shopId);
      const journalNumber = await this.getNextJournalNumber(tx, shopId);

      // 1. Post Automated Journal Entry: DR Expense, CR Cash/Bank
      const journalEntry = await tx.journalEntry.create({
        data: {
          shopId,
          entryNumber: journalNumber,
          entryDate: expenseDate,
          referenceType: JOURNAL_REF_TYPE.EXPENSE,
          narration: `Expense: ${data.description} (Payee: ${data.payee || "N/A"})`,
          status: JOURNAL_ENTRY_STATUS.POSTED,
          totalDebit: new Decimal(data.amount),
          totalCredit: new Decimal(data.amount),
          createdById: userId,
          lines: {
            create: [
              {
                accountId: data.accountId,
                type: JOURNAL_LINE_TYPE.DEBIT,
                amount: new Decimal(data.amount),
                narration: data.description,
              },
              {
                accountId: data.paidFromAccountId,
                type: JOURNAL_LINE_TYPE.CREDIT,
                amount: new Decimal(data.amount),
                narration: `Payment for ${data.description}`,
              },
            ],
          },
        },
      });

      // 2. Update Account Balances
      await tx.account.update({
        where: { id: data.accountId },
        data: { currentBalance: { increment: data.amount } },
      });
      await tx.account.update({
        where: { id: data.paidFromAccountId },
        data: { currentBalance: { decrement: data.amount } },
      });

      // 3. Create Expense Record
      const newExpense = await tx.expense.create({
        data: {
          shopId,
          expenseNumber,
          expenseDate,
          accountId: data.accountId,
          paidFromAccountId: data.paidFromAccountId,
          amount: new Decimal(data.amount),
          paymentMode: data.paymentMode,
          referenceNumber: data.referenceNumber,
          payee: data.payee,
          description: data.description,
          journalEntryId: journalEntry.id,
          createdById: userId,
        },
        include: {
          account: { select: { id: true, code: true, name: true } },
          paidFromAccount: { select: { id: true, code: true, name: true } },
          journalEntry: { select: { id: true, entryNumber: true } },
        },
      });

      return newExpense;
    });

    return expense;
  }

  /**
   * List Operating Expenses (Scoped to shop)
   */
  async listExpenses(shopId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      prisma.expense.findMany({
        where: { shopId },
        skip,
        take: limit,
        orderBy: { expenseDate: "desc" },
        include: {
          account: { select: { id: true, code: true, name: true } },
          paidFromAccount: { select: { id: true, code: true, name: true } },
        },
      }),
      prisma.expense.count({ where: { shopId } }),
    ]);

    return {
      items,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Accounts Receivable (AR) Aging Report (Scoped to shop)
   */
  async getCustomerReceivablesAging(shopId: string) {
    const customers = await prisma.customer.findMany({
      where: {
        shopId,
        currentBalance: { gt: 0 },
      },
      select: {
        id: true,
        name: true,
        mobile: true,
        currentBalance: true,
        creditLimit: true,
      },
    });

    const now = new Date();
    const result: any[] = [];
    let grandTotal = 0;
    const bucketTotals = { current0To30: 0, days31To60: 0, days61To90: 0, over90Days: 0 };

    for (const cust of customers) {
      const invoices = await prisma.salesInvoice.findMany({
        where: {
          shopId,
          customerId: cust.id,
          paymentStatus: { in: ["UNPAID", "PARTIALLY_PAID"] },
        },
        select: {
          id: true,
          invoiceNumber: true,
          invoiceDate: true,
          totalAmount: true,
          paidAmount: true,
          balanceAmount: true,
        },
      });

      let c0To30 = 0;
      let d31To60 = 0;
      let d61To90 = 0;
      let over90 = 0;

      for (const inv of invoices) {
        const balance = Number(inv.balanceAmount);
        const ageDays = Math.floor((now.getTime() - new Date(inv.invoiceDate).getTime()) / (1000 * 60 * 60 * 24));

        if (ageDays <= 30) c0To30 += balance;
        else if (ageDays <= 60) d31To60 += balance;
        else if (ageDays <= 90) d61To90 += balance;
        else over90 += balance;
      }

      const totalDebt = Number(cust.currentBalance);
      grandTotal += totalDebt;
      bucketTotals.current0To30 += c0To30;
      bucketTotals.days31To60 += d31To60;
      bucketTotals.days61To90 += d61To90;
      bucketTotals.over90Days += over90;

      result.push({
        customer: cust,
        totalOutstanding: totalDebt,
        buckets: {
          current0To30: Number(c0To30.toFixed(2)),
          days31To60: Number(d31To60.toFixed(2)),
          days61To90: Number(d61To90.toFixed(2)),
          over90Days: Number(over90.toFixed(2)),
        },
      });
    }

    return {
      summary: {
        totalReceivables: Number(grandTotal.toFixed(2)),
        buckets: {
          current0To30: Number(bucketTotals.current0To30.toFixed(2)),
          days31To60: Number(bucketTotals.days31To60.toFixed(2)),
          days61To90: Number(bucketTotals.days61To90.toFixed(2)),
          over90Days: Number(bucketTotals.over90Days.toFixed(2)),
        },
      },
      customers: result,
    };
  }

  /**
   * Accounts Payable (AP) Aging Report (Scoped to shop)
   */
  async getSupplierPayablesAging(shopId: string) {
    const suppliers = await prisma.supplier.findMany({
      where: {
        shopId,
        outstandingBalance: { gt: 0 },
      },
      select: {
        id: true,
        name: true,
        contactPerson: true,
        mobile: true,
        paymentTermsDays: true,
        outstandingBalance: true,
      },
    });

    const now = new Date();
    const result: any[] = [];
    let grandTotal = 0;
    const bucketTotals = { current0To30: 0, days31To60: 0, days61To90: 0, over90Days: 0 };

    for (const supp of suppliers) {
      const invoices = await prisma.purchaseInvoice.findMany({
        where: {
          shopId,
          supplierId: supp.id,
          paymentStatus: { in: ["UNPAID", "PARTIALLY_PAID"] },
        },
        select: {
          id: true,
          invoiceNumber: true,
          invoiceDate: true,
          totalAmount: true,
          paidAmount: true,
          balanceAmount: true,
        },
      });

      let c0To30 = 0;
      let d31To60 = 0;
      let d61To90 = 0;
      let over90 = 0;

      for (const inv of invoices) {
        const balance = Number(inv.balanceAmount);
        const ageDays = Math.floor((now.getTime() - new Date(inv.invoiceDate).getTime()) / (1000 * 60 * 60 * 24));

        if (ageDays <= 30) c0To30 += balance;
        else if (ageDays <= 60) d31To60 += balance;
        else if (ageDays <= 90) d61To90 += balance;
        else over90 += balance;
      }

      const totalDebt = Number(supp.outstandingBalance);
      grandTotal += totalDebt;
      bucketTotals.current0To30 += c0To30;
      bucketTotals.days31To60 += d31To60;
      bucketTotals.days61To90 += d61To90;
      bucketTotals.over90Days += over90;

      result.push({
        supplier: supp,
        totalOutstanding: totalDebt,
        buckets: {
          current0To30: Number(c0To30.toFixed(2)),
          days31To60: Number(d31To60.toFixed(2)),
          days61To90: Number(d61To90.toFixed(2)),
          over90Days: Number(over90.toFixed(2)),
        },
      });
    }

    return {
      summary: {
        totalPayables: Number(grandTotal.toFixed(2)),
        buckets: {
          current0To30: Number(bucketTotals.current0To30.toFixed(2)),
          days31To60: Number(bucketTotals.days31To60.toFixed(2)),
          days61To90: Number(bucketTotals.days61To90.toFixed(2)),
          over90Days: Number(bucketTotals.over90Days.toFixed(2)),
        },
      },
      suppliers: result,
    };
  }

  /**
   * Record Customer Debt Settlement / Payment Receipt (Scoped to shop)
   */
  async recordCustomerPayment(shopId: string, data: CustomerPaymentReceiptInput, userId?: string) {
    const customer = await prisma.customer.findFirst({
      where: { id: data.customerId, shopId },
    });
    if (!customer) throw AppError.notFound("Customer not found in your store");

    if (Number(customer.currentBalance) <= 0) {
      throw AppError.badRequest("Customer does not have any outstanding debt");
    }

    if (data.amount > Number(customer.currentBalance)) {
      throw AppError.badRequest(
        `Payment amount (₹${data.amount}) cannot exceed current outstanding debt (₹${customer.currentBalance})`
      );
    }

    const targetAccountCode = data.paymentMode === PAYMENT_MODE.CASH ? "1010" : "1020";
    let depositAccount = await prisma.account.findUnique({
      where: { shopId_code: { shopId, code: targetAccountCode } },
    });
    if (!depositAccount && data.paidIntoAccountId) {
      depositAccount = await prisma.account.findFirst({ where: { id: data.paidIntoAccountId, shopId } });
    }
    if (!depositAccount) throw AppError.notFound(`Deposit account (${targetAccountCode}) not found in your store`);

    let arAccount = await prisma.account.findUnique({
      where: { shopId_code: { shopId, code: "1030" } },
    });
    if (!arAccount) {
      // Auto fallback to any asset account if 1030 not created yet
      arAccount = depositAccount;
    }

    const result = await prisma.$transaction(async (tx: any) => {
      const journalNumber = await this.getNextJournalNumber(tx, shopId);

      const journal = await tx.journalEntry.create({
        data: {
          shopId,
          entryNumber: journalNumber,
          entryDate: new Date(),
          referenceType: JOURNAL_REF_TYPE.CUSTOMER_PAYMENT,
          referenceId: customer.id,
          narration: `Customer payment received from ${customer.name} via ${data.paymentMode}. Ref: ${data.referenceNumber || "N/A"}`,
          status: JOURNAL_ENTRY_STATUS.POSTED,
          totalDebit: new Decimal(data.amount),
          totalCredit: new Decimal(data.amount),
          createdById: userId,
          lines: {
            create: [
              {
                accountId: depositAccount.id,
                type: JOURNAL_LINE_TYPE.DEBIT,
                amount: new Decimal(data.amount),
                narration: `Receipt via ${data.paymentMode}`,
              },
              {
                accountId: arAccount.id,
                type: JOURNAL_LINE_TYPE.CREDIT,
                amount: new Decimal(data.amount),
                narration: `Customer debt clearance: ${customer.name}`,
              },
            ],
          },
        },
      });

      await tx.account.update({
        where: { id: depositAccount.id },
        data: { currentBalance: { increment: data.amount } },
      });
      await tx.account.update({
        where: { id: arAccount.id },
        data: { currentBalance: { decrement: data.amount } },
      });

      const updatedCustomer = await tx.customer.update({
        where: { id: customer.id },
        data: {
          currentBalance: { decrement: data.amount },
        },
      });

      const unpaidInvoices = await tx.salesInvoice.findMany({
        where: {
          shopId,
          customerId: customer.id,
          paymentStatus: { in: ["UNPAID", "PARTIALLY_PAID"] },
        },
        orderBy: { invoiceDate: "asc" },
      });

      let remainingPayment = data.amount;
      for (const inv of unpaidInvoices) {
        if (remainingPayment <= 0) break;
        const unpaidAmount = Number(inv.totalAmount) - Number(inv.paidAmount);
        const allocation = Math.min(unpaidAmount, remainingPayment);

        const newPaid = Number(inv.paidAmount) + allocation;
        const newStatus = newPaid >= Number(inv.totalAmount) ? "PAID" : "PARTIALLY_PAID";

        await tx.salesInvoice.update({
          where: { id: inv.id },
          data: {
            paidAmount: new Decimal(newPaid),
            balanceAmount: new Decimal(Math.max(0, Number(inv.totalAmount) - newPaid)),
            paymentStatus: newStatus,
          },
        });

        remainingPayment -= allocation;
      }

      return {
        customer: updatedCustomer,
        journalEntry: journal,
      };
    });

    return result;
  }

  /**
   * Cash & Bank Daybook: Real-time cash drawer & bank movement reconciliation (Scoped to shop)
   */
  async getDaybook(shopId: string, dateStr?: string) {
    const targetDate = dateStr ? new Date(dateStr) : new Date();
    const startOfDay = new Date(targetDate);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(targetDate);
    endOfDay.setHours(23, 59, 59, 999);

    const cashAccount = await prisma.account.findUnique({
      where: { shopId_code: { shopId, code: "1010" } },
    });
    const bankAccount = await prisma.account.findUnique({
      where: { shopId_code: { shopId, code: "1020" } },
    });

    if (!cashAccount || !bankAccount) {
      return {
        date: startOfDay.toISOString().split("T")[0],
        cash: { openingBalance: 0, totalIn: 0, totalOut: 0, netMovement: 0, closingBalance: 0, transactions: [] },
        bank: { openingBalance: 0, totalIn: 0, totalOut: 0, netMovement: 0, closingBalance: 0, transactions: [] },
      };
    }

    const cashLines = await prisma.journalLine.findMany({
      where: {
        accountId: cashAccount.id,
        journalEntry: {
          shopId,
          status: JOURNAL_ENTRY_STATUS.POSTED,
          entryDate: { gte: startOfDay, lte: endOfDay },
        },
      },
      include: {
        journalEntry: {
          select: { id: true, entryNumber: true, referenceType: true, narration: true, entryDate: true },
        },
      },
    });

    const bankLines = await prisma.journalLine.findMany({
      where: {
        accountId: bankAccount.id,
        journalEntry: {
          shopId,
          status: JOURNAL_ENTRY_STATUS.POSTED,
          entryDate: { gte: startOfDay, lte: endOfDay },
        },
      },
      include: {
        journalEntry: {
          select: { id: true, entryNumber: true, referenceType: true, narration: true, entryDate: true },
        },
      },
    });

    let totalCashIn = 0;
    let totalCashOut = 0;
    for (const l of cashLines) {
      if (l.type === JOURNAL_LINE_TYPE.DEBIT) totalCashIn += Number(l.amount);
      else totalCashOut += Number(l.amount);
    }

    let totalBankIn = 0;
    let totalBankOut = 0;
    for (const l of bankLines) {
      if (l.type === JOURNAL_LINE_TYPE.DEBIT) totalBankIn += Number(l.amount);
      else totalBankOut += Number(l.amount);
    }

    const priorCashLines = await prisma.journalLine.findMany({
      where: {
        accountId: cashAccount.id,
        journalEntry: {
          shopId,
          status: JOURNAL_ENTRY_STATUS.POSTED,
          entryDate: { lt: startOfDay },
        },
      },
      select: { type: true, amount: true },
    });

    let openingCash = 0;
    for (const l of priorCashLines) {
      openingCash += l.type === JOURNAL_LINE_TYPE.DEBIT ? Number(l.amount) : -Number(l.amount);
    }

    const priorBankLines = await prisma.journalLine.findMany({
      where: {
        accountId: bankAccount.id,
        journalEntry: {
          shopId,
          status: JOURNAL_ENTRY_STATUS.POSTED,
          entryDate: { lt: startOfDay },
        },
      },
      select: { type: true, amount: true },
    });

    let openingBank = 0;
    for (const l of priorBankLines) {
      openingBank += l.type === JOURNAL_LINE_TYPE.DEBIT ? Number(l.amount) : -Number(l.amount);
    }

    const closingCash = openingCash + totalCashIn - totalCashOut;
    const closingBank = openingBank + totalBankIn - totalBankOut;

    return {
      date: startOfDay.toISOString().split("T")[0],
      cash: {
        openingBalance: Number(openingCash.toFixed(2)),
        totalIn: Number(totalCashIn.toFixed(2)),
        totalOut: Number(totalCashOut.toFixed(2)),
        netMovement: Number((totalCashIn - totalCashOut).toFixed(2)),
        closingBalance: Number(closingCash.toFixed(2)),
        transactions: cashLines.map((l: any) => ({
          entryNumber: l.journalEntry.entryNumber,
          narration: l.narration || l.journalEntry.narration,
          type: l.type,
          amount: Number(l.amount),
        })),
      },
      bank: {
        openingBalance: Number(openingBank.toFixed(2)),
        totalIn: Number(totalBankIn.toFixed(2)),
        totalOut: Number(totalBankOut.toFixed(2)),
        netMovement: Number((totalBankIn - totalBankOut).toFixed(2)),
        closingBalance: Number(closingBank.toFixed(2)),
        transactions: bankLines.map((l: any) => ({
          entryNumber: l.journalEntry.entryNumber,
          narration: l.narration || l.journalEntry.narration,
          type: l.type,
          amount: Number(l.amount),
        })),
      },
    };
  }
}

export const accountingService = new AccountingService();
