import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/models/crm_models.dart';

class CrmRepository {
  final ApiClient _apiClient = ApiClient();

  /// 1. Customer Purchase & Medicine History
  /// GET /crm/customers/:id/history
  Future<CustomerHistoryModel> getCustomerHistory(String customerId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.customerHistory(customerId),
      );

      final Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data['success'] == true && data['data'] != null) {
        return CustomerHistoryModel.fromJson(data['data']);
      }
      throw ApiException(message: data['message'] ?? 'Failed to load customer history');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 2. Due & Overdue Refill Alerts
  /// GET /crm/refills/due?days=7
  Future<List<DueRefillAlertModel>> getDueRefills({int days = 7}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.refillsDue,
        queryParameters: {'days': days},
      );

      final Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data['success'] == true && data['data'] != null) {
        final List list = data['data'];
        return list.map((json) => DueRefillAlertModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 3. List All Refill Rules
  /// GET /crm/refills?page=1&limit=20&customerId=...
  Future<Map<String, dynamic>> getRefillRules({
    int page = 1,
    int limit = 20,
    String? customerId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (customerId != null && customerId.isNotEmpty) {
        queryParams['customerId'] = customerId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        ApiConstants.refills,
        queryParameters: queryParams,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data['success'] == true && data['data'] != null) {
        final List items = data['data']['items'] ?? [];
        final rules = items.map((json) => RefillRuleModel.fromJson(json)).toList();
        return {
          'items': rules,
          'total': data['data']['total'] ?? rules.length,
          'page': data['data']['page'] ?? page,
          'totalPages': data['data']['totalPages'] ?? 1,
        };
      }
      return {'items': <RefillRuleModel>[], 'total': 0, 'page': 1, 'totalPages': 1};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 4. Create Refill Schedule Rule
  /// POST /crm/refills
  Future<RefillRuleModel> createRefillRule({
    required String customerId,
    required String medicineId,
    required double dailyDosage,
    required int daysSupply,
    String? lastPurchaseDate,
    String? notes,
  }) async {
    try {
      final body = {
        'customerId': customerId,
        'medicineId': medicineId,
        'dailyDosage': dailyDosage,
        'daysSupply': daysSupply,
        if (lastPurchaseDate != null) 'lastPurchaseDate': lastPurchaseDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _apiClient.post(
        ApiConstants.refills,
        data: body,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data['success'] == true && data['data'] != null) {
        return RefillRuleModel.fromJson(data['data']);
      }
      throw ApiException(message: data['message'] ?? 'Failed to create refill schedule');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 5. Trigger Refill Reminder (WhatsApp / SMS)
  /// POST /crm/refills/:id/remind
  Future<Map<String, dynamic>> sendRefillReminder({
    required String refillRuleId,
    String channel = 'WHATSAPP',
    String? customMessage,
  }) async {
    try {
      final body = {
        'channel': channel,
        if (customMessage != null && customMessage.isNotEmpty)
          'customMessage': customMessage,
      };

      final response = await _apiClient.post(
        ApiConstants.sendRefillReminder(refillRuleId),
        data: body,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      throw ApiException(message: data['message'] ?? 'Failed to send refill reminder');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 6. Notification Audit Log
  /// GET /crm/notifications?page=1&limit=20
  Future<Map<String, dynamic>> getNotificationLogs({
    int page = 1,
    int limit = 20,
    String? customerId,
    String? channel,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (customerId != null && customerId.isNotEmpty) {
        queryParams['customerId'] = customerId;
      }
      if (channel != null && channel.isNotEmpty) {
        queryParams['channel'] = channel;
      }

      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: queryParams,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data['success'] == true && data['data'] != null) {
        final List items = data['data']['items'] ?? [];
        final logs = items.map((json) => NotificationLogModel.fromJson(json)).toList();
        return {
          'items': logs,
          'total': data['data']['total'] ?? logs.length,
          'page': data['data']['page'] ?? page,
          'totalPages': data['data']['totalPages'] ?? 1,
        };
      }
      return {'items': <NotificationLogModel>[], 'total': 0, 'page': 1, 'totalPages': 1};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 7. List Follow-ups
  /// GET /crm/follow-ups?page=1&limit=20&status=...
  Future<Map<String, dynamic>> getFollowUps({
    int page = 1,
    int limit = 20,
    String? customerId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (customerId != null && customerId.isNotEmpty) {
        queryParams['customerId'] = customerId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        ApiConstants.followUps,
        queryParameters: queryParams,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data['success'] == true && data['data'] != null) {
        final List items = data['data']['items'] ?? [];
        final followUps = items.map((json) => FollowUpModel.fromJson(json)).toList();
        return {
          'items': followUps,
          'total': data['data']['total'] ?? followUps.length,
          'page': data['data']['page'] ?? page,
          'totalPages': data['data']['totalPages'] ?? 1,
        };
      }
      return {'items': <FollowUpModel>[], 'total': 0, 'page': 1, 'totalPages': 1};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 8. Schedule Patient Follow-Up
  /// POST /crm/follow-ups
  Future<FollowUpModel> scheduleFollowUp({
    required String customerId,
    required String followUpDate,
    required String notes,
  }) async {
    try {
      final body = {
        'customerId': customerId,
        'followUpDate': followUpDate,
        'notes': notes,
      };

      final response = await _apiClient.post(
        ApiConstants.followUps,
        data: body,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data['success'] == true && data['data'] != null) {
        return FollowUpModel.fromJson(data['data']);
      }
      throw ApiException(message: data['message'] ?? 'Failed to schedule follow-up');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 9. Update / Resolve Follow-Up
  /// PATCH /crm/follow-ups/:id
  Future<FollowUpModel> updateFollowUp({
    required String followUpId,
    required String status,
    String? notes,
  }) async {
    try {
      final body = {
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _apiClient.patch(
        ApiConstants.followUpById(followUpId),
        data: body,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data['success'] == true && data['data'] != null) {
        return FollowUpModel.fromJson(data['data']);
      }
      throw ApiException(message: data['message'] ?? 'Failed to update follow-up');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
