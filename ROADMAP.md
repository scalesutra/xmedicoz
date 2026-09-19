# Medical Store Management & CRM System — Master Multi-Phase Roadmap

**System Architecture:** Layered Monolith (Node.js + TypeScript strict ESM, Prisma ORM, PostgreSQL, Redis DB 3, Keycloak isolated realm `medicalcrm`)  
**Host Port:** `5095`  
**Base URL:** `http://134.195.138.153:5095/api/v1`

---

## Roadmap Overview (Phases 1 to 8)

| Phase | Module | Status | Highlights |
|---|---|---|---|
| **Phase 1** | Foundation & Multi-Modal Auth | **COMPLETED** ✅ | Isolated PG (`medicalcrm`), Redis DB 3 (`mcrm:*`), Keycloak realm, Email/Phone + Password & 4-Digit OTP, User Profile, RBAC |
| **Phase 2** | Master Data Management | **COMPLETED** ✅ | Categories, Manufacturers, Units, Taxes (Redis cached), Medicines (search/pagination), Customers (POS mobile lookup), Suppliers |
| **Phase 3** | Inventory & Batch Management | **COMPLETED** ✅ | Multi-Batch tracking, FEFO counter sale eligibility, ACID row-locking adjustments (`SELECT ... FOR UPDATE`), Immutable stock ledger, Expiry & low stock alerts, Real-time valuation |
| **Phase 4** | Suppliers & Purchase Management | **COMPLETED** ✅ | Purchase Orders, Purchase Bills / Goods Receipt, Atomic batch ingestion, Supplier ledger & outstanding tracking, Purchase Returns, Supplier Payments |
| **Phase 5** | Fast Sales POS & Counter Billing | **COMPLETED** ✅ | Sequential invoice generation, Concurrency-safe batch deductions (`SELECT ... FOR UPDATE`), Multi-payment methods (Cash, UPI, Card, Credit), Sales Returns, Prescription tracking |
| **Phase 6** | Customer CRM & Automated Refill Reminders | **COMPLETED** ✅ | Permanent customer accounts, Medicine purchase history, Refill rules engine, BullMQ automated background workers, WhatsApp/SMS refill alerts |
| **Phase 7** | Accounting, Ledger & Banking | **COMPLETED** ✅ | Double-entry balanced journal entries, Chart of Accounts, Customer Receivables, Supplier Payables, Expense tracking, Cash/Bank daybook |
| **Phase 8** | Advanced Reports & Utilities | **READY TO EXECUTE** 🚀 | Sales/Purchase/Tax GST reports, Barcode generation & scanning, PDF invoice generation, Dashboard analytics & MargBooks-style utilities |

---

## Detailed Breakdown by Phase

### Phase 1: Foundation, Infrastructure & Multi-Modal Authentication ✅ [COMPLETED]
- Isolated PostgreSQL database `medicalcrm` and user `medicalcrm_user`.
- Redis isolated namespace (`DB index 3`, key prefix `mcrm:`).
- Dedicated Keycloak realm `medicalcrm` with confidential API client `medicalcrm-api` and public client `medicalcrm-web`.
- Multi-modal authentication:
  - Email or Phone + Password login
  - 4-digit OTP login & password reset via Redis cache (`mcrm:otp:*`)
  - Remote JWKS verification with token caching
  - Profile retrieval (`GET /profile`), profile updates (`PATCH /profile`), password updates (`POST /change-password`)
- RBAC middleware (`Admin`, `Pharmacist`, `Cashier`, `Staff`).

### Phase 2: Master Data Management ✅ [COMPLETED]
- **System Lookups:** Categories, Manufacturers, Units (Strip, Bottle, Box, etc.), Tax slabs (GST 0%, 5%, 12%, 18%, 28%) with high-performance Redis cache.
- **Medicine Master:** Generic name, brand, dosage form (Tablet, Capsule, Syrup, etc.), strength, HSN code, GST rate, standard pricing, reorder level, prescription required flag.
- **Customer Master:** Mobile number normalization, customer type (`RETAIL`, `WHOLESALE`, `INSTITUTIONAL`), permanent customer flag, credit limits, instant POS search by mobile (`/phone/:mobile`).
- **Supplier Master:** GSTIN, Drug License number (DL), contact person, mobile, payment credit terms.

### Phase 3: Inventory & Batch Management ✅ [COMPLETED]
- **Multi-Batch Management (`MedicineBatch`):** Batch number, manufacturing date, expiry date, MRP, purchase rate, selling price, current quantity.
- **FEFO Counter Sales Eligibility:** `GET /inventory/medicine/:id/eligible-batches` sorting by First Expired, First Out, strictly excluding expired or zero-stock batches.
- **Concurrency-Safe Stock Adjustments:** Raw SQL row-level locking (`SELECT ... FOR UPDATE`) inside an ACID transaction preventing overselling or race conditions.
- **Immutable Stock Ledger (`StockTransaction`):** Full audit trail tracking every single inventory movement (`PURCHASE`, `SALE`, `RETURN_IN`, `RETURN_OUT`, `ADJUSTMENT_ADD`, `ADJUSTMENT_SUB`, `DAMAGE`) with `quantityDelta` and `balanceAfter`.
- **Expiry & Low Stock Alerts:** Real-time near-expiry detection (`GET /inventory/near-expiry?days=90`) and automated low-stock alerts (`totalStock <= reorderLevel`).
- **Real-Time Stock Valuation:** Computes aggregate cost value, retail value, MRP value, and gross margin percentages.

