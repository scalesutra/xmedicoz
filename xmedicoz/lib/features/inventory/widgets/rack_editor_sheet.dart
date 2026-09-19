import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/models/rack_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/rack_controller.dart';

/// One editor for rack configuration and its child shelves.
class RackEditorSheet extends StatefulWidget {
  const RackEditorSheet({
    super.key,
    required this.controller,
    this.rack,
    this.shelf,
    this.editShelf = false,
  });
  final RackController controller;
  final RackModel? rack;
  final RackShelfModel? shelf;
  final bool editShelf;
  @override
  State<RackEditorSheet> createState() => _RackEditorSheetState();
}

class _RackEditorSheetState extends State<RackEditorSheet> {
  final _fields = <String, TextEditingController>{};
  final _error = ''.obs;
  TextEditingController field(String key) => _fields[key]!;
  @override
  void initState() {
    super.initState();
    final r = widget.rack, s = widget.shelf;
    final values = widget.editShelf
        ? {
            'shelfNumber': s?.number.toString() ?? '',
            'shelfLabel': s?.label ?? '',
            'maxCapacity': s == null || s.maxCapacity == 0
                ? ''
                : '${s.maxCapacity}',
            'temperature': s?.temperature?.toString() ?? '',
          }
        : {
            'code': r?.code ?? '',
            'name': r?.name ?? '',
            'zone': r?.zone ?? 'MAIN_COUNTER',
            'storageType': r?.storageType ?? 'STANDARD',
            'description': r?.description ?? '',
            'totalShelves': r?.totalShelves.toString() ?? '',
            'rowNumber': r == null || r.row == 0 ? '' : '${r.row}',
            'columnNumber': r == null || r.column == 0 ? '' : '${r.column}',
            'status': r?.status ?? 'ACTIVE',
          };
    for (final entry in values.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    _error.close();
    super.dispose();
  }

  Widget input(
    String key,
    String label, {
    bool number = false,
    bool readOnly = false,
    int maxLines = 1,
  }) => Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: AppTextField(
      controller: field(key),
      hintText: label,
      labelText: label,
      readOnly: readOnly,
      maxLines: maxLines,
      scrollPadding: EdgeInsets.only(bottom: 120.h),
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
    ),
  );
  Future<void> save() async {
    final data = <String, dynamic>{};
    _error.value = '';
    for (final entry in _fields.entries) {
      data[entry.key] = entry.value.text.trim();
    }
    final requiredKeys = widget.editShelf
        ? ['shelfNumber', 'shelfLabel', 'maxCapacity']
        : ['code', 'name', 'zone', 'storageType', 'totalShelves', 'status'];
    if (requiredKeys.any((key) => data[key] == '')) {
      _error.value = 'Complete all required fields.';
      return;
    }
    for (final key
        in widget.editShelf
            ? ['shelfNumber', 'maxCapacity']
            : ['totalShelves', 'rowNumber', 'columnNumber']) {
      if (data[key] == '') {
        data.remove(key);
        continue;
      }
      final number = int.tryParse('${data[key]}');
      if (number == null || number <= 0) {
        _error.value =
            'Shelf numbers, capacities and grid positions must be positive whole numbers.';
        return;
      }
      data[key] = number;
    }
    if (widget.editShelf) {
      final raw = data['temperature'] as String;
      final temperature = raw.isEmpty ? null : double.tryParse(raw);
      if (raw.isNotEmpty && (temperature == null || !temperature.isFinite)) {
        _error.value = 'Enter a valid temperature or leave it empty.';
        return;
      }
      data['temperature'] = temperature;
      if (widget.shelf == null &&
          widget.rack!.shelves.any((s) => s.number == data['shelfNumber'])) {
        _error.value = 'This shelf number already exists.';
        return;
      }
    } else if (widget.rack != null &&
        (data['totalShelves'] as int) < widget.rack!.totalShelves) {
      _error.value =
          'Remove individual shelves from the rack detail screen before reducing its layout.';
      return;
    }
    final c = widget.controller;
    final Object? result;
    if (widget.editShelf) {
      result = await c.write(
        () => widget.shelf == null
            ? c.repository.addShelf(widget.rack!.id, data)
            : c.repository.updateShelf(widget.rack!.id, widget.shelf!.id, data),
        refreshRackId: widget.rack!.id,
      );
    } else {
      result = await c.write(
        () => widget.rack == null
            ? c.repository.create(data)
            : c.repository.update(widget.rack!.id, data),
        refreshRackId: widget.rack?.id,
      );
    }
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context, result);
    } else {
      _error.value = c.operationError.value;
    }
  }

  @override
  Widget build(BuildContext context) => AppBottomSheetWrapper(
    title: widget.editShelf
        ? (widget.shelf == null ? 'Add shelf' : 'Edit shelf')
        : (widget.rack == null ? 'Create rack' : 'Edit rack'),
    child: Obx(
      () => AbsorbPointer(
        absorbing: widget.controller.saving.value,
        child: ListView(
          shrinkWrap: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: 16.h),
          children: [
            if (widget.editShelf) ...[
              input(
                'shelfNumber',
                'Shelf number *',
                number: true,
                readOnly: widget.shelf != null,
              ),
              input('shelfLabel', 'Shelf label *'),
              input('maxCapacity', 'Maximum capacity *', number: true),
              input('temperature', 'Temperature °C (optional)', number: true),
            ] else ...[
              input('code', 'Rack code *', readOnly: widget.rack != null),
              input('name', 'Rack name *'),
              input('zone', 'Zone *'),
              input('storageType', 'Storage type *'),
              input('totalShelves', 'Number of shelves *', number: true),
              Row(
                children: [
                  Expanded(child: input('rowNumber', 'Grid row', number: true)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: input('columnNumber', 'Grid column', number: true),
                  ),
                ],
              ),
              input('description', 'Description', maxLines: 2),
              if (widget.rack != null) input('status', 'Status *'),
            ],
            if (_error.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(
                  _error.value,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.debitRose,
                  ),
                ),
              ),
            AppButton(
              title: 'Save',
              onPressed: save,
              isLoading: widget.controller.saving.value,
            ),
          ],
        ),
      ),
    ),
  );
}
