import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/models/smart_search_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../controllers/smart_search_controller.dart';

class ShortageDiarySheet extends StatelessWidget {
  const ShortageDiarySheet({super.key});

  static void show(BuildContext context) {
    if (Get.isRegistered<SmartSearchController>()) {
      Get.find<SmartSearchController>().fetchShortageDiary();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ShortageDiarySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SmartSearchController>()
        ? Get.find<SmartSearchController>()
        : Get.put(SmartSearchController());

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Shortage Diary', style: AppTypography.h3),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.debitRose.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'SHORTAGE REGISTER',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.debitRose,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Track out-of-stock customer demand & auto orders',
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),

          // Shortage Items List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingShortage.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryEmerald,
                  ),
                );
              }

              final items = controller.shortageItems;
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48.sp,
                        color: AppColors.primaryEmerald,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'No Shortage Demands Logged',
                        style: AppTypography.h4,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Whenever a customer asks for an out-of-stock medicine,\nit is tracked here with suggested reorder quantities.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => SizedBox(height: 10.h),
                itemBuilder: (ctx, idx) =>
                    _buildShortageCard(context, controller, items[idx]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildShortageCard(
    BuildContext context,
    SmartSearchController controller,
    ShortageDiaryItemModel item,
  ) {
    final isPending = item.status == 'PENDING';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        border: Border.all(
          color: isPending
              ? AppColors.debitRose.withValues(alpha: 0.4)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Demand Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.medicineName,
                  style: AppTypography.labelBold.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.debitRose.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.debitRose.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${item.customerCount} Demanded',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.debitRose,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),

          // Generic formula & Rack
          Row(
            children: [
              Expanded(
                child: Text(
                  item.genericName.isNotEmpty
                      ? item.genericName
                      : (item.manufacturer.isNotEmpty
                            ? item.manufacturer
                            : 'Pharma Master'),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.clinicalCyan,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '📍 ${item.rackLocation}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Order recommendation & Preferred supplier
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: 14,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      item.preferredSupplier.name.isNotEmpty
                          ? item.preferredSupplier.name
                          : 'Apex Pharma Distributors',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Suggest: ${item.suggestedReorderQty} packs',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryEmerald,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isPending) ...[
                OutlinedButton(
                  onPressed: () async {
                    await controller.updateShortageStatus(
                      item.id,
                      status: 'PO_CREATED',
                      notes: 'Marked as PO Created by chemist',
                    );
                    if (context.mounted) {
                      UniqueSnackbar.showSuccess(
                        context,
                        title: 'Status Updated',
                        message: '${item.medicineName} marked as PO Created.',
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Mark PO Created',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: () async {
                    await controller.updateShortageStatus(
                      item.id,
                      status: 'RESOLVED',
                    );
                    if (context.mounted) {
                      UniqueSnackbar.showSuccess(
                        context,
                        title: 'Resolved',
                        message:
                            '${item.medicineName} resolved from shortage diary.',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Resolved',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryEmerald,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
