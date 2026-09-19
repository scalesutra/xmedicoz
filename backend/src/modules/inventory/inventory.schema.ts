import { z } from "zod";
import { BATCH_STATUS, STOCK_TRANSACTION_TYPE } from "../../config/constants.js";

export const CreateBatchSchema = z.object({
  medicineId: z.string().uuid("Invalid medicine ID"),
  supplierId: z.string().uuid("Invalid supplier ID").optional().nullable(),
  batchNumber: z.string().min(1, "Batch number is required"),
  manufacturingDate: z.string().datetime().optional().nullable(),
  expiryDate: z.string().datetime("Valid expiry date (ISO format) is required"),
  mrp: z.coerce.number().min(0.01, "MRP must be greater than 0"),
  purchaseRate: z.coerce.number().min(0, "Purchase rate cannot be negative"),
  sellingPrice: z.coerce.number().min(0.01, "Selling price must be greater than 0"),
  initialQuantity: z.coerce.number().int().min(0, "Quantity cannot be negative").default(0),
  notes: z.string().optional(),
});

export const UpdateBatchSchema = z.object({
  mrp: z.coerce.number().min(0.01).optional(),
  purchaseRate: z.coerce.number().min(0).optional(),
  sellingPrice: z.coerce.number().min(0.01).optional(),
  status: z
    .enum([BATCH_STATUS.ACTIVE, BATCH_STATUS.NEAR_EXPIRY, BATCH_STATUS.EXPIRED, BATCH_STATUS.QUARANTINED])
    .optional(),
  expiryDate: z.string().datetime().optional(),
});

export const StockAdjustmentSchema = z.object({
  batchId: z.string().uuid("Invalid batch ID"),
  type: z.enum([
    STOCK_TRANSACTION_TYPE.ADJUSTMENT_ADD,
    STOCK_TRANSACTION_TYPE.ADJUSTMENT_SUB,
    STOCK_TRANSACTION_TYPE.DAMAGE,
  ]),
  quantity: z.coerce.number().int().min(1, "Quantity must be at least 1"),
  reason: z.string().min(3, "Reason for stock adjustment is required"),
  notes: z.string().optional(),
});

export const QueryBatchSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(2000).default(50),
  search: z.string().optional(), // batch number or medicine name
  medicineId: z.string().uuid().optional(),
  status: z
    .enum([BATCH_STATUS.ACTIVE, BATCH_STATUS.NEAR_EXPIRY, BATCH_STATUS.EXPIRED, BATCH_STATUS.QUARANTINED])
    .optional(),
  inStockOnly: z
    .enum(["true", "false"])
    .optional()
    .transform((v) => v === "true"),
  activeOnly: z.any().optional(),
});

export const QueryExpirySchema = z.object({
  days: z.coerce.number().int().min(1).max(365).default(90),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const QueryLedgerSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  batchId: z.string().uuid().optional(),
  medicineId: z.string().uuid().optional(),
  transactionType: z
    .enum([
      STOCK_TRANSACTION_TYPE.PURCHASE,
      STOCK_TRANSACTION_TYPE.SALE,
      STOCK_TRANSACTION_TYPE.RETURN_IN,
      STOCK_TRANSACTION_TYPE.RETURN_OUT,
      STOCK_TRANSACTION_TYPE.ADJUSTMENT_ADD,
      STOCK_TRANSACTION_TYPE.ADJUSTMENT_SUB,
      STOCK_TRANSACTION_TYPE.DAMAGE,
      STOCK_TRANSACTION_TYPE.OPENING,
    ])
    .optional(),
});
