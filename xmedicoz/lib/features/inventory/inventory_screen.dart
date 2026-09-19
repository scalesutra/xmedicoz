import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/models/batch_models.dart';
import '../../core/models/master_models.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/unique_snackbar.dart';
import '../../core/widgets/unique_3d_refresh_indicator.dart';
import 'add_stock_sheet.dart';
import 'controllers/batch_controller.dart';
import 'controllers/master_data_controller.dart';
import 'controllers/rack_controller.dart';
import 'widgets/add_batch_modal.dart';
import 'widgets/stock_adjustment_modal.dart';
import 'widgets/rack_editor_sheet.dart';
import 'widgets/rack_audit_sheet.dart';
import 'widgets/rack_placement_sheet.dart';

part 'tabs/inventory_medicines_tab.dart';
part 'tabs/inventory_batches_tab.dart';
part 'tabs/inventory_near_expiry_tab.dart';
part 'tabs/inventory_low_stock_tab.dart';
part 'tabs/inventory_stock_ledger_tab.dart';
part 'tabs/inventory_racks_tab.dart';
part 'tabs/inventory_shared_widgets.dart';

class InventoryScreen extends StatefulWidget {
  final ShopModel activeShop;

  const InventoryScreen({super.key, required this.activeShop});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final MasterDataController masterController;
  late final BatchController batchController;
  late final RackController rackController;
  final TextEditingController _searchCtrl = TextEditingController();

  // 0 = Medicines, 1 = Batches, 2 = Near Expiry, 3 = Low Stock, 4 = Audit Ledger, 5 = Racks
  int _selectedTabIndex = 0;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    masterController = Get.isRegistered<MasterDataController>()
        ? Get.find<MasterDataController>()
        : Get.put(MasterDataController());

    batchController = Get.isRegistered<BatchController>()
        ? Get.find<BatchController>()
        : Get.put(BatchController());

