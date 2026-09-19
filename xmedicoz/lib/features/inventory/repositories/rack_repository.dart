import '../../../core/models/rack_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';

class RackRepository {
  RackRepository({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();
  final ApiClient _client;
  static const _base = ApiConstants.racks;
  String _rack(String id) => '$_base/${Uri.encodeComponent(id)}';
  String _shelf(String rackId, String shelfId) => '${_rack(rackId)}/shelves/${Uri.encodeComponent(shelfId)}';

  Object? _data(dynamic response) {
    if (response is! Map || response['success'] != true) {
      throw ApiException(message: response is Map ? rackText(response['message']) : 'Invalid rack response');
    }
    return response['data'];
  }
  Map<String, dynamic> _object(dynamic response) {
    final data = _data(response);
    if (data is! Map) throw ApiException(message: 'Missing rack response data');
    return rackMap(data);
  }

  Future<List<RackModel>> list({String search = '', String zone = '', String status = ''}) async {
    final data = _data(await _client.get(_base, queryParameters: {
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (zone.trim().isNotEmpty) 'zone': zone.trim(),
      if (status.trim().isNotEmpty) 'status': status.trim(),
    }));
    if (data is! List) throw ApiException(message: 'Invalid rack list');
    return rackMaps(data).map(RackModel.fromJson).toList();
  }
  Future<RackModel> detail(String id) async => RackModel.fromJson(_object(await _client.get(_rack(id))));
  Future<RackModel> create(Map<String, dynamic> body) async => RackModel.fromJson(_object(await _client.post(_base, data: body)));
  Future<RackModel> update(String id, Map<String, dynamic> body) async => RackModel.fromJson(_object(await _client.patch(_rack(id), data: body)));
  Future<void> delete(String id) async => _data(await _client.delete(_rack(id)));
  Future<RackShelfModel> addShelf(String rackId, Map<String, dynamic> body) async => RackShelfModel.fromJson(_object(await _client.post('${_rack(rackId)}/shelves', data: body)));
  Future<RackShelfModel> updateShelf(String rackId, String shelfId, Map<String, dynamic> body) async => RackShelfModel.fromJson(_object(await _client.patch(_shelf(rackId, shelfId), data: body)));
  Future<void> deleteShelf(String rackId, String shelfId) async => _data(await _client.delete(_shelf(rackId, shelfId)));
  Future<MedicineLocationModel> locate(String medicineId) async => MedicineLocationModel.fromJson(_object(await _client.get('$_base/locate/${Uri.encodeComponent(medicineId)}')));
  Future<Map<String, dynamic>> assign(RackAssignment assignment) async => _object(await _client.post('$_base/assign', data: assignment.toJson()));
  Future<Map<String, dynamic>> bulkAssign(List<RackAssignment> assignments) async => _object(await _client.post('$_base/bulk-assign', data: {'assignments': assignments.map((a) => a.toJson()).toList()}));
  Future<Map<String, dynamic>> transfer({required List<String> medicineIds, required String rackCode, required String shelfNumber, String boxCode = '', String reason = ''}) async => _object(await _client.post('$_base/transfer', data: {
    'medicineIds': medicineIds,
    'targetRackCode': rackCode,
    'targetShelfNumber': shelfNumber,
    'targetBoxCode': boxCode,
    'reason': reason,
  }));
  Future<UnassignedMedicinesPage> unassigned({int page = 1, String search = ''}) async => UnassignedMedicinesPage.fromJson(_object(await _client.get('$_base/unassigned', queryParameters: {'page': page, 'limit': 20, if (search.trim().isNotEmpty) 'search': search.trim()})));
  Future<RackAuditSheet> auditSheet(String id) async => RackAuditSheet.fromJson(_object(await _client.get('${_rack(id)}/audit-sheet')));
  Future<Map<String, dynamic>> verifyAudit(String id, List<RackAuditCount> counts) async => _object(await _client.post('${_rack(id)}/audit-verify', data: {'auditItems': counts.map((c) => c.toJson()).toList()}));
}
