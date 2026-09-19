import { z } from "zod";
import { PAYMENT_MODE } from "../../config/constants.js";

export const SalesInvoiceItemInputSchema = z.object({
  medicineId: z.string().uuid("Invalid medicine ID"),
  batchId: z.string().uuid("Invalid batch ID"),
  quantity: z.number().int().positive("Quantity must be greater than 0"),
  unitPrice: z.number().positive("Unit price must be greater than 0").optional(),
  discountAmount: z.number().min(0, "Discount cannot be negative").default(0),
  taxRate: z.number().min(0).max(100).default(0),
});

export const SalesPaymentInputSchema = z.object({
  amount: z.number().min(0, "Payment amount cannot be negative").default(0),
  paymentMode: z.enum([
    PAYMENT_MODE.CASH,
    PAYMENT_MODE.UPI,
    PAYMENT_MODE.CARD,
    PAYMENT_MODE.CREDIT,
  ]),
  referenceNumber: z.string().trim().max(100).optional(),
});

export const CreateSalesInvoiceSchema = z
  .object({
    customerId: z.string().uuid("Invalid customer ID").optional(),
    customerName: z.string().trim().max(100).optional(),
    customerMobile: z.string().trim().max(20).optional(),
    doctorName: z.string().trim().max(100).optional(),
    doctorRegNo: z.string().trim().max(50).optional(),
    notes: z.string().max(500).optional(),
    items: z.array(SalesInvoiceItemInputSchema).min(1, "At least one item is required in the sale"),
    payments: z.array(SalesPaymentInputSchema).optional().default([]),
    paymentMode: z
      .enum([
        PAYMENT_MODE.CASH,
        PAYMENT_MODE.UPI,
        PAYMENT_MODE.CARD,
        PAYMENT_MODE.CREDIT,
      ])
      .optional(),
    paymentMethod: z.string().optional(),
    paidAmount: z.number().min(0).optional(),
  })
  .transform((data) => {
    const payments = [...(data.payments || [])];
    const rawMode = data.paymentMode || data.paymentMethod?.toUpperCase();
    const mode =
      rawMode === "CREDIT DUE" || rawMode === "DUE" || rawMode === "CREDIT"
        ? PAYMENT_MODE.CREDIT
        : rawMode === "UPI"
        ? PAYMENT_MODE.UPI
        : rawMode === "CARD"
        ? PAYMENT_MODE.CARD
        : rawMode === "CASH"
        ? PAYMENT_MODE.CASH
        : undefined;

    if (payments.length === 0 && mode) {
      if (mode !== PAYMENT_MODE.CREDIT) {
        payments.push({
          amount: data.paidAmount && data.paidAmount > 0 ? data.paidAmount : 0,
          paymentMode: mode,
        });
      }
    }

    return {
      ...data,
      payments,
    };
  });

export type CreateSalesInvoiceInput = z.infer<typeof CreateSalesInvoiceSchema>;

export const SalesReturnItemInputSchema = z.object({
  salesItemId: z.string().uuid("Invalid sales item ID"),
  quantity: z.number().int().positive("Return quantity must be greater than 0"),
  refundRate: z.number().positive("Refund rate must be greater than 0").optional(),
});

export const CreateSalesReturnSchema = z.object({
  salesInvoiceId: z.string().uuid("Invalid sales invoice ID"),
  refundMode: z.enum(["CASH", "UPI", "CREDIT_NOTE"]).default("CASH"),
  reason: z.string().max(255).optional(),
  items: z.array(SalesReturnItemInputSchema).min(1, "At least one item must be returned"),
});

export type CreateSalesReturnInput = z.infer<typeof CreateSalesReturnSchema>;

export const QuerySalesSchema = z.object({
  customerId: z.string().uuid().optional(),
  paymentStatus: z.enum(["PAID", "PARTIALLY_PAID", "UNPAID"]).optional(),
  search: z.string().optional(),
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

export type QuerySalesInput = z.infer<typeof QuerySalesSchema>;
