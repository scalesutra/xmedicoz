import { z } from "zod";

export const QuerySmartSearchSchema = z.object({
  q: z.string().optional().default(""),
  symptomOnly: z
    .enum(["true", "false"])
    .optional()
    .transform((v) => v === "true"),
  inStockOnly: z
    .enum(["true", "false"])
    .optional()
    .transform((v) => v === "true"),
  sortByMargin: z
    .enum(["true", "false"])
    .optional()
    .transform((v) => v === "true"),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});

export const LogShortageSchema = z.object({
  medicineId: z.string().uuid("Invalid medicine ID"),
  customerCount: z.coerce.number().int().min(1).default(1),
  notes: z.string().optional(),
});

export const UpdateShortageSchema = z.object({
  status: z.enum(["PENDING", "PO_CREATED", "RESOLVED", "DISMISSED"]).optional(),
  suggestedReorderQty: z.coerce.number().int().min(1).optional(),
  preferredSupplierId: z.string().uuid("Invalid supplier ID").optional().nullable(),
  notes: z.string().optional().nullable(),
});
