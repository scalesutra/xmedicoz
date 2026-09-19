import { Router } from "express";
import { shopController } from "./shop.controller.js";
import { authenticateKeycloakJwt } from "../../middleware/auth.middleware.js";

export const shopRouter = Router();

// Public / Authenticated Plan directory
shopRouter.get("/plans", authenticateKeycloakJwt, shopController.listSubscriptionPlans);

// Shop list and onboarding
shopRouter.get("/", authenticateKeycloakJwt, shopController.listUserShops);
shopRouter.post("/", authenticateKeycloakJwt, shopController.createShop);

// Single Shop details & updates
shopRouter.get("/:id", authenticateKeycloakJwt, shopController.getShopById);
shopRouter.put("/:id", authenticateKeycloakJwt, shopController.updateShop);

// Subscription purchase / upgrade
shopRouter.post("/:id/subscribe", authenticateKeycloakJwt, shopController.subscribePlan);

// Staff management
shopRouter.get("/:id/members", authenticateKeycloakJwt, shopController.listMembers);
shopRouter.post("/:id/members", authenticateKeycloakJwt, shopController.addMember);
