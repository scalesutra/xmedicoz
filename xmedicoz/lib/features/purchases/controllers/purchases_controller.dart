import 'package:get/get.dart';

import '../../../core/models/purchase_models.dart';
import '../../../core/network/api_exception.dart';
import '../../inventory/controllers/batch_controller.dart';
import '../../inventory/controllers/master_data_controller.dart';
import '../../../core/controllers/ledger_controller.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../../ocr/controllers/ocr_controller.dart';
import '../repositories/purchases_repository.dart';

class PurchasesController extends GetxController {
  final PurchasesRepository _repository;

  PurchasesController({PurchasesRepository? repository})
    : _repository = repository ?? PurchasesRepository();

  // --------------------------------------------------------------------------
  // State: Purchase Invoices
  // --------------------------------------------------------------------------
  final RxList<PurchaseInvoiceModel> purchases = <PurchaseInvoiceModel>[].obs;
  final Rxn<PurchaseInvoiceModel> selectedInvoice = Rxn<PurchaseInvoiceModel>();
  final RxBool isLoadingPurchases = false.obs;
  final RxBool isLoadingDetails = false.obs;

  final RxString searchQuery = ''.obs;
  final RxString paymentStatusFilter =
      ''.obs; // '', 'UNPAID', 'PARTIALLY_PAID', 'PAID'
  final RxString supplierFilter = ''.obs;

  final RxInt page = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalCount = 0.obs;

  // --------------------------------------------------------------------------
  // State: Purchase Orders
  // --------------------------------------------------------------------------
  final RxList<PurchaseOrderModel> purchaseOrders = <PurchaseOrderModel>[].obs;
  final RxBool isLoadingOrders = false.obs;

