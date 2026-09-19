import 'package:get/get.dart';

import '../../../core/models/sales_models.dart';
import '../../../core/network/api_exception.dart';
import '../../inventory/controllers/batch_controller.dart';
import '../../inventory/controllers/master_data_controller.dart';
import '../../../core/controllers/ledger_controller.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../repositories/sales_repository.dart';

class SalesController extends GetxController {
  final SalesRepository _repository;

  SalesController({SalesRepository? repository})
    : _repository = repository ?? SalesRepository();

  // --------------------------------------------------------------------------
  // State: Sales Invoices
  // --------------------------------------------------------------------------
  final RxList<SalesInvoiceModel> salesInvoices = <SalesInvoiceModel>[].obs;
  final Rxn<SalesInvoiceModel> selectedInvoice = Rxn<SalesInvoiceModel>();
  final RxBool isLoadingSales = false.obs;
  final RxBool isLoadingDetails = false.obs;

  final RxString searchQuery = ''.obs;
  final RxString paymentStatusFilter =
      ''.obs; // '', 'PAID', 'PARTIALLY_PAID', 'UNPAID'
  final RxString customerIdFilter = ''.obs;

  final RxInt page = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalCount = 0.obs;

  // POS Checkout state
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (StorageService.hasToken()) {
      fetchSales();
    }
  }

  // --------------------------------------------------------------------------
  // Computed Metrics
  // --------------------------------------------------------------------------
  double get totalSalesValue =>
      salesInvoices.fold(0.0, (sum, item) => sum + item.totalAmount);

  double get totalPaidValue =>
      salesInvoices.fold(0.0, (sum, item) => sum + item.paidAmount);

  double get totalBalanceValue => salesInvoices.fold(
    0.0,
    (sum, item) =>
        sum +
        (item.balanceAmount > 0
            ? item.balanceAmount
            : (item.isCreditSale || item.isUnpaid ? item.totalAmount : 0.0)),
  );

  int get paidCount => salesInvoices.where((s) => s.isPaid).length;

  int get unpaidCount =>
      salesInvoices.where((s) => s.isUnpaid || s.isPartiallyPaid).length;

  List<SalesInvoiceModel> get filteredSalesInvoices {
    final filter = paymentStatusFilter.value;
    if (filter.isEmpty) return salesInvoices;
    if (filter == 'PAID') {
      return salesInvoices.where((s) => s.isPaid).toList();
    }
    if (filter == 'UNPAID') {
      return salesInvoices.where((s) => s.isUnpaid).toList();
    }
    if (filter == 'PARTIALLY_PAID') {
      return salesInvoices.where((s) => s.isPartiallyPaid).toList();
    }
    return salesInvoices;
  }

  // --------------------------------------------------------------------------
  // 1. Fetch Sales Invoices
  // --------------------------------------------------------------------------
  Future<void> fetchSales({bool resetPage = false}) async {
    if (resetPage) page.value = 1;
    isLoadingSales.value = true;
    try {
      final res = await _repository.getSalesInvoices(
        page: page.value,
        limit: 20,
        search: searchQuery.value.trim().isEmpty
            ? null
            : searchQuery.value.trim(),
        paymentStatus: null, // Keep server query broad so client can accurately filter Udhar vs Paid
        customerId: customerIdFilter.value.isEmpty
            ? null
            : customerIdFilter.value,
      );

      final List<SalesInvoiceModel> rawItems =
          res['items'] as List<SalesInvoiceModel>;
      final pagination = res['pagination'];

      // Also enrich with payment details to accurately catch CREDIT mode
      final List<SalesInvoiceModel> items = await Future.wait(
        rawItems.map((item) async {
          if (item.payments.isNotEmpty) return item;
          try {
            final detail = await _repository.getSalesInvoiceById(item.id);
            return detail;
          } catch (_) {
            return item;
          }
        }),
      );

      if (page.value == 1) {
        salesInvoices.assignAll(items);
      } else {
        salesInvoices.addAll(items);
      }
      totalPages.value = pagination.totalPages;
      totalCount.value = pagination.total;

      if (Get.isRegistered<LedgerController>()) {
        Get.find<LedgerController>().syncLiveTransactions();
      }
    } on ApiException catch (e) {
      if (StorageService.hasToken()) {
        UniqueSnackbar.showError(
          null,
          title: 'Sales Error',
          message: e.message,
        );
      }
    } catch (_) {
    } finally {
      isLoadingSales.value = false;
    }
  }

  // --------------------------------------------------------------------------
  // 2. Fetch Single Invoice Details
  // --------------------------------------------------------------------------
  Future<void> fetchInvoiceDetails(String id) async {
    isLoadingDetails.value = true;
    try {
      selectedInvoice.value = await _repository.getSalesInvoiceById(id);
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'Invoice Error',
        message: e.message,
      );
    } catch (_) {
    } finally {
      isLoadingDetails.value = false;
    }
  }

  // --------------------------------------------------------------------------
  // 3. Counter POS Checkout (POST /sales)
  // --------------------------------------------------------------------------
  Future<SalesInvoiceModel?> checkoutPOS(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final invoice = await _repository.createSalesInvoice(data);

      UniqueSnackbar.showSuccess(
        null,
        title: 'Invoice Generated (${invoice.invoiceNumber})',
        message: 'Stock deducted atomically from batch. Thermal receipt ready.',
      );

      // 1. Refresh Sales History
      fetchSales(resetPage: true);

      // 2. Refresh Batches, Valuation, and Low Stock (stock was deducted!)
      if (Get.isRegistered<BatchController>()) {
        Get.find<BatchController>().refreshAll();
      }

      // 3. Refresh Customers (if credit / partial credit was given, balance changed)
      if (Get.isRegistered<MasterDataController>()) {
        Get.find<MasterDataController>().fetchCustomers();
      }

      return invoice;
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'Checkout Failed',
        message: e.message,
      );
      return null;
    } catch (e) {
      UniqueSnackbar.showError(null, title: 'Error', message: e.toString());
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  // --------------------------------------------------------------------------
  // 4. Process Sales Return (Credit Note & Restock)
  // --------------------------------------------------------------------------
  Future<bool> processReturn({
    required String salesInvoiceId,
    required String refundMode, // "CASH", "UPI", "CREDIT_NOTE"
    required String reason,
    required List<Map<String, dynamic>> items,
  }) async {
    isSubmitting.value = true;
    try {
      final ret = await _repository.processSalesReturn(
        salesInvoiceId: salesInvoiceId,
        refundMode: refundMode,
        reason: reason,
        items: items,
      );

      UniqueSnackbar.showSuccess(
        null,
        title: 'Credit Note ${ret.returnNumber} Created',
        message:
            'Sales return confirmed. Stock restored back into candidate batches.',
      );

      // Refresh sales list and details
      fetchSales();
      fetchInvoiceDetails(salesInvoiceId);

      // Refresh Batches in BatchController
      if (Get.isRegistered<BatchController>()) {
        Get.find<BatchController>().refreshAll();
      }

      // Refresh Customers
      if (Get.isRegistered<MasterDataController>()) {
        Get.find<MasterDataController>().fetchCustomers();
      }

      return true;
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'Return Failed',
        message: e.message,
      );
      return false;
    } catch (e) {
      UniqueSnackbar.showError(null, title: 'Error', message: e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Completely clear all in-memory sales data on logout
  void clearData() {
    salesInvoices.clear();
    selectedInvoice.value = null;
    searchQuery.value = '';
    paymentStatusFilter.value = '';
    customerIdFilter.value = '';
    page.value = 1;
    totalPages.value = 1;
    totalCount.value = 0;
  }
}
