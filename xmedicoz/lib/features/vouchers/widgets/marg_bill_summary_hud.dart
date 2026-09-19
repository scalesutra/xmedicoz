import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class MargBillSummaryHud extends StatelessWidget {
  final int itemCount;
  final int totalUnits;
  final double totalSubtotal;
  final double totalDiscount;
  final double totalGst;
  final double grandTotal;
  final String paymentMode;

  const MargBillSummaryHud({
    super.key,
    required this.itemCount,
    required this.totalUnits,
    required this.totalSubtotal,
    required this.totalDiscount,
    required this.totalGst,
    required this.grandTotal,
    required this.paymentMode,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = paymentMode == 'CREDIT';

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryEmerald.withValues(alpha: 0.12),
            AppColors.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.primaryEmerald.withValues(alpha: 0.35),
          width: 1.2.w,
        ),
      ),
      child: Column(
        children: [
          _buildRow(
            'Total Items & Units',
            '$itemCount items ($totalUnits units)',
            valueColor: AppColors.primaryEmerald,
            valueFontWeight: FontWeight.w700,
          ),
          SizedBox(height: 2.h),
          _buildRow(
            'Subtotal (MRP)',
            Formatters.formatCurrency(totalSubtotal),
            valueFontWeight: FontWeight.w600,
          ),
          if (totalDiscount > 0) ...[
            SizedBox(height: 2.h),
            _buildRow(
              'Total Discount',
              '- ${Formatters.formatCurrency(totalDiscount)}',
              labelColor: AppColors.creditGreen,
              valueColor: AppColors.creditGreen,
              valueFontWeight: FontWeight.bold,
            ),
          ],
          SizedBox(height: 2.h),
          _buildRow(
            'Total Pharma GST',
            '+ ${Formatters.formatCurrency(totalGst)}',
            valueFontWeight: FontWeight.w600,
          ),
          Divider(height: 12.h, color: AppColors.borderLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCredit ? 'UDHAR / CREDIT' : 'NET PAYABLE',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: isCredit
                          ? AppColors.debitRose
                          : AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    isCredit
                        ? 'Unpaid • Debits Customer Ledger'
                        : 'Sequential Tax Invoice',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: isCredit
                          ? AppColors.debitRose
                          : AppColors.textMuted,
                      fontWeight: isCredit
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              Text(
                Formatters.formatCurrency(grandTotal),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: isCredit
                      ? AppColors.debitRose
                      : AppColors.primaryEmerald,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: labelColor ?? AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: valueFontWeight ?? FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
