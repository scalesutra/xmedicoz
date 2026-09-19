import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../../accounting/widgets/customer_debt_payment_modal.dart';
import '../../inventory/controllers/master_data_controller.dart';
import '../controllers/sales_controller.dart';
import 'sales_return_modal.dart';

class SalesInvoiceDetailSheet extends StatefulWidget {
  final String salesInvoiceId;

  const SalesInvoiceDetailSheet({super.key, required this.salesInvoiceId});

  static void show(BuildContext context, String id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SalesInvoiceDetailSheet(salesInvoiceId: id),
    );
  }

  @override
  State<SalesInvoiceDetailSheet> createState() =>
      _SalesInvoiceDetailSheetState();
}

class _SalesInvoiceDetailSheetState extends State<SalesInvoiceDetailSheet> {
  final SalesController salesController = Get.find<SalesController>();
  final DateFormat _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    salesController.fetchInvoiceDetails(widget.salesInvoiceId);
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
        final isBusy = salesController.isLoadingDetails.value;
        final inv = salesController.selectedInvoice.value;

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
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 12.h),
                Text('Sales invoice not found', style: AppTypography.h3),
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sales Invoice Receipt', style: AppTypography.h3),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Text(
                          inv.invoiceNumber,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: inv.isPaid
                                ? AppColors.creditGreenBg
                                : AppColors.debitRoseBg,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            inv.displayPaymentStatus,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: inv.isPaid
                                  ? AppColors.creditGreen
                                  : AppColors.debitRose,
                            ),
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
                  // Patient & Doctor Overview
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 18.sp,
                                  color: AppColors.primaryEmerald,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  inv.customerName,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (inv.customerMobile != null)
                              Text(
                                inv.customerMobile!,
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        if (inv.doctorName != null &&
                            inv.doctorName!.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 16.sp,
                                color: AppColors.clinicalCyan,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '${inv.doctorName} ${inv.doctorRegNo != null ? "(${inv.doctorRegNo})" : ""}',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: AppColors.clinicalCyan,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (inv.createdAt != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            'Billed on: ${_dateFmt.format(inv.createdAt!)}',
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Invoiced Medicines List
                  Text(
                    'Prescription Items (${inv.items.length})',
                    style: AppTypography.labelBold,
                  ),
                  SizedBox(height: 8.h),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inv.items.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (ctx, i) {
                      final item = inv.items[i];
                      return Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(
                            AppDecorations.radiusSm,
                          ),
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
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  Formatters.formatCurrency(item.totalAmount),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryEmerald,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Batch: ${item.batchNumber}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.clinicalCyan,
                                  ),
                                ),
                                Text(
                                  'Qty: ${item.quantity} x ₹${item.unitPrice.toInt()}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (item.discountAmount > 0 ||
                                item.taxAmount > 0) ...[
                              SizedBox(height: 2.h),
                              Text(
                                'Disc: -₹${item.discountAmount.toInt()} • GST (${item.taxRate.toInt()}%): +₹${item.taxAmount.toInt()}',
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 14.h),

                  // Financial Breakdown
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
                        _statRow(
                          'Subtotal',
                          Formatters.formatCurrency(inv.subtotal),
                        ),
                        SizedBox(height: 4.h),
                        _statRow(
                          'Discount (-)',
                          Formatters.formatCurrency(inv.discountAmount),
                          color: AppColors.debitRose,
                        ),
                        SizedBox(height: 4.h),
                        _statRow(
                          'Tax / GST (+)',
                          Formatters.formatCurrency(inv.taxAmount),
                          color: AppColors.clinicalCyan,
                        ),
                        const Divider(
                          height: 14,
                          color: AppColors.borderSubtle,
                        ),
                        _statRow(
                          'Grand Total',
                          Formatters.formatCurrency(inv.totalAmount),
                          isBold: true,
                        ),
                        SizedBox(height: 4.h),
                        _statRow(
                          'Paid Amount',
                          Formatters.formatCurrency(inv.paidAmount),
                          color: AppColors.creditGreen,
                        ),
                        if (inv.balanceAmount > 0) ...[
                          SizedBox(height: 4.h),
                          _statRow(
                            'Pending Credit Balance',
                            Formatters.formatCurrency(inv.balanceAmount),
                            isBold: true,
                            color: AppColors.debitRose,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Payments Split
                  if (inv.payments.isNotEmpty) ...[
                    Text(
                      'Payments Split (${inv.payments.length})',
                      style: AppTypography.labelBold,
                    ),
                    SizedBox(height: 6.h),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: inv.payments.length,
                      separatorBuilder: (_, __) => SizedBox(height: 6.h),
                      itemBuilder: (ctx, i) {
                        final p = inv.payments[i];
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.creditGreen.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${p.paymentMode} ${p.referenceNumber != null ? "(${p.referenceNumber})" : ""}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(p.amount),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.creditGreen,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 14.h),
                  ],

                  // Returns History
                  if (inv.returns.isNotEmpty) ...[
                    Text(
                      'Returns / Credit Notes (${inv.returns.length})',
                      style: AppTypography.labelBold,
                    ),
                    SizedBox(height: 6.h),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: inv.returns.length,
                      separatorBuilder: (_, __) => SizedBox(height: 6.h),
                      itemBuilder: (ctx, i) {
                        final r = inv.returns[i];
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.debitRose.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${r.returnNumber} • ${r.refundMode}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.debitRose,
                                    ),
                                  ),
                                  if (r.reason.isNotEmpty)
                                    Text(
                                      r.reason,
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '-${Formatters.formatCurrency(r.totalAmount)}',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.debitRose,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 14.h),
                  ],

                  // Action Button 1: Settle Udhar Bill
                  if (inv.isCreditSale ||
                      inv.isUnpaid ||
                      inv.balanceAmount > 0) ...[
                    AppButton(
                      title:
                          'Collect Payment / Settle Due (₹${inv.totalAmount.toInt()})',
                      icon: Icons.payments_rounded,
                      onPressed: () {
                        final masterCtrl =
                            Get.isRegistered<MasterDataController>()
                            ? Get.find<MasterDataController>()
                            : Get.put(MasterDataController());
                        final cust =
                            inv.customer ??
                            masterCtrl.customers.firstWhereOrNull(
                              (c) => c.id == inv.customerId,
                            );
                        if (cust != null) {
                          Navigator.of(context).pop();
                          CustomerDebtPaymentModal.show(
                            context,
                            customer: cust,
                            initialDebt: inv.balanceAmount > 0
                                ? inv.balanceAmount
                                : inv.totalAmount,
                          );
                        } else {
                          UniqueSnackbar.showInfo(
                            context,
                            title: 'Walk-in Bill',
                            message:
                                'This bill is not linked to a registered customer account.',
                          );
                        }
                      },
                    ),
                    SizedBox(height: 10.h),
                    // Action Button 2: Return / Credit Note
                    AppButton(
                      title: 'Process Return / Credit Note',
                      icon: Icons.assignment_return_outlined,
                      onPressed: () {
                        Navigator.of(context).pop();
                        SalesReturnModal.show(context, inv);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _statRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
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
