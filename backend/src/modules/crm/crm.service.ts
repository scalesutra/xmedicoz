import { Decimal } from "@prisma/client/runtime/library";
import { prisma } from "../../infrastructure/database/prisma.client.js";
import { AppError } from "../../utils/errors.js";
import {
  REFILL_STATUS,
  NOTIFICATION_CHANNEL,
  NOTIFICATION_STATUS,
  FOLLOW_UP_STATUS,
} from "../../config/constants.js";
import type {
  CreateRefillRuleInput,
  UpdateRefillRuleInput,
  TriggerReminderInput,
  CreateFollowUpInput,
  UpdateFollowUpInput,
  QueryRefillRulesInput,
} from "./crm.schema.js";

export class CrmService {
  /**
   * Get Customer Medicine Purchase History (Scoped to shop)
   */
  async getCustomerPurchaseHistory(shopId: string, customerId: string) {
    const invoices = await prisma.salesInvoice.findMany({
      where: { customerId, shopId, status: "COMPLETED" },
      orderBy: { invoiceDate: "desc" },
      include: {
        items: {
          include: {
            medicine: { select: { id: true, name: true, genericName: true, dosageForm: true } },
            batch: { select: { id: true, batchNumber: true } },
          },
        },
      },
    });

    return invoices;
  }
  /**
   * Create an Automated Refill Rule for a Customer's Chronic Medicine (Scoped to shop)
   */
  async createRefillRule(shopId: string, data: CreateRefillRuleInput, userId?: string) {
    const customer = await prisma.customer.findFirst({
      where: { id: data.customerId, shopId },
    });
    if (!customer) throw AppError.notFound("Customer not found in your store");

    const medicine = await prisma.medicine.findFirst({
      where: { id: data.medicineId, shopId },
    });
    if (!medicine) throw AppError.notFound("Medicine not found in your store");

    const lastPurchaseDate = data.lastPurchaseDate
      ? new Date(data.lastPurchaseDate)
      : new Date();

    const daysCoverage = Math.floor(data.daysSupply / (data.dailyDosage || 1));
    const expectedRefillDate = new Date(lastPurchaseDate);
    expectedRefillDate.setDate(expectedRefillDate.getDate() + daysCoverage);

    const rule = await prisma.customerRefillRule.create({
      data: {
        shopId,
        customerId: data.customerId,
        medicineId: data.medicineId,
        dailyDosage: new Decimal(data.dailyDosage),
        daysSupply: data.daysSupply,
        lastPurchaseDate,
        expectedRefillDate,
        status: REFILL_STATUS.ACTIVE,
        notes: data.notes,
        createdById: userId,
      },
      include: {
        customer: { select: { id: true, name: true, mobile: true } },
        medicine: { select: { id: true, name: true, genericName: true } },
      },
    });

    return rule;
  }

  /**
   * Update an Existing Refill Rule (Scoped to shop)
   */
  async updateRefillRule(shopId: string, id: string, data: UpdateRefillRuleInput) {
    const existing = await prisma.customerRefillRule.findFirst({ where: { id, shopId } });
    if (!existing) throw AppError.notFound("Refill rule not found in your store");

    const updateData: Record<string, unknown> = {};
    if (data.status) updateData.status = data.status;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.dailyDosage) updateData.dailyDosage = new Decimal(data.dailyDosage);
    if (data.daysSupply) updateData.daysSupply = data.daysSupply;

    if (data.dailyDosage || data.daysSupply) {
      const dosage = data.dailyDosage || Number(existing.dailyDosage);
      const supply = data.daysSupply || existing.daysSupply;
      const days = Math.floor(supply / (dosage || 1));
      const expected = new Date(existing.lastPurchaseDate);
      expected.setDate(expected.getDate() + days);
      updateData.expectedRefillDate = expected;
    }

    const updated = await prisma.customerRefillRule.update({
      where: { id },
      data: updateData,
      include: {
        customer: { select: { id: true, name: true, mobile: true } },
        medicine: { select: { id: true, name: true, genericName: true } },
      },
    });

