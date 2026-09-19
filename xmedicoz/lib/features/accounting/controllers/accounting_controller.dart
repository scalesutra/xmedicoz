import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/accounting_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../../inventory/controllers/master_data_controller.dart';
import '../../sales/controllers/sales_controller.dart';
import '../repositories/accounting_repository.dart';

class AccountingController extends GetxController {
  final AccountingRepository _repository = AccountingRepository();

  // Loading States
  final RxBool isLoadingDaybook = false.obs;
  final RxBool isLoadingAccounts = false.obs;
  final RxBool isLoadingExpenses = false.obs;
  final RxBool isLoadingJournals = false.obs;
  final RxBool isLoadingTrialBalance = false.obs;
  final RxBool isLoadingAging = false.obs;
  final RxBool isSubmitting = false.obs;

  // Reactive Data Holders
  final Rxn<DaybookStatementModel> daybook = Rxn<DaybookStatementModel>();
  final RxList<AccountModel> accounts = <AccountModel>[].obs;
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxList<JournalEntryModel> journalEntries = <JournalEntryModel>[].obs;
  final Rxn<TrialBalanceModel> trialBalance = Rxn<TrialBalanceModel>();
  final Rxn<AgingReportModel> receivablesAging = Rxn<AgingReportModel>();
  final Rxn<AgingReportModel> payablesAging = Rxn<AgingReportModel>();

  // Active Ledger Account Details (Drawer / General Ledger)
  final Rxn<GeneralLedgerModel> currentGeneralLedger = Rxn<GeneralLedgerModel>();

  // --------------------------------------------------------------------------
  // Reactive Liquidity Getters (Powering Dashboard Cockpit)
  // --------------------------------------------------------------------------
  double get cashBalance {
    if (daybook.value != null && daybook.value!.cash.closingBalance > 0) {
      return daybook.value!.cash.closingBalance;
    }
    final acc = accounts.firstWhereOrNull((a) => a.code == '1010');
    if (acc != null && acc.currentBalance > 0) return acc.currentBalance;

    if (Get.isRegistered<SalesController>()) {
      final cashSales = Get.find<SalesController>().salesInvoices.where((s) =>
          s.payments.any((p) => p.paymentMode.toUpperCase() == 'CASH')).fold(0.0, (sum, s) => sum + s.paidAmount);
      if (cashSales > 0) return cashSales;
    }

    return daybook.value?.cash.closingBalance ?? 0.0;
  }

  double get bankBalance {
    if (daybook.value != null && daybook.value!.bank.closingBalance > 0) {
      return daybook.value!.bank.closingBalance;
    }
    final acc = accounts.firstWhereOrNull((a) => a.code == '1020');
    if (acc != null && acc.currentBalance > 0) return acc.currentBalance;

    if (Get.isRegistered<SalesController>()) {
      final bankSales = Get.find<SalesController>().salesInvoices.where((s) =>
          s.payments.any((p) => p.paymentMode.toUpperCase() == 'UPI' || p.paymentMode.toUpperCase() == 'BANK' || p.paymentMode.toUpperCase() == 'CARD')).fold(0.0, (sum, s) => sum + s.paidAmount);
      if (bankSales > 0) return bankSales;
    }

    return daybook.value?.bank.closingBalance ?? 0.0;
  }

  double get totalLiquidity => cashBalance + bankBalance;

  double get cashNetMovement => daybook.value?.cash.netMovement ?? (cashBalance > 0 ? cashBalance : 0.0);
  double get bankNetMovement => daybook.value?.bank.netMovement ?? (bankBalance > 0 ? bankBalance : 0.0);

  AccountModel? get cashAccount => accounts.firstWhereOrNull((a) => a.code == '1010');
  AccountModel? get bankAccount => accounts.firstWhereOrNull((a) => a.code == '1020');

  List<AccountModel> get expenseAccounts =>
      accounts.where((a) => a.type == 'EXPENSE').toList();

  @override
  void onInit() {
    super.onInit();
    if (StorageService.hasToken()) {
      loadAccountingCore();
    }
  }

  /// Initial load for dashboard and accounting cockpit
  Future<void> loadAccountingCore() async {
    await Future.wait([
      fetchDaybook(),
      fetchAccounts(),
      fetchReceivablesAging(),
      fetchPayablesAging(),
    ]);

    // If no accounts exist yet on backend, auto-seed standard 24 chart of accounts
    if (accounts.isEmpty) {
      await seedAccounts(silent: true);
    }
  }

  /// 1. Fetch Daily Cash & Bank Reconciliation Daybook
  Future<void> fetchDaybook({String? date}) async {
    try {
      isLoadingDaybook.value = true;
      final result = await _repository.getDaybookStatement(date: date);
      daybook.value = result;
    } catch (e) {
      debugPrint('Error fetching daybook: $e');
    } finally {
      isLoadingDaybook.value = false;
    }
  }

  /// 2. Fetch Chart of Accounts (COA)
  Future<void> fetchAccounts() async {
    try {
      isLoadingAccounts.value = true;
      final list = await _repository.getAccounts();
      accounts.assignAll(list);
    } catch (e) {
      debugPrint('Error fetching chart of accounts: $e');
    } finally {
      isLoadingAccounts.value = false;
    }
  }

