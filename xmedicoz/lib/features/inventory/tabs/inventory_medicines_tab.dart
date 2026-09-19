// ignore_for_file: invalid_use_of_protected_member
part of '../inventory_screen.dart';

extension _InventoryMedicinesTabExt on _InventoryScreenState {
  Widget _buildCategoryFilterBar() {
    return Obx(() {
      final cats = masterController.categories;
      return SizedBox(
        height: 36.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          children: [
            _catChip(null, 'All Categories'),
            ...cats.map((c) => _catChip(c.id, c.name)),
          ],
        ),
      );
    });
  }

  Widget _catChip(String? id, String label) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() => _selectedCategoryId = val ? id : null);
          masterController.fetchMedicines(
            search: _searchCtrl.text.trim(),
            categoryId: _selectedCategoryId,
          );
        },
        backgroundColor: AppColors.bgCard,
        selectedColor: AppColors.primaryEmerald.withValues(alpha: 0.15),
        labelStyle: AppTypography.bodySmall.copyWith(
          color: isSelected
              ? AppColors.primaryEmerald
              : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
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

  Widget _buildMedicinesList() {
    return Obx(() {
      final isBusy = masterController.isLoadingMedicines.value;
      final medicines = masterController.medicines;

      if (isBusy && medicines.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryEmerald),
        );
      }
      if (medicines.isEmpty) {
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
                        color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryEmerald.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 42.sp,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'No Medicines In Catalog',
                      style: AppTypography.h3.copyWith(fontSize: 16.sp),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Tap "Add Medicine" below to register new pharmaceutical products.',
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

      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 115.h),
        itemCount: medicines.length,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (ctx, i) => _buildMedicineCard(medicines[i]),
      );
    });
  }

  Widget _buildMedicineCard(MedicineModel item) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38.w,
                height: 38.h,
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                  border: Border.all(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: AppColors.primaryEmerald,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.genericName.isNotEmpty)
                      Text(
                        item.genericName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: AppColors.primaryEmerald.withValues(alpha: 0.06),
                  splashColor: AppColors.primaryEmerald.withValues(alpha: 0.1),
                ),
                child: PopupMenuButton<String>(
                  tooltip: 'Medicine Actions',
                  color: AppColors.bgSurface,
                  surfaceTintColor: AppColors.transparent,
                  elevation: 14,
                  shadowColor: AppColors.darkInk.withValues(alpha: 0.22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(
                      color: AppColors.borderMedium.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  offset: Offset(0, 38.h),
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                      size: 19.sp,
                    ),
                  ),
                  onSelected: (val) {
                    if (val == 'add_batch') {
                      _showAddBatchSheet(item);
                    } else if (val == 'deactivate') {
                      _handleDeleteMedicine(item);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      height: 28.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Text(
                        'QUICK ACTIONS',
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'add_batch',
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34.w,
                            height: 34.w,
                            decoration: BoxDecoration(
                              color: AppColors.clinicalCyan.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(9.r),
                              border: Border.all(
                                color: AppColors.clinicalCyan.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18.sp,
                              color: AppColors.clinicalCyan,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Add Batch Stock',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'New inventory, expiry & rates',
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'deactivate',
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34.w,
                            height: 34.w,
                            decoration: BoxDecoration(
                              color: AppColors.debitRoseBg,
                              borderRadius: BorderRadius.circular(9.r),
                              border: Border.all(
                                color: AppColors.debitRose.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.archive_outlined,
                              size: 18.sp,
                              color: AppColors.debitRose,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Deactivate Medicine',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.debitRose,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Archive from active catalog',
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Medicine Meta Tags Row
          Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: [
              _tagBadge(
                item.dosageForm,
                AppColors.textPrimary,
                AppColors.bgCard,
              ),
              if (item.strength.isNotEmpty)
                _tagBadge(
                  item.strength,
                  AppColors.primaryEmerald,
                  AppColors.creditGreenBg,
                ),
              if (item.brand.isNotEmpty && item.brand != item.name)
                _tagBadge(
                  'Brand: ${item.brand}',
                  AppColors.clinicalCyan,
                  AppColors.clinicalCyan.withValues(alpha: 0.1),
                ),
              if (item.unit != null)
                _tagBadge(
                  item.unit!.name,
                  AppColors.textSecondary,
                  AppColors.bgCard,
                ),
              if (item.prescriptionRequired)
                _tagBadge(
                  'Rx Required',
                  AppColors.debitRose,
                  AppColors.debitRoseBg,
                ),
              if (item.category != null)
                _tagBadge(
                  item.category!.name,
                  AppColors.textMuted,
                  AppColors.bgCard,
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // Pricing Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _priceCol('MRP', Formatters.formatCurrency(item.mrp)),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _priceCol(
                    'Sale Price',
                    Formatters.formatCurrency(item.sellingPrice),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _priceCol(
                    'Purchase',
                    Formatters.formatCurrency(item.purchaseRate),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _priceCol(
                    'Margin',
                    '${item.profitMargin.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
