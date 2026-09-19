/**
 * Centralized Application Constants & Enums
 * Adheres strictly to Section 4 of instruction.md: No magic strings or numbers.
 */

export const USER_STATUS = {
  ACTIVE: "ACTIVE",
  INACTIVE: "INACTIVE",
  SUSPENDED: "SUSPENDED",
} as const;

export type UserStatus = (typeof USER_STATUS)[keyof typeof USER_STATUS];

export const ROLES = {
  ADMIN: "Admin",
  PHARMACIST: "Pharmacist",
  CASHIER: "Cashier",
  STAFF: "Staff",
} as const;

export type RoleName = (typeof ROLES)[keyof typeof ROLES];

export const PERMISSIONS = {
  // Auth & Profile
  PROFILE_READ: "profile.read",
  PROFILE_UPDATE: "profile.update",
  PROFILE_PASSWORD_UPDATE: "profile.password.update",

  // Users & Staff
  USER_READ: "user.read",
  USER_CREATE: "user.create",
  USER_UPDATE: "user.update",
  USER_DELETE: "user.delete",

  // Masters
  MEDICINE_READ: "medicine.read",
  MEDICINE_CREATE: "medicine.create",
  MEDICINE_UPDATE: "medicine.update",
  MEDICINE_DELETE: "medicine.delete",
  CUSTOMER_READ: "customer.read",
  CUSTOMER_CREATE: "customer.create",
  CUSTOMER_UPDATE: "customer.update",
  SUPPLIER_READ: "supplier.read",
  SUPPLIER_CREATE: "supplier.create",
  SUPPLIER_UPDATE: "supplier.update",

  // Inventory & Batches
  INVENTORY_READ: "inventory.read",
  INVENTORY_ADJUST: "inventory.adjust",
  BATCH_READ: "batch.read",
  BATCH_CREATE: "batch.create",

  // Sales & Purchases
  SALES_READ: "sales.read",
  SALES_CREATE: "sales.create",
  SALES_RETURN: "sales.return",
  PURCHASE_READ: "purchase.read",
  PURCHASE_CREATE: "purchase.create",
  PURCHASE_RETURN: "purchase.return",

  // CRM & Reminders
  CRM_FOLLOWUP_READ: "crm.followup.read",
  CRM_FOLLOWUP_WRITE: "crm.followup.write",
  CRM_REMINDER_READ: "crm.reminder.read",
  CRM_REMINDER_WRITE: "crm.reminder.write",

  // Reports & Audit
  REPORT_READ: "report.read",
  AUDIT_READ: "audit.read",
} as const;

export type PermissionCode = (typeof PERMISSIONS)[keyof typeof PERMISSIONS];

export const SHOP_ROLE = {
  OWNER: "OWNER",
  PHARMACIST: "PHARMACIST",
  CASHIER: "CASHIER",
  STAFF: "STAFF",
} as const;

export type ShopRole = (typeof SHOP_ROLE)[keyof typeof SHOP_ROLE];

export const SUBSCRIPTION_PLAN_CODE = {
  TRIAL: "TRIAL",
  STARTER: "STARTER",
  PRO: "PRO",
  ENTERPRISE: "ENTERPRISE",
} as const;

export type SubscriptionPlanCode = (typeof SUBSCRIPTION_PLAN_CODE)[keyof typeof SUBSCRIPTION_PLAN_CODE];

export const SUBSCRIPTION_STATUS = {
  TRIAL: "TRIAL",
  ACTIVE: "ACTIVE",
  PAST_DUE: "PAST_DUE",
  EXPIRED: "EXPIRED",
  CANCELLED: "CANCELLED",
} as const;

export type SubscriptionStatus = (typeof SUBSCRIPTION_STATUS)[keyof typeof SUBSCRIPTION_STATUS];

export const ERROR_CODES = {
  BAD_REQUEST: "BAD_REQUEST",
  UNAUTHORIZED: "UNAUTHORIZED",
  FORBIDDEN: "FORBIDDEN",
  NOT_FOUND: "NOT_FOUND",
  CONFLICT: "CONFLICT",
  VALIDATION_ERROR: "VALIDATION_ERROR",
  RATE_LIMITED: "RATE_LIMITED",
  INVALID_CREDENTIALS: "INVALID_CREDENTIALS",
  INVALID_OTP: "INVALID_OTP",
  OTP_EXPIRED: "OTP_EXPIRED",
  OTP_ATTEMPTS_EXCEEDED: "OTP_ATTEMPTS_EXCEEDED",
  USER_NOT_FOUND: "USER_NOT_FOUND",
  USER_INACTIVE: "USER_INACTIVE",
  SHOP_NOT_FOUND: "SHOP_NOT_FOUND",
  SHOP_ACCESS_DENIED: "SHOP_ACCESS_DENIED",
  SUBSCRIPTION_EXPIRED: "SUBSCRIPTION_EXPIRED",
  SUBSCRIPTION_LIMIT_EXCEEDED: "SUBSCRIPTION_LIMIT_EXCEEDED",
  INTERNAL_SERVER_ERROR: "INTERNAL_SERVER_ERROR",
} as const;

export type ErrorCode = (typeof ERROR_CODES)[keyof typeof ERROR_CODES];

export const CUSTOMER_TYPE = {
  WALK_IN: "WALK_IN",
  REGULAR: "REGULAR",
  PERMANENT: "PERMANENT",
} as const;

export type CustomerType = (typeof CUSTOMER_TYPE)[keyof typeof CUSTOMER_TYPE];

export const BATCH_STATUS = {
  ACTIVE: "ACTIVE",
  NEAR_EXPIRY: "NEAR_EXPIRY",
  EXPIRED: "EXPIRED",
  QUARANTINED: "QUARANTINED",
} as const;