    return updated;
  }

  /**
   * List Refill Rules with Filters & Pagination (Scoped to shop)
   */
  async listRefillRules(shopId: string, query: QueryRefillRulesInput) {
    const { customerId, status, page, limit } = query;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { shopId };
    if (customerId) where.customerId = customerId;
    if (status) where.status = status;

    const [items, total] = await Promise.all([
      prisma.customerRefillRule.findMany({
        where,
        skip,
        take: limit,
        orderBy: { expectedRefillDate: "asc" },
        include: {
          customer: { select: { id: true, name: true, mobile: true, notificationOptOut: true } },
          medicine: { select: { id: true, name: true, genericName: true } },
        },
      }),
      prisma.customerRefillRule.count({ where }),
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
   * List Upcoming Due Refills (Scoped to shop)
   */
  async listDueRefills(shopId: string, daysAhead = 7) {
    const targetDate = new Date();
    targetDate.setDate(targetDate.getDate() + daysAhead);

    const rules = await prisma.customerRefillRule.findMany({
      where: {
        shopId,
        status: REFILL_STATUS.ACTIVE,
        expectedRefillDate: {
          lte: targetDate,
        },
      },
      orderBy: { expectedRefillDate: "asc" },
      include: {
        customer: {
          select: { id: true, name: true, mobile: true, notificationOptOut: true },
        },
        medicine: {
          select: { id: true, name: true, genericName: true, dosageForm: true },
        },
      },
    });

    const now = new Date();
    const enriched = rules.map((r: typeof rules[number]) => {
      const diffMs = new Date(r.expectedRefillDate).getTime() - now.getTime();
      const daysLeft = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
      return {
        ...r,
        daysLeft,
        isOverdue: daysLeft < 0,
      };
    });

    return enriched;
  }

  /**
   * Trigger / Dispatch Refill Reminder Notification (Scoped to shop)
   */
  async triggerReminder(shopId: string, ruleId: string, input: TriggerReminderInput, _userId?: string) {
    const rule = await prisma.customerRefillRule.findFirst({
      where: { id: ruleId, shopId },
      include: {
        customer: true,
        medicine: true,
      },
    });

    if (!rule) {
      throw AppError.notFound("Refill rule not found in your store");
    }

    if (rule.customer.notificationOptOut) {
      throw AppError.badRequest("Customer has opted out of notifications");
    }

    const channel = input.channel || NOTIFICATION_CHANNEL.WHATSAPP;
    const recipient = channel === "EMAIL" ? rule.customer.email : rule.customer.mobile;

    if (!recipient) {
      throw AppError.badRequest(`Customer does not have a valid ${channel} contact address`);
    }

    const formattedDate = new Date(rule.expectedRefillDate).toLocaleDateString("en-IN", {
      day: "numeric",
      month: "short",
      year: "numeric",
    });

    const message =
      input.customMessage ||
      `Dear ${rule.customer.name}, your prescription refill for ${rule.medicine.name} is due on ${formattedDate}. Please visit our pharmacy to replenish your supply. Thank you!`;

    const log = await prisma.notificationLog.create({
      data: {
        shopId,
        customerId: rule.customerId,
        channel,
        recipient,
        templateName: "CHRONIC_REFILL_REMINDER",
        message,
        status: NOTIFICATION_STATUS.SENT,
        sentAt: new Date(),
      },
    });

    return log;
  }

  /**
   * List Notification Logs (Scoped to shop)
   */
  async listNotifications(shopId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      prisma.notificationLog.findMany({
        where: { shopId },
        skip,
        take: limit,
        orderBy: { sentAt: "desc" },
        include: {
          customer: { select: { id: true, name: true, mobile: true } },
        },
      }),
      prisma.notificationLog.count({ where: { shopId } }),
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
   * Customer Follow-ups (Scoped to shop)
   */
  async createFollowUp(shopId: string, data: CreateFollowUpInput, userId?: string) {
    const customer = await prisma.customer.findFirst({
      where: { id: data.customerId, shopId },
    });
    if (!customer) throw AppError.notFound("Customer not found in your store");

    const followUp = await prisma.customerFollowUp.create({
      data: {
        shopId,
        customerId: data.customerId,
        followUpDate: new Date(data.followUpDate),
        notes: data.notes,
        status: FOLLOW_UP_STATUS.PENDING,
        createdById: userId,
      },
      include: {
        customer: { select: { id: true, name: true, mobile: true } },
      },
    });

    return followUp;
  }

  async listFollowUps(shopId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      prisma.customerFollowUp.findMany({
        where: { shopId },
        skip,
        take: limit,
        orderBy: { followUpDate: "asc" },
        include: {
          customer: { select: { id: true, name: true, mobile: true } },
        },
      }),
      prisma.customerFollowUp.count({ where: { shopId } }),
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

  async updateFollowUp(shopId: string, id: string, data: UpdateFollowUpInput) {
    const existing = await prisma.customerFollowUp.findFirst({ where: { id, shopId } });
    if (!existing) throw AppError.notFound("Follow-up not found in your store");

    const updated = await prisma.customerFollowUp.update({
      where: { id },
      data: {
        notes: data.notes,
        status: data.status,
        completedAt: data.status === "COMPLETED" ? new Date() : undefined,
      },
      include: {
        customer: { select: { id: true, name: true, mobile: true } },
      },
    });

    return updated;
  }
}

export const crmService = new CrmService();
