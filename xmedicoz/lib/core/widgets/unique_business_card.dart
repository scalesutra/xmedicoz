import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_typography.dart';

class UniqueBusinessCard extends StatelessWidget {
  final BusinessCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const UniqueBusinessCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = category.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withValues(alpha: 0.12)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
          border: Border.all(
            color: isSelected ? themeColor : AppColors.borderSubtle,
            width: isSelected ? 2.0.w : 1.0.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.28),
                    blurRadius: 18.r,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8.r,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Glowing Icon Badge
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.45),
                      width: 1.w,
                    ),
                  ),
                  child: Icon(
                    category.icon,
                    size: 24.sp,
                    color: themeColor,
                  ),
                ),
                const Spacer(),
                // Selection Indicator Chip
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? themeColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? themeColor : AppColors.borderSubtle,
                      width: 1.5.w,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded, size: 16.sp, color: AppColors.darkContrast)
                      : null,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              category.title,
              style: AppTypography.h4.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              category.subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.textPrimary.withValues(alpha: 0.8) : AppColors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 10.h),
            // Industry specific feature pills
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: category.highlights.take(2).map((perk) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                    border: Border.all(
                      color: isSelected
                          ? themeColor.withValues(alpha: 0.35)
                          : AppColors.borderSubtle,
                      width: 0.8.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 10.sp, color: themeColor),
                      SizedBox(width: 3.w),
                      Text(
                        perk,
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
