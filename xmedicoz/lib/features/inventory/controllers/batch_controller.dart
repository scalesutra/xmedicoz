import 'package:get/get.dart';

import '../../../core/models/batch_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../repositories/batch_repository.dart';

class BatchController extends GetxController {
  final BatchRepository _repository;

  BatchController({BatchRepository? repository})
    : _repository = repository ?? BatchRepository();

  // --------------------------------------------------------------------------
  // State: Batches
  // --------------------------------------------------------------------------
  final RxList<BatchModel> batches = <BatchModel>[].obs;
  final RxBool isLoadingBatches = false.obs;
  final RxString batchSearchQuery = ''.obs;
  final RxString batchStatusFilter =
      ''.obs; // ACTIVE, NEAR_EXPIRY, EXPIRED, QUARANTINED
  final RxBool inStockOnlyFilter = false.obs;
  final RxInt batchPage = 1.obs;
  final RxInt batchTotalPages = 1.obs;
  final RxInt batchTotalCount = 0.obs;

  // --------------------------------------------------------------------------
  // State: Near Expiry
  // --------------------------------------------------------------------------
  final RxList<NearExpiryBatchModel> nearExpiryList =
      <NearExpiryBatchModel>[].obs;
  final RxBool isLoadingNearExpiry = false.obs;
  final RxInt nearExpiryDays = 90.obs; // 30, 60, 90, 180

  // --------------------------------------------------------------------------
  // State: Low Stock Alerts
  // --------------------------------------------------------------------------
  final RxList<LowStockMedicineModel> lowStockList =
      <LowStockMedicineModel>[].obs;
  final RxBool isLoadingLowStock = false.obs;

  // --------------------------------------------------------------------------
  // State: Stock Audit Ledger
  // --------------------------------------------------------------------------
  final RxList<StockAuditModel> stockLedgerList = <StockAuditModel>[].obs;
  final RxBool isLoadingLedger = false.obs;
  final RxString ledgerTransactionFilter =
      ''.obs; // DAMAGE, OPENING, ADJUSTMENT, etc.

  // --------------------------------------------------------------------------
  // State: Stock Valuation
  // --------------------------------------------------------------------------
  final Rx<StockValuationModel> valuation = StockValuationModel.empty().obs;
  final RxBool isLoadingValuation = false.obs;

