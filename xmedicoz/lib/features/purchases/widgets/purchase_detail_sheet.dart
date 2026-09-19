import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/purchases_controller.dart';
import 'purchase_return_modal.dart';
import 'supplier_payment_modal.dart';

class PurchaseDetailSheet extends StatefulWidget {
  final String purchaseInvoiceId;

  const PurchaseDetailSheet({super.key, required this.purchaseInvoiceId});

  static void show(BuildContext context, String id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PurchaseDetailSheet(purchaseInvoiceId: id),
    );
  }

  @override
  State<PurchaseDetailSheet> createState() => _PurchaseDetailSheetState();
}

class _PurchaseDetailSheetState extends State<PurchaseDetailSheet> {
  final PurchasesController purchasesController = Get.find<PurchasesController>();
  final DateFormat _dateFmt = DateFormat('dd MMM yyyy');
  final DateFormat _timeFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    purchasesController.fetchInvoiceDetails(widget.purchaseInvoiceId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.90,
      padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Obx(() {
        final isBusy = purchasesController.isLoadingDetails.value;
        final inv = purchasesController.selectedInvoice.value;

        if (isBusy && inv == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryEmerald),
          );
        }

        if (inv == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.debitRose,
                ),
                SizedBox(height: 12.h),
                Text('Purchase bill not found', style: AppTypography.h3),
              ],
            ),
          );
        }

        return Column(
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

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Purchase Invoice', style: AppTypography.h3),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Text(
                          inv.invoiceNumber,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.clinicalCyan,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '(${inv.internalNumber})',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.borderSubtle),

            // Scrollable Content
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 24.h,
                ),
                children: [
                  // Status & Dates Strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
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
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: inv.isPaid
                                ? AppColors.creditGreen
                                : AppColors.debitRose,
                          ),
                        ),
                      ),
                      Text(
                        inv.invoiceDate != null
                            ? 'Bill Date: ${_dateFmt.format(inv.invoiceDate!)}'
                            : '',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: 12.h),

            // Supplier Card
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 18.sp, color: AppColors.primaryBlue),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          inv.supplier?.name ?? 'Apex Medico Distributors',
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  if (inv.supplier?.mobile != null)
                    Text('Mobile: ${inv.supplier!.mobile}', style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary)),
                  if (inv.supplier?.gstin != null)
                    Text('GSTIN: ${inv.supplier!.gstin}', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Invoiced Items List Header
            Text('Items & Batch Stock Ingested (${inv.items.length})', style: AppTypography.labelBold),
            SizedBox(height: 8.h),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: inv.items.length,
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (ctx, i) {
                final item = inv.items[i];
                return Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
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
                              item.medicineName,
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(item.totalAmount),
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Batch: ${item.batchNumber}', style: TextStyle(fontSize: 11.sp, color: AppColors.clinicalCyan)),
                          if (item.expiryDate != null)
                            Text('Exp: ${_dateFmt.format(item.expiryDate!)}', style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary)),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Qty: ${item.quantity} + ${item.freeQuantity} Free',
                            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Rate: ₹${item.purchaseRate.toInt()} • MRP: ₹${item.mrp.toInt()} • Sale: ₹${item.sellingPrice.toInt()}',
                            style: TextStyle(fontSize: 10.5.sp, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 14.h),

            // Financial Breakdown Box
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _statRow('Subtotal', Formatters.formatCurrency(inv.subtotal)),
                  SizedBox(height: 4.h),
                  _statRow('Discount', Formatters.formatCurrency(inv.discountAmount), color: AppColors.debitRose),
                  SizedBox(height: 4.h),
                  _statRow('Tax / GST', Formatters.formatCurrency(inv.taxAmount), color: AppColors.clinicalCyan),
                  const Divider(height: 14, color: AppColors.borderSubtle),
                  _statRow('Total Bill Amount', Formatters.formatCurrency(inv.totalAmount), isBold: true),
                  SizedBox(height: 4.h),
                  _statRow('Amount Paid', Formatters.formatCurrency(inv.paidAmount), color: AppColors.creditGreen),
                  SizedBox(height: 4.h),
                  _statRow('Pending Balance', Formatters.formatCurrency(inv.balanceAmount), isBold: true, color: AppColors.debitRose),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Payments History (if any)
            if (inv.payments.isNotEmpty) ...[
              Text('Settlement Payments (${inv.payments.length})', style: AppTypography.labelBold),
              SizedBox(height: 6.h),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: inv.payments.length,
                separatorBuilder: (_, _) => SizedBox(height: 6.h),
                itemBuilder: (ctx, i) {
                  final p = inv.payments[i];
                  return Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.creditGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p.paymentNumber} • ${p.paymentMode}',
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            if (p.paymentDate != null)
                              Text(_timeFmt.format(p.paymentDate!), style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted)),
                          ],
                        ),
                        Text(
                          Formatters.formatCurrency(p.amount),
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.creditGreen),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 14.h),
            ],

            // Returns History (if any)
            if (inv.returns.isNotEmpty) ...[
              Text('Purchase Returns (${inv.returns.length})', style: AppTypography.labelBold),
              SizedBox(height: 6.h),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: inv.returns.length,
                separatorBuilder: (_, _) => SizedBox(height: 6.h),
                itemBuilder: (ctx, i) {
                  final r = inv.returns[i];
                  return Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.debitRose.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r.returnNumber} • ${r.reason}',
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.debitRose)),
                            if (r.returnDate != null)
                              Text(_timeFmt.format(r.returnDate!), style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted)),
                          ],
                        ),
                        Text(
                          Formatters.formatCurrency(r.totalAmount),
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.debitRose),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 14.h),
            ],

            // Quick Action Buttons
            Row(
              children: [
                if (!inv.isPaid) ...[
                  Expanded(
                    child: AppButton(
                      title: 'Record Payment',
                      icon: Icons.payments_outlined,
                      onPressed: () {
                        Navigator.of(context).pop();
                        SupplierPaymentModal.show(context, inv);
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      PurchaseReturnModal.show(context, inv);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.debitRose),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    icon: const Icon(Icons.assignment_return_outlined, size: 18, color: AppColors.debitRose),
                    label: Text(
                      'Return Stock',
                      style: AppTypography.labelBold.copyWith(color: AppColors.debitRose),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}),
);
}

  Widget _statRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 13.sp : 11.5.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14.sp : 12.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
