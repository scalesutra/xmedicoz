import 'package:dio/dio.dart';
import '../../../core/models/accounting_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';

class AccountingRepository {
  final ApiClient _apiClient = ApiClient();

  /// 1. Seed Standard Pharmacy Accounts (24 Accounts)
  /// POST /accounting/accounts/seed
  Future<Map<String, dynamic>> seedStandardAccounts() async {
    try {
      final response = await _apiClient.post(ApiConstants.accountingSeedAccounts);
      if (response is Map<String, dynamic>) {
        return response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
      }
      return {};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 2. List All Accounts (COA)
  /// GET /accounting/accounts?type=...&groupId=...
  Future<List<AccountModel>> getAccounts({String? type, String? groupId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (groupId != null && groupId.isNotEmpty) queryParams['groupId'] = groupId;

      final response = await _apiClient.get(
        ApiConstants.accountingAccounts,
        queryParameters: queryParams,
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        final rawList = response['data'];
        if (rawList is List) {
          return rawList.map((json) => AccountModel.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 3. Create Custom Ledger Account
  /// POST /accounting/accounts
  Future<AccountModel> createAccount({
    required String code,
    required String name,
    required String type,
    required String groupId,
    String? description,
  }) async {
    try {
      final body = {
        'code': code,
        'name': name,
        'type': type,
        'groupId': groupId,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      final response = await _apiClient.post(
        ApiConstants.accountingAccounts,
        data: body,
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        return AccountModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: response?['message'] ?? 'Failed to create ledger account');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 4. Post Balanced Double-Entry Journal Entry
  /// POST /accounting/journals
  Future<JournalEntryModel> postJournalEntry({
    required String referenceType,
    required String narration,
    required List<Map<String, dynamic>> lines,
  }) async {
    try {
      final body = {
        'referenceType': referenceType,
        'narration': narration,
        'lines': lines,
      };

      final response = await _apiClient.post(
        ApiConstants.accountingJournals,
        data: body,
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        return JournalEntryModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: response?['message'] ?? 'Failed to post journal entry');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 5. List Journal Entries
  /// GET /accounting/journals?page=1&limit=20&referenceType=...
  Future<Map<String, dynamic>> getJournalEntries({
    int page = 1,
    int limit = 20,
    String? referenceType,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (referenceType != null && referenceType.isNotEmpty) {
        queryParams['referenceType'] = referenceType;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }

      final response = await _apiClient.get(
        ApiConstants.accountingJournals,
        queryParameters: queryParams,
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final List items = data['items'] ?? [];
        final entries = items.map((json) => JournalEntryModel.fromJson(json as Map<String, dynamic>)).toList();
        final pagination = data['pagination'] ?? {};
        return {
          'items': entries,
          'total': pagination['total'] ?? entries.length,
          'page': pagination['page'] ?? page,
          'totalPages': pagination['totalPages'] ?? 1,
        };
      }
      return {'items': <JournalEntryModel>[], 'total': 0, 'page': 1, 'totalPages': 1};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 6. Dynamic Trial Balance
  /// GET /accounting/reports/trial-balance
  Future<TrialBalanceModel> getTrialBalance() async {
    try {
      final response = await _apiClient.get(ApiConstants.accountingTrialBalance);

      if (response is Map<String, dynamic> && response['data'] != null) {
        return TrialBalanceModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: response?['message'] ?? 'Failed to calculate trial balance');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 7. General Ledger Statement for a specific account
  /// GET /accounting/ledger/:accountId
  Future<GeneralLedgerModel> getGeneralLedger(
    String accountId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;

      final response = await _apiClient.get(
        ApiConstants.accountingLedger(accountId),
        queryParameters: queryParams,
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        return GeneralLedgerModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: response?['message'] ?? 'Failed to load general ledger statement');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 8. Record Store Operating Expense
  /// POST /accounting/expenses
  Future<ExpenseModel> recordExpense({
    required String accountId,
    required String paidFromAccountId,
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    String? payee,
    String? description,
  }) async {
    try {
      final body = {
        'accountId': accountId,
        'paidFromAccountId': paidFromAccountId,
        'amount': amount,
        'paymentMode': paymentMode,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'referenceNumber': referenceNumber,
        if (payee != null && payee.isNotEmpty) 'payee': payee,
        if (description != null && description.isNotEmpty)
          'description': description,
      };

      final response = await _apiClient.post(
        ApiConstants.accountingExpenses,
        data: body,
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        return ExpenseModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: response?['message'] ?? 'Failed to record expense');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 9. List Operating Expenses
  /// GET /accounting/expenses?page=1&limit=20
  Future<Map<String, dynamic>> getExpenses({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.accountingExpenses,
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final List items = data['items'] ?? [];
        final expenses = items.map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>)).toList();
        final pagination = data['pagination'] ?? {};
        return {
          'items': expenses,
          'total': pagination['total'] ?? expenses.length,
          'page': pagination['page'] ?? page,
          'totalPages': pagination['totalPages'] ?? 1,
        };
      }
      return {'items': <ExpenseModel>[], 'total': 0, 'page': 1, 'totalPages': 1};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 10. Accounts Receivable (AR) Aging
  /// GET /accounting/receivables/aging
  Future<AgingReportModel> getReceivablesAging() async {
    try {
      final response = await _apiClient.get(ApiConstants.accountingReceivablesAging);

      if (response is Map<String, dynamic> && response['data'] != null) {
        return AgingReportModel.fromJsonReceivables(response['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: response?['message'] ?? 'Failed to retrieve AR aging report');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 11. Customer Debt Payment Receipt
  /// POST /accounting/receivables/payment
  Future<Map<String, dynamic>> recordCustomerDebtPayment({
    required String customerId,
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
  }) async {
    try {
      final body = {
        'customerId': customerId,
        'amount': amount,
        'paymentMode': paymentMode,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'referenceNumber': referenceNumber,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _apiClient.post(
        ApiConstants.accountingReceivablesPayment,
        data: body,
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
      throw ApiException(message: response?['message'] ?? 'Failed to record customer debt payment');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 12. Accounts Payable (AP) Aging
  /// GET /accounting/payables/aging
  Future<AgingReportModel> getPayablesAging() async {
    try {
      final response = await _apiClient.get(ApiConstants.accountingPayablesAging);

      if (response is Map<String, dynamic> && response['data'] != null) {
        return AgingReportModel.fromJsonPayables(response['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: response?['message'] ?? 'Failed to retrieve AP aging report');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 13. Daily Cash & Bank Reconciliation Daybook
  /// GET /accounting/daybook?date=YYYY-MM-DD
  Future<DaybookStatementModel> getDaybookStatement({String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null && date.isNotEmpty) queryParams['date'] = date;

      final response = await _apiClient.get(
        ApiConstants.accountingDaybook,
        queryParameters: queryParams,
      );

      if (response is Map<String, dynamic> && response['data'] != null) {
        return DaybookStatementModel.fromJson(response['data'] as Map<String, dynamic>);
      }
      throw ApiException(message: response?['message'] ?? 'Failed to load daybook reconciliation');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
