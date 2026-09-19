import '../../../core/models/master_models.dart';
import '../../../core/models/sales_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';

class SalesRepository {
  final ApiClient _apiClient;

  SalesRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // --------------------------------------------------------------------------
  // 1. Counter POS Checkout (POST /sales)
  // --------------------------------------------------------------------------
  Future<SalesInvoiceModel> createSalesInvoice(Map<String, dynamic> data) async {
    final sanitizedData = Map<String, dynamic>.from(data)
      ..removeWhere((key, value) => value == null);

    if (sanitizedData['items'] is List) {
      sanitizedData['items'] = (sanitizedData['items'] as List).map((item) {
        if (item is Map<String, dynamic>) {
          return Map<String, dynamic>.from(item)
            ..removeWhere((key, value) => value == null);
        }
        return item;
      }).toList();
    }

    final response = await _apiClient.post(
      ApiConstants.sales,
      data: sanitizedData,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return SalesInvoiceModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to generate sales invoice');
  }

  // --------------------------------------------------------------------------
  // 2. List Sales Invoices (GET /sales)
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getSalesInvoices({
    String? customerId,
    String? paymentStatus,
    String? search,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (customerId != null && customerId.isNotEmpty) {
      query['customerId'] = customerId;
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      query['paymentStatus'] = paymentStatus;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (startDate != null && startDate.isNotEmpty) {
      query['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      query['endDate'] = endDate;
    }

    final response = await _apiClient.get(
      ApiConstants.sales,
      queryParameters: query,
    );

    final List<SalesInvoiceModel> items = [];
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
          (data['items'] as List)
              .map((e) => SalesInvoiceModel.fromJson(e as Map<String, dynamic>)),
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
  // 3. Get Single Sales Invoice Details (GET /sales/:id)
  // --------------------------------------------------------------------------
  Future<SalesInvoiceModel> getSalesInvoiceById(String id) async {
    final response = await _apiClient.get(ApiConstants.saleById(id));

    if (response is Map<String, dynamic> && response['data'] != null) {
      return SalesInvoiceModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Sales invoice not found');
  }

  // --------------------------------------------------------------------------
  // 4. Sales Return & Automated Restock (POST /sales/returns)
  // --------------------------------------------------------------------------
  Future<SalesReturnModel> processSalesReturn({
    required String salesInvoiceId,
    required String refundMode, // "CASH", "UPI", "CREDIT_NOTE"
    required String reason,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = {
      'salesInvoiceId': salesInvoiceId,
      'refundMode': refundMode,
      'reason': reason,
      'items': items,
    };

    final response = await _apiClient.post(
      ApiConstants.salesReturns,
      data: payload,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return SalesReturnModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to process sales return');
  }
}
