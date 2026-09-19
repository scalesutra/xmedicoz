import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/purchase_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../controllers/purchases_controller.dart';

class _PurchaseReturnItemDraft {
  final PurchaseInvoiceItemModel item;
  bool isSelected;
  final TextEditingController qtyCtrl;
  final TextEditingController rateCtrl;

  _PurchaseReturnItemDraft({
    required this.item,
    this.isSelected = true,
  })  : qtyCtrl = TextEditingController(
          text: '${item.quantity > 0 ? item.quantity : 1}',
        ),
        rateCtrl = TextEditingController(
          text: item.purchaseRate.toStringAsFixed(2),
        );

  int get quantity => int.tryParse(qtyCtrl.text.trim()) ?? 0;
  double get rate => double.tryParse(rateCtrl.text.trim()) ?? item.purchaseRate;
  double get subtotal => quantity * rate;

  void dispose() {
    qtyCtrl.dispose();
    rateCtrl.dispose();
  }
}

class PurchaseReturnModal extends StatefulWidget {
  final PurchaseInvoiceModel invoice;

  const PurchaseReturnModal({super.key, required this.invoice});

  static void show(BuildContext context, PurchaseInvoiceModel invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => PurchaseReturnModal(invoice: invoice),
    );
  }

  @override
  State<PurchaseReturnModal> createState() => _PurchaseReturnModalState();
}

class _PurchaseReturnModalState extends State<PurchaseReturnModal> {
  final PurchasesController purchasesController =
      Get.find<PurchasesController>();

  String _reason = 'DAMAGED'; // DAMAGED, EXPIRED, RECALLED, OVERSTOCK
  late final List<_PurchaseReturnItemDraft> _items;

