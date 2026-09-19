import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/models/master_models.dart';
import '../../../core/models/rack_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../controllers/master_data_controller.dart';
import '../controllers/rack_controller.dart';

class RackPlacementSheet extends StatefulWidget {
  const RackPlacementSheet({super.key, required this.controller, this.initialMedicine, this.initialRack, this.transfer = false});
  final RackController controller;
  final MedicineModel? initialMedicine;
  final RackModel? initialRack;
  final bool transfer;
  @override
  State<RackPlacementSheet> createState() => _RackPlacementSheetState();
}

class _RackPlacementSheetState extends State<RackPlacementSheet> {
  final _medicine = Rxn<MedicineModel>(), _rack = Rxn<RackModel>(), _shelf = Rxn<RackShelfModel>();
  final _shelves = <RackShelfModel>[].obs;
  final _queue = <RackAssignment>[].obs;
  final _names = <String, String>{};
  final _shelfLoading = false.obs;
  final _error = ''.obs;
  final _box = TextEditingController(), _reason = TextEditingController();
  int _rackRequest = 0;
  late final MasterDataController _masters;
  @override
  void initState() {
    super.initState();
    _masters = Get.find<MasterDataController>();
    _medicine.value = widget.initialMedicine;
    if (widget.initialRack != null) _selectRack(widget.initialRack);
  }
  Future<void> _selectRack(RackModel? rack) async {
    final request = ++_rackRequest;
    _rack.value = rack; _shelf.value = null; _shelves.clear();
    if (rack == null) return;
    _shelfLoading.value = true; _error.value = '';
    try {
      final detail = await widget.controller.repository.detail(rack.id);
      if (mounted && request == _rackRequest) _shelves.assignAll(detail.shelves);
    } catch (e) { if (mounted && request == _rackRequest) _error.value = RackController.message(e); }
    finally { if (mounted && request == _rackRequest) _shelfLoading.value = false; }
  }
  bool _destinationValid() {
    if (_rack.value == null || _shelf.value == null) { _error.value = 'Choose a rack and shelf.'; return false; }
    return true;
  }
  void _add() {
    final medicine = _medicine.value;
    if (medicine == null) { _error.value = 'Choose a medicine.'; return; }
    if (!widget.transfer && !_destinationValid()) return;
    if (_queue.any((a) => a.medicineId == medicine.id)) { _error.value = 'This medicine is already in the list.'; return; }
    _names[medicine.id] = medicine.name;
    _queue.add(RackAssignment(medicineId: medicine.id, rackCode: _rack.value?.code ?? '', shelfNumber: _shelf.value?.number.toString() ?? '', boxCode: _box.text.trim()));
    _medicine.value = null; _error.value = '';
  }
  Future<void> _submit() async {
    _error.value = '';
    if (_queue.isEmpty) { _error.value = 'Add at least one medicine to the list.'; return; }
    if (widget.transfer && !_destinationValid()) return;
    final c = widget.controller;
    final Map<String, dynamic>? result;
    if (widget.transfer) {
      result = await c.write(() => c.repository.transfer(medicineIds: _queue.map((a) => a.medicineId).toList(), rackCode: _rack.value!.code, shelfNumber: '${_shelf.value!.number}', boxCode: _box.text.trim(), reason: _reason.text.trim()), refreshRackId: widget.initialRack?.id);
    } else if (_queue.length == 1) {
      result = await c.write(() => c.repository.assign(_queue.single), refreshRackId: widget.initialRack?.id);
    } else {
      result = await c.write(() => c.repository.bulkAssign(_queue.toList()), refreshRackId: widget.initialRack?.id);
    }
    if (!mounted) return;
    if (result == null) { _error.value = c.operationError.value; return; }
    if (rackInt(result['failedCount']) > 0) {
      // Never automatically retry the entire batch after a partial success.
      final errors = result['errors'] is List ? result['errors'] as List : [];
      _queue.clear();
      _error.value = '${rackInt(result['assignedCount'])} assigned; ${rackInt(result['failedCount'])} failed. Review and add only failed medicines again.\n${errors.map((e) => e is Map ? '${e['medicineId'] ?? ''}: ${e['message'] ?? e['error'] ?? e}' : '$e').join('\n')}';
      return;
    }
    Navigator.pop(context, result);
  }
  @override
  void dispose() { _rackRequest++; _box.dispose(); _reason.dispose(); _medicine.close(); _rack.close(); _shelf.close(); _shelves.close(); _queue.close(); _shelfLoading.close(); _error.close(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AppBottomSheetWrapper(
    title: widget.transfer ? 'Transfer medicines' : 'Place medicines',
    subtitle: widget.transfer ? 'Choose medicines, then their new destination.' : 'Add one placement or build a bulk assignment list.',
    child: Obx(() => AbsorbPointer(absorbing: widget.controller.saving.value, child: ListView(shrinkWrap: true, children: [
      SearchableDropdown<MedicineModel>(value: _medicine.value, items: _masters.medicineChoices, label: (m) => '${m.name} ${m.strength}', loadItems: _masters.loadMedicineChoices, onChanged: (m) => _medicine.value = m),
      SizedBox(height: 12.h),
      SearchableDropdown<RackModel>(value: _rack.value, items: widget.controller.racks.toList(), label: (r) => r.displayName,
        loadItems: () => widget.controller.repository.list(status: 'ACTIVE'),
        onChanged: _selectRack, itemName: 'rack', itemPlural: 'racks', itemIcon: Icons.shelves),
      SizedBox(height: 12.h),
      if (_shelfLoading.value) const LinearProgressIndicator(color: AppColors.primaryEmerald)
      else SearchableDropdown<RackShelfModel>(key: ValueKey(_rack.value?.id), value: _shelf.value, items: _shelves.toList(), label: (s) => s.displayName, onChanged: (s) => _shelf.value = s, itemName: 'shelf', itemPlural: 'shelves', itemIcon: Icons.view_agenda_outlined),
      SizedBox(height: 12.h),
      AppTextField(controller: _box, labelText: 'Box / bin (optional)', hintText: 'Box code'),
      if (widget.transfer) Padding(padding: EdgeInsets.only(top: 12.h), child: AppTextField(controller: _reason, labelText: 'Transfer reason', hintText: 'Reason')),
      TextButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add medicine to list')),
      for (final assignment in _queue) ListTile(
        title: Text(_names[assignment.medicineId] ?? '', style: AppTypography.bodyMedium),
        subtitle: widget.transfer ? null : Text('Rack ${assignment.rackCode} • Shelf ${assignment.shelfNumber}${assignment.boxCode.isEmpty ? '' : ' • Box ${assignment.boxCode}'}'),
        trailing: IconButton(tooltip: 'Remove from list', onPressed: () => _queue.remove(assignment), icon: const Icon(Icons.close)),
      ),
      if (_error.isNotEmpty) Padding(padding: EdgeInsets.symmetric(vertical: 10.h), child: Text(_error.value, style: AppTypography.bodySmall.copyWith(color: AppColors.debitRose))),
      AppButton(title: widget.transfer ? 'Transfer ${_queue.length} medicines' : 'Save ${_queue.length} placements', onPressed: _submit, isLoading: widget.controller.saving.value),
    ]))),
  );
}
