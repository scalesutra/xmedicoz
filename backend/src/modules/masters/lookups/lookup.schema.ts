import { z } from "zod";

export const CreateCategorySchema = z.object({
  name: z.string().min(2, "Category name must be at least 2 characters"),
  description: z.string().optional(),
});

export const UpdateCategorySchema = CreateCategorySchema.partial();

export const CreateManufacturerSchema = z.object({
  name: z.string().min(2, "Manufacturer name must be at least 2 characters"),
  contactPerson: z.string().optional(),
  email: z.string().email("Invalid email address").optional().or(z.literal("")),
  phone: z.string().optional(),
  address: z.string().optional(),
});

export const UpdateManufacturerSchema = CreateManufacturerSchema.partial();

export const CreateUnitSchema = z.object({
  name: z.string().min(1, "Unit name is required"), // e.g. Strip, Bottle, Box, Vial
  abbreviation: z.string().optional(),
});

export const UpdateUnitSchema = CreateUnitSchema.partial();

export const CreateTaxSchema = z.object({
  name: z.string().min(2, "Tax slab name is required"), // e.g. GST 5%
  rate: z.coerce.number().min(0).max(100, "Tax rate must be between 0 and 100"),
  cgst: z.coerce.number().min(0).max(50).optional(),
  sgst: z.coerce.number().min(0).max(50).optional(),
  igst: z.coerce.number().min(0).max(100).optional(),
});

export const UpdateTaxSchema = CreateTaxSchema.partial();
