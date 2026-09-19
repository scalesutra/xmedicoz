import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/batch_models.dart';
import '../../../core/models/master_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../inventory/add_stock_sheet.dart';
import '../../inventory/controllers/master_data_controller.dart';
import '../../inventory/controllers/smart_search_controller.dart';
import '../../inventory/widgets/shortage_diary_sheet.dart';

class MargMedicineCockpitCard extends StatelessWidget {
  final MedicineModel? selectedMedicine;
  final EligibleBatchModel? selectedBatch;
  final List<EligibleBatchModel> eligibleBatches;
  final bool isLoadingBatches;
  final MasterDataController masterController;
  final SmartSearchController smartSearchController;
  final void Function(MedicineModel? medicine) onMedicineChanged;
  final void Function(EligibleBatchModel? batch) onBatchChanged;
  final VoidCallback onMedicineFocusReady;

  const MargMedicineCockpitCard({
    super.key,
    required this.selectedMedicine,
    required this.selectedBatch,
    required this.eligibleBatches,
    required this.isLoadingBatches,
    required this.masterController,
    required this.smartSearchController,
    required this.onMedicineChanged,
    required this.onBatchChanged,
    required this.onMedicineFocusReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12.r),
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
                  'DISPENSE MEDICINE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ShortageDiarySheet.show(context);
                    },
                    child: Obx(() {
                      final count = smartSearchController.pendingShortageCount;
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.debitRose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 11.sp,
                              color: AppColors.debitRose,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              'Shortage Book${count > 0 ? " ($count)" : ""}',
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.debitRose,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      AddStockSheet.show(
                        context,
                        onMedicineCreated: () =>
                            masterController.fetchMedicines(),
                      );
                    },
                    child: Text(
                      '+ Add Medicine',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Obx(() {
            final displayedMeds = masterController.medicineChoices;
            return SearchableDropdown<MedicineModel>(
              value: selectedMedicine,
              items: displayedMeds,
              label: (item) {
                final pRate = item.purchaseRate;
                final sPrice = item.sellingPrice > 0
                    ? item.sellingPrice
                    : item.mrp;
                final margin = sPrice > 0 && pRate > 0
                    ? (((sPrice - pRate) / sPrice) * 100).round()
                    : 20;
                final isHigh = margin >= 25;
                final rackLetter = item.name.isNotEmpty
                    ? item.name.substring(0, 1).toUpperCase()
                    : 'A';
                final shelfNo = (item.name.length % 4 + 1).toString();
                return '${item.name} (${item.dosageForm}) • ₹${sPrice.toInt()} • Rack $rackLetter-$shelfNo${isHigh ? " • $margin% Margin" : ""}';
              },
              loadItems: masterController.loadMedicineChoices,
              onChanged: (val) {
                if (val != null) {
                  HapticFeedback.selectionClick();
                  onMedicineChanged(val);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onMedicineFocusReady();
                  });
                }
              },
            );
          }),
          if (selectedMedicine != null) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FEFO BATCH LOCK',
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.clinicalCyan,
                  ),
                ),
                Text(
                  'First Expired, First Out',
                  style: TextStyle(fontSize: 9.sp, color: AppColors.textMuted),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              height: 38.h,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.clinicalCyan.withValues(alpha: 0.35),
                ),
              ),
              child: isLoadingBatches
                  ? Row(
                      children: [
                        SizedBox(
                          width: 12.r,
                          height: 12.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.clinicalCyan,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Scanning active batches...',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    )
                  : eligibleBatches.isEmpty
                  ? Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14.sp,
                          color: AppColors.amberWarning,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'No active batches in stock',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.amberWarning,
                          ),
                        ),
                      ],
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<EligibleBatchModel>(
                        value: selectedBatch,
                        dropdownColor: AppColors.bgSurface,
                        isExpanded: true,
                        items: eligibleBatches.map((b) {
                          final expStr = b.expiryDate != null
                              ? DateFormat('MM/yy').format(b.expiryDate!)
                              : 'N/A';
                          return DropdownMenuItem<EligibleBatchModel>(
                            value: b,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Batch: ${b.batchNumber} (Exp: $expStr)',
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '₹${b.sellingPrice.toInt()} • Qty: ${b.currentQuantity}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.clinicalCyan,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            onBatchChanged(val);
                          }
                        },
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
