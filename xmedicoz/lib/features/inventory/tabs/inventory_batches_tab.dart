part of '../inventory_screen.dart';

extension _InventoryBatchesTabExt on _InventoryScreenState {
  Widget _buildBatchStatusFilterBar() {
    return Obx(() {
      final inStockOnly = batchController.inStockOnlyFilter.value;

      return SizedBox(
        height: 36.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          children: [
            _statusChip('', 'All Batches'),
            _statusChip('ACTIVE', 'Active'),
            _statusChip('NEAR_EXPIRY', 'Near Expiry'),
            _statusChip('EXPIRED', 'Expired'),
            _statusChip('QUARANTINED', 'Quarantined'),
            Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: FilterChip(
                label: const Text('In-Stock Only'),
                selected: inStockOnly,
                onSelected: (val) {
                  batchController.inStockOnlyFilter.value = val;
                  batchController.fetchBatches(resetPage: true);
                },
                backgroundColor: AppColors.bgCard,
                selectedColor: AppColors.primaryEmerald.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontSize: 11.5.sp,
                  color: inStockOnly
                      ? AppColors.primaryEmerald
                      : AppColors.textSecondary,
                  fontWeight: inStockOnly ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                  side: BorderSide(
                    color: inStockOnly
                        ? AppColors.primaryEmerald
                        : AppColors.borderSubtle,
                  ),
                ),
                showCheckmark: false,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _statusChip(String status, String label) {
    final isSelected = batchController.batchStatusFilter.value == status;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          batchController.batchStatusFilter.value = val ? status : '';
          batchController.fetchBatches(resetPage: true);
        },
        backgroundColor: AppColors.bgCard,
        selectedColor: AppColors.primaryEmerald.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          fontSize: 11.5.sp,
          color: isSelected
              ? AppColors.primaryEmerald
              : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          side: BorderSide(
            color: isSelected
                ? AppColors.primaryEmerald
                : AppColors.borderSubtle,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildBatchesList() {
    return Obx(() {
      final isBusy = batchController.isLoadingBatches.value;
      final filter = batchController.batchStatusFilter.value;
      final rawBatches = batchController.batches;

      final batches = rawBatches.where((b) {
        if (filter.isEmpty) return true;
        if (filter == 'EXPIRED') return b.isExpired;
        if (filter == 'NEAR_EXPIRY')
          return !b.isExpired && b.daysUntilExpiry <= 90;
        if (filter == 'ACTIVE') return b.status == 'ACTIVE' && !b.isExpired;
        return b.status == filter;
      }).toList();

      if (isBusy && batches.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryEmerald),
        );
      }

      if (batches.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 70.h),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.clinicalCyan.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.clinicalCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.layers_clear_outlined,
                        size: 42.sp,
                        color: AppColors.clinicalCyan,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'No Batches In Inventory',
                      style: AppTypography.h3.copyWith(fontSize: 16.sp),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Tap "Add Batch" below to record opening stock, MRP, expiry, and supplier inward.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }

      final dateFmt = DateFormat('dd MMM yyyy');

      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 115.h),
        itemCount: batches.length,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (ctx, i) {
          final b = batches[i];
          final isExpired = b.isExpired;
          final isNearExp = !isExpired && b.daysUntilExpiry <= 90;

          return Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              border: Border.all(
                color: isExpired
                    ? AppColors.debitRose.withValues(alpha: 0.5)
                    : isNearExp
                    ? Colors.orange.withValues(alpha: 0.5)
                    : AppColors.borderSubtle,
              ),
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
                            b.medicine?.name ?? 'Medicine Name',
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6.w,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.clinicalCyan.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  b.batchNumber,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.clinicalCyan,
                                  ),
                                ),
                              ),
                              if (b.medicine?.dosageForm != null)
                                Text(
                                  '(${b.medicine!.dosageForm})',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Current Stock Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: b.currentQuantity > 0
                            ? AppColors.primaryEmerald.withValues(alpha: 0.12)
                            : AppColors.debitRoseBg,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: b.currentQuantity > 0
                              ? AppColors.primaryEmerald.withValues(alpha: 0.3)
                              : AppColors.debitRose.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${b.currentQuantity}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: b.currentQuantity > 0
                                  ? AppColors.primaryEmerald
                                  : AppColors.debitRose,
                            ),
                          ),
                          Text(
                            'In Stock',
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Dates & Condition Tag Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 14.sp,
                            color: isExpired
                                ? AppColors.debitRose
                                : isNearExp
                                ? Colors.orange.shade700
                                : AppColors.textMuted,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              b.expiryDate != null
                                  ? 'Exp: ${dateFmt.format(b.expiryDate!)}'
                                  : 'No Expiry',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: isExpired || isNearExp
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isExpired
                                    ? AppColors.debitRose
                                    : isNearExp
                                    ? Colors.orange.shade700
                                    : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    _tagBadge(
                      b.status,
                      b.status == 'ACTIVE'
                          ? AppColors.primaryEmerald
                          : AppColors.debitRose,
                      b.status == 'ACTIVE'
                          ? AppColors.creditGreenBg
                          : AppColors.debitRoseBg,
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                // Financial Row & Adjust Button
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(
                      AppDecorations.radiusSm,
                    ),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _priceCol(
                          'MRP',
                          Formatters.formatCurrency(b.mrp),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: _priceCol(
                          'Sale Price',
                          Formatters.formatCurrency(b.sellingPrice),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: _priceCol(
                          'Purchase',
                          Formatters.formatCurrency(b.purchaseRate),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      OutlinedButton.icon(
                        onPressed: () => _showStockAdjustmentSheet(b),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primaryEmerald,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(
                          Icons.tune_rounded,
                          size: 13,
                          color: AppColors.primaryEmerald,
                        ),
                        label: Text(
                          'Adjust',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: AppColors.primaryEmerald,
                            fontWeight: FontWeight.bold,
                          ),
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