    rackController = Get.isRegistered<RackController>()
        ? Get.find<RackController>()
        : Get.put(RackController());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_selectedTabIndex == 0) {
      masterController.medicineSearch.value = val.trim();
      masterController.fetchMedicines(
        search: val.trim(),
        categoryId: _selectedCategoryId,
      );
    } else if (_selectedTabIndex == 1) {
      batchController.batchSearchQuery.value = val.trim();
      batchController.fetchBatches(resetPage: true);
    }
  }

  void _showAddBatchSheet([MedicineModel? initialMed]) {
    AppBottomSheet.show(
      context: context,
      builder: (_) => AddBatchModal(initialMedicine: initialMed),
    );
  }

  void _showStockAdjustmentSheet(BatchModel batch) {
    AppBottomSheet.show(
      context: context,
      builder: (_) => StockAdjustmentModal(batch: batch),
    );
  }

  Future<void> _handleDeleteMedicine(MedicineModel medicine) async {
    final confirm = await _showUniqueDeactivateDialog(medicine);
    if (confirm == true) {
      final success = await masterController.deleteMedicine(medicine.id);
      if (mounted && success) {
        UniqueSnackbar.showSuccess(
          context,
          title: 'Medicine Deactivated',
          message:
              '${medicine.name} has been safely removed from the active catalog.',
        );
      }
    }
  }

  Future<bool?> _showUniqueDeactivateDialog(MedicineModel medicine) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Deactivate Medicine',
      barrierColor: AppColors.darkInk.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim,
            child: Dialog(
              backgroundColor: AppColors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 24.h,
              ),
              elevation: 0,
              child: Container(
                constraints: BoxConstraints(maxWidth: 380.w),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: AppColors.debitRose.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.debitRose.withValues(alpha: 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppColors.darkInk.withValues(alpha: 0.16),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.r),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top glowing accent line
                      Container(
                        height: 4.h,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF4B6E),
                              AppColors.debitRose,
                              Color(0xFFB91C1C),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Glowing Danger Badge Icon
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 64.w,
                                  height: 64.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.debitRoseBg,
                                    border: Border.all(
                                      color: AppColors.debitRose.withValues(
                                        alpha: 0.22,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 48.w,
                                  height: 48.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFF5370),
                                        AppColors.debitRose,
                                        Color(0xFFB91C1C),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.debitRose.withValues(
                                          alpha: 0.38,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.archive_outlined,
                                    color: AppColors.white,
                                    size: 24.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),

                            // Dialog Title
                            Text(
                              'Deactivate Medicine',
                              style: AppTypography.h2.copyWith(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.debitRoseBg,
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: AppColors.debitRose.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_clock_rounded,
                                    size: 12.sp,
                                    color: AppColors.debitRose,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'REMOVE FROM ACTIVE CATALOG',
                                    style: TextStyle(
                                      fontSize: 9.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.debitRose,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 14.h),

                            // Medicine Preview Card
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.bgPrimary,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryEmerald
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.medication_rounded,
                                          size: 16.sp,
                                          color: AppColors.primaryEmerald,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              medicine.name,
                                              style: AppTypography.bodyLarge
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14.sp,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (medicine.genericName.isNotEmpty)
                                              Text(
                                                medicine.genericName,
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 11.sp,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Wrap(
                                    spacing: 5.w,
                                    runSpacing: 4.h,
                                    children: [
                                      if (medicine.dosageForm.isNotEmpty)
                                        _tagBadge(
                                          medicine.dosageForm,
                                          AppColors.textPrimary,
                                          AppColors.bgSurface,
                                        ),
                                      if (medicine.strength.isNotEmpty)
                                        _tagBadge(
                                          medicine.strength,
                                          AppColors.primaryEmerald,
                                          AppColors.creditGreenBg,
                                        ),
                                      if (medicine.brand.isNotEmpty &&
                                          medicine.brand != medicine.name)
                                        _tagBadge(
                                          medicine.brand,
                                          AppColors.clinicalCyan,
                                          AppColors.clinicalCyan.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                      if (medicine.prescriptionRequired)
                                        _tagBadge(
                                          'Rx Required',
                                          AppColors.debitRose,
                                          AppColors.debitRoseBg,
                                        ),
                                    ],
                                  ),
                                  if (medicine.mrp > 0 ||
                                      medicine.sellingPrice > 0) ...[
                                    SizedBox(height: 8.h),
                                    const Divider(
                                      height: 1,
                                      color: AppColors.borderSubtle,
                                    ),
                                    SizedBox(height: 6.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'MRP: ${Formatters.formatCurrency(medicine.mrp)}',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          'Sale: ${Formatters.formatCurrency(medicine.sellingPrice)}',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryEmerald,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: 12.h),

                            // Explanatory Safety Warning Notice
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: AppColors.debitRoseBg,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.debitRose.withValues(
                                    alpha: 0.22,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16.sp,
                                    color: AppColors.debitRose,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'This medicine will be hidden from new sales and POS billing. Past invoices, audit ledgers, and batches remain safely archived.',
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        color: AppColors.debitRoseDark,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.borderMedium,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 11.h,
                                      ),
                                      backgroundColor: AppColors.bgSurface,
                                    ),
                                    child: Text(
                                      'Keep Active',
                                      style: TextStyle(
                                        fontSize: 12.5.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.r),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF4B6E),
                                          AppColors.debitRose,
                                          Color(0xFFB91C1C),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.debitRose.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.transparent,
                                        shadowColor: AppColors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 11.h,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.archive_rounded,
                                        size: 16.sp,
                                        color: AppColors.white,
                                      ),
                                      label: Text(
                                        'Deactivate',
                                        style: TextStyle(
                                          fontSize: 12.5.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: SafeArea(
        child: Obx(() {
          final val = batchController.valuation.value;
          final totalMedCount = masterController.totalMedicinesCount;
          final totalBatchCount = batchController.batchTotalCount.value;
          final nearExpiryCount = batchController.nearExpiryList.length;
          final lowStockCount = batchController.lowStockList.length;

          return Column(
            children: [
              // Top Header Bar
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 6.h),
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
                                AppStrings.inventoryTitle,
                                style: AppTypography.h2,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '$totalMedCount Medicines • $totalBatchCount Batches In Stock',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.primaryEmerald,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppColors.primaryEmerald,
                          ),
                          onPressed: () {
                            masterController.fetchMedicines();
                            batchController.refreshAll();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // Live Stock Valuation Cards Row
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(
                          AppDecorations.radiusMd,
                        ),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _valStat(
                              'Stock Units',
                              '${val.totalUnitsInStock}',
                              AppColors.primaryEmerald,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: _valStat(
                              'Cost Value',
                              Formatters.formatCurrency(val.totalCostValue),
                              AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: _valStat(
                              'Retail Value',
                              Formatters.formatCurrency(val.totalRetailValue),
                              AppColors.clinicalCyan,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: _valStat(
                              'Gross Margin',
                              '${val.marginPercentage.toStringAsFixed(1)}%',
                              AppColors.creditGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Navigation Tabs Switcher
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _navTab(
                            0,
                            'Medicines ($totalMedCount)',
                            Icons.medication_outlined,
                          ),
                          SizedBox(width: 6.w),
                          _navTab(
                            1,
                            'Batches ($totalBatchCount)',
                            Icons.layers_outlined,
                          ),
                          SizedBox(width: 6.w),
                          _navTab(
                            2,
                            'Near Expiry ($nearExpiryCount)',
                            Icons.timer_outlined,
                            isAlert: nearExpiryCount > 0,
                          ),
                          SizedBox(width: 6.w),
                          _navTab(
                            3,
                            'Low Stock ($lowStockCount)',
                            Icons.warning_amber_rounded,
                            isAlert: lowStockCount > 0,
                          ),
                          SizedBox(width: 6.w),
                          _navTab(4, 'Audit Ledger', Icons.history_outlined),
                          SizedBox(width: 6.w),
                          _navTab(
                            5,
                            'Racks & Shelves',
                            Icons.inventory_2_outlined,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Search and Filters (Shown for Medicines and Batches)
                    if (_selectedTabIndex == 0 || _selectedTabIndex == 1)
                      TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        style: AppTypography.bodyMedium,
                        decoration: AppDecorations.searchDecoration(
                          hintText: _selectedTabIndex == 0
                              ? 'Search medicines...'
                              : 'Search batches...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primaryEmerald,
                          ),
                          focusColor: AppColors.primaryEmerald,
                        ),
                      ),
                  ],
                ),
              ),

              // Sub-Filter Bar (Category chips for Medicines, Status chips for Batches, Days for Near-Expiry)
              if (_selectedTabIndex == 0) _buildCategoryFilterBar(),
              if (_selectedTabIndex == 1) _buildBatchStatusFilterBar(),
              if (_selectedTabIndex == 2) _buildNearExpiryDaysFilterBar(),
              if (_selectedTabIndex == 4) _buildLedgerTypeFilterBar(),

              SizedBox(height: 8.h),

              // Active Tab Content with 3D Cyber-Pharma Refresh Indicator
              Expanded(
                child: Unique3DRefreshIndicator(
                  title: _selectedTabIndex == 0
                      ? 'Syncing Medicines Catalog...'
                      : _selectedTabIndex == 1
                      ? 'Syncing Batch Inventory...'
                      : _selectedTabIndex == 2
                      ? 'Syncing Near-Expiry Batches...'
                      : _selectedTabIndex == 3
                      ? 'Syncing Low Stock Deficits...'
                      : 'Syncing Inventory Audit Ledger...',
                  primaryColor: _selectedTabIndex == 2
                      ? AppColors.debitRose
                      : _selectedTabIndex == 1
                      ? AppColors.clinicalCyan
                      : _selectedTabIndex == 3
                      ? Colors.orange
                      : AppColors.primaryEmerald,
                  secondaryColor: _selectedTabIndex == 2
                      ? Colors.orangeAccent
                      : _selectedTabIndex == 1
                      ? AppColors.primaryEmerald
                      : AppColors.clinicalCyan,
                  onRefresh: () async {
                    if (_selectedTabIndex == 0) {
                      await masterController.fetchMedicines(
                        search: _searchCtrl.text.trim(),
                        categoryId: _selectedCategoryId,
                      );
                    } else if (_selectedTabIndex == 1) {
                      await batchController.fetchBatches(resetPage: true);
                    } else if (_selectedTabIndex == 2) {
                      await batchController.fetchNearExpiry();
                    } else if (_selectedTabIndex == 3) {
                      await batchController.fetchLowStock();
                    } else if (_selectedTabIndex == 4) {
                      await batchController.fetchLedger();
                    }
                    await batchController.fetchValuation();
                  },
                  child: _buildActiveTabContent(),
                ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: _selectedTabIndex == 0
          ? AppFloatingButton(
              label: 'Add Medicine',
              icon: Icons.medication_rounded,
              gradient: const LinearGradient(
                colors: [AppColors.primaryEmerald, AppColors.clinicalCyan],
              ),
              glowColor: AppColors.primaryEmerald,
              onPressed: () {
                AddStockSheet.show(
                  context,
                  onMedicineCreated: () {
                    masterController.fetchMedicines();
                  },
                );
              },
            )
          : _selectedTabIndex == 1
          ? AppFloatingButton(
              label: 'Add Batch',
              icon: Icons.layers_rounded,
              gradient: const LinearGradient(
                colors: [AppColors.clinicalCyan, AppColors.primaryEmerald],
              ),
              glowColor: AppColors.clinicalCyan,
              onPressed: () => _showAddBatchSheet(),
            )
          : _selectedTabIndex == 5
          ? AppFloatingButton(
              label: 'Add Rack',
              icon: Icons.add_rounded,
              gradient: const LinearGradient(
                colors: [AppColors.textSecondary, AppColors.textPrimary],
              ),
              glowColor: AppColors.textSecondary,
              onPressed: () {
                AppBottomSheet.show(
                  context: context,
                  builder: (_) => RackEditorSheet(controller: rackController),
                );
              },
            )
          : null,
    );
  }


  Widget _navTab(
    int index,
    String title,
    IconData icon, {
    bool isAlert = false,
  }) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
          _searchCtrl.clear();
        });
        if (index == 1) {
          batchController.fetchBatches(resetPage: true);
        } else if (index == 2) {
          batchController.fetchNearExpiry();
        } else if (index == 3) {
          batchController.fetchLowStock();
        } else if (index == 4) {
          batchController.fetchLedger();
        }
      },
      borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryEmerald.withValues(alpha: 0.15)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryEmerald
                : isAlert
                ? AppColors.debitRose.withValues(alpha: 0.5)
                : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15.sp,
              color: isSelected
                  ? AppColors.primaryEmerald
                  : isAlert
                  ? AppColors.debitRose
                  : AppColors.textSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryEmerald
                    : isAlert
                    ? AppColors.debitRose
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Tab 0: Medicines Master Catalog
  // --------------------------------------------------------------------------




  // --------------------------------------------------------------------------
  // Tab 1: Physical Batches
  // --------------------------------------------------------------------------



  // --------------------------------------------------------------------------
  // Tab 2: Near Expiry & Expired Stock Radar
  // --------------------------------------------------------------------------



  // --------------------------------------------------------------------------
  // Tab 3: Low-Stock Deficit Alerts
  // --------------------------------------------------------------------------

  // --------------------------------------------------------------------------
  // Tab 4: Stock Audit Ledger
  // --------------------------------------------------------------------------



  Widget _buildActiveTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildMedicinesList();
      case 1:
        return _buildBatchesList();
      case 2:
        return _buildNearExpiryList();
      case 3:
        return _buildLowStockList();
      case 4:
        return _buildStockLedgerList();
      case 5:
        return _buildRackList();
      default:
        return _buildMedicinesList();
    }
  }



}
