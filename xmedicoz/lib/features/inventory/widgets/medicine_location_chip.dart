import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/rack_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../repositories/rack_repository.dart';

/// Read-only location lookup. Never reuses a previous medicine's coordinates.
class MedicineLocationChip extends StatefulWidget {
  const MedicineLocationChip({super.key, required this.medicineId, this.repository});
  final String medicineId;
  final RackRepository? repository;
  @override
  State<MedicineLocationChip> createState() => _MedicineLocationChipState();
}

class _MedicineLocationChipState extends State<MedicineLocationChip> {
  final _location = Rxn<MedicineLocationModel>();
  final _loading = false.obs, _failed = false.obs;
  int _request = 0;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void didUpdateWidget(covariant MedicineLocationChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medicineId != widget.medicineId) _load();
  }
  Future<void> _load() async {
    final request = ++_request;
    _location.value = null;
    _failed.value = false;
    _loading.value = true;
    try {
      final value = await (widget.repository ?? RackRepository()).locate(widget.medicineId);
      if (mounted && request == _request) _location.value = value;
    } catch (_) {
      if (mounted && request == _request) _failed.value = true;
    } finally {
      if (mounted && request == _request) _loading.value = false;
    }
  }
  @override
  void dispose() {
    _request++;
    _location.close(); _loading.close(); _failed.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Obx(() {
    final location = _location.value;
    return InkWell(
      onTap: location == null ? null : () => AppBottomSheet.show(context: context, builder: (_) => AppBottomSheetWrapper(
        title: location.name,
        subtitle: location.formatted,
        child: ListView(shrinkWrap: true, children: [
          Text('${location.totalStock} units across ${location.batches.length} batches', style: AppTypography.bodyMedium),
          if (location.batches.isEmpty) Text('No batch stock reported.', style: AppTypography.bodySmall),
          for (final batch in location.batches) ListTile(
            title: Text(batch.number, style: AppTypography.bodyMedium),
            subtitle: Text(batch.expiry == null ? 'Expiry not recorded' : 'Expiry ${DateFormat.yMMMd().format(batch.expiry!)}'),
            trailing: Text('${batch.quantity}', style: AppTypography.labelBold),
          ),
        ]),
      )),
      child: Padding(padding: EdgeInsets.symmetric(vertical: 8.h), child: Row(children: [
        Icon(Icons.location_on_outlined, color: AppColors.primaryEmerald, size: 18.sp),
        SizedBox(width: 6.w),
        Expanded(child: Text(_loading.value ? 'Finding rack location…' : _failed.value ? 'Location unavailable' : location?.formatted ?? 'Location not assigned', style: AppTypography.bodySmall)),
        if (_failed.value) IconButton(tooltip: 'Retry location', onPressed: _load, icon: const Icon(Icons.refresh)),
      ])),
    );
  });
}
