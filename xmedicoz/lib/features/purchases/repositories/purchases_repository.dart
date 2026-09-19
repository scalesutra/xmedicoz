import '../../../core/models/master_models.dart';
import '../../../core/models/purchase_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';

class PurchasesRepository {
  final ApiClient _apiClient;

  PurchasesRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // --------------------------------------------------------------------------
  // 1. Enter Purchase Bill / Ingest Stock (POST /purchases/invoices or /purchases)
  // --------------------------------------------------------------------------
  Future<PurchaseInvoiceModel> createPurchaseInvoice(Map<String, dynamic> data) async {
    dynamic response;
    try {
      response = await _apiClient.post(
        ApiConstants.purchaseInvoices,
        data: data,
      );
    } catch (_) {
      // Fallback if backend uses /purchases
      response = await _apiClient.post(
        ApiConstants.purchases,
        data: data,
      );
    }

    if (response is Map<String, dynamic> && response['data'] != null) {
      return PurchaseInvoiceModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create purchase invoice');
  }

  // --------------------------------------------------------------------------
  // 2. List Purchase Bills / Invoices (GET /purchases)
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getPurchaseInvoices({
    String? supplierId,
    String? paymentStatus,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (supplierId != null && supplierId.isNotEmpty) {
      query['supplierId'] = supplierId;
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      query['paymentStatus'] = paymentStatus;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final response = await _apiClient.get(
      ApiConstants.purchases,
      queryParameters: query,
    );

    final List<PurchaseInvoiceModel> items = [];
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
              .map((e) => PurchaseInvoiceModel.fromJson(e as Map<String, dynamic>)),
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
  // 3. Get Single Purchase Bill Details (GET /purchases/:id)
  // --------------------------------------------------------------------------
  Future<PurchaseInvoiceModel> getPurchaseInvoiceById(String id) async {
    final response = await _apiClient.get(ApiConstants.purchaseById(id));

    if (response is Map<String, dynamic> && response['data'] != null) {
      return PurchaseInvoiceModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Purchase invoice not found');
  }

  // --------------------------------------------------------------------------
  // 3b. Create Purchase Invoice from OCR Scan (POST /purchases)
  //     Simplified payload — backend auto-creates supplier & medicines by name.
  //     No supplierId / medicineId UUIDs needed.
  // --------------------------------------------------------------------------
  Future<PurchaseInvoiceModel> createOcrPurchaseInvoice({
    required Map<String, dynamic> supplier,
    required String invoiceNumber,
    required String invoiceDate,
    required int paymentTermsDays,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'supplier': supplier,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate,
      'paymentTermsDays': paymentTermsDays,
      'items': items,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = await _apiClient.post(
      ApiConstants.purchases,
      data: payload,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return PurchaseInvoiceModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create OCR purchase invoice');
  }

  // --------------------------------------------------------------------------
  // 4. Record Supplier Payment (POST /purchases/payments)
  // --------------------------------------------------------------------------
  Future<PurchasePaymentModel> recordSupplierPayment({
    required String supplierId,
    required String purchaseInvoiceId,
    required double amount,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'supplierId': supplierId,
      'purchaseInvoiceId': purchaseInvoiceId,
      'amount': amount,
      'paymentMode': paymentMode,
    };
    if (referenceNumber != null && referenceNumber.trim().isNotEmpty) {
      payload['referenceNumber'] = referenceNumber.trim();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      payload['notes'] = notes.trim();
    }

    final response = await _apiClient.post(
      ApiConstants.purchasePayments,
      data: payload,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return PurchasePaymentModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to record supplier payment');
  }

  // --------------------------------------------------------------------------
  // 5. Process Purchase Return (POST /purchases/returns)
  // --------------------------------------------------------------------------
  Future<PurchaseReturnModel> processPurchaseReturn({
    required String supplierId,
    String? purchaseInvoiceId,
    required String reason,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = <String, dynamic>{
      'supplierId': supplierId,
      'reason': reason,
      'items': items,
    };
    if (purchaseInvoiceId != null && purchaseInvoiceId.isNotEmpty) {
      payload['purchaseInvoiceId'] = purchaseInvoiceId;
    }

    final endpoint = purchaseInvoiceId != null && purchaseInvoiceId.isNotEmpty
        ? ApiConstants.purchaseReturnForInvoice(purchaseInvoiceId)
        : ApiConstants.purchaseReturns;

    final response = await _apiClient.post(
      endpoint,
      data: payload,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return PurchaseReturnModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to process purchase return');
  }

  // --------------------------------------------------------------------------
  // 6. Create Purchase Order (POST /purchases/orders)
  // --------------------------------------------------------------------------
  Future<PurchaseOrderModel> createPurchaseOrder({
    required String supplierId,
    required String expectedDate,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = <String, dynamic>{
      'supplierId': supplierId,
      'expectedDate': expectedDate,
      'items': items,
    };
    if (notes != null && notes.trim().isNotEmpty) {
      payload['notes'] = notes.trim();
    }

    final response = await _apiClient.post(
      ApiConstants.purchaseOrders,
      data: payload,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return PurchaseOrderModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create purchase order');
  }

  // --------------------------------------------------------------------------
  // 7. List Purchase Orders (GET /purchases/orders)
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getPurchaseOrders({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.purchaseOrders,
      queryParameters: {'page': page, 'limit': limit},
    );

    final List<PurchaseOrderModel> items = [];
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
              .map((e) => PurchaseOrderModel.fromJson(e as Map<String, dynamic>)),
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
}
