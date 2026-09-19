import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:ledger_app/features/inventory/controllers/master_data_controller.dart';

import '../../../core/models/master_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../../sales/controllers/sales_controller.dart';
import '../controllers/accounting_controller.dart';

class CustomerDebtPaymentModal extends StatefulWidget {
  final CustomerModel customer;
  final double? initialDebt;
  final VoidCallback? onSuccess;

  const CustomerDebtPaymentModal({
    super.key,
    required this.customer,
    this.initialDebt,
    this.onSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    required CustomerModel customer,
    double? initialDebt,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerDebtPaymentModal(
        customer: customer,
        initialDebt: initialDebt,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<CustomerDebtPaymentModal> createState() =>
      _CustomerDebtPaymentModalState();
}

class _CustomerDebtPaymentModalState extends State<CustomerDebtPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final AccountingController accountingController =
      Get.find<AccountingController>();

  late final TextEditingController _amountCtrl;
  final TextEditingController _refCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController(
    text: 'Partial settlement of credit invoice balance',
  );
  final ScrollController _scrollCtrl = ScrollController();

  String _paymentMode = 'CASH'; // CASH, UPI, BANK_TRANSFER, CHEQUE
  bool _showAdvanced = false;

  double get effectiveDebt {
    // 1. Check live updated customer in MasterDataController first
    if (Get.isRegistered<MasterDataController>()) {
      final liveCust = Get.find<MasterDataController>()
          .customers
          .firstWhereOrNull((c) => c.id == widget.customer.id);
      if (liveCust != null) {
        if (liveCust.outstandingBalance > 0) return liveCust.outstandingBalance;
        if (liveCust.currentBalance > 0) return liveCust.currentBalance;
      }
    }

    if (widget.initialDebt != null && widget.initialDebt! > 0) {
      return widget.initialDebt!;
    }
    if (widget.customer.outstandingBalance > 0) {
      return widget.customer.outstandingBalance;
    }
    if (widget.customer.currentBalance > 0) {
      return widget.customer.currentBalance;
    }
    if (Get.isRegistered<SalesController>()) {
      final sales = Get.find<SalesController>().salesInvoices;
      final unpaid = sales
          .where(
            (s) =>
                (s.customerId == widget.customer.id ||
                    (widget.customer.mobile.isNotEmpty &&
                        s.customerMobile == widget.customer.mobile)) &&
                (s.isCreditSale || s.isUnpaid),
          )
          .fold(
            0.0,
            (sum, s) =>
                sum + (s.balanceAmount > 0 ? s.balanceAmount : s.totalAmount),
          );
      if (unpaid > 0) return unpaid;
    }
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    final balance = effectiveDebt;
    _amountCtrl = TextEditingController(
      text: balance > 0 ? balance.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Invalid Amount',
        message: 'Payment amount must be greater than 0',
      );
      return;
    }

    final debt = effectiveDebt;
    if (debt > 0 && amount > debt) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Exceeds Balance',
        message:
            'Payment amount (₹${amount.toStringAsFixed(0)}) cannot exceed current outstanding debt (₹${debt.toStringAsFixed(0)})',
      );
      return;
    }

    // If customer has 0 balance recorded on server, attempt to sync current balance first
    if (widget.customer.currentBalance <= 0 && debt > 0) {
      if (Get.isRegistered<MasterDataController>()) {
        try {
          await Get.find<MasterDataController>().updateCustomer(
            widget.customer.id,
            {'currentBalance': debt},
          );
        } catch (_) {}
      }
    }

    final success = await accountingController.recordCustomerDebtPayment(
      customerId: widget.customer.id,
      amount: amount,
      paymentMode: _paymentMode,
      referenceNumber: _refCtrl.text.trim().isNotEmpty
          ? _refCtrl.text.trim()
          : null,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );

