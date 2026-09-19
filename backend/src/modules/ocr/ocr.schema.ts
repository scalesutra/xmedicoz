import { z } from "zod";

export const OCR_DOCUMENT_TYPES = {
  MEDICINE: "MEDICINE",
  CUSTOMER: "CUSTOMER",
  SUPPLIER: "SUPPLIER",
  BATCH: "BATCH",
  BILL_PRESCRIPTION: "BILL_PRESCRIPTION",
  BILL_PURCHASE: "BILL_PURCHASE",
} as const;

export type OcrDocumentType = (typeof OCR_DOCUMENT_TYPES)[keyof typeof OCR_DOCUMENT_TYPES];

export const ScanDocumentSchema = z.object({
  documentType: z.enum([
    OCR_DOCUMENT_TYPES.MEDICINE,
    OCR_DOCUMENT_TYPES.CUSTOMER,
    OCR_DOCUMENT_TYPES.SUPPLIER,
    OCR_DOCUMENT_TYPES.BATCH,
    OCR_DOCUMENT_TYPES.BILL_PRESCRIPTION,
    OCR_DOCUMENT_TYPES.BILL_PURCHASE,
  ]),
  image: z.string().min(1, "Base64 image or data URL is required"),
  options: z
    .object({
      hints: z.string().optional(),
    })
    .optional(),
});

export type ScanDocumentInput = z.infer<typeof ScanDocumentSchema>;