  // Action status
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (StorageService.hasToken()) {
      fetchPurchases();
      fetchOrders();
    }
  }

  // --------------------------------------------------------------------------
  // Computed Properties
  // --------------------------------------------------------------------------
  double get totalPurchasesValue =>
      purchases.fold(0.0, (sum, item) => sum + item.totalAmount);

  double get totalBalanceDue =>
      purchases.fold(0.0, (sum, item) => sum + item.balanceAmount);

  double get totalPaidAmount =>
      purchases.fold(0.0, (sum, item) => sum + item.paidAmount);

  int get unpaidInvoicesCount =>
      purchases.where((p) => p.paymentStatus != 'PAID').length;

  // --------------------------------------------------------------------------
  // 1. Fetch Purchase Invoices
  // --------------------------------------------------------------------------
  Future<void> fetchPurchases({bool resetPage = false}) async {
    if (resetPage) page.value = 1;
    isLoadingPurchases.value = true;
    try {
      final res = await _repository.getPurchaseInvoices(
        page: page.value,
        limit: 20,
        search: searchQuery.value.trim().isEmpty
            ? null
            : searchQuery.value.trim(),
        paymentStatus: paymentStatusFilter.value.isEmpty
            ? null
            : paymentStatusFilter.value,
        supplierId: supplierFilter.value.isEmpty ? null : supplierFilter.value,
      );

      final List<PurchaseInvoiceModel> items =
          res['items'] as List<PurchaseInvoiceModel>;
      final pagination = res['pagination'];

      if (page.value == 1) {
        purchases.assignAll(items);
      } else {
        purchases.addAll(items);
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
          title: 'Purchases Error',
          message: e.message,
        );
      }
    } catch (_) {
    } finally {
      isLoadingPurchases.value = false;
    }
  }

  // --------------------------------------------------------------------------
  // 2. Fetch Single Invoice Details
  // --------------------------------------------------------------------------
  Future<void> fetchInvoiceDetails(String id) async {
    isLoadingDetails.value = true;
    try {
      selectedInvoice.value = await _repository.getPurchaseInvoiceById(id);
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
  // 3. Create Purchase Invoice (Ingest Stock) — legacy UUID-based flow
  // --------------------------------------------------------------------------
  Future<PurchaseInvoiceModel?> createPurchaseInvoice(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final invoice = await _repository.createPurchaseInvoice(data);

      UniqueSnackbar.showSuccess(
        null,
        title: 'Stock Ingested Successfully',
        message:
            'Bill ${invoice.invoiceNumber} recorded. Batches updated & stock ledger audited.',
      );

      // 1. Refresh Purchases
      fetchPurchases(resetPage: true);

      // 2. Refresh Batches, Valuation, and Low Stock in BatchController
      if (Get.isRegistered<BatchController>()) {
        Get.find<BatchController>().refreshAll();
      }

      // 3. Refresh Suppliers in MasterDataController (outstanding balance updated!)
      if (Get.isRegistered<MasterDataController>()) {
        Get.find<MasterDataController>().fetchSuppliers();
      }

      return invoice;
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'Purchase Failed',
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
  // 3b. Create Purchase Invoice — OCR Simplified Flow (POST /purchases)
  //     Supplier & medicines auto-created by backend. No UUIDs needed.
  // --------------------------------------------------------------------------
  Future<PurchaseInvoiceModel?> createOcrPurchaseInvoice({
    required Map<String, dynamic> supplier,
    required String invoiceNumber,
    required String invoiceDate,
    required int paymentTermsDays,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    isSubmitting.value = true;
    try {
      final invoice = await _repository.createOcrPurchaseInvoice(
        supplier: supplier,
        invoiceNumber: invoiceNumber,
        invoiceDate: invoiceDate,
        paymentTermsDays: paymentTermsDays,
        items: items,
        notes: notes,
      );

      UniqueSnackbar.showSuccess(
        null,
        title: '✅ Purchase Saved!',
        message:
            'Invoice ${invoice.invoiceNumber} recorded. Supplier, medicines & stock all updated.',
      );

      fetchPurchases(resetPage: true);

      if (Get.isRegistered<BatchController>()) {
        Get.find<BatchController>().refreshAll();
      }
      if (Get.isRegistered<MasterDataController>()) {
        Get.find<MasterDataController>().fetchSuppliers();
      }

      if (Get.isRegistered<OcrController>()) {
        Get.find<OcrController>().clear();
      }

      return invoice;
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'Purchase Failed',
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
  // 4. Record Supplier Settlement Payment
  // --------------------------------------------------------------------------
  Future<bool> recordPayment({
    required String supplierId,
    required String purchaseInvoiceId,
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
  }) async {
    isSubmitting.value = true;
    try {
      final payment = await _repository.recordSupplierPayment(
        supplierId: supplierId,
        purchaseInvoiceId: purchaseInvoiceId,
        amount: amount,
        paymentMode: paymentMode,
        referenceNumber: referenceNumber,
        notes: notes,
      );

      UniqueSnackbar.showSuccess(
        null,
        title: 'Payment Recorded',
        message:
            'Payment ${payment.paymentNumber} of ₹${amount.toStringAsFixed(2)} confirmed.',
      );

      // Refresh invoice list and details
      fetchPurchases();
      fetchInvoiceDetails(purchaseInvoiceId);

      // Refresh Suppliers in MasterDataController
      if (Get.isRegistered<MasterDataController>()) {
        Get.find<MasterDataController>().fetchSuppliers();
      }

      return true;
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'Payment Failed',
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

  // --------------------------------------------------------------------------
  // 5. Process Purchase Return (Stock Deduction)
  // --------------------------------------------------------------------------
  Future<bool> processReturn({
    required String supplierId,
    String? purchaseInvoiceId,
    required String reason,
    required List<Map<String, dynamic>> items,
  }) async {
    isSubmitting.value = true;
    try {
      final pr = await _repository.processPurchaseReturn(
        supplierId: supplierId,
        purchaseInvoiceId: purchaseInvoiceId,
        reason: reason,
        items: items,
      );

      UniqueSnackbar.showSuccess(
        null,
        title: 'Return Confirmed',
        message:
            'Purchase Return ${pr.returnNumber} processed. Stock deducted from batch.',
      );

      // Refresh list and details
      fetchPurchases();
      if (purchaseInvoiceId != null) {
        fetchInvoiceDetails(purchaseInvoiceId);
      }

      // Refresh batches & valuation
      if (Get.isRegistered<BatchController>()) {
        Get.find<BatchController>().refreshAll();
      }

      // Refresh suppliers
      if (Get.isRegistered<MasterDataController>()) {
        Get.find<MasterDataController>().fetchSuppliers();
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

  // --------------------------------------------------------------------------
  // 6. Fetch Purchase Orders
  // --------------------------------------------------------------------------
  Future<void> fetchOrders() async {
    isLoadingOrders.value = true;
    try {
      final res = await _repository.getPurchaseOrders(page: 1, limit: 50);
      purchaseOrders.assignAll(res['items'] as List<PurchaseOrderModel>);
    } on ApiException catch (e) {
      if (StorageService.hasToken()) {
        UniqueSnackbar.showError(
          null,
          title: 'Orders Error',
          message: e.message,
        );
      }
    } catch (_) {
    } finally {
      isLoadingOrders.value = false;
    }
  }

  // --------------------------------------------------------------------------
  // 7. Create Purchase Order
  // --------------------------------------------------------------------------
  Future<bool> createOrder({
    required String supplierId,
    required String expectedDate,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    isSubmitting.value = true;
    try {
      final order = await _repository.createPurchaseOrder(
        supplierId: supplierId,
        expectedDate: expectedDate,
        notes: notes,
        items: items,
      );

      UniqueSnackbar.showSuccess(
        null,
        title: 'Purchase Order Placed',
        message: 'PO ${order.orderNumber} successfully created.',
      );

      fetchOrders();
      return true;
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'PO Creation Failed',
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

  /// Completely clear all in-memory purchases data on logout
  void clearData() {
    purchases.clear();
    purchaseOrders.clear();
    selectedInvoice.value = null;
    searchQuery.value = '';
    paymentStatusFilter.value = '';
    supplierFilter.value = '';
    page.value = 1;
    totalPages.value = 1;
    totalCount.value = 0;
  }
}
