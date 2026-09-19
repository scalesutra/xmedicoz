Medical Store Management & CRM System — PRD

Version: 1.0
Status: Development Reference
Product: Single-location Medical Store Management System
Reference: MargBooks workflows/screens supplied by the team
Backend: Node.js + TypeScript + Node.js ESM
Authentication: Keycloak (already deployed)
Database: PostgreSQL
Cache/Jobs: Redis + BullMQ
Architecture: Modular monolith

1. Product Definition

Build an internal web application for one medical store at one physical location.

Core areas:

Authentication and users

Roles and permissions

Dashboard

Master data

Customers and CRM

Permanent customers

Customer purchase/medicine history

Medicine and batch inventory

Expiry and low-stock management

Suppliers and purchases

Sales and billing

Payments

Accounting

Banking

Customer reminders and notifications

Reports

Audit logs

Settings/utilities

Explicit exclusions

The current scope does not include:

Multiple branches

Branch transfers

Multiple companies

Franchise management

Customer mobile application

Customer login/portal

Multi-tenant SaaS infrastructure

Online marketplace/store

Do not implement excluded features unless a new requirement explicitly adds them.

2. Product Goals

Digitize daily medical-store operations.

Make billing fast and reliable.

Maintain accurate batch-wise medicine inventory.

Track expiry and low-stock medicines.

Manage suppliers and purchases.

Maintain customer and permanent-customer history.

Support customer follow-ups and refill reminders.

Send notifications without requiring a customer app.

Keep sales, inventory, payment and accounting records consistent.

Provide operational and financial reports.

Provide strong authorization and auditability.

3. Users and Roles

Admin

Full access.

Pharmacist

Typical access to customers, medicines, inventory, sales, purchases, prescriptions if enabled, and relevant reports.

Cashier

Typical access to customers, sales, billing, payments and returns.

Staff

Custom permissions.

Permissions must be configurable; authorization must not depend only on hardcoded role names.

4. Authentication — Keycloak

Keycloak is already deployed and is the identity provider.

Do not build a separate password authentication system in Node.js.

Keycloak responsibilities

Authentication

Password management

Login/logout

Access/refresh tokens

Sessions

User identity

Realm/client configuration

Role mapping where appropriate

Application responsibilities

Verify Keycloak tokens

Enforce application permissions

Enforce business authorization

Authorize access to resources

Record audit information

Flow:

User -> Frontend -> Keycloak -> Access Token -> Node.js API -> Token Verification -> Permission Check -> Business Service -> PostgreSQL

5. Technology Stack

Backend

Node.js

TypeScript

Node.js ESM ("type": "module")

module: NodeNext

REST API

Express or Fastify

Do not introduce NestJS.

Data

PostgreSQL

Prisma, Drizzle or pg based on team decision

Redis

BullMQ

Infrastructure

Keycloak

Docker

Nginx

S3-compatible object storage where required

Quality

Zod or equivalent runtime validation

Pino structured logging

Vitest/Jest

OpenAPI/Swagger

6. Backend Architecture

Use a modular monolith initially.

Frontend
   |
Nginx / HTTPS
   |
Node.js + TypeScript
   |
   +-- Auth
   +-- Users
   +-- Customers
   +-- CRM
   +-- Medicines
   +-- Inventory
   +-- Suppliers
   +-- Purchases
   +-- Sales
   +-- Invoices
   +-- Payments
   +-- Accounting
   +-- Banking
   +-- Notifications
   +-- Reports
   +-- Audit
   |
PostgreSQL

Redis
  |
BullMQ
  |
Background Workers

Do not create microservices merely for theoretical scalability.

7. Suggested Backend Structure

src/
├── server.ts
├── app.ts
├── config/
├── modules/
│   ├── auth/
│   ├── users/
│   ├── roles/
│   ├── permissions/
│   ├── dashboard/
│   ├── masters/
│   │   ├── medicines/
│   │   ├── categories/
│   │   ├── manufacturers/
│   │   ├── units/
│   │   ├── taxes/
│   │   ├── discounts/
│   │   └── accounts/
│   ├── customers/
│   ├── crm/
│   ├── inventory/
│   ├── suppliers/
│   ├── purchases/
│   ├── sales/
│   ├── invoices/
│   ├── payments/
│   ├── accounting/
│   ├── banking/
│   ├── notifications/
│   ├── reports/
│   └── audit/
├── infrastructure/
│   ├── keycloak/
│   ├── database/
│   ├── redis/
│   ├── queue/
│   └── storage/
├── middleware/
├── utils/
└── types/

8. Dashboard