  final NumberFormat _currencyFmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _items = widget.invoice.items
        .map((item) => _PurchaseReturnItemDraft(item: item, isSelected: true))
        .toList();
  }

  @override
  void dispose() {
    for (final draft in _items) {
      draft.dispose();
    }
    super.dispose();
  }

  bool get _allSelected =>
      _items.isNotEmpty && _items.every((i) => i.isSelected);

  void _toggleSelectAll() {
    final target = !_allSelected;
    setState(() {
      for (final i in _items) {
        i.isSelected = target;
      }
    });
  }

  int get _selectedCount => _items.where((i) => i.isSelected).length;

  int get _totalReturnQty => _items
      .where((i) => i.isSelected)
      .fold(0, (sum, i) => sum + i.quantity);

  double get _totalReturnAmount => _items
      .where((i) => i.isSelected)
      .fold(0.0, (sum, i) => sum + i.subtotal);

  Future<void> _handleSubmit() async {
    final selectedDrafts = _items.where((i) => i.isSelected).toList();

    if (selectedDrafts.isEmpty) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Validation',
        message: 'Please select at least one medicine item to return',
      );
      return;
    }

    for (final draft in selectedDrafts) {
      if (draft.quantity <= 0) {
        UniqueSnackbar.showWarning(
          context,
          title: 'Invalid Quantity',
          message:
              'Return quantity for ${draft.item.medicineName} must be greater than 0',
        );
        return;
      }
      if (draft.quantity > draft.item.quantity) {
        UniqueSnackbar.showWarning(
          context,
          title: 'Quantity Exceeded',
          message:
              'Cannot return ${draft.quantity} units of ${draft.item.medicineName}. Invoiced quantity is ${draft.item.quantity}.',
        );
        return;
      }
    }

    final returnItems = selectedDrafts
        .map((draft) => {
              'medicineId': draft.item.medicineId,
              'batchId': draft.item.batchId,
              'quantity': draft.quantity,
              'returnRate': draft.rate,
              'totalAmount': draft.subtotal,
            })
        .toList();

    final success = await purchasesController.processReturn(
      supplierId: widget.invoice.supplierId,
      purchaseInvoiceId: widget.invoice.id,
      reason: _reason,
      items: returnItems,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.90,
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
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
            SizedBox(height: 12.h),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Process Purchase Return',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkContrast,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Bill #${inv.invoiceNumber} • ${inv.supplier?.name ?? "Distributor"}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
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
            const Divider(height: 18, color: AppColors.borderSubtle),

            // Scrollable Content
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 24.h,
                ),
                children: [
                  // Reason Selector
                  Text('Return Reason *', style: AppTypography.labelBold),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      _reasonPill(
                        'DAMAGED',
                        'Damaged',
                        Icons.broken_image_outlined,
                      ),
                      SizedBox(width: 6.w),
                      _reasonPill(
                        'EXPIRED',
                        'Expired',
                        Icons.hourglass_bottom_rounded,
                      ),
                      SizedBox(width: 6.w),
                      _reasonPill(
                        'RECALLED',
                        'Recalled',
                        Icons.warning_amber_rounded,
                      ),
                      SizedBox(width: 6.w),
                      _reasonPill(
                        'OVERSTOCK',
                        'Overstock',
                        Icons.inventory_2_outlined,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Items List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('Select Items', style: AppTypography.titleSmall),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryEmerald
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              '$_selectedCount of ${_items.length} Selected',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryEmeraldDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_items.isNotEmpty)
                        InkWell(
                          onTap: _toggleSelectAll,
                          borderRadius: BorderRadius.circular(6.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 4.h,
                            ),
                            child: Text(
                              _allSelected ? 'Deselect All' : 'Select All',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryEmeraldDark,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  if (_items.isEmpty)
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.bgPrimary,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Center(
                        child: Text(
                          'No items attached to this purchase invoice.',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    )
                  else
                    ...List.generate(_items.length, (idx) {
                      return _buildItemCard(_items[idx], idx);
                    }),

                  // Summary Box & Submit Button
                  if (_items.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgPrimary,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Returning Units',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '$_totalReturnQty Units ($_selectedCount Items)',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkContrast,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Credit Return Amount',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _currencyFmt.format(_totalReturnAmount),
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.debitRose,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 14.h),

                  // Submit Button
                  Obx(() {
                    return AppButton(
                      title: _selectedCount > 0
                          ? 'Confirm Return ($_selectedCount Items • ${_currencyFmt.format(_totalReturnAmount)})'
                          : 'Select Items to Return',
                      icon: Icons.assignment_return_outlined,
                      isLoading: purchasesController.isSubmitting.value,
                      onPressed: _selectedCount > 0 ? _handleSubmit : null,
                      isFullWidth: true,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(_PurchaseReturnItemDraft draft, int index) {
    final item = draft.item;
    final isSelected = draft.isSelected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.bgSurface : AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryEmerald.withValues(alpha: 0.6)
              : AppColors.borderSubtle,
          width: isSelected ? 1.2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Checkbox, Name, Batch info, and Subtotal
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24.w,
                height: 24.w,
                child: Checkbox(
                  value: isSelected,
                  activeColor: AppColors.primaryEmerald,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  onChanged: (val) {
                    setState(() {
                      draft.isSelected = val ?? false;
                    });
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.medicineName.isNotEmpty
                          ? item.medicineName
                          : 'Medicine #${index + 1}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: isSelected
                            ? AppColors.darkContrast
                            : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Wrap(
                      spacing: 5.w,
                      runSpacing: 2.h,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.borderSubtle,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'Batch: ${item.batchNumber}',
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkContrast,
                            ),
                          ),
                        ),
                        Text(
                          'Billed: ${item.quantity}u @ ₹${item.purchaseRate.toStringAsFixed(2)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Text(
                  _currencyFmt.format(draft.subtotal),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.debitRose,
                  ),
                ),
            ],
          ),

          // Row 2: Editable inputs when selected
          if (isSelected) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5.h),
              child: Divider(color: AppColors.borderSubtle, height: 1),
            ),
            Row(
              children: [
                // Qty Stepper
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Return Qty (Max: ${item.quantity})',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          _buildStepperBtn(
                            icon: Icons.remove,
                            onTap: () {
                              final cur = draft.quantity;
                              if (cur > 1) {
                                draft.qtyCtrl.text = '${cur - 1}';
                                setState(() {});
                              }
                            },
                          ),
                          Container(
                            width: 44.w,
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            child: TextFormField(
                              controller: draft.qtyCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 4.h,
                                  horizontal: 2.w,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                  borderSide: BorderSide(
                                    color: AppColors.borderMedium,
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          _buildStepperBtn(
                            icon: Icons.add,
                            onTap: () {
                              final cur = draft.quantity;
                              if (cur < item.quantity) {
                                draft.qtyCtrl.text = '${cur + 1}';
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),

                // Rate field
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate (₹)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      TextFormField(
                        controller: draft.rateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixText: '₹ ',
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 5.h,
                            horizontal: 6.w,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.r),
                            borderSide: BorderSide(
                              color: AppColors.borderMedium,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepperBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, size: 14.sp, color: AppColors.darkContrast),
      ),
    );
  }

  Widget _reasonPill(String r, String label, IconData icon) {
    final isSelected = _reason == r;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _reason = r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.debitRose.withValues(alpha: 0.12)
                : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            border: Border.all(
              color: isSelected ? AppColors.debitRose : AppColors.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16.sp,
                color:
                    isSelected ? AppColors.debitRose : AppColors.textSecondary,
              ),
              SizedBox(height: 3.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.debitRose
                      : AppColors.textSecondary,
                ),
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
