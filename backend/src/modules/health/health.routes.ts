import { Router } from "express";
import { HealthController } from "./health.controller.js";

export const healthRouter = Router();

healthRouter.get("/health", HealthController.getLiveness);
healthRouter.get("/ready", HealthController.getReadiness);
