import '../../../core/models/smart_search_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';

class InventorySmartRepository {
  final ApiClient _apiClient;

  InventorySmartRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Symptom & Fast Smart Search: GET /inventory/smart-search
  Future<SmartSearchResponseModel> getSmartSearch({
    String? q,
    bool? symptomOnly,
    bool? inStockOnly,
    bool? sortByMargin,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };
    if (q != null && q.trim().isNotEmpty) {
      queryParams['q'] = q.trim();
    }
    if (symptomOnly == true) {
      queryParams['symptomOnly'] = true;
    }
    if (inStockOnly == true) {
      queryParams['inStockOnly'] = true;
    }
    if (sortByMargin == true) {
      queryParams['sortByMargin'] = true;
    }

    final response = await _apiClient.get(
      ApiConstants.smartSearch,
      queryParameters: queryParams,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return SmartSearchResponseModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to load smart search results');
  }

  /// Instant Salt-Equivalent Substitute Engine: GET /inventory/substitutes/:medicineId
  Future<MedicineSubstituteResponseModel> getSubstitutes(
    String medicineId,
  ) async {
    final response = await _apiClient.get(
      ApiConstants.substitutes(medicineId),
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return MedicineSubstituteResponseModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to load substitutes');
  }

  /// Shortage Diary (Kami Register): GET /inventory/shortage-diary
  Future<List<ShortageDiaryItemModel>> getShortageDiary({String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      ApiConstants.shortageDiary,
      queryParameters: queryParams,
    );

    final List<ShortageDiaryItemModel> items = [];
    if (response is Map<String, dynamic> && response['data'] != null) {
      final data = response['data'];
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data is List ? data : []);
      items.addAll(
        rawList
            .whereType<Map<String, dynamic>>()
            .map(ShortageDiaryItemModel.fromJson),
      );
    }
    return items;
  }

  /// Log Out-of-Stock Demand: POST /inventory/shortage-diary/log
  Future<bool> logShortage({
    required String medicineId,
    int customerCount = 1,
    String? notes,
  }) async {
    final payload = {
      'medicineId': medicineId,
      'customerCount': customerCount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _apiClient.post(
      ApiConstants.shortageDiaryLog,
      data: payload,
    );

    return response != null;
  }

  /// Update Shortage Item Status: PATCH /inventory/shortage-diary/:id
  Future<bool> updateShortageStatus(
    String id, {
    required String status,
    int? suggestedReorderQty,
    String? notes,
  }) async {
    final payload = {
      'status': status,
      if (suggestedReorderQty != null)
        'suggestedReorderQty': suggestedReorderQty,
      if (notes != null) 'notes': notes,
    };

    final response = await _apiClient.patch(
      ApiConstants.shortageDiaryById(id),
      data: payload,
    );

    return response != null;
  }
}
