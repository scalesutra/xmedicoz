import { z } from "zod";
import { CUSTOMER_TYPE } from "../../../config/constants.js";

export const CreateCustomerSchema = z.object({
  name: z.string().min(2, "Customer name is required"),
  mobile: z.string().min(8, "Valid mobile number is required"),
  email: z.string().email("Invalid email").optional().or(z.literal("")),
  address: z.string().optional(),
  dob: z.string().datetime().optional().nullable(),
  customerType: z.enum([CUSTOMER_TYPE.WALK_IN, CUSTOMER_TYPE.REGULAR, CUSTOMER_TYPE.PERMANENT]).default(CUSTOMER_TYPE.REGULAR),
  isPermanent: z.boolean().default(false),
  creditLimit: z.coerce.number().min(0).default(0),
  notificationOptOut: z.boolean().default(false),
});

export const UpdateCustomerSchema = CreateCustomerSchema.partial();

export const QueryCustomerSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  search: z.string().optional(), // search by mobile or name
  customerType: z.enum([CUSTOMER_TYPE.WALK_IN, CUSTOMER_TYPE.REGULAR, CUSTOMER_TYPE.PERMANENT]).optional(),
  isPermanent: z
    .enum(["true", "false"])
    .optional()
    .transform((val) => (val === "true" ? true : val === "false" ? false : undefined)),
  status: z.enum(["ACTIVE", "INACTIVE"]).optional().default("ACTIVE"),
});
