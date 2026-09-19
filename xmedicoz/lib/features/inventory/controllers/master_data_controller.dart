import 'package:get/get.dart';
import 'package:ledger_app/core/network/api_exception.dart';
import '../../../core/models/master_models.dart';
import '../../../core/utils/text_search.dart';
import '../../../core/storage/storage_service.dart';
import '../repositories/masters_repository.dart';
import '../../accounting/controllers/accounting_controller.dart';
import '../../purchases/controllers/purchases_controller.dart';
import '../../sales/controllers/sales_controller.dart';
import 'batch_controller.dart';

class MasterDataController extends GetxController {
  final MastersRepository _repository;

  MasterDataController({MastersRepository? repository})
    : _repository = repository ?? MastersRepository();

  // Reactive Collections (Zero Mock - 100% Live)
  final RxList<MedicineModel> medicines = <MedicineModel>[].obs;
  // Selector snapshots are deliberately non-reactive: completing a catalog
  // request must not rebuild every entry row underneath an animating popup.
  final List<MedicineModel> _medicineChoices = [];
  bool _medicineChoicesLoaded = false;
  int _medicineChoiceGeneration = 0;
  Future<List<MedicineModel>>? _medicineChoicesRequest;
  int _choiceGeneration = 0;
  final List<SupplierModel> _supplierChoices = [];
  final List<CustomerModel> _customerChoices = [];

  List<SupplierModel> get supplierChoices => {
    for (final supplier in _supplierChoices) supplier.id: supplier,
    for (final supplier in suppliers) supplier.id: supplier,
  }.values.toList();

  List<MedicineModel> get medicineChoices => {
    for (final medicine in _medicineChoices) medicine.id: medicine,
    for (final medicine in medicines) medicine.id: medicine,
  }.values.toList();

  List<CustomerModel> get customerChoices => {
    for (final customer in _customerChoices) customer.id: customer,
    for (final customer in customers) customer.id: customer,
  }.values.toList();
  final RxList<CustomerModel> customers = <CustomerModel>[].obs;
  final RxList<SupplierModel> suppliers = <SupplierModel>[].obs;

  // Lookups
  final RxList<CategoryLookupModel> categories = <CategoryLookupModel>[].obs;
  final RxList<ManufacturerLookupModel> manufacturers =
      <ManufacturerLookupModel>[].obs;
  final RxList<UnitLookupModel> units = <UnitLookupModel>[].obs;
  final RxList<TaxLookupModel> taxes = <TaxLookupModel>[].obs;

  // Loading States
  final RxBool isLoadingMedicines = false.obs;
  final RxBool isLoadingCustomers = false.obs;
  final RxBool isLoadingSuppliers = false.obs;
  final RxBool isLoadingLookups = false.obs;
  final RxString errorMessage = ''.obs;

  // Pagination State
  Rx<PaginationModel> medicinePagination = PaginationModel(
    total: 0,
    page: 1,
    limit: 20,
    totalPages: 1,
  ).obs;
  Rx<PaginationModel> customerPagination = PaginationModel(
    total: 0,
    page: 1,
    limit: 20,
    totalPages: 1,
  ).obs;
  Rx<PaginationModel> supplierPagination = PaginationModel(
    total: 0,
    page: 1,
    limit: 20,
    totalPages: 1,
  ).obs;

