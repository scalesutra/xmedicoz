import '../../../core/models/master_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';

class MastersRepository {
  final ApiClient _apiClient;

  MastersRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // --------------------------------------------------------------------------
  // 1. Medicines
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> getMedicines({
    int page = 1,
    int limit = 20,
    String? search,
    String? categoryId,
    String? manufacturerId,
    String? status,
    bool? prescriptionRequired,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query['categoryId'] = categoryId;
    }
    if (manufacturerId != null && manufacturerId.isNotEmpty) {
      query['manufacturerId'] = manufacturerId;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (prescriptionRequired != null) {
      query['prescriptionRequired'] = prescriptionRequired;
    }

    final response = await _apiClient.get(
      ApiConstants.medicines,
      queryParameters: query,
    );

    final List<MedicineModel> items = [];
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
            (e) => MedicineModel.fromJson(e as Map<String, dynamic>),
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

  Future<MedicineModel> getMedicineById(String id) async {
    final response = await _apiClient.get('${ApiConstants.medicines}/$id');
    if (response is Map<String, dynamic> && response['data'] != null) {
      return MedicineModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Medicine details not found.');
  }

  Future<MedicineModel> createMedicine(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiConstants.medicines, data: data);
    if (response is Map<String, dynamic> && response['data'] != null) {
      return MedicineModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create medicine.');
  }

  Future<void> updateMedicine(String id, Map<String, dynamic> data) async {
    await _apiClient.patch('${ApiConstants.medicines}/$id', data: data);
  }

  Future<void> deleteMedicine(String id) async {
    await _apiClient.dio.delete('${ApiConstants.medicines}/$id');
  }

  // --------------------------------------------------------------------------
  // 2. Customers
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> getCustomers({
    int page = 1,
    int limit = 20,
    String? search,
    String? customerType,
    bool? isPermanent,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (customerType != null && customerType.isNotEmpty) {
      query['customerType'] = customerType;
    }
    if (isPermanent != null) {
      query['isPermanent'] = isPermanent;
    }

    final response = await _apiClient.get(
      ApiConstants.customers,
      queryParameters: query,
    );

    final List<CustomerModel> items = [];
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
            (e) => CustomerModel.fromJson(e as Map<String, dynamic>),
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

  Future<CustomerModel> getCustomerByPhone(String mobile) async {
    final response = await _apiClient.get(
      '${ApiConstants.customerByPhone}/$mobile',
    );
    if (response is Map<String, dynamic> && response['data'] != null) {
      return CustomerModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Customer not found for phone $mobile.');
  }

  Future<CustomerModel> createCustomer(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiConstants.customers, data: data);
    if (response is Map<String, dynamic> && response['data'] != null) {
      return CustomerModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to register customer.');
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    await _apiClient.patch('${ApiConstants.customers}/$id', data: data);
  }

  // --------------------------------------------------------------------------
  // 3. Suppliers
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> getSuppliers({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    final response = await _apiClient.get(
      ApiConstants.suppliers,
      queryParameters: query,
    );

    final List<SupplierModel> items = [];
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
            (e) => SupplierModel.fromJson(e as Map<String, dynamic>),
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

  Future<SupplierModel> createSupplier(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiConstants.suppliers, data: data);
    if (response is Map<String, dynamic> && response['data'] != null) {
      return SupplierModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to register supplier.');
  }

  Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    await _apiClient.patch('${ApiConstants.suppliers}/$id', data: data);
  }

  Future<void> deleteSupplier(String id) async {
    await _apiClient.dio.delete('${ApiConstants.suppliers}/$id');
  }

  // --------------------------------------------------------------------------
  // 4. Lookups (Categories, Manufacturers, Units, Taxes)
  // --------------------------------------------------------------------------

  Future<List<CategoryLookupModel>> getCategories() async {
    final response = await _apiClient.get(ApiConstants.categories);
    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((e) => CategoryLookupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ManufacturerLookupModel>> getManufacturers() async {
    final response = await _apiClient.get(ApiConstants.manufacturers);
    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map(
            (e) => ManufacturerLookupModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<List<UnitLookupModel>> getUnits() async {
    final response = await _apiClient.get(ApiConstants.units);
    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((e) => UnitLookupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<TaxLookupModel>> getTaxes() async {
    final response = await _apiClient.get(ApiConstants.taxes);
    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((e) => TaxLookupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