### Phase 4: Suppliers & Purchase Management 🚀 [READY TO EXECUTE]
- **Purchase Orders (`PurchaseOrder`, `PurchaseOrderItem`):** Track procurement requests to suppliers with status (`DRAFT`, `PLACED`, `PARTIALLY_RECEIVED`, `COMPLETED`, `CANCELLED`).
- **Purchase Bills / Goods Receipt (`PurchaseInvoice`, `PurchaseInvoiceItem`):**
  - Record supplier bill number, invoice date, due date, items, discounts, and GST taxes.
  - **Atomic Stock Receiving:** Automatically matches or creates `MedicineBatch`, increases available stock, creates `StockTransaction` (type: `PURCHASE`), and updates medicine purchase/selling rates.
  - Updates supplier `outstandingBalance` by net bill amount.
- **Purchase Returns (`PurchaseReturn`, `PurchaseReturnItem`):**
  - Return damaged, excess, or recalled stock to suppliers with `SELECT ... FOR UPDATE` batch locking.
  - Deducts batch stock, records `StockTransaction` (type: `RETURN_OUT`), and deducts supplier outstanding balance.
- **Supplier Payments (`SupplierPayment`):**
  - Record payments against purchase invoices or account balances (Cash, Bank Transfer, UPI, Cheque).
  - Updates invoice `paidAmount`, `balanceAmount`, `paymentStatus` (`UNPAID`, `PARTIALLY_PAID`, `PAID`), and reduces supplier outstanding debt.

### Phase 5: Fast Sales POS & Counter Billing ⏳ [UPCOMING]
- **Sequential Invoice Numbering:** Race-condition-proof invoice sequence generator (e.g., `INV-2026-00001`).
- **Fast POS Checkout:** Customer selection, barcode/medicine search, batch selection (FEFO prioritized), quantity, discount, tax calculation.
- **ACID Batch Deduction:** Row-level locking ensures concurrent cashiers never oversell the same batch.
- **Multiple Payment Modes:** Split tender (Cash, UPI, Card, Customer Credit).
- **Doctor & Prescription Tracking:** Doctor name, registration number, prescription image/file.
- **Sales Return / Credit Note:** Returning medicines back into batch stock with `StockTransaction` (type: `RETURN_IN`).

### Phase 6: Customer CRM & Automated Refill Reminders ⏳ [UPCOMING]
- **Permanent Customer Profile:** Full chronological medicine purchase history, total lifetime spend, visit frequency.
- **Smart Refill Engine:** Calculates refill due date based on dosage duration (e.g. 30 days of antihypertensives).
- **Background Worker (BullMQ + Redis):** Scheduled cron job scanning for upcoming refill dates.
- **Multi-Channel Notifications:** WhatsApp / SMS template generation for automatic refill reminders.

### Phase 7: Accounting, Financial Ledger & Banking ✅ [COMPLETED]
- **Double-Entry Bookkeeping:** Standard 5-Group Chart of Accounts (Assets, Liabilities, Equity, Revenue, Expenses) with 24 default pharmacy accounts.
- **Strict Invariant Validation:** Automated validation ensuring `SUM(Debit) === SUM(Credit)` on every posted journal entry (`JE-YYYY-NNNNN`).
- **Store Operating Expenses (`Expense`):** Recorded with automated balanced journal entry generation (`DR Expense` | `CR Cash/Bank`) and atomic ledger balance adjustments.
- **Trial Balance & General Ledger:** Real-time ledger statement with running balance and dynamically balanced Trial Balance check.
- **Accounts Receivable & Accounts Payable Aging:** 0-30, 31-60, 61-90, 90+ days aging reports with Customer Debt Settlement / Payment Receipts.
- **Cash & Bank Daybook:** Inflow/outflow tracking and physical cash drawer reconciliation.

### Phase 8: Advanced Reports, Dashboards & Utilities 🚀 [READY TO EXECUTE]
- **Comprehensive Reports:** Sales summary, Purchase summary, GST GSTR-1 & GSTR-2 reports, Expiry loss report, Profit & Loss.
- **Executive Dashboard:** Today's sales, month-to-date revenue, gross profit, inventory valuation, active low-stock & expiry alerts.
- **Utilities:** Barcode label printing, PDF invoice thermal/A4 printing, and bulk data import/export.