  /// 3. Seed Standard 24 Pharmacy Accounts
  Future<bool> seedAccounts({bool silent = false}) async {
    try {
      isSubmitting.value = true;
      final res = await _repository.seedStandardAccounts();
      await fetchAccounts();
      await fetchDaybook();

      if (!silent) {
        UniqueSnackbar.showSuccess(
          null,
          title: 'Chart of Accounts Seeded',
          message:
              res['message'] ??
              'Standard pharmacy 24-account structure initialized',
        );
      }
      return true;
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to seed accounts';
      if (!silent) {
        UniqueSnackbar.showError(
          null,
          title: 'Seed Failed',
          message: msg,
        );
      }
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 4. Record Store Operating Expense
  Future<bool> recordExpense({
    required String accountId,
    required String paidFromAccountId,
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    String? payee,
    String? description,
  }) async {
    try {
      isSubmitting.value = true;
      final expense = await _repository.recordExpense(
        accountId: accountId,
        paidFromAccountId: paidFromAccountId,
        amount: amount,
        paymentMode: paymentMode,
        referenceNumber: referenceNumber,
        payee: payee,
        description: description,
      );

      expenses.insert(0, expense);

      // Refresh Daybook & Accounts to reflect cash deduction immediately
      await Future.wait([
        fetchDaybook(),
        fetchAccounts(),
      ]);

      UniqueSnackbar.showSuccess(
        null,
        title: 'Expense Recorded',
        message:
            '₹${expense.amount.toStringAsFixed(0)} paid via ${expense.paymentMode}. Ref: ${expense.expenseNumber}',
      );
      return true;
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to record expense';
      UniqueSnackbar.showError(
        null,
        title: 'Expense Error',
        message: msg,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 5. Customer Debt Payment Receipt
  Future<bool> recordCustomerDebtPayment({
    required String customerId,
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      isSubmitting.value = true;
      final res = await _repository.recordCustomerDebtPayment(
        customerId: customerId,
        amount: amount,
        paymentMode: paymentMode,
        referenceNumber: referenceNumber,
        notes: notes,
      );

      // Refresh Cash/Bank Daybook & Accounts
      await Future.wait([
        fetchDaybook(),
        fetchAccounts(),
        fetchReceivablesAging(),
      ]);

      if (Get.isRegistered<MasterDataController>()) {
        Get.find<MasterDataController>().fetchCustomers();
      }
      if (Get.isRegistered<SalesController>()) {
        Get.find<SalesController>().fetchSales(resetPage: true);
      }

      UniqueSnackbar.showSuccess(
        null,
        title: 'Payment Recorded',
        message: res['message'] ?? 'Customer debt payment credited to cash drawer & receivables',
      );
      return true;
    } catch (e) {
      String msg = e is ApiException ? e.message : 'Payment recording failed';
      if (msg.contains('Customer does not have any outstanding debt')) {
        msg = 'Server par is customer ka koi baki udhar nahi hai (Purana bill server par already settled recorded hai).';
      }
      UniqueSnackbar.showError(
        null,
        title: 'Payment Error',
        message: msg,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 6. Fetch Dynamic Trial Balance
  Future<TrialBalanceModel?> fetchTrialBalance() async {
    try {
      isLoadingTrialBalance.value = true;
      final tb = await _repository.getTrialBalance();
      trialBalance.value = tb;
      return tb;
    } catch (e) {
      debugPrint('Error calculating trial balance: $e');
      return null;
    } finally {
      isLoadingTrialBalance.value = false;
    }
  }

  /// 7. Fetch General Ledger Statement for an Account
  Future<GeneralLedgerModel?> fetchGeneralLedger(
    String accountId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      isSubmitting.value = true;
      final ledger = await _repository.getGeneralLedger(
        accountId,
        startDate: startDate,
        endDate: endDate,
      );
      currentGeneralLedger.value = ledger;
      return ledger;
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Error loading general ledger';
      UniqueSnackbar.showError(
        null,
        title: 'Ledger Error',
        message: msg,
      );
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 8. Fetch Receivables Aging
  Future<void> fetchReceivablesAging() async {
    try {
      isLoadingAging.value = true;
      final ar = await _repository.getReceivablesAging();
      receivablesAging.value = ar;
    } catch (e) {
      debugPrint('Error fetching AR aging: $e');
    } finally {
      isLoadingAging.value = false;
    }
  }

  /// 9. Fetch Payables Aging
  Future<void> fetchPayablesAging() async {
    try {
      isLoadingAging.value = true;
      final ap = await _repository.getPayablesAging();
      payablesAging.value = ap;
    } catch (e) {
      debugPrint('Error fetching AP aging: $e');
    } finally {
      isLoadingAging.value = false;
    }
  }

  /// 10. Fetch Operating Expenses List
  Future<void> fetchExpenses({int page = 1, int limit = 20}) async {
    try {
      isLoadingExpenses.value = true;
      final res = await _repository.getExpenses(page: page, limit: limit);
      final List<ExpenseModel> items = res['items'] ?? [];
      expenses.assignAll(items);
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
    } finally {
      isLoadingExpenses.value = false;
    }
  }

  /// 11. Fetch Journal Entries
  Future<void> fetchJournalEntries({int page = 1, int limit = 20}) async {
    try {
      isLoadingJournals.value = true;
      final res = await _repository.getJournalEntries(page: page, limit: limit);
      final List<JournalEntryModel> items = res['items'] ?? [];
      journalEntries.assignAll(items);
    } catch (e) {
      debugPrint('Error fetching journal entries: $e');
    } finally {
      isLoadingJournals.value = false;
    }
  }

  /// Completely clear all in-memory accounting data on logout
  void clearData() {
    daybook.value = null;
    accounts.clear();
    expenses.clear();
    journalEntries.clear();
    trialBalance.value = null;
    receivablesAging.value = null;
    payablesAging.value = null;
    currentGeneralLedger.value = null;
  }
}
