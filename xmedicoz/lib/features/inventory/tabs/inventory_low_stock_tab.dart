part of '../inventory_screen.dart';

extension _InventoryLowStockTabExt on _InventoryScreenState {
  Widget _buildLowStockList() {
    return Obx(() {
      final isBusy = batchController.isLoadingLowStock.value;
      final items = batchController.lowStockList;

      if (isBusy && items.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.orange),
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
                    Icons.check_circle_outline_rounded,
                    size: 48.sp,
                    color: AppColors.primaryEmerald,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'All medicines are adequately stocked!',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 115.h),
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              border: Border.all(color: Colors.orange.shade700, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.genericName != null &&
                              item.genericName!.isNotEmpty)
                            Text(
                              item.genericName!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Deficit: ${item.deficit}',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                // Stock vs Reorder Level comparison
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Stock: ${item.totalStock} ${item.unit ?? ''}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: item.totalStock == 0
                            ? AppColors.debitRose
                            : Colors.orange.shade800,
                      ),
                    ),
                    Text(
                      'Reorder Level: ${item.reorderLevel}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Action to Restock
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Find matching medicine in MasterDataController if available
                      MedicineModel? med;
                      try {
                        med = masterController.medicines.firstWhere(
                          (m) => m.id == item.id,
                        );
                      } catch (_) {}
                      _showAddBatchSheet(med);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryEmerald),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      size: 16,
                      color: AppColors.primaryEmerald,
                    ),
                    label: Text(
                      'Add Batch Stock (Restock)',
                      style: AppTypography.labelBold.copyWith(
                        color: AppColors.primaryEmerald,
                      ),
                    ),
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