Show:

Today's sales

Monthly sales

Invoice count

Sales returns

Today's/monthly purchases

Supplier outstanding

Total medicines

Low-stock medicines

Near-expiry batches

Expired batches

Stock value

Total customers

Permanent customers

New customers

Pending follow-ups

Pending reminders

Receivable

Payable

Cash/bank balance

Expenses

Gross profit where supported

9. Master Management

Core masters:

Medicine

Category

Manufacturer

Unit

Tax

Discount

Customer

Supplier

Account Group

Ledger Account

Additional masters should be added only when confirmed.

10. Medicine Master

Possible fields:

Medicine name

Generic name

Brand

Manufacturer

Category

Dosage form

Strength

Unit

HSN/SAC

GST rate

MRP

Selling price

Reorder level

Prescription-required flag

Active/inactive status

11. Batch Management

A medicine can have multiple batches.

Each batch tracks:

Batch number

Medicine ID

Supplier

Purchase reference

Manufacturing date

Expiry date

Purchase price

MRP

Selling price

Quantity

Status

Expired batches must not be sold according to the configured business rule.

12. Inventory

Operations:

Stock in

Stock out

Stock adjustment

Stock return

Batch stock

Current stock

Low-stock alerts

Near-expiry alerts

Expired-stock report

Stock ledger

Stock valuation

Do not rely only on a mutable stock number. Maintain stock transactions.

Example:

Opening        +100
Purchase        +50
Sale            -20
Return           +5
Adjustment       -2
--------------------
Available       133

Stock-changing operations must be transactionally safe.

13. Expiry Management

Identify:

Expired medicines

Near-expiry medicines

Warning periods should be configurable, such as 90/60/30/7 days.

Final rules for selling expired or near-expiry stock must be confirmed by the client.

14. Supplier Management

Supplier fields:

Name

Contact

GSTIN

Address

Payment terms

Purchase history

Outstanding amount

Status

15. Purchase Management

Workflow:

Supplier -> Purchase Order -> Goods Received -> Batch Created/Updated -> Inventory Increased -> Purchase Invoice -> Supplier Payable -> Payment

Features:

Purchase order

Purchase bill/invoice

Purchase items

Purchase return

Purchase draft

Stock receiving

Supplier payment

Purchase history

Supplier outstanding

16. Sales Management

Workflow:

Customer -> Medicine -> Batch -> Quantity -> Price -> Discount -> Tax -> Invoice -> Payment

Before completing a sale, validate:

User permission

Medicine existence

Batch existence

Batch sale eligibility

Available quantity

Price/tax rules

Successful sale should:

Create sale and items

Deduct stock

Create invoice

Create accounting entries where applicable

Record payment

Update customer history

Create required reminder/notification jobs

17. Billing

Invoice contains:

Invoice number

Date

Customer

Items

Medicine

Batch

Quantity

MRP

Selling price

Discount

Tax

Total

Payment mode

Payment status

Payment status:

Paid

Partially paid

Pending

Invoice numbers must remain unique under concurrent requests.

18. Sales Return

Workflow:

Original Invoice -> Select Item -> Validate Return -> Return Quantity -> Inventory Adjustment -> Refund/Credit -> Accounting Adjustment

Return-to-stock rules must be confirmed for medicines.

19. Customer CRM

CRM is transaction-connected.

CRM
├── Customer Profile
├── Permanent Customers
├── Purchase History
├── Medicine History
├── Follow-ups
├── Notes
├── Reminders
└── Notifications

20. Customer Profile

Fields may include:

Name

Mobile

Email

Address

Date of birth if required

Customer type

Permanent customer flag

Notification preference

Created date

Status

Possible types:

Walk-in

Regular

Permanent

Final classification rules must be confirmed.

21. Permanent Customers

A customer may be marked permanent/regular.

Track:

Purchase history

Frequently purchased medicines

Last purchase

Medicine history

Payment history

Follow-ups

Notification preferences

Reminder schedule

There is no customer application or customer login.

22. Customer Medicine History

When a sale is associated with a customer, maintain medicine purchase history.

The history should be derived from actual sales wherever possible rather than manually duplicating data.

23. Medicine Refill Reminder

Possible flow:

Previous Purchase -> Medicine Duration/Reminder Rule -> Expected Refill Date -> Reminder Job -> Notification

Duration can come from:

Staff-entered duration

Prescription duration

Medicine-level default

Customer-specific recurring rule

Do not assume duration from purchase history without a confirmed business rule.

24. Customer Follow-up

Fields:

Customer

Subject

Notes

Assigned user

Due date

Priority

