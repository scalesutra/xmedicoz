-- ============================================================
-- MedicalCRM: Clear all business data
-- KEEPS: users, roles, permissions, user_roles, role_permissions
-- DELETES: everything else (medicines, inventory, sales,
--          purchases, customers, suppliers, accounting, crm, etc.)
-- ============================================================

BEGIN;

-- 1. Accounting
TRUNCATE TABLE
  daybook_records,
  journal_lines,
  expenses,
  journal_entries,
  accounts,
  account_groups
CASCADE;

-- 2. CRM
TRUNCATE TABLE
  notification_logs,
  customer_follow_ups,
  customer_refill_rules
CASCADE;

-- 3. Sales
TRUNCATE TABLE
  sales_return_items,
  sales_returns,
  sales_payments,
  sales_invoice_items,
  sales_invoices
CASCADE;

-- 4. Purchases
TRUNCATE TABLE
  purchase_return_items,
  purchase_returns,
  supplier_payments,
  purchase_invoice_items,
  purchase_invoices,
  purchase_order_items,
  purchase_orders
CASCADE;

-- 5. Inventory
TRUNCATE TABLE
  stock_transactions,
  medicine_batches
CASCADE;

-- 6. Masters
TRUNCATE TABLE
  customers,
  suppliers,
  medicines,
  categories,
  manufacturers,
  units,
  taxes
CASCADE;

-- 7. Audit logs (optional — comment out if you want to keep them)
TRUNCATE TABLE audit_logs CASCADE;

COMMIT;

SELECT 'All business data cleared successfully. Login credentials preserved.' AS status;
