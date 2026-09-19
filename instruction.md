AI IDE Engineering Instructions — Medical Store Management System

1. Purpose

These instructions apply to every AI-assisted coding task in this repository.

The goal is to produce production-quality Node.js + TypeScript code that is:

Minimal

DRY

Type-safe

Secure

Scalable

Maintainable

Consistent with the existing architecture

Free from unnecessary abstractions and speculative code

The AI must prefer simple, reusable implementations over long generated code.

2. Non-Negotiable Rules

2.1 Do not over-engineer

Before writing code:

Inspect the existing repository.

Reuse existing utilities, types, services, middleware, constants and patterns.

Do not create a new abstraction if an existing abstraction already solves the problem.

Do not introduce a library unless there is a clear requirement.

Do not introduce microservices for a feature that can live in the modular monolith.

Do not add speculative features, fallbacks or compatibility layers.

If two lines of existing code can solve the problem, do not generate twenty lines.

3. DRY — Don't Repeat Yourself

Avoid duplication in:

Validation

Error handling

Response formatting

Database access

Permission checks

Constants

Configuration

Query building

Notification logic

Pagination

Cache handling

Logging

Bad:

if (status === "ACTIVE") { ... }
if (status === "ACTIVE") { ... }
if (status === "ACTIVE") { ... }

Prefer:

export const USER_STATUS = {
  ACTIVE: "ACTIVE",
  INACTIVE: "INACTIVE",
} as const;

Use the same source everywhere.

Do not duplicate business logic between controllers, services and workers.

4. Constants and Enums

Never scatter magic strings/numbers throughout the codebase.

Centralize reusable values.

Examples:

export const USER_STATUS = {
  ACTIVE: "ACTIVE",
  INACTIVE: "INACTIVE",
} as const;

export const PAYMENT_STATUS = {
  PAID: "PAID",
  PARTIAL: "PARTIAL",
  PENDING: "PENDING",
} as const;

Use constants for:

Statuses

Notification types

Queue names

Cache prefixes

Permission names

Error codes

Pagination limits

Rate-limit configuration

Business configuration where appropriate

Do not create constants for values used only once when doing so makes the code harder to understand.

5. Response Format

All API responses must use the project's single standard response structure.

Do NOT return different response formats from different modules.

Recommended shape:

{
  success: true,
  data: result,
  message: "Customer fetched successfully"
}

Error:

{
  success: false,
  error: {
    code: "CUSTOMER_NOT_FOUND",
    message: "Customer not found"
  }
}

The exact structure should be implemented once as shared infrastructure and reused everywhere.

Never expose internal responses

Do NOT return:

Stack traces

Database errors

Prisma/ORM errors

SQL errors

Internal exception messages

File paths

Redis errors

Keycloak internals

Provider credentials

Internal service names

Debug information

Raw exception objects

Bad:

return res.status(500).json({
  error: error.message,
});

Good:

logger.error({ err: error }, "Failed to create customer");

return res.status(500).json({
  success: false,
  error: {
    code: ERROR_CODES.INTERNAL_SERVER_ERROR,
    message: "Something went wrong",
  },
});

Internal details belong in secure logs, not API responses.

6. Error Handling

Use centralized error handling.

Do not write repetitive try/catch blocks in every controller unless recovery or additional context is actually required.

Preferred flow:

Route
  ↓
Controller
  ↓
Service
  ↓
Repository
  ↓
Error
  ↓
Central Error Handler
  ↓
Safe API Response

Every error should have:

Internal log information

Safe public error code

Safe public message

Appropriate HTTP status

Do not silently swallow errors.

Bad:

try {
  ...
} catch {
  return null;
}

This creates hidden failures.

7. Fallbacks

Do NOT automatically add fallbacks.

Fallbacks often hide bugs and create unwanted rework.

Examples of prohibited speculative fallbacks:

value ?? "unknown"

when value is required.

try {
  newImplementation();
} catch {
  oldImplementation();
}

without an explicit migration requirement.

if (!newField) {
  useOldField();
}

without a documented compatibility requirement.

Only implement a fallback when:

It is required by the business requirement, OR

It is required for backward compatibility, OR

The external dependency is explicitly documented as unreliable.

Every fallback must have a reason and preferably a test.

8. No Redundant Code

Before adding code, ask:

Can the existing implementation be reused or extended?

Do not create:

CustomerServiceV2
CustomerHelperNew
CustomerUtils2
NewCustomerRepository
GenericCustomerManager

just because the current code needs a small change.

