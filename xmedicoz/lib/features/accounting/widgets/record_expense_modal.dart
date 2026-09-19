import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../controllers/accounting_controller.dart';

class RecordExpenseModal extends StatefulWidget {
  const RecordExpenseModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RecordExpenseModal(),
    );
  }

  @override
  State<RecordExpenseModal> createState() => _RecordExpenseModalState();
}

class _RecordExpenseModalState extends State<RecordExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  final AccountingController accountingController =
      Get.find<AccountingController>();

  String? _selectedExpenseAccountId;
  String? _selectedPaidFromAccountId;

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _payeeCtrl = TextEditingController();
  final TextEditingController _refCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String _paymentMode = 'CASH'; // CASH, BANK_TRANSFER, UPI, CHEQUE
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    // Default paid from Cash drawer (1010) if available
    final cashAcc =
        accountingController.cashAccount ??
        accountingController.accounts.firstWhereOrNull((a) => a.code == '1010');
    _selectedPaidFromAccountId = cashAcc?.id;

    // Default expense account
    final expenses = accountingController.expenseAccounts;
    if (expenses.isNotEmpty) {
      _selectedExpenseAccountId = expenses.first.id;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _payeeCtrl.dispose();
    _refCtrl.dispose();
    _descCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExpenseAccountId == null) {
      UniqueSnackbar.showWarning(
        context,
        message: 'Please select an expense account',
      );
      return;
    }
    if (_selectedPaidFromAccountId == null) {
      UniqueSnackbar.showWarning(
        context,
        message: 'Please select a payment source account (Cash/Bank)',
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) {
      UniqueSnackbar.showWarning(
        context,
        message: 'Amount must be greater than 0',
      );
      return;
    }

    final success = await accountingController.recordExpense(
      accountId: _selectedExpenseAccountId!,
      paidFromAccountId: _selectedPaidFromAccountId!,
      amount: amount,
      paymentMode: _paymentMode,
      payee: _payeeCtrl.text.trim().isNotEmpty ? _payeeCtrl.text.trim() : null,
      referenceNumber: _refCtrl.text.trim().isNotEmpty
          ? _refCtrl.text.trim()
          : null,
      description: _descCtrl.text.trim().isNotEmpty
          ? _descCtrl.text.trim()
          : null,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.debitRose.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.debitRose,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record Operating Expense',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Electricity, Rent, Maintenance & Tea expenses',
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
                    // Expense Account Selector
                    Text(
                      'Expense Category / Account *',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Obx(() {
                      final expenses = accountingController.expenseAccounts;
                      final currentVal =
                          expenses.any((e) => e.id == _selectedExpenseAccountId)
                          ? _selectedExpenseAccountId
                          : (expenses.isNotEmpty ? expenses.first.id : null);

                      return DropdownButtonFormField<String>(
                        initialValue: currentVal,
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
                        hint: Text(
                          'Select Expense Head',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        items: expenses.map((acc) {
                          return DropdownMenuItem<String>(
                            value: acc.id,
                            child: Text(
                              '${acc.code} - ${acc.name}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedExpenseAccountId = val),
                        validator: (v) =>
                            v == null ? 'Expense head is required' : null,
                      );
                    }),
                    SizedBox(height: 14.h),

                    // Amount & Payment Mode
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount (₹) *',
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
                                  hintText: 'e.g. 250',
                                  filled: true,
                                  fillColor: AppColors.bgSurface,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 10.h,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
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
                        SizedBox(width: 10.w),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Mode',
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
                                    horizontal: 10.w,
                                    vertical: 10.h,
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
                                      'Cash',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'UPI',
                                    child: Text(
                                      'UPI',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'BANK_TRANSFER',
                                    child: Text(
                                      'Bank',
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

                    // Quick Amount Chips
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [50, 100, 200, 500, 1000].map((amt) {
                        final isSel = _amountCtrl.text.trim() == '$amt';
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _amountCtrl.text = '$amt');
                          },
                          borderRadius: BorderRadius.circular(6.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.debitRose.withValues(alpha: 0.15)
                                  : AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: isSel
                                    ? AppColors.debitRose
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Text(
                              '₹$amt',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSel
                                    ? AppColors.debitRose
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 14.h),

                    // Progressive Disclosure: Paid From, Payee, Ref & Notes
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showAdvanced = !_showAdvanced);
                        if (_showAdvanced) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollCtrl.hasClients) {
                              _scrollCtrl.animateTo(
                                _scrollCtrl.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: _showAdvanced
                                ? AppColors.debitRose.withValues(alpha: 0.4)
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
                                      ? AppColors.debitRose
                                      : AppColors.textSecondary,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  _showAdvanced
                                      ? 'Hide Payee & Account Details'
                                      : '+ Payee, Receipt No & Bank Account (Optional)',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _showAdvanced
                                        ? AppColors.debitRose
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

                      // Paid From Account Selector
                      Text(
                        'Paid From (Cash / Bank)',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Obx(() {
                        final assets = accountingController.accounts
                            .where(
                              (a) =>
                                  a.type == 'ASSET' &&
                                  (a.code == '1010' || a.code == '1020'),
                            )
                            .toList();
                        final currentVal =
                            assets.any(
                              (a) => a.id == _selectedPaidFromAccountId,
                            )
                            ? _selectedPaidFromAccountId
                            : (assets.isNotEmpty ? assets.first.id : null);

                        return DropdownButtonFormField<String>(
                          initialValue: currentVal,
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
                              vertical: 10.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: const BorderSide(
                                color: AppColors.borderLight,
                              ),
                            ),
                          ),
                          items: assets.map((acc) {
                            return DropdownMenuItem<String>(
                              value: acc.id,
                              child: Text(
                                '${acc.code} - ${acc.name} (Bal: ₹${acc.currentBalance.toStringAsFixed(0)})',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedPaidFromAccountId = val),
                          validator: (v) =>
                              v == null ? 'Source account is required' : null,
                        );
                      }),
                      SizedBox(height: 10.h),

                      // Payee & Reference Number
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paid To / Payee',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                TextFormField(
                                  controller: _payeeCtrl,
                                  scrollPadding: EdgeInsets.only(bottom: 100.h),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Electricity Board',
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
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bill / Receipt No.',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                TextFormField(
                                  controller: _refCtrl,
                                  scrollPadding: EdgeInsets.only(bottom: 100.h),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. EBILL-2026',
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      // Description / Remarks
                      Text(
                        'Expense Remarks / Description',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 2,
                        scrollPadding: EdgeInsets.only(bottom: 120.h),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Store power bill for August-September 2026',
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
                      return AppButton(
                        title: 'Post Expense & Deduct Cash',
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
}
