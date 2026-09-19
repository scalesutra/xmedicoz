import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';

class MargDoctorStrip extends StatelessWidget {
  final TextEditingController doctorCtrl;
  final TextEditingController doctorRegCtrl;
  final bool showDoctorDetails;
  final VoidCallback onToggleShow;
  final VoidCallback onClear;

  const MargDoctorStrip({
    super.key,
    required this.doctorCtrl,
    required this.doctorRegCtrl,
    required this.showDoctorDetails,
    required this.onToggleShow,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShow = showDoctorDetails ||
        doctorCtrl.text.isNotEmpty ||
        doctorRegCtrl.text.isNotEmpty;

    if (shouldShow) {
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
                controller: doctorCtrl,
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
                controller: doctorRegCtrl,
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
              icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onToggleShow,
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
