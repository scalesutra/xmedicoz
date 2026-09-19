import { z } from "zod";

const optionalString = z
  .union([z.string(), z.literal(""), z.null()])
  .optional()
  .transform((val) => (!val ? undefined : val.trim()));

const optionalEmail = z
  .union([z.string().email("Valid email is required"), z.literal(""), z.null()])
  .optional()
  .transform((val) => (!val ? undefined : val.trim()));

export const CreateShopSchema = z.object({
  name: z.string().min(2, "Store name must be at least 2 characters"),
  ownerName: optionalString,
  phone: z.string().min(7, "Phone number is required"),
  email: optionalEmail,
  drugLicenseNo: optionalString,
  gstin: optionalString,
  address: optionalString,
  city: optionalString,
  state: optionalString,
  pincode: optionalString,
  invoicePrefix: z.string().max(6).optional().default("INV"),
  planCode: z.enum(["TRIAL", "STARTER", "PRO", "ENTERPRISE"]).optional().default("TRIAL"),
});

export type CreateShopInput = z.infer<typeof CreateShopSchema>;

export const UpdateShopSchema = CreateShopSchema.partial().omit({ planCode: true });
export type UpdateShopInput = z.infer<typeof UpdateShopSchema>;

export const SubscribePlanSchema = z.object({
  planCode: z.enum(["TRIAL", "STARTER", "PRO", "ENTERPRISE"]),
  billingCycle: z.enum(["MONTHLY", "YEARLY"]).default("MONTHLY"),
});
export type SubscribePlanInput = z.infer<typeof SubscribePlanSchema>;

export const AddMemberSchema = z.object({
  email: z.string().email(),
  firstName: z.string().min(1),
  lastName: z.string().optional().default(""),
  role: z.enum(["OWNER", "PHARMACIST", "CASHIER", "STAFF"]).default("STAFF"),
});
export type AddMemberInput = z.infer<typeof AddMemberSchema>;
