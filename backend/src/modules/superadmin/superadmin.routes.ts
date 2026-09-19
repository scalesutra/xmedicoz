import { Router } from "express";
import { superadminController } from "./superadmin.controller.js";
import { authenticateKeycloakJwt } from "../../middleware/auth.middleware.js";
import { requireRole } from "../../middleware/rbac.middleware.js";

export const superadminRouter = Router();

// Gating all endpoints to authenticated users with system Admin or Superadmin role
superadminRouter.use(authenticateKeycloakJwt);
superadminRouter.use(requireRole("Admin", "Superadmin"));

// SaaS Cockpit & Analytics
superadminRouter.get("/overview", (req, res, next) => superadminController.getOverview(req, res, next));

// Tenant / Pharmacy Operations
superadminRouter.get("/shops", (req, res, next) => superadminController.getShops(req, res, next));
superadminRouter.get("/shops/:id", (req, res, next) => superadminController.getShopById(req, res, next));
superadminRouter.patch("/shops/:id/status", (req, res, next) => superadminController.updateShopStatus(req, res, next));
superadminRouter.patch("/shops/:id/subscription", (req, res, next) => superadminController.updateShopSubscription(req, res, next));

// SaaS Subscription Plans
superadminRouter.get("/plans", (req, res, next) => superadminController.getPlans(req, res, next));
superadminRouter.put("/plans/:id", (req, res, next) => superadminController.updatePlan(req, res, next));

// Platform Users
superadminRouter.get("/users", (req, res, next) => superadminController.getUsers(req, res, next));
superadminRouter.patch("/users/:id/role", (req, res, next) => superadminController.updateUserRole(req, res, next));

// Audit Logs
superadminRouter.get("/audit-logs", (req, res, next) => superadminController.getAuditLogs(req, res, next));

// System Health Diagnostics
superadminRouter.get("/system-health", (req, res, next) => superadminController.getSystemHealth(req, res, next));