  // Search Filters
  final RxString medicineSearch = ''.obs;
  final RxString customerSearch = ''.obs;
  final RxString supplierSearch = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (StorageService.hasToken()) {
      fetchAllData();
    }
  }

  Future<void> fetchAllData() async {
    await Future.wait([
      fetchLookups(),
      fetchMedicines(),
      fetchCustomers(),
      fetchSuppliers(),
    ]);
  }

  // --------------------------------------------------------------------------
  // Lookups
  // --------------------------------------------------------------------------

  Future<void> fetchLookups() async {
    try {
      isLoadingLookups.value = true;
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getManufacturers(),
        _repository.getUnits(),
        _repository.getTaxes(),
      ]);

      categories.assignAll(results[0] as List<CategoryLookupModel>);
      manufacturers.assignAll(results[1] as List<ManufacturerLookupModel>);
      units.assignAll(results[2] as List<UnitLookupModel>);
      taxes.assignAll(results[3] as List<TaxLookupModel>);
    } catch (_) {
      // Ignore background lookup errors
    } finally {
      isLoadingLookups.value = false;
    }
  }

  // --------------------------------------------------------------------------
  // Medicines
  // --------------------------------------------------------------------------

  Future<void> fetchMedicines({
    String? search,
    String? categoryId,
    String? manufacturerId,
    bool? prescriptionRequired,
    int page = 1,
  }) async {
    try {
      isLoadingMedicines.value = true;
      errorMessage.value = '';

      final res = await _repository.getMedicines(
        page: page,
        limit: 20,
        search:
            search ??
            (medicineSearch.value.isNotEmpty ? medicineSearch.value : null),
        categoryId: categoryId,
        manufacturerId: manufacturerId,
        prescriptionRequired: prescriptionRequired,
      );

      medicines.assignAll(res['items'] as List<MedicineModel>);
      medicinePagination.value = res['pagination'] as PaginationModel;
      _invalidateMedicineChoices();
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Failed to load medicines from server.';
    } finally {
      isLoadingMedicines.value = false;
    }
  }

  /// Load complete choices without changing the inventory/ledger page filters.
  Future<List<MedicineModel>> loadMedicineChoices() {
    if (_medicineChoicesLoaded) return Future.value(medicineChoices);
    return _medicineChoicesRequest ??= _fetchMedicineChoices();
  }

  void _invalidateMedicineChoices() {
    _medicineChoiceGeneration++;
    _medicineChoicesLoaded = false;
    _medicineChoicesRequest = null;
  }

  Future<List<MedicineModel>> _fetchMedicineChoices() async {
    final generation = _medicineChoiceGeneration;
    try {
      final items = await _loadChoices<MedicineModel>(
        (page) => _repository.getMedicines(page: page, limit: 100),
        (medicine) => medicine.id,
      );
      if (items == null) return [];
      if (generation != _medicineChoiceGeneration) return medicineChoices;
      _medicineChoices
        ..clear()
        ..addAll(items);
      _medicineChoicesLoaded = true;
      return medicineChoices;
    } finally {
      if (generation == _medicineChoiceGeneration) {
        _medicineChoicesRequest = null;
      }
    }
  }

  Future<List<SupplierModel>> loadSupplierChoices() async {
    final items = await _loadChoices<SupplierModel>(
      (page) => _repository.getSuppliers(page: page, limit: 100),
      (supplier) => supplier.id,
    );
    if (items == null) return [];
    _supplierChoices
      ..clear()
      ..addAll(items);
    return supplierChoices;
  }

  Future<List<CustomerModel>> loadCustomerChoices() async {
    final items = await _loadChoices<CustomerModel>(
      (page) => _repository.getCustomers(page: page, limit: 100),
      (customer) => customer.id,
    );
    if (items == null) return [];
    _customerChoices
      ..clear()
      ..addAll(items);
    return customerChoices;
  }

  Future<List<T>?> _loadChoices<T>(
    Future<Map<String, dynamic>> Function(int page) fetch,
    String Function(T) id,
  ) async {
    final generation = _choiceGeneration;
    final choices = <String, T>{};
    var page = 1;
    while (true) {
      final result = await fetch(page);
      if (generation != _choiceGeneration) return null;
      final items = result['items'] as List<T>;
      for (final item in items) {
        choices[id(item)] = item;
      }
      final pagination = result['pagination'] as PaginationModel;
      if (items.isEmpty || page >= pagination.totalPages) break;
      page++;
    }
    return choices.values.toList();
  }

  Future<bool> createMedicine(Map<String, dynamic> data) async {
    final med = await registerMedicine(data);
    return med != null;
  }

  Future<MedicineModel?> registerMedicine(Map<String, dynamic> data) async {
    try {
      final created = await _repository.createMedicine(data);
      _invalidateMedicineChoices();
      medicines.insert(0, created);
      return created;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      return null;
    } catch (e) {
      errorMessage.value = 'Failed to create medicine.';
      return null;
    }
  }

  Future<bool> deleteMedicine(String id) async {
    try {
      await _repository.deleteMedicine(id);
      _invalidateMedicineChoices();
      _medicineChoices.removeWhere((m) => m.id == id);
      medicines.removeWhere((m) => m.id == id);
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to deactivate medicine.';
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // Customers
  // --------------------------------------------------------------------------

  Future<void> fetchCustomers({
    String? search,
    String? customerType,
    int page = 1,
  }) async {
    try {
      isLoadingCustomers.value = true;
      errorMessage.value = '';

      final res = await _repository.getCustomers(
        page: page,
        limit: 20,
        search:
            search ??
            (customerSearch.value.isNotEmpty ? customerSearch.value : null),
        customerType: customerType,
      );

      customers.assignAll(res['items'] as List<CustomerModel>);
      customerPagination.value = res['pagination'] as PaginationModel;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Failed to load customers from server.';
    } finally {
      isLoadingCustomers.value = false;
    }
  }

  Future<bool> createCustomer(Map<String, dynamic> data) async {
    final cust = await registerCustomer(data);
    return cust != null;
  }

  Future<CustomerModel?> registerCustomer(Map<String, dynamic> data) async {
    try {
      final created = await _repository.createCustomer(data);
      customers.insert(0, created);
      return created;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      return null;
    } catch (e) {
      errorMessage.value = 'Failed to register customer.';
      return null;
    }
  }

  Future<bool> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateCustomer(id, data);
      await fetchCustomers();
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to update customer.';
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // Suppliers
  // --------------------------------------------------------------------------

  Future<void> fetchSuppliers({String? search, int page = 1}) async {
    try {
      isLoadingSuppliers.value = true;
      errorMessage.value = '';

      final res = await _repository.getSuppliers(
        page: page,
        limit: 20,
        search:
            search ??
            (supplierSearch.value.isNotEmpty ? supplierSearch.value : null),
      );

      suppliers.assignAll(res['items'] as List<SupplierModel>);
      supplierPagination.value = res['pagination'] as PaginationModel;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Failed to load suppliers from server.';
    } finally {
      isLoadingSuppliers.value = false;
    }
  }

  Future<bool> createSupplier(Map<String, dynamic> data) async {
    final sup = await registerSupplier(data);
    return sup != null;
  }

  Future<SupplierModel?> registerSupplier(Map<String, dynamic> data) async {
    try {
      final created = await _repository.createSupplier(data);
      suppliers.insert(0, created);
      return created;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      return null;
    } catch (e) {
      errorMessage.value = 'Failed to register supplier.';
      return null;
    }
  }

  Future<bool> deleteSupplier(String id) async {
    try {
      await _repository.deleteSupplier(id);
      suppliers.removeWhere((s) => s.id == id);
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to deactivate supplier.';
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // Zero-Touch Atomic Lookups (Local Cache -> Remote API Fallback)
  // --------------------------------------------------------------------------

  /// Finds a supplier matching GSTIN (exact) or Name (fuzzy) locally or queries the server
  Future<SupplierModel?> findOrSearchSupplier({
    String? gstin,
    String? name,
  }) async {
    final cleanGst = gstin?.trim().toUpperCase();
    final cleanName = name?.trim().toLowerCase();

    // 1. Check local cache by GSTIN (exact match takes priority)
    if (cleanGst != null && cleanGst.isNotEmpty) {
      final local = suppliers.firstWhereOrNull(
        (s) => s.gstin != null && s.gstin!.trim().toUpperCase() == cleanGst,
      );
      if (local != null) return local;
    }

    // 2. Check local cache by Name (case-insensitive fuzzy)
    if (cleanName != null && cleanName.isNotEmpty) {
      final local = suppliers.firstWhereOrNull(
        (s) =>
            s.name.toLowerCase().contains(cleanName) ||
            cleanName.contains(s.name.toLowerCase()),
      );
      if (local != null) return local;
    }

    // 3. Search server by GSTIN
    if (cleanGst != null && cleanGst.isNotEmpty) {
      try {
        final res = await _repository.getSuppliers(search: cleanGst, limit: 5);
        final items = res['items'] as List<SupplierModel>;
        if (items.isNotEmpty) {
          for (final item in items) {
            if (!suppliers.any((s) => s.id == item.id)) {
              suppliers.add(item);
            }
          }
          return items.first;
        }
      } catch (_) {}
    }

    // 4. Search server by Name
    if (name != null && name.trim().isNotEmpty) {
      try {
        final res = await _repository.getSuppliers(
          search: name.trim(),
          limit: 5,
        );
        final items = res['items'] as List<SupplierModel>;
        if (items.isNotEmpty) {
          for (final item in items) {
            if (!suppliers.any((s) => s.id == item.id)) {
              suppliers.add(item);
            }
          }
          return items.first;
        }
      } catch (_) {}
    }

    return null;
  }

  /// Finds a medicine by name in local catalog or queries the server master catalog
  Future<MedicineModel?> findOrSearchMedicine(String name) async {
    final cleanName = TextSearch.normalize(name);
    if (cleanName.isEmpty) return null;

    // 1. Check local cache
    final local = medicines.firstWhereOrNull(
      (m) =>
          TextSearch.matches(m.name, cleanName) ||
          cleanName.contains(m.name.toLowerCase()),
    );
    if (local != null) return local;

    // 2. Search server catalog
    try {
      final res = await _repository.getMedicines(search: name.trim(), limit: 5);
      final items = res['items'] as List<MedicineModel>;
      if (items.isNotEmpty) {
        for (final item in items) {
          if (!medicines.any((m) => m.id == item.id)) {
            medicines.add(item);
          }
        }
        return items.first;
      }
    } catch (_) {}

    return null;
  }

  // --------------------------------------------------------------------------
  // Computed Metrics for Dashboard & Headers
  // --------------------------------------------------------------------------

  double get totalStockValuation {
    if (Get.isRegistered<BatchController>()) {
      final cost = Get.find<BatchController>().valuation.value.totalCostValue;
      if (cost > 0) return cost;
    }
    return medicines.fold(
      0.0,
      (sum, m) =>
          sum + (m.purchaseRate * (m.reorderLevel > 0 ? m.reorderLevel : 10)),
    );
  }

  double get totalReceivables {
    final customerSum = customers.fold(
      0.0,
      (sum, c) => sum + (c.currentBalance > 0 ? c.currentBalance : 0.0),
    );
    if (customerSum > 0) return customerSum;

    // Live Sales Controller credit & unpaid bills
    if (Get.isRegistered<SalesController>()) {
      final sales = Get.find<SalesController>().salesInvoices;
      final creditSum = sales
          .where((s) => s.isCreditSale || s.isUnpaid)
          .fold(
            0.0,
            (sum, s) =>
                sum + (s.balanceAmount > 0 ? s.balanceAmount : s.totalAmount),
          );
      if (creditSum > 0) return creditSum;
    }

    // Live Accounting AR Aging
    if (Get.isRegistered<AccountingController>()) {
      final ar =
          Get.find<AccountingController>()
              .receivablesAging
              .value
              ?.totalAmount ??
          0.0;
      if (ar > 0) return ar;
    }

    return 0.0;
  }

  double get totalPayables {
    final supplierSum = suppliers.fold(
      0.0,
      (sum, s) => sum + (s.outstandingBalance > 0 ? s.outstandingBalance : 0.0),
    );
    if (supplierSum > 0) return supplierSum;

    // Live Purchases Controller unpaid invoices
    if (Get.isRegistered<PurchasesController>()) {
      final purchases = Get.find<PurchasesController>().purchases;
      final unpaidSum = purchases
          .where(
            (p) =>
                p.paymentStatus == 'UNPAID' ||
                p.paymentStatus == 'PARTIALLY_PAID',
          )
          .fold(
            0.0,
            (sum, p) =>
                sum + (p.balanceAmount > 0 ? p.balanceAmount : p.totalAmount),
          );
      if (unpaidSum > 0) return unpaidSum;
    }

    // Live Accounting AP Aging
    if (Get.isRegistered<AccountingController>()) {
      final ap =
          Get.find<AccountingController>().payablesAging.value?.totalAmount ??
          0.0;
      if (ap > 0) return ap;
    }

    return 0.0;
  }

  int get totalMedicinesCount => medicinePagination.value.total > 0
      ? medicinePagination.value.total
      : medicines.length;

  int get totalCustomersCount => customerPagination.value.total > 0
      ? customerPagination.value.total
      : customers.length;

  int get totalSuppliersCount => supplierPagination.value.total > 0
      ? supplierPagination.value.total
      : suppliers.length;

  /// Completely clear all in-memory master data on logout
  void clearData() {
    _choiceGeneration++;
    _invalidateMedicineChoices();
    medicines.clear();
    _medicineChoices.clear();
    _supplierChoices.clear();
    customers.clear();
    suppliers.clear();
    categories.clear();
    manufacturers.clear();
    units.clear();
    taxes.clear();
    medicineSearch.value = '';
    customerSearch.value = '';
    supplierSearch.value = '';
    medicinePagination.value = PaginationModel(
      total: 0,
      page: 1,
      limit: 20,
      totalPages: 1,
    );
    customerPagination.value = PaginationModel(
      total: 0,
      page: 1,
      limit: 20,
      totalPages: 1,
    );
    supplierPagination.value = PaginationModel(
      total: 0,
      page: 1,
      limit: 20,
      totalPages: 1,
    );
    errorMessage.value = '';
  }
}