Status

Statuses:

Pending

In progress

Completed

Cancelled

25. Notifications

No customer app.

Possible channels:

WhatsApp

SMS

Email

Possible notification types:

Medicine refill reminder

Order ready

Invoice

Payment reminder

Medicine available

Follow-up

General notification

Provider/API credentials must be supplied or approved by the client.

26. Notification Architecture

Notifications must be asynchronous.

Business API
  |
Database Transaction
  |
Create Notification Job
  |
BullMQ
  |
Notification Worker
  +-- WhatsApp
  +-- SMS
  +-- Email

Statuses:

Pending

Processing

Sent

Failed

Cancelled

Store provider message IDs where available.

27. Accounting

Accounting depth must follow confirmed client requirements.

Potential areas:

Chart of accounts

Account groups

Ledger

Journal

Receivables

Payables

Income

Expenses

Payments

Receipts

Credit note

Debit note

Accounting entries should follow double-entry principles and be balanced.

Example sale:

Customer Receivable    DR 10,000
    Sales Revenue          CR 10,000

Payment:

Cash/Bank              DR 10,000
    Customer Receivable    CR 10,000

Actual accounting rules must be validated by the client's accountant.

28. GST / Tax

Potential requirements:

GST rates

CGST

SGST

IGST

HSN/SAC

Tax calculation

Tax-inclusive/exclusive pricing if required

GST invoice

Credit/debit notes

GST reports

Do not invent tax rules; confirm the required workflow.

29. Banking

Potential features:

Bank accounts

Cash account

Payments

Receipts

Cheque management

Bank reconciliation

Online payment records

Only implement confirmed requirements.

30. Expense Management

Potential categories:

Rent

Electricity

Salary

Transport

Software

Miscellaneous

Fields:

Amount

Category

Payment method

Date

Description

Attachment if required

Created by

31. Reports

Sales

Daily sales

Monthly sales

Product-wise sales

Customer-wise sales

Payment-wise sales

Sales returns

Purchase

Supplier-wise purchase

Purchase history

Purchase returns

Supplier outstanding

Inventory

Current stock

Batch-wise stock

Low stock

Near expiry

Expired stock

Stock movement

Stock valuation

CRM

Customer list

Permanent customers

Purchase history

Medicine history

Follow-ups

Reminders

Notification history

Accounting

Ledger

Receivables

Payables

Expenses

Profit/Loss if required

Trial balance if required

32. Audit Logs

Sensitive actions must be auditable.

Fields:

id
user_id
action
entity_type
entity_id
old_value
new_value
ip_address
user_agent
created_at

Track at minimum:

Invoice creation/modification/cancellation

Payment changes

Stock adjustments

Medicine price changes

Medicine deactivation

User changes

Permission changes

Accounting changes

33. Transaction Integrity

Use PostgreSQL transactions for operations that must be atomic.

Example:

BEGIN

Create Sale
Create Sale Items
Update Stock
Create Invoice
Create Accounting Entries
Create Payment

COMMIT

On critical failure:

ROLLBACK

Do not allow an invoice to exist while its stock/accounting update silently failed.

Use suitable locking/concurrency control for stock and invoice-number generation.

34. API Design

Base URL:

/api/v1

Examples:

GET/POST       /customers
GET/PATCH      /customers/:id
GET            /customers/:id/history

GET/POST       /medicines
GET/PATCH      /medicines/:id

GET            /inventory
GET            /inventory/batches
POST           /inventory/adjustments

GET/POST       /suppliers

GET/POST       /purchases
POST           /purchases/:id/return

GET/POST       /sales
GET            /sales/:id
POST           /sales/:id/return

GET            /invoices
GET            /invoices/:id

GET/POST       /payments

GET            /crm/customers
POST           /crm/followups
POST           /crm/reminders

GET/POST       /notifications

