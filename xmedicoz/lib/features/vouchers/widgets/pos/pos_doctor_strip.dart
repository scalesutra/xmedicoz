import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class PosDoctorStrip extends StatefulWidget {
  final TextEditingController doctorCtrl;
  final TextEditingController doctorRegCtrl;
  final bool initialExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const PosDoctorStrip({
    super.key,
    required this.doctorCtrl,
    required this.doctorRegCtrl,
    this.initialExpanded = false,
    this.onExpansionChanged,
  });

  @override
  State<PosDoctorStrip> createState() => _PosDoctorStripState();
}

class _PosDoctorStripState extends State<PosDoctorStrip> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initialExpanded ||
        widget.doctorCtrl.text.isNotEmpty ||
        widget.doctorRegCtrl.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_expanded ||
        widget.doctorCtrl.text.isNotEmpty ||
        widget.doctorRegCtrl.text.isNotEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(
              Icons.medical_services_rounded,
              size: 16.sp,
              color: AppColors.primaryEmerald,
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 3,
              child: TextField(
                controller: widget.doctorCtrl,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Consulting Doctor',
                ),
              ),
            ),
            Container(
              width: 1.w,
              height: 18.h,
              color: AppColors.borderLight,
            ),
            SizedBox(width: 8.w),
            Expanded(
              flex: 2,
              child: TextField(
                controller: widget.doctorRegCtrl,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  color: AppColors.textSecondary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'MCI Reg No',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _expanded = false;
                  widget.doctorCtrl.clear();
                  widget.doctorRegCtrl.clear();
                });
                widget.onExpansionChanged?.call(false);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() => _expanded = true);
        widget.onExpansionChanged?.call(true);
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
        child: Row(
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 14.sp,
              color: AppColors.textMuted,
            ),
            SizedBox(width: 6.w),
            Text(
              '+ Add Doctor / MCI Reg No (Optional)',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