  // General Action State
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (StorageService.hasToken()) {
      refreshAll();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchBatches(),
      fetchValuation(),
      fetchNearExpiry(),
      fetchLowStock(),
    ]);
  }

  // --------------------------------------------------------------------------
  // 1. Fetch Batches
  // --------------------------------------------------------------------------
  Future<void> fetchBatches({bool resetPage = false}) async {
    if (resetPage) batchPage.value = 1;
    isLoadingBatches.value = true;
    try {
      final res = await _repository.getBatches(
        page: batchPage.value,
        limit: 20,
        search: batchSearchQuery.value.trim().isEmpty
            ? null
            : batchSearchQuery.value.trim(),
        status: (batchStatusFilter.value.isEmpty || 
                 batchStatusFilter.value == 'EXPIRED' || 
                 batchStatusFilter.value == 'NEAR_EXPIRY')
            ? null
            : batchStatusFilter.value,
        inStockOnly: inStockOnlyFilter.value ? true : null,
      );

      final List<BatchModel> items = res['items'] as List<BatchModel>;
      final pagination = res['pagination'];
      if (batchPage.value == 1) {
        batches.assignAll(items);
      } else {
        batches.addAll(items);
      }
      batchTotalPages.value = pagination.totalPages;
      batchTotalCount.value = pagination.total;
    } on ApiException catch (e) {
      if (StorageService.hasToken()) {
        UniqueSnackbar.showError(
          null,
          title: 'Batches Error',
          message: e.message,
        );
      }
    } catch (_) {
    } finally {
      isLoadingBatches.value = false;
    }
  }

  // --------------------------------------------------------------------------
  // 2. Fetch Eligible Batches for Medicine (FEFO)
  // --------------------------------------------------------------------------
  Future<List<EligibleBatchModel>> getEligibleBatches(String medicineId) async {
    try {
      return await _repository.getEligibleBatches(medicineId);
    } on ApiException catch (e) {
      UniqueSnackbar.showError(null, title: 'FEFO Error', message: e.message);
      return [];
    } catch (_) {
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // 3. Create Initial Batch
  // --------------------------------------------------------------------------
  Future<bool> createBatch({
    required String medicineId,
    required String batchNumber,
    required double mrp,
    required double purchaseRate,
    required double sellingPrice,
    required int initialQuantity,
    String? supplierId,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
    String? notes,
  }) async {
    isSubmitting.value = true;
    try {
      final res = await _repository.createBatch(
        medicineId: medicineId,
        batchNumber: batchNumber,
        mrp: mrp,
        purchaseRate: purchaseRate,
        sellingPrice: sellingPrice,
        initialQuantity: initialQuantity,
        supplierId: supplierId,
        manufacturingDate: manufacturingDate,
        expiryDate: expiryDate,
        notes: notes,
      );

      final msg = res['message'] ?? 'Medicine batch created successfully';
      UniqueSnackbar.showSuccess(null, title: 'Success', message: msg);

      // Refresh batches, valuation & low-stock immediately
      fetchBatches(resetPage: true);
      fetchValuation();
      fetchLowStock();
      return true;
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'Creation Failed',
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
  // 4. Adjust Stock (Row-level locked atomic update)
  // --------------------------------------------------------------------------
  Future<bool> adjustStock({
    required String batchId,
    required String type, // "ADJUSTMENT_ADD" | "ADJUSTMENT_SUB" | "DAMAGE"
    required int quantity,
    required String reason,
    String? notes,
  }) async {
    isSubmitting.value = true;
    try {
      final res = await _repository.adjustStock(
        batchId: batchId,
        type: type,
        quantity: quantity,
        reason: reason,
        notes: notes,
      );

      final msg = res['message'] ?? 'Stock adjusted successfully';
      UniqueSnackbar.showSuccess(null, title: 'Adjusted', message: msg);

      // Refresh all relevant stock lists
      fetchBatches();
      fetchValuation();
      fetchNearExpiry();
      fetchLowStock();
      fetchLedger();
      return true;
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'Adjustment Failed',
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
  // 5. Fetch Near Expiry
  // --------------------------------------------------------------------------
  Future<void> fetchNearExpiry({int? days}) async {
    if (days != null) nearExpiryDays.value = days;
    isLoadingNearExpiry.value = true;
    try {
      final res = await _repository.getNearExpiry(
        days: nearExpiryDays.value,
        page: 1,
        limit: 50,
      );
      nearExpiryList.assignAll(res['items'] as List<NearExpiryBatchModel>);
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'Near Expiry Error',
        message: e.message,
      );
    } catch (_) {
    } finally {
      isLoadingNearExpiry.value = false;
    }
  }

  // --------------------------------------------------------------------------
  // 6. Fetch Low Stock
  // --------------------------------------------------------------------------
  Future<void> fetchLowStock() async {
    isLoadingLowStock.value = true;
    try {
      final res = await _repository.getLowStock(page: 1, limit: 50);
      lowStockList.assignAll(res['items'] as List<LowStockMedicineModel>);
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'Low Stock Error',
        message: e.message,
      );
    } catch (_) {
    } finally {
      isLoadingLowStock.value = false;
    }
  }

  // --------------------------------------------------------------------------
  // 7. Fetch Stock Ledger
  // --------------------------------------------------------------------------
  Future<void> fetchLedger({String? batchId, String? medicineId}) async {
    isLoadingLedger.value = true;
    try {
      final res = await _repository.getStockLedger(
        batchId: batchId,
        medicineId: medicineId,
        transactionType: ledgerTransactionFilter.value.isEmpty
            ? null
            : ledgerTransactionFilter.value,
        page: 1,
        limit: 50,
      );
      stockLedgerList.assignAll(res['items'] as List<StockAuditModel>);
    } on ApiException catch (e) {
      UniqueSnackbar.showError(null, title: 'Ledger Error', message: e.message);
    } catch (_) {
    } finally {
      isLoadingLedger.value = false;
    }
  }

  /// Alias for [fetchLedger] to refresh stock audit ledger entries.
  Future<void> fetchStockLedger({String? batchId, String? medicineId}) =>
      fetchLedger(batchId: batchId, medicineId: medicineId);

  // --------------------------------------------------------------------------
  // 8. Fetch Valuation
  // --------------------------------------------------------------------------
  Future<void> fetchValuation() async {
    isLoadingValuation.value = true;
    try {
      valuation.value = await _repository.getValuation();
    } on ApiException catch (e) {
      UniqueSnackbar.showError(
        null,
        title: 'Valuation Error',
        message: e.message,
      );
    } catch (_) {
    } finally {
      isLoadingValuation.value = false;
    }
  }

  /// Completely clear all in-memory batch and inventory tracking data on logout
  void clearData() {
    batches.clear();
    nearExpiryList.clear();
    lowStockList.clear();
    stockLedgerList.clear();
    valuation.value = StockValuationModel.empty();
    batchSearchQuery.value = '';
    batchStatusFilter.value = '';
    inStockOnlyFilter.value = false;
    batchPage.value = 1;
    batchTotalPages.value = 1;
    batchTotalCount.value = 0;
  }
}
