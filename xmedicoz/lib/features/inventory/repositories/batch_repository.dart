import '../../../core/models/batch_models.dart';
import '../../../core/models/master_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';

class BatchRepository {
  final ApiClient _apiClient;

  BatchRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // --------------------------------------------------------------------------
  // 1. List Batches
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getBatches({
    int page = 1,
    int limit = 20,
    String? search,
    String? medicineId,
    String? status,
    bool? inStockOnly,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (medicineId != null && medicineId.isNotEmpty) {
      query['medicineId'] = medicineId;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (inStockOnly != null) {
      query['inStockOnly'] = inStockOnly;
    }

    final response = await _apiClient.get(
      ApiConstants.batches,
      queryParameters: query,
    );

    final List<BatchModel> items = [];
    PaginationModel pagination = PaginationModel(
      total: 0,
      page: 1,
      limit: limit,
      totalPages: 1,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      if (data['items'] is List) {
        items.addAll(
          (data['items'] as List).map(
            (e) => BatchModel.fromJson(e as Map<String, dynamic>),
          ),
        );
      }
      if (data['pagination'] is Map) {
        pagination = PaginationModel.fromJson(
          data['pagination'] as Map<String, dynamic>,
        );
      }
    }

    return {'items': items, 'pagination': pagination};
  }

  // --------------------------------------------------------------------------
  // 2. FEFO Sale-Eligible Batches
  // --------------------------------------------------------------------------
  Future<List<EligibleBatchModel>> getEligibleBatches(String medicineId) async {
    final response = await _apiClient.get(
      ApiConstants.eligibleBatches(medicineId),
    );

    final List<EligibleBatchModel> items = [];
    if (response is Map<String, dynamic> && response['data'] is List) {
      items.addAll(
        (response['data'] as List).map(
          (e) => EligibleBatchModel.fromJson(e as Map<String, dynamic>),
        ),
      );
    }
    return items;
  }

  // --------------------------------------------------------------------------
  // 3. Create Initial Batch
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> createBatch({
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
    final payload = <String, dynamic>{
      'medicineId': medicineId,
      'batchNumber': batchNumber.trim(),
      'mrp': mrp,
      'purchaseRate': purchaseRate,
      'sellingPrice': sellingPrice,
      'initialQuantity': initialQuantity,
    };

    if (supplierId != null && supplierId.isNotEmpty) {
      payload['supplierId'] = supplierId;
    }
    if (manufacturingDate != null) {
      payload['manufacturingDate'] = _toApiDateTime(manufacturingDate);
    }
    if (expiryDate != null) {
      payload['expiryDate'] = _toApiDateTime(expiryDate);
    }
    if (notes != null && notes.trim().isNotEmpty) {
      payload['notes'] = notes.trim();
    }

    final response = await _apiClient.post(ApiConstants.batches, data: payload);

    return (response is Map<String, dynamic>) ? response : {};
  }

  String _toApiDateTime(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day).toIso8601String();
  }

  // --------------------------------------------------------------------------
  // 4. Stock Adjustment (Add, Subtract, Damage)
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> adjustStock({
    required String batchId,
    required String type, // "ADJUSTMENT_ADD" | "ADJUSTMENT_SUB" | "DAMAGE"
    required int quantity,
    required String reason,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'batchId': batchId,
      'type': type,
      'quantity': quantity,
      'reason': reason.trim(),
    };
    if (notes != null && notes.trim().isNotEmpty) {
      payload['notes'] = notes.trim();
    }

    final response = await _apiClient.post(
      ApiConstants.stockAdjustments,
      data: payload,
    );

    return (response is Map<String, dynamic>) ? response : {};
  }

  // --------------------------------------------------------------------------
  // 5. Near-Expiry & Expired Stock Report
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getNearExpiry({
    int days = 90,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.nearExpiry,
      queryParameters: {'days': days, 'page': page, 'limit': limit},
    );

    final List<NearExpiryBatchModel> items = [];
    PaginationModel pagination = PaginationModel(
      total: 0,
      page: 1,
      limit: limit,
      totalPages: 1,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      if (data['items'] is List) {
        items.addAll(
          (data['items'] as List).map(
            (e) => NearExpiryBatchModel.fromJson(e as Map<String, dynamic>),
          ),
        );
      }
      if (data['pagination'] is Map) {
        pagination = PaginationModel.fromJson(
          data['pagination'] as Map<String, dynamic>,
        );
      }
    }

    return {'items': items, 'pagination': pagination};
  }

  // --------------------------------------------------------------------------
  // 6. Low-Stock Medicines Alert
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getLowStock({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.lowStock,
      queryParameters: {'page': page, 'limit': limit},
    );

    final List<LowStockMedicineModel> items = [];
    PaginationModel pagination = PaginationModel(
      total: 0,
      page: 1,
      limit: limit,
      totalPages: 1,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      if (data['items'] is List) {
        items.addAll(
          (data['items'] as List).map(
            (e) => LowStockMedicineModel.fromJson(e as Map<String, dynamic>),
          ),
        );
      }
      if (data['pagination'] is Map) {
        pagination = PaginationModel.fromJson(
          data['pagination'] as Map<String, dynamic>,
        );
      }
    }

    return {'items': items, 'pagination': pagination};
  }

  // --------------------------------------------------------------------------
  // 7. Stock Audit Ledger
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getStockLedger({
    String? batchId,
    String? medicineId,
    String? transactionType,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (batchId != null && batchId.isNotEmpty) {
      query['batchId'] = batchId;
    }
    if (medicineId != null && medicineId.isNotEmpty) {
      query['medicineId'] = medicineId;
    }
    if (transactionType != null && transactionType.isNotEmpty) {
      query['transactionType'] = transactionType;
    }

    final response = await _apiClient.get(
      ApiConstants.stockAuditLedger,
      queryParameters: query,
    );

    final List<StockAuditModel> items = [];
    PaginationModel pagination = PaginationModel(
      total: 0,
      page: 1,
      limit: limit,
      totalPages: 1,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      if (data['items'] is List) {
        items.addAll(
          (data['items'] as List).map(
            (e) => StockAuditModel.fromJson(e as Map<String, dynamic>),
          ),
        );
      }
      if (data['pagination'] is Map) {
        pagination = PaginationModel.fromJson(
          data['pagination'] as Map<String, dynamic>,
        );
      }
    }

    return {'items': items, 'pagination': pagination};
  }

  // --------------------------------------------------------------------------
  // 8. Total Stock Valuation
  // --------------------------------------------------------------------------
  Future<StockValuationModel> getValuation() async {
    final response = await _apiClient.get(ApiConstants.stockValuation);

    if (response is Map<String, dynamic> && response['data'] != null) {
      return StockValuationModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    return StockValuationModel.empty();
  }
}
