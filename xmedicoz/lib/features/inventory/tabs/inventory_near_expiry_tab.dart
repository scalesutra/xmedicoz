part of '../inventory_screen.dart';

extension _InventoryNearExpiryTabExt on _InventoryScreenState {
  Widget _buildNearExpiryDaysFilterBar() {
    return Obx(() {
      return SizedBox(
        height: 36.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          children: [
            _daysChip(30, 'Expiring in 30 Days'),
            _daysChip(60, 'Expiring in 60 Days'),
            _daysChip(90, 'Expiring in 90 Days'),
            _daysChip(180, 'Expiring in 180 Days'),
          ],
        ),
      );
    });
  }

  Widget _daysChip(int d, String label) {
    final isSelected = batchController.nearExpiryDays.value == d;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => batchController.fetchNearExpiry(days: d),
        backgroundColor: AppColors.bgCard,
        selectedColor: AppColors.debitRose.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          fontSize: 11.5.sp,
          color: isSelected ? AppColors.debitRose : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          side: BorderSide(
            color: isSelected ? AppColors.debitRose : AppColors.borderSubtle,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildNearExpiryList() {
    return Obx(() {
      final isBusy = batchController.isLoadingNearExpiry.value;
      final items = batchController.nearExpiryList;

      if (isBusy && items.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.debitRose),
        );
      }

      if (items.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 80.h),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 48.sp,
                    color: AppColors.primaryEmerald,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'No expiring stock within selected window!',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        );
      }

      final dateFmt = DateFormat('dd MMM yyyy');

      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 115.h),
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(height: 8.h),
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              border: Border.all(
                color: item.isExpired
                    ? AppColors.debitRose
                    : Colors.orange.shade700,
                width: 1.1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.medicineName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.5.h),
                      Text(
                        'Batch: ${item.batchNumber}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.clinicalCyan,
                          fontSize: 10.5.sp,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(
                            item.isExpired
                                ? Icons.cancel_outlined
                                : Icons.timelapse,
                            size: 13.sp,
                            color: item.isExpired
                                ? AppColors.debitRose
                                : Colors.orange.shade800,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            item.isExpired
                                ? 'EXPIRED (${item.daysRemaining.abs()} days ago)'
                                : 'Expires in ${item.daysRemaining} days',
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              color: item.isExpired
                                  ? AppColors.debitRose
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      if (item.expiryDate != null)
                        Text(
                          'Expiry Date: ${dateFmt.format(item.expiryDate!)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.debitRoseBg,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppColors.debitRose.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${item.currentQuantity}',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.debitRose,
                        ),
                      ),
                      Text(
                        'Units Left',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

}
