import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/ocr_models.dart';
import '../../../core/theme/app_colors.dart';

class MargOcrPrescriptionStrip extends StatelessWidget {
  final List<OcrItemModel> ocrItems;
  final int selectedIndex;
  final void Function(int index) onItemSelected;

  const MargOcrPrescriptionStrip({
    super.key,
    required this.ocrItems,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (ocrItems.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.primaryEmerald.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primaryEmerald.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 14.sp,
                        color: AppColors.primaryEmerald,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'Prescribed Medicines (${ocrItems.length})',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Tap item to load batch',
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 34.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ocrItems.length,
                  separatorBuilder: (context, index) => SizedBox(width: 6.w),
                  itemBuilder: (ctx, i) {
                    final item = ocrItems[i];
                    final isSelected = i == selectedIndex;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onItemSelected(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryEmerald
                              : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryEmerald
                                : AppColors.borderLight,
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${i + 1} ${item.medicineName}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 1.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white24
                                    : AppColors.borderLight,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'x${item.quantity.toInt()}',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }
}
