import { Router } from "express";
import { CustomerController } from "./customer.controller.js";
import { validate } from "../../../middleware/validation.middleware.js";
import { authenticateKeycloakJwt } from "../../../middleware/auth.middleware.js";
import {
  CreateCustomerSchema,
  UpdateCustomerSchema,
  QueryCustomerSchema,
} from "./customer.schema.js";

export const customerRouter = Router();

// All customer routes require authentication
customerRouter.use(authenticateKeycloakJwt);

customerRouter.get("/", validate(QueryCustomerSchema, "query"), CustomerController.list);
customerRouter.get("/phone/:mobile", CustomerController.getByMobile);
customerRouter.get("/:id", CustomerController.getById);

customerRouter.post("/", validate(CreateCustomerSchema), CustomerController.create);
customerRouter.patch("/:id", validate(UpdateCustomerSchema), CustomerController.update);
