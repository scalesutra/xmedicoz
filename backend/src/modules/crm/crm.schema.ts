import { z } from "zod";
import { NOTIFICATION_CHANNEL, REFILL_STATUS, FOLLOW_UP_STATUS } from "../../config/constants.js";

export const CreateRefillRuleSchema = z.object({
  customerId: z.string().uuid("Invalid customer ID"),
  medicineId: z.string().uuid("Invalid medicine ID"),
  dailyDosage: z.number().positive("Daily dosage must be greater than 0").default(1),
  daysSupply: z.number().int().positive("Days supply must be greater than 0").default(30),
  lastPurchaseDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
  notes: z.string().max(500).optional(),
});

export type CreateRefillRuleInput = z.infer<typeof CreateRefillRuleSchema>;

export const UpdateRefillRuleSchema = z.object({
  dailyDosage: z.number().positive().optional(),
  daysSupply: z.number().int().positive().optional(),
  status: z.enum([REFILL_STATUS.ACTIVE, REFILL_STATUS.PAUSED, REFILL_STATUS.COMPLETED]).optional(),
  notes: z.string().max(500).optional(),
});

export type UpdateRefillRuleInput = z.infer<typeof UpdateRefillRuleSchema>;

export const TriggerReminderSchema = z.object({
  channel: z.enum([
    NOTIFICATION_CHANNEL.WHATSAPP,
    NOTIFICATION_CHANNEL.SMS,
    NOTIFICATION_CHANNEL.EMAIL,
  ]).default(NOTIFICATION_CHANNEL.WHATSAPP),
  customMessage: z.string().max(500).optional(),
});

export type TriggerReminderInput = z.infer<typeof TriggerReminderSchema>;

export const CreateFollowUpSchema = z.object({
  customerId: z.string().uuid("Invalid customer ID"),
  followUpDate: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Follow-up date must be YYYY-MM-DD or ISO")),
  notes: z.string().trim().min(1, "Notes are required").max(500),
});

export type CreateFollowUpInput = z.infer<typeof CreateFollowUpSchema>;

export const UpdateFollowUpSchema = z.object({
  notes: z.string().max(500).optional(),
  status: z.enum([
    FOLLOW_UP_STATUS.PENDING,
    FOLLOW_UP_STATUS.COMPLETED,
    FOLLOW_UP_STATUS.CANCELLED,
  ]).optional(),
});

export type UpdateFollowUpInput = z.infer<typeof UpdateFollowUpSchema>;

export const QueryRefillRulesSchema = z.object({
  customerId: z.string().uuid().optional(),
  status: z.enum([REFILL_STATUS.ACTIVE, REFILL_STATUS.PAUSED, REFILL_STATUS.COMPLETED]).optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

export type QueryRefillRulesInput = z.infer<typeof QueryRefillRulesSchema>;
