import { z } from "zod";

export const CreateSupplierSchema = z.object({
  name: z.string().min(2, "Supplier business name is required"),
  contactPerson: z.string().optional(),
  mobile: z.string().min(8, "Contact phone number is required"),
  email: z.string().email("Invalid email address").optional().or(z.literal("")),
  gstin: z.string().optional(), // 15-character GSTIN format if provided
  dlNumber: z.string().optional(), // Drug license number
  address: z.string().optional(),
  paymentTermsDays: z.coerce.number().int().min(0).default(30),
  outstandingBalance: z.coerce.number().default(0),
});

export const UpdateSupplierSchema = CreateSupplierSchema.partial();

export const QuerySupplierSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  search: z.string().optional(), // search by name, gstin, or mobile
  status: z.enum(["ACTIVE", "INACTIVE"]).optional().default("ACTIVE"),
});
