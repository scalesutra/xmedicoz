import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/models/smart_search_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../controllers/smart_search_controller.dart';

class SubstituteAlertModal extends StatelessWidget {
  final MedicineSubstituteResponseModel substituteData;
  final Function(MedicineSubstituteModel selectedSubstitute) onSwapSelected;

  const SubstituteAlertModal({
    super.key,
    required this.substituteData,
    required this.onSwapSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required MedicineSubstituteResponseModel data,
    required Function(MedicineSubstituteModel selectedSubstitute) onSwapSelected,
  }) async {
    // Auto-log out-of-stock demand into Shortage Diary
    if (Get.isRegistered<SmartSearchController>()) {
      Get.find<SmartSearchController>().logOutofStockDemand(
        medicineId: data.targetMedicine.id,
        notes: 'Out-of-stock substitute lookup triggered at counter',
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubstituteAlertModal(
        substituteData: data,
        onSwapSelected: onSwapSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = substituteData.targetMedicine;
    final substitutes = substituteData.substitutes;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        border: Border.all(color: AppColors.debitRose.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 38.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Red Alert Header: Out of Stock
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.debitRose.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
              border: Border.all(color: AppColors.debitRose.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.debitRose,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ ${target.name} is Out of Stock!',
                        style: AppTypography.labelBold.copyWith(
                          color: AppColors.debitRose,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Formula: ${target.genericName}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Available In-Stock Substitutes Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Salt-Equivalent Substitutes (${substitutes.length})',
                style: AppTypography.labelBold.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12.sp,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Active Stock Found',
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryEmerald,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // List of Substitutes
          if (substitutes.isEmpty)
            Container(
              padding: EdgeInsets.all(20.w),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    color: AppColors.textMuted,
                    size: 36.sp,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'No direct in-stock substitute found for this formula.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.only(bottom: 24.h),
                itemCount: substitutes.length,
                separatorBuilder: (_, _) => SizedBox(height: 10.h),
                itemBuilder: (ctx, idx) =>
                    _buildSubstituteCard(context, substitutes[idx]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubstituteCard(BuildContext context, MedicineSubstituteModel sub) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        border: Border.all(
          color: sub.isHighMargin
              ? AppColors.primaryEmerald.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name, MRP & Savings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sub.name,
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13.5.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (sub.isCheaper && sub.savingsAmount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'SAVE ₹${sub.savingsAmount.toInt()}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),

          // Salt composition & Manufacturer
          Text(
            'Formula: ${sub.saltComposition}',
            style: AppTypography.caption.copyWith(color: AppColors.clinicalCyan),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.h),

          // Chemist Pitch Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: AppColors.clinicalCyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.record_voice_over_outlined,
                  size: 14.sp,
                  color: AppColors.clinicalCyan,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '"${sub.pitchScript}"',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Badges: Location, Stock, Margin
          Row(
            children: [
              // Rack Locator Chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '📍 ${sub.location.formatted}',
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              SizedBox(width: 6.w),

              // Stock Status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '🟢 Stock: ${sub.totalStock}',
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryEmerald,
                  ),
                ),
              ),
              SizedBox(width: 6.w),

              // Margin Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: sub.isHighMargin
                      ? AppColors.primaryEmerald.withValues(alpha: 0.15)
                      : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: sub.isHighMargin
                        ? AppColors.primaryEmerald.withValues(alpha: 0.4)
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Text(
                  sub.isHighMargin
                      ? '⭐ ${sub.marginPercent}% Margin'
                      : '${sub.marginPercent}% Margin',
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                    color: sub.isHighMargin
                        ? AppColors.primaryEmerald
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // 1-Click Swap Action Button
          AppButton(
            title: '⚡ 1-Click Swap into Bill',
            icon: Icons.swap_horiz_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              onSwapSelected(sub);
              UniqueSnackbar.showSuccess(
                context,
                title: 'Substitute Swapped',
                message: '${sub.name} added to cart! Saved ₹${sub.savingsAmount.toInt()}.',
              );
            },
          ),
        ],
      ),
    );
  }
}
