part of '../inventory_screen.dart';

extension _InventoryStockLedgerTabExt on _InventoryScreenState {
  Widget _buildLedgerTypeFilterBar() {
    return Obx(() {
      return SizedBox(
        height: 36.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          children: [
            _ledgerFilterChip('', 'All Entries'),
            _ledgerFilterChip('OPENING', 'Opening'),
            _ledgerFilterChip('DAMAGE', 'Damage'),
            _ledgerFilterChip('ADJUSTMENT_ADD', 'Added'),
            _ledgerFilterChip('ADJUSTMENT_SUB', 'Subtracted'),
            _ledgerFilterChip('PURCHASE', 'Purchases'),
            _ledgerFilterChip('SALE', 'Sales'),
          ],
        ),
      );
    });
  }

  Widget _ledgerFilterChip(String type, String label) {
    final isSelected = batchController.ledgerTransactionFilter.value == type;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          batchController.ledgerTransactionFilter.value = val ? type : '';
          batchController.fetchLedger();
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

  Widget _buildStockLedgerList() {
    return Obx(() {
      final isBusy = batchController.isLoadingLedger.value;
      final logs = batchController.stockLedgerList;

      if (isBusy && logs.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryEmerald),
        );
      }

      if (logs.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 80.h),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48.sp,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'No inventory audit records found',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        );
      }

      final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 115.h),
        itemCount: logs.length,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (ctx, i) {
          final entry = logs[i];
          final isPositive = entry.quantityDelta >= 0;

          return Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.medicineName ?? 'Medicine',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? AppColors.creditGreenBg
                            : AppColors.debitRoseBg,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${entry.quantityDelta}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? AppColors.creditGreen
                              : AppColors.debitRose,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Batch: ${entry.batchNumber ?? ''} • Type: ${entry.transactionType}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.clinicalCyan,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Balance: ${entry.balanceAfter}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (entry.notes.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Notes: ${entry.notes}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 6.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.createdAt != null
                            ? dateFmt.format(entry.createdAt!)
                            : '',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.performedByName != null) ...[
                      SizedBox(width: 8.w),
                      Text(
                        'By: ${entry.performedByName}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

}
