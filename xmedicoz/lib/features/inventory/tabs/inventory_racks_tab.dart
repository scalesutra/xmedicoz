part of '../inventory_screen.dart';

extension _InventoryRacksTabExt on _InventoryScreenState {
  Widget _buildRackList() {
    return Obx(() {
      if (rackController.loading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryEmerald),
        );
      }
      if (rackController.error.value.isNotEmpty) {
        return Center(
          child: Text(
            rackController.error.value,
            style: const TextStyle(color: AppColors.debitRose),
          ),
        );
      }
      final racks = rackController.racks;
      if (racks.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64.sp,
                color: AppColors.textMuted,
              ),
              SizedBox(height: 16.h),
              Text(
                'No Racks Found',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Create your first rack to track physical inventory.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 115.h),
        itemCount: racks.length,
        separatorBuilder: (_, _) => SizedBox(height: 8.h),
        itemBuilder: (ctx, i) {
          final rack = racks[i];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28.r,
                      height: 28.r,
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                      ),
                      child: Icon(
                        Icons.shelves,
                        size: 15.sp,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rack.displayName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (rack.zone.isNotEmpty)
                            Text(
                              'Zone: ${rack.zone}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    // Compact Place Medicine button
                    InkWell(
                      borderRadius: BorderRadius.circular(6.r),
                      onTap: () {
                        AppBottomSheet.show(
                          context: context,
                          builder: (_) => RackPlacementSheet(
                            controller: rackController,
                            initialRack: rack,
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                            width: 0.8.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_location_alt_outlined,
                              size: 12.sp,
                              color: AppColors.primaryEmerald,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              'Place',
                              style: TextStyle(
                                color: AppColors.primaryEmerald,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    // Compact Audit button
                    InkWell(
                      borderRadius: BorderRadius.circular(6.r),
                      onTap: () {
                        AppBottomSheet.show(
                          context: context,
                          builder: (_) => RackAuditSheetView(
                            controller: rackController,
                            rack: rack,
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.5.h),
                        decoration: BoxDecoration(
                          color: AppColors.clinicalCyan.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: AppColors.clinicalCyan.withValues(alpha: 0.25),
                            width: 0.8.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fact_check_outlined,
                              size: 12.sp,
                              color: AppColors.clinicalCyan,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              'Audit',
                              style: TextStyle(
                                color: AppColors.clinicalCyan,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    // Compact Edit Icon Button
                    InkWell(
                      borderRadius: BorderRadius.circular(6.r),
                      onTap: () {
                        AppBottomSheet.show(
                          context: context,
                          builder: (_) => RackEditorSheet(
                            controller: rackController,
                            rack: rack,
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.5.r),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 7.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _valStat(
                        'Shelves',
                        '${rack.totalShelves}',
                        AppColors.textPrimary,
                      ),
                      Container(width: 1, height: 16.h, color: AppColors.borderSubtle),
                      _valStat(
                        'Medicines',
                        '${rack.medicineCount}',
                        AppColors.primaryEmerald,
                      ),
                      Container(width: 1, height: 16.h, color: AppColors.borderSubtle),
                      _valStat(
                        'Status',
                        rack.status.isNotEmpty ? rack.status : 'ACTIVE',
                        AppColors.clinicalCyan,
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
