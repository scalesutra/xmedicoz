import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/models/batch_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../controllers/batch_controller.dart';

class StockAdjustmentModal extends StatefulWidget {
  final BatchModel batch;

  const StockAdjustmentModal({super.key, required this.batch});

  @override
  State<StockAdjustmentModal> createState() => _StockAdjustmentModalState();
}

class _StockAdjustmentModalState extends State<StockAdjustmentModal> {
  final _formKey = GlobalKey<FormState>();
  final BatchController batchController = Get.find<BatchController>();

  String _adjustmentType = 'DAMAGE'; // "ADJUSTMENT_ADD" | "ADJUSTMENT_SUB" | "DAMAGE"
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Validation',
        message: 'Quantity must be greater than 0',
      );
      return;
    }

    if ((_adjustmentType == 'DAMAGE' || _adjustmentType == 'ADJUSTMENT_SUB') &&
        qty > widget.batch.currentQuantity) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Insufficient Batch Stock',
        message:
            'Cannot deduct $qty units. Batch only has ${widget.batch.currentQuantity} units.',
      );
      return;
    }

    final success = await batchController.adjustStock(
      batchId: widget.batch.id,
      type: _adjustmentType,
      quantity: qty,
      reason: _reasonCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        FocusScope.of(context).unfocus();
      },
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.borderMedium,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
            SizedBox(height: 14.h),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adjust Physical Stock', style: AppTypography.h3),
                    SizedBox(height: 2.h),
                    Text('PostgreSQL Row-Locked Audit Update',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primaryEmerald)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.borderSubtle),

            // Batch Details Card
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.batch.medicine?.name ?? 'Medicine',
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Batch: ${widget.batch.batchNumber}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.clinicalCyan),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${widget.batch.currentQuantity}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                        Text(
                          'In Stock',
                          style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Adjustment Type Selector
            Text('Adjustment Type *', style: AppTypography.labelBold),
            SizedBox(height: 8.h),
            Row(
              children: [
                _typePill(
                  type: 'DAMAGE',
                  label: 'Damage / Spoiled',
                  icon: Icons.delete_sweep_outlined,
                  color: AppColors.debitRose,
                ),
                SizedBox(width: 8.w),
                _typePill(
                  type: 'ADJUSTMENT_SUB',
                  label: 'Subtract Stock',
                  icon: Icons.remove_circle_outline,
                  color: Colors.orange.shade700,
                ),
                SizedBox(width: 8.w),
                _typePill(
                  type: 'ADJUSTMENT_ADD',
                  label: 'Add Stock',
                  icon: Icons.add_circle_outline,
                  color: AppColors.primaryEmerald,
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Quantity Field
            Text('Units to Adjust *', style: AppTypography.labelBold),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: AppDecorations.inputDecoration(
                hintText: 'Enter quantity',
                prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textSecondary),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Required';
                final n = int.tryParse(val.trim());
                if (n == null || n <= 0) return 'Must be a positive integer';
                return null;
              },
            ),
            SizedBox(height: 14.h),

            // Reason Field
            Text('Reason *', style: AppTypography.labelBold),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _reasonCtrl,
              decoration: AppDecorations.inputDecoration(
                hintText: 'e.g. Broken strip during rack shifting / Physical count discrepancy',
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
            ),
            SizedBox(height: 14.h),

            // Notes
            Text('Manager Notes (Optional)', style: AppTypography.labelBold),
            SizedBox(height: 6.h),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: AppDecorations.inputDecoration(hintText: 'Verified by inventory auditor'),
            ),
            SizedBox(height: 24.h),

            // Submit Button
            Obx(() {
              return AppButton(
                title: 'Confirm Inventory Adjustment',
                icon: Icons.shield_outlined,
                isLoading: batchController.isSubmitting.value,
                onPressed: _handleSubmit,
              );
            }),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _typePill({
    required String type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _adjustmentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _adjustmentType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            border: Border.all(
              color: isSelected ? color : AppColors.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 18.sp),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