Modify the existing abstraction if it remains conceptually correct.

Avoid generated comments explaining obvious code.

Avoid unnecessary wrapper functions.

Avoid unnecessary interfaces when TypeScript types already provide sufficient structure.

9. TypeScript Rules

Use strict TypeScript.

Required principles:

strict: true

Avoid any

Avoid unnecessary type assertions

Prefer explicit domain types

Validate external input at runtime

Do not trust request bodies

Do not trust query parameters

Do not trust external API responses

Bad:

const body: any = req.body;

Prefer validated input:

const input = CreateCustomerSchema.parse(req.body);

Use runtime validation with Zod or the project's chosen validator.

10. Node.js ESM

The project uses:

{
  "type": "module"
}

and TypeScript NodeNext module resolution.

Use ESM imports consistently.

Example:

import { customerService } from "./customer.service.js";

Do not mix CommonJS and ESM patterns.

Do not introduce require() unless the repository has an explicit compatibility requirement.

11. Layering

Use clear boundaries:

Route
 ↓
Controller
 ↓
Service / Use Case
 ↓
Repository / Data Access
 ↓
Database

Route

Defines endpoint and middleware.

Controller

Handles HTTP concerns only.

Service

Contains business rules.

Repository

Handles persistence.

Worker

Handles asynchronous jobs.

Do not put business logic directly inside routes.

Do not put SQL/database logic inside controllers.

Do not put HTTP response logic inside services.

12. Database

PostgreSQL is the source of truth for transactional data.

Rules:

Use transactions for atomic business operations.

Use foreign keys.

Use appropriate indexes.

Use unique constraints where required.

Avoid N+1 queries.

Use pagination for list APIs.

Never load unlimited records.

Avoid unnecessary SELECT fields.

Use database constraints to protect important invariants.

For financial/inventory operations:

BEGIN
  sale
  sale_items
  stock update
  invoice
  accounting entries
  payment
COMMIT

On critical failure:

ROLLBACK

Do not implement critical consistency using multiple independent requests.

13. Inventory Concurrency

Inventory is a critical resource.

Do not assume:

read stock
↓
check stock
↓
update stock

is safe under concurrent requests.

Use PostgreSQL transactions and appropriate locking/concurrency control.

Example:

Transaction
  ↓
Lock/validate stock
  ↓
Check available quantity
  ↓
Create sale
  ↓
Deduct stock
  ↓
Commit

The system must prevent overselling caused by race conditions.

14. Authentication

Keycloak is already deployed.

Do not build a second authentication system.

Authentication:

Client
 ↓
Keycloak
 ↓
Access Token
 ↓
Node.js API
 ↓
Token Verification

Authorization must still be enforced by the application.

Authentication means:

Who are you?

Authorization means:

What are you allowed to do?

Never confuse the two.

15. Authorization

Every protected operation must check permission.

Example:

sales.invoice.create
sales.invoice.read
sales.invoice.cancel

inventory.stock.read
inventory.stock.adjust

customer.read
customer.create
customer.update

Do not rely only on frontend hiding buttons.

The backend must enforce permissions.

16. Security

Always consider:

Authentication

Authorization

Input validation

SQL injection

XSS

CSRF where applicable

SSRF where applicable

Rate limiting

Secure headers

CORS

File-upload security

Sensitive-data exposure

Secrets management

Audit logging

Dependency vulnerabilities

Abuse of expensive endpoints

Never trust client-provided:

User ID

Role

Permission

Price

Discount

Tax

Stock quantity

Payment status

Invoice ownership

Business-critical values must be calculated/validated on the server.

17. Rate Limiting

Rate limiting must exist at API boundaries.

Use Redis-backed rate limiting when multiple application processes may run.

Different limits may apply to:

Login/authentication-related endpoints

Public endpoints

Normal API endpoints

Expensive report endpoints

Notification endpoints

File upload endpoints

Do not apply one unnecessarily aggressive global limit to every endpoint.

Rate limits should be configurable.

Never hardcode arbitrary values throughout controllers.

18. Caching

Use Redis only where caching provides measurable value.

Good candidates:

Frequently accessed master data

Read-heavy dashboard summaries

Configuration

Stable lookup data

Expensive repeated queries

Do NOT cache:

Highly transactional stock values without a carefully designed invalidation strategy

Payment state

Financial truth

Data where stale results could cause incorrect transactions

Database remains the source of truth.

Recommended pattern:

Request
 ↓