export type BatchStatus = (typeof BATCH_STATUS)[keyof typeof BATCH_STATUS];

export const STOCK_TRANSACTION_TYPE = {
  PURCHASE: "PURCHASE",
  SALE: "SALE",
  RETURN_IN: "RETURN_IN",
  RETURN_OUT: "RETURN_OUT",
  ADJUSTMENT_ADD: "ADJUSTMENT_ADD",
  ADJUSTMENT_SUB: "ADJUSTMENT_SUB",
  DAMAGE: "DAMAGE",
  OPENING: "OPENING",
} as const;

export const PURCHASE_ORDER_STATUS = {
  DRAFT: "DRAFT",
  PLACED: "PLACED",
  PARTIALLY_RECEIVED: "PARTIALLY_RECEIVED",
  COMPLETED: "COMPLETED",
  CANCELLED: "CANCELLED",
} as const;

export type PurchaseOrderStatus = (typeof PURCHASE_ORDER_STATUS)[keyof typeof PURCHASE_ORDER_STATUS];

export const PURCHASE_PAYMENT_STATUS = {
  UNPAID: "UNPAID",
  PARTIALLY_PAID: "PARTIALLY_PAID",
  PAID: "PAID",
} as const;

export type PurchasePaymentStatus = (typeof PURCHASE_PAYMENT_STATUS)[keyof typeof PURCHASE_PAYMENT_STATUS];

export const PAYMENT_MODE = {
  CASH: "CASH",
  BANK_TRANSFER: "BANK_TRANSFER",
  UPI: "UPI",
  CHEQUE: "CHEQUE",
  CARD: "CARD",
  CREDIT: "CREDIT",
} as const;

export type PaymentMode = (typeof PAYMENT_MODE)[keyof typeof PAYMENT_MODE];

export const SALES_PAYMENT_STATUS = {
  PAID: "PAID",
  PARTIALLY_PAID: "PARTIALLY_PAID",
  UNPAID: "UNPAID",
} as const;

export type SalesPaymentStatus = (typeof SALES_PAYMENT_STATUS)[keyof typeof SALES_PAYMENT_STATUS];

export const REFILL_STATUS = {
  ACTIVE: "ACTIVE",
  PAUSED: "PAUSED",
  COMPLETED: "COMPLETED",
} as const;

export type RefillStatus = (typeof REFILL_STATUS)[keyof typeof REFILL_STATUS];

export const NOTIFICATION_CHANNEL = {
  WHATSAPP: "WHATSAPP",
  SMS: "SMS",
  EMAIL: "EMAIL",
} as const;

export type NotificationChannel = (typeof NOTIFICATION_CHANNEL)[keyof typeof NOTIFICATION_CHANNEL];

export const NOTIFICATION_STATUS = {
  PENDING: "PENDING",
  SENT: "SENT",
  FAILED: "FAILED",
} as const;

export type NotificationStatus = (typeof NOTIFICATION_STATUS)[keyof typeof NOTIFICATION_STATUS];

export const FOLLOW_UP_STATUS = {
  PENDING: "PENDING",
  COMPLETED: "COMPLETED",
  CANCELLED: "CANCELLED",
} as const;

export type FollowUpStatus = (typeof FOLLOW_UP_STATUS)[keyof typeof FOLLOW_UP_STATUS];

export const CACHE_KEYS = {
  otp: (channel: string, identifier: string) => `otp:${channel}:${identifier.toLowerCase()}`,
  otpRateLimit: (channel: string, identifier: string) => `ratelimit:otp:${channel}:${identifier.toLowerCase()}`,
  userProfile: (userId: string) => `user:profile:${userId}`,
  userPermissions: (userId: string) => `user:permissions:${userId}`,
  masterCategories: () => `masters:categories`,
  masterManufacturers: () => `masters:manufacturers`,
  masterUnits: () => `masters:units`,
  masterTaxes: () => `masters:taxes`,
} as const;

export const ACCOUNT_TYPE = {
  ASSET: "ASSET",
  LIABILITY: "LIABILITY",
  EQUITY: "EQUITY",
  REVENUE: "REVENUE",
  EXPENSE: "EXPENSE",
} as const;

export type AccountType = (typeof ACCOUNT_TYPE)[keyof typeof ACCOUNT_TYPE];

export const JOURNAL_ENTRY_STATUS = {
  DRAFT: "DRAFT",
  POSTED: "POSTED",
  VOID: "VOID",
} as const;

export type JournalEntryStatus = (typeof JOURNAL_ENTRY_STATUS)[keyof typeof JOURNAL_ENTRY_STATUS];

export const JOURNAL_LINE_TYPE = {
  DEBIT: "DEBIT",
  CREDIT: "CREDIT",
} as const;

export type JournalLineType = (typeof JOURNAL_LINE_TYPE)[keyof typeof JOURNAL_LINE_TYPE];

export const JOURNAL_REF_TYPE = {
  SALES_INVOICE: "SALES_INVOICE",
  PURCHASE_INVOICE: "PURCHASE_INVOICE",
  CUSTOMER_PAYMENT: "CUSTOMER_PAYMENT",
  SUPPLIER_PAYMENT: "SUPPLIER_PAYMENT",
  SALES_RETURN: "SALES_RETURN",
  PURCHASE_RETURN: "PURCHASE_RETURN",
  EXPENSE: "EXPENSE",
  MANUAL: "MANUAL",
  OPENING_BALANCE: "OPENING_BALANCE",
} as const;

export type JournalRefType = (typeof JOURNAL_REF_TYPE)[keyof typeof JOURNAL_REF_TYPE];

