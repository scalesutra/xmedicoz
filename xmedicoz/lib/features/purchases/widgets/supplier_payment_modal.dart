import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/models/purchase_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../controllers/purchases_controller.dart';

class SupplierPaymentModal extends StatefulWidget {
  final PurchaseInvoiceModel invoice;

  const SupplierPaymentModal({super.key, required this.invoice});

  static void show(BuildContext context, PurchaseInvoiceModel invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SupplierPaymentModal(invoice: invoice),
    );
  }

  @override
  State<SupplierPaymentModal> createState() => _SupplierPaymentModalState();
}

class _SupplierPaymentModalState extends State<SupplierPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final PurchasesController purchasesController = Get.find<PurchasesController>();

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _refCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  String _paymentMode = 'BANK_TRANSFER'; // BANK_TRANSFER, CASH, UPI, CHEQUE

  @override
  void initState() {
    super.initState();
    // Default to the remaining balance amount
    _amountCtrl.text = widget.invoice.balanceAmount > 0
        ? widget.invoice.balanceAmount.toStringAsFixed(2)
        : widget.invoice.totalAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
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

    final success = await purchasesController.recordPayment(
      supplierId: widget.invoice.supplierId,
      purchaseInvoiceId: widget.invoice.id,
      amount: amount,
      paymentMode: _paymentMode,
      referenceNumber: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
        height: MediaQuery.sizeOf(context).height * 0.88,
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
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
            SizedBox(height: 14.h),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Record Supplier Payment', style: AppTypography.h3),
                      SizedBox(height: 2.h),
                      Text(
                        'Settle Bill ${inv.invoiceNumber}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primaryBlue,
                        ),
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
            const Divider(height: 20, color: AppColors.borderSubtle),

            // Scrollable Form Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 24.h,
                  ),
                  children: [
                    // Bill Balance Overview Card
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(
                          AppDecorations.radiusSm,
                        ),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  inv.supplier?.name ?? 'Supplier',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: inv.isPaid
                                      ? AppColors.creditGreenBg
                                      : AppColors.debitRoseBg,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  inv.paymentStatus,
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: inv.isPaid
                                        ? AppColors.creditGreen
                                        : AppColors.debitRose,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Expanded(
                                child: _col(
                                  'Total Bill',
                                  Formatters.formatCurrency(inv.totalAmount),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: _col(
                                  'Paid',
                                  Formatters.formatCurrency(inv.paidAmount),
                                  color: AppColors.creditGreen,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: _col(
                                  'Balance Due',
                                  Formatters.formatCurrency(inv.balanceAmount),
                                  color: AppColors.debitRose,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Amount input
                    Text('Payment Amount (₹) *', style: AppTypography.labelBold),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: AppDecorations.inputDecoration(
                        hintText: '0.00',
                        prefixIcon: const Icon(
                          Icons.currency_rupee_rounded,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Amount is required';
                        }
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount > 0';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Payment Mode selector
                    Text('Payment Mode', style: AppTypography.labelBold),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        _modePill(
                          'BANK_TRANSFER',
                          'Bank / NEFT',
                          Icons.account_balance_outlined,
                        ),
                        SizedBox(width: 8.w),
                        _modePill('UPI', 'UPI / QR', Icons.qr_code_scanner),
                        SizedBox(width: 8.w),
                        _modePill('CASH', 'Cash', Icons.payments_outlined),
                        SizedBox(width: 8.w),
                        _modePill('CHEQUE', 'Cheque', Icons.receipt_outlined),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Reference Number (UTR / Cheque No)
                    Text(
                      'Reference / Transaction ID',
                      style: AppTypography.labelBold,
                    ),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _refCtrl,
                      decoration: AppDecorations.inputDecoration(
                        hintText: 'e.g. NEFT-78901234 / UPI-89423719',
                        prefixIcon: const Icon(
                          Icons.tag_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Notes
                    Text('Notes / Memo', style: AppTypography.labelBold),
                    SizedBox(height: 6.h),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: AppDecorations.inputDecoration(
                        hintText: 'e.g. Part payment via HDFC Current A/C',
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Submit Button
                    Obx(() {
                      return AppButton(
                        title: 'Confirm Payment & Deduct Balance',
                        icon: Icons.check_circle_outline,
                        isLoading: purchasesController.isSubmitting.value,
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
    );
  }

  Widget _col(String label, String val, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.5.sp, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            val,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textPrimary,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _modePill(String mode, String label, IconData icon) {
    final isSelected = _paymentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryEmerald.withValues(alpha: 0.12) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            border: Border.all(
              color: isSelected ? AppColors.primaryEmerald : AppColors.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18.sp, color: isSelected ? AppColors.primaryEmerald : AppColors.textSecondary),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primaryEmerald : AppColors.textSecondary,
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