    if (success) {
      widget.onSuccess?.call();
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = effectiveDebt;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableHeight =
        (screenHeight - bottomInset).clamp(320.0, screenHeight);

    return PopScope(
      canPop: bottomInset == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          FocusScope.of(context).unfocus();
        }
      },
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          height: bottomInset > 0
              ? availableHeight * 0.94
              : screenHeight * 0.88,
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
            Center(
              child: Container(
                width: 48.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: AppColors.primaryEmerald,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receive Customer Payment (Udhar Jama)',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Decrements debt and greedily closes unpaid credit invoices',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
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
            const Divider(height: 20, color: AppColors.borderSubtle),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: _scrollCtrl,
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: 24.h + (bottomInset > 0 ? 16.h : 0),
                  ),
                  children: [
                    // Customer Summary Card
                    Container(
                      padding: EdgeInsets.all(12.r),
                    decoration: AppDecorations.cardDecoration,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer.name,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.customer.mobile,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Outstanding Debt',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${balance.toStringAsFixed(2)}',
                              style: AppTypography.titleMedium.copyWith(
                                color: balance > 0
                                    ? Colors.redAccent
                                    : AppColors.primaryEmerald,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Amount & Payment Mode
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Amount (₹)',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            TextFormField(
                              controller: _amountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.currency_rupee,
                                  size: 18,
                                ),
                                hintText: 'e.g. 200',
                                filled: true,
                                fillColor: AppColors.bgSurface,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 12.h,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                final d = double.tryParse(v ?? '');
                                if (d == null || d <= 0) {
                                  return 'Invalid amount';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deposit Mode',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            DropdownButtonFormField<String>(
                              initialValue: _paymentMode,
                              isExpanded: true,
                              dropdownColor: AppColors.bgSurface,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.bgSurface,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 12.h,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'CASH',
                                  child: Text(
                                    'Cash (Drawer)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'UPI',
                                  child: Text(
                                    'UPI / QR',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'BANK_TRANSFER',
                                  child: Text(
                                    'Bank Transfer',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'CHEQUE',
                                  child: Text(
                                    'Cheque',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _paymentMode = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Quick Settlement Chips (100% Full, 50% Half, Round amounts)
                  if (balance > 0)
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        _buildQuickChip(
                          label: 'Full (₹${balance.toStringAsFixed(0)})',
                          isSelected: _amountCtrl.text.trim() == balance.toStringAsFixed(0),
                          onTap: () => setState(() => _amountCtrl.text = balance.toStringAsFixed(0)),
                        ),
                        if (balance > 100)
                          _buildQuickChip(
                            label: '50% (₹${(balance / 2).toStringAsFixed(0)})',
                            isSelected: _amountCtrl.text.trim() == (balance / 2).toStringAsFixed(0),
                            onTap: () => setState(() => _amountCtrl.text = (balance / 2).toStringAsFixed(0)),
                          ),
                        if (balance > 500)
                          _buildQuickChip(
                            label: '₹500',
                            isSelected: _amountCtrl.text.trim() == '500',
                            onTap: () => setState(() => _amountCtrl.text = '500'),
                          ),
                        if (balance > 1000)
                          _buildQuickChip(
                            label: '₹1,000',
                            isSelected: _amountCtrl.text.trim() == '1000',
                            onTap: () => setState(() => _amountCtrl.text = '1000'),
                          ),
                      ],
                    ),
                  SizedBox(height: 14.h),

                  // Progressive Disclosure: Reference Number & Notes
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showAdvanced = !_showAdvanced);
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: _showAdvanced
                              ? AppColors.primaryEmerald.withValues(alpha: 0.4)
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _showAdvanced
                                    ? Icons.tune_rounded
                                    : Icons.add_circle_outline_rounded,
                                size: 15.sp,
                                color: _showAdvanced
                                    ? AppColors.primaryEmerald
                                    : AppColors.textSecondary,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                _showAdvanced
                                    ? 'Hide Receipt / Notes'
                                    : '+ Add Receipt No & Notes (Optional)',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _showAdvanced
                                      ? AppColors.primaryEmerald
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _showAdvanced
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18.sp,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_showAdvanced) ...[
                    SizedBox(height: 12.h),

                    // Reference Number
                    Text(
                      'Receipt / UTR Reference Number',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextFormField(
                      controller: _refCtrl,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. RCPT-2026-001 or UPI Transaction ID',
                        filled: true,
                        fillColor: AppColors.bgSurface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.borderLight,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Notes
                    Text(
                      'Settlement Notes',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      scrollPadding: EdgeInsets.only(bottom: 120.h),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Partial settlement of credit invoice balance',
                        filled: true,
                        fillColor: AppColors.bgSurface,
                        contentPadding: EdgeInsets.all(10.r),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.borderLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 20.h),

                  // Submit Button
                  Obx(() {
                    final enteredAmt = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
                    final btnLabel = enteredAmt > 0
                        ? 'Confirm ₹${enteredAmt.toStringAsFixed(0)} Receipt & Settle'
                        : 'Confirm Payment & Update Balance';

                      return AppButton(
                        title: btnLabel,
                        icon: Icons.check_circle_outline_rounded,
                        isLoading: accountingController.isSubmitting.value,
                        onPressed: _handleSubmit,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildQuickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryEmerald.withValues(alpha: 0.15)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryEmerald : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primaryEmerald : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
