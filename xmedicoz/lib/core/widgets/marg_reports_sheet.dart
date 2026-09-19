import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/ledger_controller.dart';
import '../../features/accounting/controllers/accounting_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';

class MargReportsSheet extends StatefulWidget {
  const MargReportsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MargReportsSheet(),
    );
  }

  @override
  State<MargReportsSheet> createState() => _MargReportsSheetState();
}

class _MargReportsSheetState extends State<MargReportsSheet> {
  AccountingController? _accountingController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AccountingController>()) {
      _accountingController = Get.find<AccountingController>();
      _accountingController?.fetchTrialBalance();
      _accountingController?.fetchReceivablesAging();
      _accountingController?.fetchPayablesAging();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LedgerController>();
    final acc = _accountingController;

    return Obx(() {
      final stockVal = controller.totalStockValuation;
      final sales = controller.netSalesToday * 12.5; // Monthly estimate
      final purchases = controller.netPurchasesToday * 11.2;
      final grossProfit = sales - purchases;
      final netMargin = sales > 0 ? (grossProfit / sales) * 100 : 0.0;

      final tb = acc?.trialBalance.value;
      final ar = acc?.receivablesAging.value;
      final ap = acc?.payablesAging.value;

      return Container(
        height: 0.88.sh,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.analytics_rounded, color: AppColors.primaryEmerald, size: 22.sp),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pharma Financial Intelligence', style: AppTypography.titleMedium),
                        Text('Trial Balance, Audits & Debt Aging', style: AppTypography.bodySmall),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  onPressed: () {
                    acc?.fetchTrialBalance();
                    acc?.fetchReceivablesAging();
                    acc?.fetchPayablesAging();
                  },
                ),
              ],
            ),
            SizedBox(height: 18.h),

            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // 1. Live Trial Balance Statement
                    _reportContainer(
                      title: 'TRIAL BALANCE STATEMENT',
                      icon: Icons.account_balance_rounded,
                      color: AppColors.primaryCyan,
                      headerBadge: tb != null
                          ? Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: tb.isBalanced
                                    ? AppColors.primaryEmerald.withValues(alpha: 0.15)
                                    : Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: tb.isBalanced ? AppColors.primaryEmerald : Colors.red,
                                ),
                              ),
                              child: Text(
                                tb.isBalanced ? 'BALANCED (Dr = Cr)' : 'UNBALANCED',
                                style: TextStyle(
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: tb.isBalanced ? AppColors.primaryEmerald : Colors.redAccent,
                                ),
                              ),
                            )
                          : null,
                      child: tb == null
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(12.r),
                                child: Text('Loading Trial Balance...',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp)),
                              ),
                            )
                          : Column(
                              children: [
                                _statRow('Total Debits (Dr)', Formatters.formatCurrency(tb.totalDebit), AppColors.creditGreenLight),
                                SizedBox(height: 8.h),
                                _statRow('Total Credits (Cr)', Formatters.formatCurrency(tb.totalCredit), AppColors.primaryCyan),
                                SizedBox(height: 8.h),
                                _statRow(
                                  'Net Difference',
                                  Formatters.formatCurrency(tb.difference),
                                  tb.difference == 0 ? AppColors.creditGreenLight : Colors.redAccent,
                                  isBold: true,
                                ),
                                if (tb.accounts.isNotEmpty) ...[
                                  const Divider(height: 20),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Account Breakdown (${tb.accounts.length} active)',
                                      style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  ...tb.accounts.take(5).map((a) {
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 6.h),
                                      child: Row(
                                        children: [
                                          Text('${a.code} ',
                                              style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                          Expanded(
                                            child: Text(a.name,
                                                style: TextStyle(fontSize: 11.5.sp, color: AppColors.textSecondary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                          ),
                                          if (a.debit > 0)
                                            Text(
                                              'Dr ${Formatters.formatCurrency(a.debit, showDecimals: false)}',
                                              style: TextStyle(fontSize: 11.sp, color: AppColors.creditGreen, fontWeight: FontWeight.w600),
                                            ),
                                          if (a.credit > 0)
                                            Text(
                                              'Cr ${Formatters.formatCurrency(a.credit, showDecimals: false)}',
                                              style: TextStyle(fontSize: 11.sp, color: AppColors.debitRose, fontWeight: FontWeight.w600),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                    ),

                    SizedBox(height: 14.h),

                    // 2. Accounts Receivable Aging (Debtors)
                    _reportContainer(
                      title: 'ACCOUNTS RECEIVABLE AGING (DEBTORS / UDHAR)',
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.cashGold,
                      child: ar == null
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(12.r),
                                child: Text('Loading Receivables Aging...',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp)),
                              ),
                            )
                          : Column(
                              children: [
                                _statRow('Total Debt Outstanding', Formatters.formatCurrency(ar.totalAmount), AppColors.cashGold, isBold: true),
                                const Divider(height: 16),
                                _statRow('0 to 30 Days (Current)', Formatters.formatCurrency(ar.summaryBuckets.current0To30), AppColors.creditGreenLight),
                                SizedBox(height: 8.h),
                                _statRow('31 to 60 Days (Due Soon)', Formatters.formatCurrency(ar.summaryBuckets.days31To60), AppColors.cashGold),
                                SizedBox(height: 8.h),
                                _statRow('61 to 90 Days (Aging)', Formatters.formatCurrency(ar.summaryBuckets.days61To90), Colors.orangeAccent),
                                SizedBox(height: 8.h),
                                _statRow('90+ Days (Critical Follow-up)', Formatters.formatCurrency(ar.summaryBuckets.over90Days), AppColors.debitRoseLight),
                              ],
                            ),
                    ),

                    SizedBox(height: 14.h),

                    // 3. Accounts Payable Aging (Suppliers / Creditors)
                    _reportContainer(
                      title: 'ACCOUNTS PAYABLE AGING (CREDITORS / SUPPLIERS)',
                      icon: Icons.local_shipping_rounded,
                      color: AppColors.primaryTeal,
                      child: ap == null
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(12.r),
                                child: Text('Loading Payables Aging...',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp)),
                              ),
                            )
                          : Column(
                              children: [
                                _statRow('Total Payables to Distributors', Formatters.formatCurrency(ap.totalAmount), AppColors.primaryTeal, isBold: true),
                                const Divider(height: 16),
                                _statRow('0 to 30 Days (Within Terms)', Formatters.formatCurrency(ap.summaryBuckets.current0To30), AppColors.creditGreenLight),
                                SizedBox(height: 8.h),
                                _statRow('31 to 60 Days (Due Soon)', Formatters.formatCurrency(ap.summaryBuckets.days31To60), AppColors.cashGold),
                                SizedBox(height: 8.h),
                                _statRow('61 to 90 Days (Overdue)', Formatters.formatCurrency(ap.summaryBuckets.days61To90), Colors.orangeAccent),
                                SizedBox(height: 8.h),
                                _statRow('90+ Days (Critical Payment Hold)', Formatters.formatCurrency(ap.summaryBuckets.over90Days), AppColors.debitRoseLight),
                              ],
                            ),
                    ),

                    SizedBox(height: 14.h),

                    // 4. Profit & Loss Summary
                    _reportContainer(
                      title: 'PROFIT & LOSS ESTIMATE (MTD)',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.creditGreen,
                      child: Column(
                        children: [
                          _statRow('Gross Revenue (Net Sales)', Formatters.formatCurrency(sales), AppColors.creditGreenLight),
                          SizedBox(height: 8.h),
                          _statRow('Cost of Goods (Purchases)', '- ${Formatters.formatCurrency(purchases)}', AppColors.debitRoseLight),
                          SizedBox(height: 8.h),
                          _statRow('Closing Stock Valuation', Formatters.formatCurrency(stockVal), AppColors.primaryCyan),
                          const Divider(height: 20),
                          _statRow(
                            'Estimated Gross Profit',
                            Formatters.formatCurrency(grossProfit),
                            AppColors.creditGreenLight,
                            isBold: true,
                          ),
                          SizedBox(height: 6.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: AppDecorations.badge(color: AppColors.creditGreen),
                              child: Text(
                                'Gross Profit Margin: ${netMargin.toStringAsFixed(1)}%',
                                style: AppTypography.badge.copyWith(color: AppColors.creditGreenLight),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 14.h),

                    // 5. GST & Tax Overview (GSTR-1 / 3B)
                    _reportContainer(
                      title: 'GST & TAX SUMMARY (GSTR-1 & 3B)',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.primaryBlue,
                      child: Column(
                        children: [
                          _statRow('Total Taxable Turnover', Formatters.formatCurrency(sales * 0.82), AppColors.textPrimary),
                          SizedBox(height: 8.h),
                          _statRow('Output CGST (9%)', Formatters.formatCurrency(sales * 0.09), AppColors.amberWarningLight),
                          SizedBox(height: 8.h),
                          _statRow('Output SGST (9%)', Formatters.formatCurrency(sales * 0.09), AppColors.amberWarningLight),
                          SizedBox(height: 8.h),
                          _statRow('Eligible Input Tax Credit (ITC)', '- ${Formatters.formatCurrency(purchases * 0.18)}', AppColors.creditGreenLight),
                          const Divider(height: 20),
                          _statRow(
                            'Net GST Payable to Govt',
                            Formatters.formatCurrency((sales * 0.18 - purchases * 0.18).clamp(0, double.infinity)),
                            AppColors.primaryCyan,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _reportContainer({
    required String title,
    required IconData icon,
    required Color color,
    Widget? headerBadge,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: AppDecorations.card(borderColor: color.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16.sp, color: color),
                  SizedBox(width: 8.w),
                  Text(title, style: AppTypography.badge.copyWith(color: color, letterSpacing: 0.5)),
                ],
              ),
              ?headerBadge,
            ],
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isBold ? Colors.white : AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14.sp : 12.5.sp,
            color: color,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