Check Redis
 ├── HIT → return cached data
 └── MISS
       ↓
    PostgreSQL
       ↓
    Set Redis
       ↓
    Return

Every cache needs:

Key convention

TTL

Invalidation strategy

Serialization strategy

Do not add caching without defining invalidation.

19. Cache Key Convention

Use centralized cache-key builders.

Example:

cacheKeys.customer(id)
cacheKeys.medicine(id)
cacheKeys.dashboard(date)

Avoid manually concatenating cache keys throughout the application.

Example:

customer:${id}

should not be repeated in ten files.

20. Background Jobs

Use BullMQ for work that does not need to block the HTTP request.

Good examples:

Customer reminders

Notifications

PDF generation

Large report generation

Email/SMS/WhatsApp delivery

Retryable external API operations

Do not move simple CRUD into queues without a reason.

Job handlers must be idempotent where retries are possible.

21. Notifications

Do not make sales/billing depend synchronously on WhatsApp/SMS/email provider availability.

Preferred:

Sale
 ↓
DB transaction
 ↓
Create notification job
 ↓
Return API response
 ↓
BullMQ worker
 ↓
Provider

External-provider failures must not corrupt the sale transaction.

Store delivery status and provider reference where available.

22. Idempotency

Use idempotency for operations where duplicate requests can cause financial or business damage.

Examples:

Payment creation

Invoice creation where retried requests are possible

External notification submission

Webhooks

Other externally retried operations

Do not blindly add idempotency everywhere.

Implement it where duplicate execution is dangerous.

23. External APIs

Treat external systems as untrusted dependencies.

For external calls:

Timeout requests

Validate responses

Handle expected failures

Log safe diagnostic information

Avoid leaking provider errors to clients

Use retries only for retryable errors

Use exponential backoff where appropriate

Prevent infinite retries

Make operations idempotent when possible

Do not add retries as a generic catch-all.

24. Logging

Use structured logging.

Log:

Request ID

User ID where appropriate

Endpoint

Duration

Error code

Safe business context

Job ID where relevant

Never log:

Passwords

Access tokens

Refresh tokens

API secrets

Full payment credentials

Sensitive customer information unnecessarily

25. API Performance

Avoid:

GET /customers
→ fetch everything

Use:

GET /customers?page=1&limit=20

Apply:

Pagination

Filtering

Sorting

Search

Appropriate indexes

Default limits must be configured centrally.

Never accept unlimited page sizes.

26. API Design

Use versioning:

/api/v1/...

Keep controllers thin.

Example:

router.post(
  "/customers",
  requirePermission(PERMISSIONS.CUSTOMER_CREATE),
  validate(CreateCustomerSchema),
  customerController.create,
);

Controller:

async create(req, res) {
  const customer = await customerService.create(req.validatedBody);
  return sendSuccess(res, customer);
}

Business logic stays in the service.

27. Financial and Accounting Rules

Never use floating-point arithmetic for monetary calculations where precision matters.

Prefer PostgreSQL numeric/decimal and an appropriate application-level decimal strategy.

Do not casually use:

const total = price * quantity;

for financial logic if precision can matter.

Centralize:

Tax calculations

Discounts

Totals

Rounding rules

Do not duplicate financial calculations in frontend and backend.

Frontend may display calculations, but backend is authoritative.

28. Auditability

Financial/inventory changes must be traceable.

Audit:

Who

What

Which entity

Before value where appropriate

After value where appropriate

When

Request/context information where appropriate

Do not allow ordinary users to modify audit records.

29. File Uploads

For prescriptions or documents, if required:

Validate file type

Validate file size

Generate safe storage names

Do not trust original filename

Store outside the application executable directory

Restrict access

Scan where infrastructure supports it

Do not expose private files directly without authorization

30. Testing

Every business-critical feature should include tests.

Priorities:

Unit tests

Pricing

GST

Discounts

Inventory calculations

Reminder calculations

Permission rules

Integration tests

Sales + inventory

Purchase + inventory

Payment + accounting

Customer history

Notifications

Security tests

Unauthorized access

Permission bypass

Invalid IDs

Invalid input

Rate-limit behavior

Regression tests

Before modifying existing behavior, inspect existing tests and preserve valid behavior.

31. Code Generation Rules for AI IDE

When asked to implement a feature:

Step 1

Inspect existing code.

Step 2

Identify reusable code.

Step 3

Identify the minimum files that need changes.

Step 4

Implement the smallest complete solution.

Step 5

Run/type-check/test the affected area.

Step 6

