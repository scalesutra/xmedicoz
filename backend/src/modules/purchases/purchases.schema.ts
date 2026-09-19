import { z } from "zod";
import { PAYMENT_MODE } from "../../config/constants.js";

export const CreatePurchaseOrderSchema = z.object({
  supplierId: z.string().uuid("Invalid supplier ID"),
  expectedDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
  notes: z.string().max(500).optional(),
  items: z
    .array(
      z.object({
        medicineId: z.string().uuid("Invalid medicine ID"),
        quantity: z.number().int().positive("Quantity must be greater than 0"),
        expectedRate: z.number().positive("Expected rate must be greater than 0"),
      })
    )
    .min(1, "At least one item is required in the purchase order"),
});

export type CreatePurchaseOrderInput = z.infer<typeof CreatePurchaseOrderSchema>;

export const PurchaseInvoiceItemSchema = z.object({
  medicineId: z.string().uuid("Invalid medicine ID").optional(),
  medicineName: z.string().trim().min(1).max(200).optional(),
  batchNumber: z.string().trim().min(1, "Batch number is required").max(50),
  hsnCode: z.string().trim().max(20).optional(),
  manufacturingDate: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
  expiryDate: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Expiry date must be YYYY-MM-DD or ISO")),
  quantity: z.number().int().positive("Quantity must be greater than 0"),
  freeQuantity: z.number().int().min(0).default(0),
  purchaseRate: z.number().positive("Purchase rate must be greater than 0"),
  mrp: z.number().positive("MRP must be greater than 0"),
  sellingPrice: z.number().positive("Selling price must be greater than 0").optional(),
  discountPercent: z.number().min(0).max(100).default(0),
  taxRate: z.number().min(0).max(100).default(0),
});

export const CreatePurchaseInvoiceSchema = z.object({
  supplierId: z.string().uuid("Invalid supplier ID").optional(),
  supplier: z.object({
    name: z.string().trim().min(1).max(200),
    contactPerson: z.string().trim().max(200).optional(),
    mobile: z.string().trim().max(20).optional(),
    gstin: z.string().trim().max(20).optional(),
    dlNumber: z.string().trim().max(50).optional(),
    address: z.string().trim().max(500).optional(),
    paymentTermsDays: z.number().int().min(0).default(30),
  }).optional(),
  purchaseOrderId: z.string().uuid().optional(),
  invoiceNumber: z.string().trim().min(1, "Supplier invoice number is required").max(100),
  invoiceDate: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Invoice date must be YYYY-MM-DD or ISO")),
  paymentTermsDays: z.number().int().min(0).default(30),
  notes: z.string().max(500).optional(),
  items: z.array(PurchaseInvoiceItemSchema).min(1, "At least one item is required in the purchase bill"),
});

export type CreatePurchaseInvoiceInput = z.infer<typeof CreatePurchaseInvoiceSchema>;

export const CreatePurchaseReturnSchema = z.object({
  supplierId: z.string().uuid("Invalid supplier ID"),
  purchaseInvoiceId: z.string().uuid().optional(),
  reason: z.enum(["EXPIRED", "DAMAGED", "EXCESS", "RECALLED", "OTHER"]).default("EXPIRED"),
  items: z
    .array(
      z.object({
        batchId: z.string().uuid("Invalid batch ID"),
        quantity: z.number().int().positive("Return quantity must be greater than 0"),
        returnRate: z.number().positive("Return rate must be greater than 0"),
      })
    )
    .min(1, "At least one item must be returned"),
});

export type CreatePurchaseReturnInput = z.infer<typeof CreatePurchaseReturnSchema>;

export const RecordSupplierPaymentSchema = z.object({
  supplierId: z.string().uuid("Invalid supplier ID"),
  purchaseInvoiceId: z.string().uuid().optional(),
  amount: z.number().positive("Payment amount must be greater than 0"),
  paymentMode: z.enum([
    PAYMENT_MODE.CASH,
    PAYMENT_MODE.BANK_TRANSFER,
    PAYMENT_MODE.UPI,
    PAYMENT_MODE.CHEQUE,
  ]),
  referenceNumber: z.string().trim().max(100).optional(),
  notes: z.string().max(500).optional(),
});

export type RecordSupplierPaymentInput = z.infer<typeof RecordSupplierPaymentSchema>;

export const QueryPurchasesSchema = z.object({
  supplierId: z.string().uuid().optional(),
  search: z.string().optional(),
  paymentStatus: z.enum(["UNPAID", "PARTIALLY_PAID", "PAID"]).optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

export type QueryPurchasesInput = z.infer<typeof QueryPurchasesSchema>;
