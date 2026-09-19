import 'package:get/get.dart';
import '../../../core/models/master_models.dart';
import '../../../core/models/rack_models.dart';
import '../../../core/network/api_exception.dart';
import '../repositories/rack_repository.dart';

class RackController extends GetxController {
  RackController({RackRepository? repository}) : repository = repository ?? RackRepository();
  final RackRepository repository;
  final racks = <RackModel>[].obs;
  final unassigned = <MedicineModel>[].obs;
  final detail = Rxn<RackModel>();
  final loading = false.obs, detailLoading = false.obs, unassignedLoading = false.obs, saving = false.obs;
  final error = ''.obs, detailError = ''.obs, unassignedError = ''.obs, operationError = ''.obs;
  final search = ''.obs, zone = ''.obs, status = ''.obs, unassignedSearch = ''.obs;
  final page = 1.obs, pages = 0.obs, unassignedTotal = 0.obs;
  Worker? _searchWorker, _unassignedWorker;
  int _listRequest = 0, _detailRequest = 0, _unassignedRequest = 0;
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    _searchWorker = debounce(search, (_) => loadRacks(), time: const Duration(milliseconds: 250));
    _unassignedWorker = debounce(unassignedSearch, (_) => loadUnassigned(1), time: const Duration(milliseconds: 250));
    loadRacks();
    loadUnassigned(1);
  }

  static String message(Object e) => e is ApiException ? e.message : 'Could not complete the request. Please retry.';

  Future<void> loadRacks() async {
    final request = ++_listRequest;
    loading.value = true;
    error.value = '';
    try {
      final result = await repository.list(search: search.value, zone: zone.value, status: status.value);
      if (!_closed && request == _listRequest) racks.assignAll(result);
    } catch (e) {
      if (!_closed && request == _listRequest) error.value = message(e);
    } finally {
      if (!_closed && request == _listRequest) loading.value = false;
    }
  }

  Future<void> loadDetail(String id) async {
    final request = ++_detailRequest;
    if (detail.value?.id != id) detail.value = null;
    detailLoading.value = true;
    detailError.value = '';
    try {
      final result = await repository.detail(id);
      if (!_closed && request == _detailRequest) detail.value = result;
    } catch (e) {
      if (!_closed && request == _detailRequest) detailError.value = message(e);
    } finally {
      if (!_closed && request == _detailRequest) detailLoading.value = false;
    }
  }

  Future<void> loadUnassigned(int targetPage) async {
    final request = ++_unassignedRequest;
    unassignedLoading.value = true;
    unassignedError.value = '';
    try {
      final result = await repository.unassigned(page: targetPage, search: unassignedSearch.value);
      if (_closed || request != _unassignedRequest) return;
      unassigned.assignAll(result.medicines);
      page.value = result.page > 0 ? result.page : targetPage;
      pages.value = result.totalPages;
      unassignedTotal.value = result.total;
    } catch (e) {
      if (!_closed && request == _unassignedRequest) unassignedError.value = message(e);
    } finally {
      if (!_closed && request == _unassignedRequest) unassignedLoading.value = false;
    }
  }

  /// A successful write stays successful even if a subsequent refresh fails.
  Future<T?> write<T>(Future<T> Function() action, {String? refreshRackId}) async {
    if (saving.value || _closed) return null;
    saving.value = true;
    operationError.value = '';
    try {
      final result = await action();
      if (_closed) return null;
      await Future.wait([
        loadRacks(), loadUnassigned(1),
        if (refreshRackId != null) loadDetail(refreshRackId),
      ]);
      return result;
    } catch (e) {
      if (!_closed) operationError.value = message(e);
      return null;
    } finally {
      if (!_closed) saving.value = false;
    }
  }

  @override
  void onClose() {
    _closed = true;
    _searchWorker?.dispose();
    _unassignedWorker?.dispose();
    super.onClose();
  }
}
