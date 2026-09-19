# Zero-Mock Data & Fallback Architecture Policy

> **Authoritative Mandate**: Strict prohibition of synthetic, hardcoded, or mock data across the entire Ledger Pharmacy codebase. All states must be backed by real APIs, real local persistence, or standardized, robust fallback states (empty states, skeletons, offline sync queues).

---

## 1. Core Principles (Zero-Mock Rule)

1. **Absolute Ban on Mock / Synthetic Seeds**:
   - No hardcoded customer lists, dummy medicines, fake sales invoices, or artificial ledger balances.
   - Controllers and repositories must initialize with empty reactive collections:
     ```dart
     final RxList<MedicineModel> medicines = <MedicineModel>[].obs;
     final RxList<CustomerModel> customers = <CustomerModel>[].obs;
     final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
     ```
   - Never inject `MockDataService` or fake arrays when an API response is empty or errors out.

2. **Clean State Truth**:
   - If a chemist opens a fresh account or has zero sales today, the UI must accurately reflect **0 records**, **₹0.00 revenue**, and an inviting **Empty State**, not fabricated demo sales.

3. **Production Data Integrity**:
   - All write actions (sales, purchases, vouchers, customer additions) must save to the local SQLite/Hive/Cache storage and sync via genuine REST/GraphQL API endpoints.

---

## 2. Standardized Fallback System

When real data is unavailable (first run, offline, network delay, or error), the application must adhere to the following fallback matrix:

| Scenario | Strict Fallback Behavior | Forbidden Anti-Pattern |
| :--- | :--- | :--- |
| **Empty Data (0 Records)** | Display branded `EmptyStateWidget` with clear icon, explanation message, and a primary CTA (e.g. "Create First Invoice"). | Populating dummy/demo transactions or sample medicines. |
| **Loading State** | Cyber shimmer skeleton or `CircularProgressIndicator(color: AppColors.primaryEmerald)`. | Showing hardcoded placeholder items that mimic real data. |
| **Network / Offline** | Read from local persistent cache (`StorageService` / SQLite / Hive). If cache is empty, show offline banner with retry button. | Fabricating mock responses in HTTP catch blocks. |
| **API Error (5xx / 4xx)** | Catch `ApiException`, log via telemetry, and show non-blocking `UniqueSnackbar.showError` or inline retry widget. | Silently replacing errors with fallback dummy items. |
| **Missing / Null Model Fields** | Safe null-coalescing defaults: `field ?? ''`, `amount ?? 0.0`, `date ?? DateTime.now()`, `list ?? []`. | Crashing with null-pointer or showing `null` string in UI. |

---

## 3. UI Fallback Component Specifications

### 3.1 Empty State Pattern
Every list view and detail sheet must implement an empty state when collection `.isEmpty`:
```dart
if (controller.transactions.isEmpty) {
  return Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.primaryEmerald.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, size: 36.sp, color: AppColors.primaryEmerald),
          ),
          SizedBox(height: 14.h),
          Text('No Rx Transactions Yet', style: AppTypography.h3.copyWith(fontSize: 16.sp)),
          SizedBox(height: 6.h),
          Text(
            'New fast counter sales and purchase inward bills will automatically appear here.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: 16.h),
          AppButton(
            text: 'Create First Sale',
            onPressed: () => openFastSaleSheet(),
          ),
        ],
      ),
    ),
  );
}
```

### 3.2 Safe Null Defaults in Models & Vouchers
- **Numeric Fields**: Never allow `null` for financial calculations. Default to `0.0` or `0`.
- **String Fields**:
  - Customer Name fallback: `partyName.isNotEmpty ? partyName : 'Walk-in Retail Patient'`
  - Doctor Name fallback: `doctorName?.isNotEmpty == true ? doctorName! : 'Self / Counter'`
  - License/GSTIN fallback: `gstin?.isNotEmpty == true ? gstin! : 'Unregistered / Consumer'`
- **Dates**:
  - Invoice Date fallback: `invoiceDate ?? DateTime.now()`

---

## 4. Current Codebase Audit & Action Plan

### 4.1 Identified Mock Remnants to Remove
1. **`lib/core/models/models.dart`**:
   - `MockDataService`: Contains fallback `shops = [ShopModel(...)]`.
   - **Target**: Replace with `StorageService.getShops()` or real API fetch. If no shop exists, redirect to shop onboarding (`AddShopScreen`).
2. **`lib/features/auth/add_shop_screen.dart`**:
   - Remove direct insertion to `MockDataService.shops`.
   - Save directly to `StorageService` and call API.
3. **`lib/core/widgets/shop_switcher_sheet.dart`**:
   - Replace `MockDataService.shops` with `controller.shops` or `StorageService.getShops()`.
4. **`lib/core/controllers/ledger_controller.dart`**:
   - Remove `MockDataService.shops` fallback in `onInit()`.

### 4.2 Implementation Rules for Agents
- When adding any new screen, modal, or service, **NEVER** write `// Fallback mock data` or seed dummy objects.
- Always provide an `Obx` with:
  1. `isLoading.value` -> Skeleton/loader.
  2. `data.isEmpty` -> Branded empty state.
  3. `data.isNotEmpty` -> Real item list.
