import { z } from "zod";

export const CreateMedicineSchema = z.object({
  name: z.string().min(2, "Medicine name is required"),
  genericName: z.string().min(2, "Generic formula name is required"),
  brand: z.string().optional(),
  dosageForm: z.string().min(1, "Dosage form (e.g. Tablet, Syrup, Injection) is required"),
  strength: z.string().optional(), // 500mg, 650mg
  hsnCode: z.string().optional(),
  gstRate: z.coerce.number().min(0).max(100).default(0),
  mrp: z.coerce.number().min(0.01, "MRP must be greater than 0"),
  purchaseRate: z.coerce.number().min(0).default(0),
  sellingPrice: z.coerce.number().min(0.01, "Selling price must be greater than 0"),
  reorderLevel: z.coerce.number().int().min(0).default(10),
  prescriptionRequired: z.boolean().default(false),
  categoryId: z.string().uuid("Invalid category ID").optional().nullable(),
  manufacturerId: z.string().uuid("Invalid manufacturer ID").optional().nullable(),
  unitId: z.string().uuid("Invalid unit ID").optional().nullable(),
  rack: z.string().optional().nullable(),
  shelf: z.string().optional().nullable(),
  box: z.string().optional().nullable(),
  symptoms: z.string().optional().nullable(),
  saltComposition: z.string().optional().nullable(),
  otcFlag: z.boolean().default(false),
});

export const UpdateMedicineSchema = CreateMedicineSchema.partial();

export const QueryMedicineSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(1000).default(50),
  search: z.string().optional(),
  categoryId: z.string().optional(),
  manufacturerId: z.string().optional(),
  status: z.enum(["ACTIVE", "INACTIVE"]).optional().default("ACTIVE"),
  prescriptionRequired: z
    .enum(["true", "false"])
    .optional()
    .transform((val) => (val === "true" ? true : val === "false" ? false : undefined)),
});
