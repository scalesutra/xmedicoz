import { z } from "zod";

export const RACK_ZONES = [
  "MAIN_COUNTER",
  "BACK_STORAGE",
  "COLD_STORAGE",
  "NARCOTICS_LOCKER",
  "OTC_FLOOR",
  "GENERAL",
] as const;

export const STORAGE_TYPES = [
  "STANDARD",
  "REFRIGERATED",
  "NARCOTICS_SAFE",
  "HAZARDOUS",
] as const;

export const RACK_STATUSES = ["ACTIVE", "MAINTENANCE", "INACTIVE"] as const;

export const CreateRackSchema = z.object({
  code: z
    .string()
    .min(1, "Rack code is required")
    .max(10, "Rack code max length is 10")
    .transform((val) => val.trim().toUpperCase()),
  name: z.string().min(2, "Rack name must be at least 2 characters").max(100),
  zone: z.enum(RACK_ZONES).default("MAIN_COUNTER"),
  storageType: z.enum(STORAGE_TYPES).default("STANDARD"),
  description: z.string().optional().nullable(),
  totalShelves: z.coerce.number().int().min(1).max(50).default(4),
  rowNumber: z.coerce.number().int().optional().nullable(),
  columnNumber: z.coerce.number().int().optional().nullable(),
});

export const UpdateRackSchema = CreateRackSchema.partial().extend({
  status: z.enum(RACK_STATUSES).optional(),
});

export const QueryRackSchema = z.object({
  zone: z.enum(RACK_ZONES).optional(),
  storageType: z.enum(STORAGE_TYPES).optional(),
  status: z.enum(RACK_STATUSES).optional(),
  search: z.string().optional(),
});

export const CreateShelfSchema = z.object({
  shelfNumber: z.coerce.number().int().min(1, "Shelf number must be positive"),
  shelfLabel: z.string().optional().nullable(),
  barcode: z.string().optional().nullable(),
  maxCapacity: z.coerce.number().int().min(1).default(100),
  temperature: z.coerce.number().optional().nullable(),
});

export const UpdateShelfSchema = CreateShelfSchema.partial();

export const AssignMedicineRackSchema = z.object({
  medicineId: z.string().uuid("Invalid medicine ID"),
  rackId: z.string().uuid().optional().nullable(),
  rackCode: z.string().optional().nullable(),
  shelfNumber: z.coerce.string().optional().nullable(),
  boxCode: z.coerce.string().optional().nullable(),
});

export const BulkAssignRackSchema = z.object({
  assignments: z.array(AssignMedicineRackSchema).min(1, "At least one assignment required").max(500),
});

export const TransferRackSchema = z.object({
  medicineIds: z.array(z.string().uuid("Invalid medicine ID")).min(1, "At least one medicine ID required"),
  targetRackId: z.string().uuid().optional().nullable(),
  targetRackCode: z.string().optional().nullable(),
  targetShelfNumber: z.coerce.string().optional().nullable(),
  targetBoxCode: z.coerce.string().optional().nullable(),
  reason: z.string().optional().nullable(),
});

export const AuditVerifyItemSchema = z.object({
  batchId: z.string().uuid("Invalid batch ID"),
  physicalCount: z.coerce.number().int().min(0, "Count cannot be negative"),
  systemCount: z.coerce.number().int().min(0),
  notes: z.string().optional().nullable(),
});

export const AuditVerifySchema = z.object({
  auditItems: z.array(AuditVerifyItemSchema).min(1, "At least one item required for verification"),
});

export type CreateRackInput = z.infer<typeof CreateRackSchema>;
export type UpdateRackInput = z.infer<typeof UpdateRackSchema>;
export type QueryRackInput = z.infer<typeof QueryRackSchema>;
export type CreateShelfInput = z.infer<typeof CreateShelfSchema>;
export type UpdateShelfInput = z.infer<typeof UpdateShelfSchema>;
export type AssignMedicineRackInput = z.infer<typeof AssignMedicineRackSchema>;
export type BulkAssignRackInput = z.infer<typeof BulkAssignRackSchema>;
export type TransferRackInput = z.infer<typeof TransferRackSchema>;
export type AuditVerifyInput = z.infer<typeof AuditVerifySchema>;
