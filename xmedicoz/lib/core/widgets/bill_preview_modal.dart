import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import 'unique_snackbar.dart';

class BillPreviewModal extends StatelessWidget {
  final TransactionModel transaction;
  final ShopModel shop;

  const BillPreviewModal({
    super.key,
    required this.transaction,
    required this.shop,
  });

  static void show(BuildContext context, {
    required TransactionModel transaction,
    required ShopModel shop,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BillPreviewModal(transaction: transaction, shop: shop),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCash = transaction.paymentMode == PaymentMode.cash;
    final isCredit = transaction.paymentMode == PaymentMode.credit;
    final modeColor = isCredit
        ? AppColors.debitRose
        : (isCash ? AppColors.cashGold : AppColors.onlineBlue);
    final modeLabel = isCredit
        ? 'UDHAR (CREDIT)'
        : (isCash
            ? 'CASH PAYMENT'
            : (transaction.paymentMode == PaymentMode.onlineUpi
                ? 'ONLINE UPI'
                : 'BANK TRANSFER'));

    return Container(
      height: 0.88.sh,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Header handle
          SizedBox(height: 12.h),
          Container(
            width: 44.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 14.h),

          // Title bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Text('Tax Invoice & Voucher', style: AppTypography.h3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Invoice Body (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Container(
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.w),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shop.name, style: AppTypography.h3),
                              SizedBox(height: 4.h),
                              Text(
                                '${shop.category.title} • ${shop.city}',
                                style: AppTypography.bodySmall,
                              ),
                              Text(
                                'Phone: ${shop.phone}',
                                style: AppTypography.bodySmall,
                              ),
                              Text(
                                'D.L. No: ${shop.drugLicenseNo}',
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  color: AppColors.primaryEmerald,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                shop.isGstRegistered
                                    ? 'GSTIN: ${shop.gstin}'
                                    : 'Composition / Unregistered Chemist',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: AppDecorations.badge(color: modeColor),
                          child: Text(
                            modeLabel,
                            style: AppTypography.badge.copyWith(color: modeColor),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    const Divider(),
                    SizedBox(height: 12.h),

                    // Invoice Meta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('INVOICE NO', style: AppTypography.bodySmall),
                            SizedBox(height: 2.h),
                            Text(
                              transaction.invoiceNo,
                              style: AppTypography.h4.copyWith(color: AppColors.primaryCyan),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('DATE & TIME', style: AppTypography.bodySmall),
                            SizedBox(height: 2.h),
                            Text(
                              Formatters.formatDateTime(transaction.date),
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),

                    // Bill To Party
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BILLED TO / PARTY', style: AppTypography.bodySmall),
                          SizedBox(height: 4.h),
                          Text(
                            transaction.partyName,
                            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 2.h),
                          if (transaction.doctorName != null && transaction.doctorName!.isNotEmpty) ...[
                            Text(
                              'Prescribed by: ${transaction.doctorName}',
                              style: TextStyle(fontSize: 11.sp, color: AppColors.primaryEmerald, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 2.h),
                          ],
                          Text(
                            'Item Details: ${transaction.notes}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Itemized summary preview
                    Text('ITEMIZED DETAILS', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderSubtle),
                        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                      ),
                      child: Column(
                        children: [
                          _buildLineItem('Medicines & Healthcare Total', 1, transaction.amount * 0.88),
                          SizedBox(height: 8.h),
                          _buildLineItem('CGST (6%)', 1, transaction.amount * 0.06),
                          SizedBox(height: 8.h),
                          _buildLineItem('SGST (6%)', 1, transaction.amount * 0.06),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('GRAND TOTAL', style: AppTypography.h4),
                              Text(
                                Formatters.formatCurrency(transaction.amount),
                                style: AppTypography.h3.copyWith(color: AppColors.creditGreenDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Terms Note
                    Center(
                      child: Text(
                        'Medicines sold are non-refundable • Schedule H drugs to be sold on Rx only',
                        style: AppTypography.bodySmall.copyWith(fontSize: 10.sp),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Buttons (Share & Print)
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                // Print Thermal Bill Button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _showPrintDialog(context);
                    },
                    borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: AppColors.bgCardHover,
                        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.print_rounded, color: AppColors.textPrimary, size: 18.sp),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                'Print Bill',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.button.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                // WhatsApp Share Button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _showShareToast(context);
                    },
                    borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        gradient: AppColors.creditGradient,
                        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.creditGreen.withValues(alpha: 0.35),
                            blurRadius: 10.r,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_rounded, color: Colors.white, size: 18.sp),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                'WhatsApp Share',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.button,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(String name, int qty, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '$name (x$qty)',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          Formatters.formatCurrency(amount),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showPrintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Row(
          children: [
            Icon(Icons.print_rounded, color: AppColors.primaryCyan, size: 24.sp),
            SizedBox(width: 10.w),
            Text('Thermal Printer', style: AppTypography.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sending Invoice ${transaction.invoiceNo} to 2-inch / 3-inch Bluetooth ESC/POS POS Printer.',
              style: AppTypography.bodyMedium,
            ),
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              ),
              child: Row(
                children: [
                  const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text('Printing receipt...', style: AppTypography.bodySmall),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: AppColors.primaryCyan, fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }

  void _showShareToast(BuildContext context) {
    UniqueSnackbar.showSuccess(
      context,
      title: 'Invoice Sent via WhatsApp',
      message: 'Prescription Invoice ${transaction.invoiceNo} shared with ${transaction.partyName}!',
    );
  }
}
