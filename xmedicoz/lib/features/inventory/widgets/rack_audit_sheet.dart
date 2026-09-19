import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/rack_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/batch_controller.dart';
import '../controllers/rack_controller.dart';

class RackAuditSheetView extends StatefulWidget {
  const RackAuditSheetView({
    super.key,
    required this.controller,
    required this.rack,
  });
  final RackController controller;
  final RackModel rack;
  @override
  State<RackAuditSheetView> createState() => _RackAuditSheetViewState();
}

class _RackAuditSheetViewState extends State<RackAuditSheetView> {
  final _sheet = Rxn<RackAuditSheet>();
  final _loading = true.obs, _done = false.obs;
  final _error = ''.obs, _result = ''.obs;
  final _counts = <String, TextEditingController>{},
      _notes = <String, TextEditingController>{};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _loading.value = true;
    _error.value = '';
    try {
      final sheet = await widget.controller.repository.auditSheet(
        widget.rack.id,
      );
      if (!mounted) return;
      if (sheet.rackId != widget.rack.id ||
          sheet.items.any((i) => i.batchId.isEmpty) ||
          sheet.items.map((i) => i.batchId).toSet().length !=
              sheet.items.length) {
        throw StateError('Invalid audit data');
      }
      _sheet.value = sheet;
      for (final item in sheet.items) {
        _counts[item.batchId] = TextEditingController();
        _notes[item.batchId] = TextEditingController();
      }
    } catch (e) {
      if (mounted) _error.value = RackController.message(e);
    } finally {
      if (mounted) _loading.value = false;
    }
  }

  Future<void> _submit() async {
    if (_done.value || widget.controller.saving.value) return;
    final items = _sheet.value?.items ?? [];
    if (items.isEmpty) return;
    final counts = <RackAuditCount>[];
    for (final item in items) {
      final count = int.tryParse(_counts[item.batchId]!.text.trim());
      if (count == null || count < 0) {
        _error.value =
            'Enter an actual count of zero or more for every batch. Counts are never filled automatically.';
        return;
      }
      final notes = _notes[item.batchId]!.text.trim();
      counts.add(
        RackAuditCount(
          batchId: item.batchId,
          physicalCount: count,
          systemCount: item.systemStock,
          notes: notes.isEmpty ? null : notes,
        ),
      );
    }
    final changes = counts
        .where((c) => c.physicalCount != c.systemCount)
        .toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Review physical counts', style: AppTypography.h3),
        content: SizedBox(
          width: 420.w,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${counts.length} batches checked; ${changes.length} stock adjustments. Submitting updates inventory quantities and records the adjustments.',
                  style: AppTypography.bodyMedium,
                ),
                for (final change in changes)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      '${items.firstWhere((i) => i.batchId == change.batchId).batchNumber}: ${change.systemCount} → ${change.physicalCount}',
                      style: AppTypography.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm counts'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await widget.controller.write(
      () => widget.controller.repository.verifyAudit(widget.rack.id, counts),
      refreshRackId: widget.rack.id,
    );
    if (!mounted) return;
    if (result == null) {
      _error.value = widget.controller.operationError.value;
      return;
    }
    _done.value = true;
    _error.value = '';
    _result.value =
        '${rackInt(result['totalItemsAudited'])} batches audited • ${rackInt(result['adjustmentsRecorded'])} adjustments recorded';
    if (Get.isRegistered<BatchController>()) {
      final batches = Get.find<BatchController>();
      batches.refreshAll();
      batches.fetchLedger();
    }
  }

  @override
  void dispose() {
    for (final c in [..._counts.values, ..._notes.values]) {
      c.dispose();
    }
    _sheet.close();
    _loading.close();
    _done.close();
    _error.close();
    _result.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppBottomSheetWrapper(
    title: 'Stocktake • Rack ${widget.rack.code}',
    child: Obx(() {
      if (_loading.value)
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryEmerald),
        );
      if (_done.value)
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_outlined,
              color: AppColors.primaryEmerald,
              size: 40.sp,
            ),
            Text(_result.value, style: AppTypography.bodyMedium),
            SizedBox(height: 12.h),
            AppButton(title: 'Done', onPressed: () => Navigator.pop(context)),
          ],
        );
      final sheet = _sheet.value;
      if (sheet == null)
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error.value, style: AppTypography.bodySmall),
            AppButton(title: 'Retry', onPressed: _load),
          ],
        );
      if (sheet.items.isEmpty)
        return Text(
          'No batches on this rack to count.',
          style: AppTypography.bodyMedium,
        );
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sheet.generatedAt == null
                ? 'Count each batch physically before submitting.'
                : 'Snapshot ${DateFormat.yMMMd().add_jm().format(sheet.generatedAt!.toLocal())}',
            style: AppTypography.bodySmall,
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sheet.items.length,
              itemBuilder: (_, index) {
                final item = sheet.items[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 6.h),
                  padding: EdgeInsets.all(12.r),
                  decoration: AppDecorations.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.medicineName, style: AppTypography.labelBold),
                      Text(
                        '${item.batchNumber} • Shelf ${item.shelf}${item.box.isEmpty ? '' : ' • Box ${item.box}'}',
                        style: AppTypography.bodySmall,
                      ),
                      Text(
                        'System stock: ${item.systemStock}${item.expiry == null ? '' : ' • Expiry ${DateFormat.yMMMd().format(item.expiry!)}'}',
                        style: AppTypography.bodySmall,
                      ),
                      SizedBox(height: 8.h),
                      AppTextField(
                        controller: _counts[item.batchId],
                        hintText: 'Actual physical count *',
                        keyboardType: TextInputType.number,
                        readOnly: widget.controller.saving.value,
                      ),
                      SizedBox(height: 8.h),
                      AppTextField(
                        controller: _notes[item.batchId],
                        hintText: 'Notes (optional)',
                        readOnly: widget.controller.saving.value,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_error.isNotEmpty)
            Text(
              _error.value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.debitRose,
              ),
            ),
          SizedBox(height: 10.h),
          AppButton(
            title: 'Review and reconcile',
            onPressed: _submit,
            isLoading: widget.controller.saving.value,
          ),
        ],
      );
    }),
  );
}
