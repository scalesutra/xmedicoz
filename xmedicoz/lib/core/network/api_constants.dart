import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static const String _mobileBaseUrl = 'http://134.195.138.153:5095/api/v1';
  static const String _webBaseUrl = '/api/v1';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      final isLocalDevelopment =
          host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';

      // Route local Flutter Web traffic through the development proxy. Direct
      // browser calls are blocked by the backend's same-origin resource policy.
      if (isLocalDevelopment) {
        final proxyHost = host == '0.0.0.0' ? 'localhost' : host;
        return 'http://$proxyHost:8088/api/v1';
      }

      return _webBaseUrl;
    }

    return _mobileBaseUrl;
  }

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  // Shop & Tenant Endpoints
  static const String shops = '/shops';
  static String shopMembers(String shopId) => '/shops/$shopId/members';

  // Master Data Endpoints
  static const String medicines = '/masters/medicines';
  static const String customers = '/masters/customers';
  static const String customerByPhone = '/masters/customers/phone';
  static const String suppliers = '/masters/suppliers';
  static const String categories = '/masters/categories';
  static const String manufacturers = '/masters/manufacturers';
  static const String units = '/masters/units';
  static const String taxes = '/masters/taxes';

  // Inventory & Batch Endpoints
  static const String batches = '/inventory/batches';
  static const String racks = '/inventory/racks';
  static String eligibleBatches(String medicineId) =>
      '/inventory/medicine/$medicineId/eligible-batches';
  static const String stockAdjustments = '/inventory/adjustments';
  static const String nearExpiry = '/inventory/near-expiry';
  static const String lowStock = '/inventory/low-stock';
  static const String stockAuditLedger = '/inventory/ledger';
  static const String stockValuation = '/inventory/valuation';
  static const String smartSearch = '/inventory/smart-search';
  static String substitutes(String medicineId) =>
      '/inventory/substitutes/$medicineId';
  static const String shortageDiary = '/inventory/shortage-diary';
  static const String shortageDiaryLog = '/inventory/shortage-diary/log';
  static String shortageDiaryById(String id) =>
      '/inventory/shortage-diary/$id';

  // Purchases & Supplier Inward Endpoints
  static const String purchases = '/purchases';
  static const String purchaseInvoices = '/purchases/invoices';
  static String purchaseById(String id) => '/purchases/$id';
  static const String purchasePayments = '/purchases/payments';
  static const String purchaseReturns = '/purchases/returns';
  static String purchaseReturnForInvoice(String id) => '/purchases/$id/return';
  static const String purchaseOrders = '/purchases/orders';

  // Fast Sales POS & Counter Billing Endpoints
  static const String sales = '/sales';
  static String saleById(String id) => '/sales/$id';
  static const String salesReturns = '/sales/returns';
  static String salesReturnForInvoice(String id) => '/sales/$id/return';

  // Customer CRM & Automated Refill Reminders Endpoints
  static String customerHistory(String id) => '/crm/customers/$id/history';
  static const String refills = '/crm/refills';
  static const String refillsDue = '/crm/refills/due';
  static String sendRefillReminder(String id) => '/crm/refills/$id/remind';
  static const String notifications = '/crm/notifications';
  static const String followUps = '/crm/follow-ups';
  static String followUpById(String id) => '/crm/follow-ups/$id';

  // Accounting, Financial Ledger & Banking Endpoints
  static const String accountingSeedAccounts = '/accounting/accounts/seed';
  static const String accountingAccounts = '/accounting/accounts';
  static const String accountingJournals = '/accounting/journals';
  static const String accountingTrialBalance =
      '/accounting/reports/trial-balance';
  static String accountingLedger(String accountId) =>
      '/accounting/ledger/$accountId';
  static const String accountingExpenses = '/accounting/expenses';
  static const String accountingReceivablesAging =
      '/accounting/receivables/aging';
  static const String accountingReceivablesPayment =
      '/accounting/receivables/payment';
  static const String accountingPayablesAging = '/accounting/payables/aging';
  static const String accountingDaybook = '/accounting/daybook';

  // OCR Document Recognition Engine
  static const String ocrScan = '/ocr/scan';

  // Request Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Dedicated OCR Heavy Processing Timeouts (OpenCV + Python Tesseract Engine)
  static const Duration ocrSendTimeout = Duration(seconds: 60);
  static const Duration ocrReceiveTimeout = Duration(seconds: 120);
}