Fix only actual issues.

Do not generate an entire architecture for a small feature.

Do not rewrite unrelated files.

Do not rename existing code without a requirement.

Do not refactor unrelated modules during feature implementation.

32. Before Creating a New File

Ask:

Can this functionality belong in an existing module/file without reducing maintainability?

If yes, prefer the existing location.

Create a new file only when it creates a meaningful separation of responsibility.

33. Before Creating a New Utility

Ask:

Is this logic duplicated?

Will it be reused?

Does centralization improve correctness?

If the answer is no, keep it local.

Avoid giant utils.ts files.

Prefer domain-specific utilities:

pricing/
  pricing.utils.ts

inventory/
  stock.utils.ts

notifications/
  notification.utils.ts

34. Avoid Generic Abstractions

Do not create abstractions such as:

BaseService
BaseRepository
GenericCRUDService
UniversalManager
GenericProcessor

unless the repository genuinely needs them.

Generic abstractions created prematurely often make simple business code harder to understand.

35. Do Not Over-Comment

Comments should explain why, not what.

Bad:

// Increment stock by quantity
stock += quantity;

Good:

// Stock is updated only inside the purchase transaction
// so invoice and inventory cannot become inconsistent.

36. Configuration

Environment-specific values belong in configuration/environment variables.

Examples:

DATABASE_URL
REDIS_URL
KEYCLOAK_URL
KEYCLOAK_REALM
KEYCLOAK_CLIENT_ID
KEYCLOAK_CLIENT_SECRET
WHATSAPP_API_URL
WHATSAPP_API_KEY

Never commit secrets.

Do not read process.env throughout business logic.

Centralize configuration.

37. Dependency Management

Before adding a package:

Check whether an existing dependency already solves the problem.

Check whether Node.js/TypeScript already provides the capability.

Check package maintenance/security.

Add the dependency only if justified.

Do not add libraries for trivial two-line functionality.

38. Scalability Principle

Current scope is one medical store.

Therefore:

Keep the architecture modular.

Keep database design clean.

Use proper indexes.

Use transactions.

Use queues for asynchronous work.

Use Redis where justified.

Keep stateless API processes where possible.

Do not build distributed systems prematurely.

The system should be easy to scale later, but should not pay today's complexity cost for tomorrow's hypothetical traffic.

39. Performance Principle

Prefer:

Simple + indexed PostgreSQL query

over:

Redis + cache layer + background synchronization + complex abstraction

unless measurements or requirements justify the latter.

Correctness first, then optimize measured bottlenecks.

40. Frontend/Backend Responsibility

Frontend:

User experience

Form validation for UX

Display

Local state

Loading/error states

Backend:

Authentication

Authorization

Business validation

Pricing

GST

Inventory

Accounting

Payment state

Customer ownership/access

Final data validation

Never rely on frontend validation for security.

41. Business Transaction Principle

The core system chain is:

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

Changes affecting this chain must be evaluated for:

Database consistency

Transactions

Concurrency

Auditability

Notifications

Reporting impact

42. AI Must Not Guess Requirements

If a requirement is ambiguous and the decision changes:

Database schema

API contract

Accounting behavior

Security

Business workflow

External integration

STOP and ask for clarification.

Do not invent behavior.

If a safe implementation can be made without guessing, implement only the confirmed portion.

43. No Unrequested Refactoring

When implementing a requested feature:

DO:

Modify required code.

Fix directly related defects.

Add required tests.

DO NOT:

Rewrite the whole module.

Change architecture.

Rename unrelated functions.

Replace libraries.

Reformat unrelated files.

Add speculative abstractions.

44. Completion Checklist

Before considering a task complete:

Existing code inspected

Existing reusable code reused

No unnecessary files created

No duplicate business logic

No magic values unnecessarily introduced

Types are strict

Input is validated

Authorization is enforced

Internal errors are not exposed

Sensitive data is not logged

Rate limiting considered

Caching considered only where useful

Cache invalidation defined if cache is used

Transactions used where required

Concurrency considered for stock/financial operations

Background jobs used only where appropriate

External API failures handled safely

No speculative fallbacks

Tests added/updated

Typecheck passes

Lint passes

Existing tests pass

API documentation updated where required

45. Golden Rule

Write the least amount of code necessary to implement the complete requirement correctly.

Do not optimize for:

More files

More classes

More abstractions

More fallback logic

More comments

More dependencies

More architecture

Optimize for:

Correctness → Security → Maintainability → Performance → Scalability.