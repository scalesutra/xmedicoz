import { Router } from "express";
import { medicineRouter } from "./medicines/medicine.routes.js";
import { customerRouter } from "./customers/customer.routes.js";
import { supplierRouter } from "./suppliers/supplier.routes.js";
import { lookupRouter } from "./lookups/lookup.routes.js";
import { authenticateKeycloakJwt } from "../../middleware/auth.middleware.js";
import { tenantMiddleware } from "../../middleware/tenant.middleware.js";

export const mastersRouter = Router();

// Enforce authentication & active shop tenant context
mastersRouter.use(authenticateKeycloakJwt, tenantMiddleware);

mastersRouter.use("/medicines", medicineRouter);
mastersRouter.use("/customers", customerRouter);
mastersRouter.use("/suppliers", supplierRouter);
mastersRouter.use("/", lookupRouter); // /categories, /manufacturers, /units, /taxes
