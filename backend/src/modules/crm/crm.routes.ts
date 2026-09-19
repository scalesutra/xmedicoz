import { Router } from "express";
import { CrmController } from "./crm.controller.js";
import { validate } from "../../middleware/validation.middleware.js";
import { authenticateKeycloakJwt } from "../../middleware/auth.middleware.js";
import {
  CreateRefillRuleSchema,
  TriggerReminderSchema,
  CreateFollowUpSchema,
  UpdateFollowUpSchema,
  QueryRefillRulesSchema,
} from "./crm.schema.js";

import { tenantMiddleware } from "../../middleware/tenant.middleware.js";

export const crmRouter = Router();

// All CRM routes require authentication and active shop context
crmRouter.use(authenticateKeycloakJwt, tenantMiddleware);

// Customer Medicine Purchase History
crmRouter.get("/customers/:id/history", CrmController.getCustomerHistory);

// Refill Rules & Automated Reminders
crmRouter.get("/refills/due", CrmController.listDueRefills);
crmRouter.get("/refills", validate(QueryRefillRulesSchema, "query"), CrmController.listRefillRules);
crmRouter.post("/refills", validate(CreateRefillRuleSchema), CrmController.createRefillRule);
crmRouter.post("/refills/:id/remind", validate(TriggerReminderSchema), CrmController.triggerReminder);

// Notification Logs
crmRouter.get("/notifications", CrmController.listNotifications);

// Follow-ups & Callback Reminders
crmRouter.get("/follow-ups", CrmController.listFollowUps);
crmRouter.post("/follow-ups", validate(CreateFollowUpSchema), CrmController.createFollowUp);
crmRouter.patch("/follow-ups/:id", validate(UpdateFollowUpSchema), CrmController.updateFollowUp);