GET            /reports/*

Routes/controllers should remain thin. Business rules belong in services/use-cases.

35. Core Database Entities

users
roles
permissions

customers
customer_medicines
customer_followups

medicines
categories
manufacturers
units
medicine_batches

suppliers

purchase_orders
purchase_items
purchase_invoices
purchase_returns

sales
sale_items
invoices
invoice_items
sales_returns

payments
expenses

stock_transactions
stock_balances

ledger_accounts
account_groups
journal_entries
journal_entry_lines

notifications
notification_templates

audit_logs

36. Critical Relationships

Customer
  |
  +-- Sales
  |     |
  |     +-- Sale Items
  |            |
  |            +-- Medicine Batch
  |
  +-- Customer Medicine History
  +-- Follow-ups
  +-- Reminders
          |
          +-- Notifications

Medicine
  |
  +-- Batches
        |
        +-- Stock Transactions
        +-- Sales
        +-- Purchases

37. Security Requirements

Minimum:

HTTPS

Keycloak authentication

JWT/access-token validation

RBAC

Fine-grained permission checks

Input validation

Rate limiting

CORS configuration

Secure HTTP headers

Parameterized SQL/ORM

Secure file-upload validation

Audit logs

Database backups

Secret management

No secrets in Git

No sensitive data in ordinary logs

Never trust IDs sent by the frontend. Every resource operation must verify authorization.

38. Scalability

The current requirement is one store. Prioritize correctness and maintainability.

Use:

PostgreSQL indexes

Connection pooling

Pagination

Efficient queries

Redis only where justified

BullMQ for background work

Async notification processing

Batched/streamed large reports

Database transactions

Do not introduce microservices solely for theoretical scalability.

39. Backup and Recovery

Production needs:

Automated PostgreSQL backups

Retention policy

Backup monitoring

Recovery procedure

Periodic restore testing

40. Observability

Implement:

Structured logs

Request/correlation IDs

Error tracking

Health endpoint

Readiness endpoint

Database monitoring

Queue monitoring

Notification failure monitoring

Suggested:
GET /health
GET /ready

41. Development Phases

Phase 1 — Foundation

Node.js + TypeScript + ESM

Keycloak integration

User/role/permission system

PostgreSQL

Logging

Error handling

Validation

Audit foundation

Docker

Phase 2 — Masters

Medicines

Categories

Manufacturers

Units

Tax

Discounts

Customers

Suppliers

Accounts

Phase 3 — Inventory

Batches

Stock

Stock ledger

Expiry

Low stock

Stock adjustment

Phase 4 — Purchase

Suppliers

Purchase orders

Purchase bills

Stock receiving

Purchase returns

Supplier payments

Phase 5 — Sales/Billing

Customers

Sales

Batch selection

Invoice

Payments

Sales returns

Stock deduction

Accounting integration

Phase 6 — CRM

Permanent customers

Purchase history

Medicine history

Follow-ups

Reminder rules

Notification templates

Notification queue

Phase 7 — Accounting/Banking

Ledger

Journal

Receivables

Payables

Expenses

Banking

Reconciliation if required

Phase 8 — Reports/Advanced

Reports

Dashboard analytics

Import/export

PDF

Barcode

Advanced notifications

Other confirmed MargBooks-like utilities

42. MVP

MVP should contain:

Keycloak Authentication
Users / Roles / Permissions

Medicine Master
Customer Master
Supplier Master

Batch Inventory
Expiry
Low Stock

Purchase
Purchase Return

Sales
Billing
Payment
Sales Return

Customer CRM
Permanent Customer
Purchase History
Medicine History

Reminder
Notification

Basic Dashboard
Basic Reports

Audit Logs
Backup

Accounting, banking, GST, advanced reporting and integrations should follow confirmed client scope and priority.

43. Golden Business Workflow

Supplier
  ↓
Purchase
  ↓
Medicine Batch
  ↓
Inventory
  ↓
Customer
  ↓
Sale
  ↓
Invoice
  ↓
Payment
  ↓
Stock Deduction
  ↓
Customer Purchase History
  ↓
Permanent Customer
  ↓
Medicine Reminder
  ↓
Notification

Every step must remain consistent.

44. Client Decisions Required Before Development

Confirm:

Exact CRM screens/functions.

Which MargBooks modules are actually required.

Prescription upload/storage.

Prescription-required medicine workflow.

GST requirements.

Accounting depth.

Credit/udhaar sales.

WhatsApp/SMS/email provider.

Automatic vs manually approved reminders.

How refill duration is determined.

Customer notification consent/opt-out.

Return-to-stock rules.

Barcode requirements.

Invoice/receipt printing.

Barcode scanner/printer hardware.

Existing data import.

Required report formats.

Backup/retention requirements.

45. Engineering Principle

Build around business transactions, not screens.

The central chain is:

Medicine
   ↓
Batch
   ↓
Stock
   ↓
Purchase / Sale
   ↓
Invoice
   ↓
Payment
   ↓
Accounting
   ↓
Customer History
   ↓
CRM
   ↓
Reminder
   ↓
Notification

Correctness across this chain is more important than adding superficial features.

46. Final Engineering Direction

Use:

Node.js + TypeScript + Node ESM + Express + PostgreSQL + Redis + BullMQ + Keycloak + Docker/Nginx.

Use a modular monolith.

Current business s