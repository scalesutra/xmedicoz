import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:ledger_app/features/crm/controllers/crm_controller.dart';
import 'package:ledger_app/features/inventory/controllers/master_data_controller.dart';
import '../../core/constants/app_strings.dart';
import '../../core/controllers/ledger_controller.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bill_preview_modal.dart';
import '../../core/widgets/marg_reports_sheet.dart';
import '../../core/widgets/stat_card.dart';
import '../vouchers/marg_sale_invoice_modal.dart';
import '../purchases/widgets/ocr_purchase_review_sheet.dart';
import '../../core/routes/app_routes.dart';
import '../accounting/controllers/accounting_controller.dart';
import '../accounting/widgets/record_expense_modal.dart';
import '../accounting/widgets/account_ledger_sheet.dart';
import '../ocr/widgets/ocr_scanner_modal.dart';
import '../../core/widgets/unique_3d_refresh_indicator.dart';
import '../inventory/controllers/batch_controller.dart';
import '../sales/controllers/sales_controller.dart';
import '../purchases/controllers/purchases_controller.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToInventory;
  final VoidCallback onNavigateToLedger;
  final VoidCallback onNavigateToVouchers;
  final VoidCallback? onToggleDrawer;

  const DashboardScreen({
    super.key,
    required this.onNavigateToInventory,
    required this.onNavigateToLedger,
    required this.onNavigateToVouchers,
    this.onToggleDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LedgerController>();

    return SafeArea(
      child: Obx(() {
        final activeShop = controller.activeShop.value;
        return Unique3DRefreshIndicator(
          title: 'Syncing Pharmacy Ledger...',
          onRefresh: () async {
            if (Get.isRegistered<AccountingController>()) {
              await Future.wait([
                Get.find<AccountingController>().fetchDaybook(),
                Get.find<AccountingController>().fetchAccounts(),
              ]);
            }
            if (Get.isRegistered<MasterDataController>()) {
              await Get.find<MasterDataController>().fetchAllData();
            }
            if (Get.isRegistered<BatchController>()) {
              await Get.find<BatchController>().refreshAll();
            }
            if (Get.isRegistered<SalesController>()) {
              await Get.find<SalesController>().fetchSales(resetPage: true);
            }
            if (Get.isRegistered<PurchasesController>()) {
              await Get.find<PurchasesController>().fetchPurchases(
                resetPage: true,
              );
            }
            if (Get.isRegistered<CrmController>()) {
              await Get.find<CrmController>().loadCrmDashboardData();
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. MARGBOOKS TOP HEADER: Shop & Financial Year
                _buildMargHeader(context, activeShop, controller),

                SizedBox(height: 16.h),

                // 2. CASH IN HAND & BANK BALANCE COCKPIT
                _buildCashAndBankCockpit(context, activeShop),

                SizedBox(height: 16.h),

                // 3. "KITNA AAYA / KITNA GYA" INFLOW & OUTFLOW TRACKER (Cash vs Online split)
                _buildInflowOutflowPulse(controller),

                SizedBox(height: 16.h),

                // 4. NET SALES & NET PURCHASES + STOCK VALUE
                _buildNetSalesAndPurchasesRow(controller),

                SizedBox(height: 16.h),

                // 5. RECEIVABLES & PAYABLES (Tally Sundry Debtors & Creditors)
                _buildReceivablesAndPayablesRow(controller),

                SizedBox(height: 20.h),

                // 6. MARGBOOKS 6-GRID SERVICE SHORTCUTS
                _buildMargServicesGrid(context, controller),

                SizedBox(height: 16.h),

                // 6.5 PATIENT CRM & REFILL REMINDERS RADAR
                _buildCrmRefillRadar(context),

                SizedBox(height: 20.h),

                // 7. CRITICAL STOCK & RE-ORDER WARNINGS
                _buildLowStockWarningCarousel(context, controller),

                SizedBox(height: 20.h),

                // 8. RECENT DAYBOOK TRANSACTIONS (Tap to View, Share, Print Bill)
                _buildRecentTransactionsSection(
                  context,
                  controller,
                  activeShop,
                ),

                SizedBox(height: 80.h), // Bottom nav padding
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMargHeader(
    BuildContext context,
    ShopModel activeShop,
    LedgerController controller,
  ) {
    return Row(
      children: [
        // Drawer Menu Trigger
        Builder(
          builder: (scaffoldCtx) => GestureDetector(
            onTap:
                onToggleDrawer ?? () => Scaffold.of(scaffoldCtx).openDrawer(),
            child: Container(
              width: 40.r,
              height: 40.r,
              margin: EdgeInsets.only(right: 10.w),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                border: Border.all(
                  color: AppColors.primaryCyan.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                Icons.menu_rounded,
                color: AppColors.primaryCyan,
                size: 22.sp,
              ),
            ),
          ),
        ),

        // Single Store Pharmacy Header Card
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              border: Border.all(color: AppColors.borderSubtle, width: 1.w),
            ),
            child: Row(
              children: [
                Container(
                  width: 34.r,
                  height: 34.r,
                  decoration: BoxDecoration(
                    color: activeShop.category.primaryColor.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    activeShop.category.icon,
                    size: 18.sp,
                    color: activeShop.category.primaryColor,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              activeShop.name,
                              style: AppTypography.h4,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 1.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryEmerald.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4.r),
                              border: Border.all(
                                color: AppColors.primaryEmerald.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 10.sp,
                                  color: AppColors.primaryEmerald,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'Store',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryEmerald,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${activeShop.city} • DL: ${activeShop.drugLicenseNo}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.primaryCyan,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),
        // Marg Financial Intelligence Report Icon
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.15),
            foregroundColor: AppColors.primaryCyan,
          ),
          icon: const Icon(Icons.analytics_rounded),
          onPressed: () => MargReportsSheet.show(context),
        ),
      ],
    );
  }

  Widget _buildCashAndBankCockpit(BuildContext context, ShopModel activeShop) {
    return Obx(() {
      double cashVal = 0.0;
      double bankVal = 0.0;
      double cashMove = 0.0;
      double bankMove = 0.0;
      bool isLiveApi = false;

      if (Get.isRegistered<AccountingController>()) {
        final acc = Get.find<AccountingController>();
        cashVal = acc.cashBalance;
        bankVal = acc.bankBalance;
        cashMove = acc.cashNetMovement;
        bankMove = acc.bankNetMovement;
        isLiveApi = acc.daybook.value != null || acc.accounts.isNotEmpty;
      }

      final totalVal = cashVal + bankVal;

      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: AppColors.luxuryCardGradient,
          borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
          border: Border.all(
            color: AppColors.borderHighlight.withValues(alpha: 0.3),
            width: 1.2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16.r,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'LIQUIDITY COCKPIT',
                      style: AppTypography.badge.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (isLiveApi) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 1.h,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Total: ${Formatters.formatCurrency(totalVal)}',
                  style: AppTypography.label.copyWith(
                    color: AppColors.primaryCyan,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                // Cash in Hand
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(
                        AppDecorations.radiusMd,
                      ),
                      border: Border.all(
                        color: AppColors.cashGold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payments_rounded,
                              size: 15.sp,
                              color: AppColors.cashGold,
                            ),
                            SizedBox(width: 5.w),
                            Expanded(
                              child: Text(
                                AppStrings.cashInHand,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  Formatters.formatCurrency(
                                    cashVal,
                                    showDecimals: false,
                                  ),
                                  style: AppTypography.balanceMedium.copyWith(
                                    color: AppColors.cashGold,
                                  ),
                                ),
                              ),
                            ),
                            if (isLiveApi && cashMove != 0) ...[
                              SizedBox(width: 4.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: cashMove > 0
                                      ? AppColors.primaryEmerald.withValues(
                                          alpha: 0.15,
                                        )
                                      : Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  cashMove > 0
                                      ? '+₹${cashMove.toStringAsFixed(0)}'
                                      : '-₹${(-cashMove).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                    color: cashMove > 0
                                        ? AppColors.primaryEmerald
                                        : Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Drawer',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Bank Account
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(
                        AppDecorations.radiusMd,
                      ),
                      border: Border.all(
                        color: AppColors.primaryCyan.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_rounded,
                              size: 15.sp,
                              color: AppColors.primaryCyan,
                            ),
                            SizedBox(width: 5.w),
                            Expanded(
                              child: Text(
                                AppStrings.bankAccounts,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  Formatters.formatCurrency(
                                    bankVal,
                                    showDecimals: false,
                                  ),
                                  style: AppTypography.balanceMedium.copyWith(
                                    color: AppColors.primaryCyan,
                                  ),
                                ),
                              ),
                            ),
                            if (isLiveApi && bankMove != 0) ...[
                              SizedBox(width: 4.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: bankMove > 0
                                      ? AppColors.primaryEmerald.withValues(
                                          alpha: 0.15,
                                        )
                                      : Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  bankMove > 0
                                      ? '+₹${bankMove.toStringAsFixed(0)}'
                                      : '-₹${(-bankMove).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                    color: bankMove > 0
                                        ? AppColors.primaryEmerald
                                        : Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Current A/c (1020)',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => RecordExpenseModal.show(context),
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.debitRose.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.debitRose.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_card_rounded,
                            size: 14.sp,
                            color: AppColors.debitRoseLight,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '+ Record Expense',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.debitRoseLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: InkWell(
                    onTap: () => AccountLedgerSheet.show(context),
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.primaryCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 14.sp,
                            color: AppColors.primaryCyan,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'General Ledger',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInflowOutflowPulse(LedgerController controller) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: AppDecorations.card(borderColor: AppColors.borderSubtle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sync_alt_rounded,
                    size: 18.sp,
                    color: AppColors.primaryCyan,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'TODAY INFLOW & OUTFLOW',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: AppDecorations.badge(color: AppColors.creditGreen),
                child: Text(
                  'Daybook',
                  style: AppTypography.badge.copyWith(
                    color: AppColors.creditGreenLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              // Kitna Aaya (Inflow)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.kitnaAaya,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.creditGreenLight,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      Formatters.formatCurrency(
                        controller.totalInflow,
                        showDecimals: false,
                      ),
                      style: AppTypography.balanceMedium.copyWith(
                        color: AppColors.creditGreenLight,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Cash: ${Formatters.formatCompact(controller.cashInflow)} • UPI: ${Formatters.formatCompact(controller.onlineInflow)}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1.w,
                height: 44.h,
                color: AppColors.borderSubtle,
              ),
              SizedBox(width: 14.w),
              // Kitna Gya (Outflow)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.kitnaGya,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.debitRoseLight,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      Formatters.formatCurrency(
                        controller.totalOutflow,
                        showDecimals: false,
                      ),
                      style: AppTypography.balanceMedium.copyWith(
                        color: AppColors.debitRoseLight,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Vendor & Expense Pay',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetSalesAndPurchasesRow(LedgerController controller) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: AppStrings.netSales,
            value: Formatters.formatCurrency(
              controller.netSalesToday,
              showDecimals: false,
            ),
            subtitle: '+24% today',
            icon: Icons.trending_up_rounded,
            accentColor: AppColors.creditGreen,
            onTap: onNavigateToVouchers,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: StatCard(
            title: AppStrings.netPurchases,
            value: Formatters.formatCurrency(
              controller.netPurchasesToday,
              showDecimals: false,
            ),
            subtitle: 'Suppliers Stock In',
            icon: Icons.shopping_bag_outlined,
            accentColor: AppColors.primaryBlue,
            onTap: onNavigateToVouchers,
          ),
        ),
      ],
    );
  }

  Widget _buildReceivablesAndPayablesRow(LedgerController controller) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: AppStrings.toReceive,
            value: Formatters.formatCurrency(
              controller.totalReceivables,
              showDecimals: false,
            ),
            subtitle: 'Debtors Balance',
            icon: Icons.call_received_rounded,
            accentColor: AppColors.creditGreen,
            onTap: onNavigateToLedger,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: StatCard(
            title: AppStrings.toPay,
            value: Formatters.formatCurrency(
              controller.totalPayables,
              showDecimals: false,
            ),
            subtitle: 'Creditors Balance',
            icon: Icons.call_made_rounded,
            accentColor: AppColors.debitRose,
            onTap: onNavigateToLedger,
          ),
        ),
      ],
    );
  }

  Widget _buildMargServicesGrid(
    BuildContext context,
    LedgerController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Futuristic Cyber-Medical Cockpit Console Header Card
        Container(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 11.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryEmerald.withValues(alpha: 0.12),
                AppColors.bgCard,
                AppColors.clinicalCyan.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: AppColors.primaryEmerald.withValues(alpha: 0.28),
              width: 1.2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                blurRadius: 16.r,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.02),
                blurRadius: 6.r,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Cockpit Icon Emblem + Title & Live Badge + Audit Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // 3D Glowing Hex/Square Launcher Pod
                        Container(
                          width: 38.r,
                          height: 38.r,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.5),
                              width: 1.2.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryEmerald.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10.r,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.space_dashboard_rounded,
                              size: 20.sp,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Pharma Cockpit',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.h4.copyWith(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                ],
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'One-Touch Dispense, Inward & Expiry Radar',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      MargReportsSheet.show(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryEmerald,
                            AppColors.primaryEmeraldDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppDecorations.radiusPill,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryEmerald.withValues(
                              alpha: 0.28,
                            ),
                            blurRadius: 8.r,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.analytics_rounded,
                            size: 13.sp,
                            color: AppColors.white,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Rx P&L',
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              // Live Telemetry Mini Status Strip
              Obx(() {
                final totalMedicines = controller.stockItems.length;
                final nearExpiryCount = controller.stockItems
                    .where((i) => i.isNearExpiry)
                    .length;
                final todayTxCount = controller.transactions.where((t) {
                  final now = DateTime.now();
                  return t.date.year == now.year &&
                      t.date.month == now.month &&
                      t.date.day == now.day;
                }).length;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _cockpitTelemetryPill(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'POS Ready',
                        color: AppColors.creditGreen,
                      ),
                      SizedBox(width: 6.w),
                      _cockpitTelemetryPill(
                        icon: Icons.inventory_2_outlined,
                        label: '$totalMedicines Medicines In-Stock',
                        color: AppColors.clinicalCyan,
                      ),
                      SizedBox(width: 6.w),
                      _cockpitTelemetryPill(
                        icon: Icons.receipt_long_outlined,
                        label: '$todayTxCount Vouchers Today',
                        color: AppColors.primaryPurple,
                      ),
                      if (nearExpiryCount > 0) ...[
                        SizedBox(width: 6.w),
                        _cockpitTelemetryPill(
                          icon: Icons.warning_amber_rounded,
                          label: '$nearExpiryCount Near Expiry Alert',
                          color: AppColors.amberWarning,
                          isWarning: true,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // 2. High-Tech Action Bento Grid (Primary Actions)
        Row(
          children: [
            Expanded(
              child: _serviceBentoCard(
                tag: 'Rx POS BILL',
                title: 'Fast Rx Sale',
                subtitle: 'Doctor Memo & GST',
                icon: Icons.receipt_long_rounded,
                color: AppColors.creditGreen,
                onTap: () => MargSaleInvoiceModal.show(context),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _serviceBentoCard(
                tag: 'STOCKIST',
                title: 'Stockist Inward',
                subtitle: 'Pharma Bill & Batch',
                icon: Icons.local_shipping_rounded,
                color: AppColors.primaryBlue,
                onTap: () => OcrPurchaseReviewSheet.show(context),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _serviceBentoCard(
                tag: 'AI OCR',
                title: 'AI Smart Scanner',
                subtitle: 'Camera / Gallery Rx & Bill',
                icon: Icons.document_scanner_rounded,
                color: AppColors.primaryPurple,
                onTap: () => OcrScannerModal.show(context),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _serviceBentoCard(
                tag: 'EXPENSE',
                title: 'Store Expense',
                subtitle: 'Rent, Bill & Tea Outflow',
                icon: Icons.receipt_rounded,
                color: AppColors.debitRose,
                onTap: () => RecordExpenseModal.show(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCrmRefillRadar(BuildContext context) {
    if (!Get.isRegistered<CrmController>()) return const SizedBox.shrink();
    final crmController = Get.find<CrmController>();

    return Obx(() {
      final overdue = crmController.overdueCount;
      final upcoming = crmController.upcomingDueCount;
      final callbacks = crmController.pendingFollowUpsCount;

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.crmHub),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryEmerald.withValues(alpha: 0.12),
                AppColors.bgCard,
                AppColors.clinicalCyan.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: overdue > 0
                  ? Colors.redAccent.withValues(alpha: 0.4)
                  : AppColors.primaryEmerald.withValues(alpha: 0.3),
              width: 1.2.w,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.autorenew_rounded,
                      color: AppColors.primaryEmerald,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Patient CRM & Refills',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5.sp,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            if (overdue > 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 1.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  '$overdue OVERDUE',
                                  style: TextStyle(
                                    fontSize: 8.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          'WhatsApp chronic repeat alerts & callbacks',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10.5.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14.sp,
                    color: AppColors.primaryEmerald,
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 6.h,
                        horizontal: 8.w,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 14.sp,
                            color: AppColors.primaryEmerald,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '$upcoming Due Soon',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryEmerald,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 6.h,
                        horizontal: 8.w,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_callback_rounded,
                            size: 14.sp,
                            color: AppColors.accentTeal,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '$callbacks Callbacks',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accentTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _cockpitTelemetryPill({
    required IconData icon,
    required String label,
    required Color color,
    bool isWarning = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isWarning ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
        border: Border.all(
          color: color.withValues(alpha: isWarning ? 0.45 : 0.22),
          width: 0.8.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceBentoCard({
    required String tag,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.09), AppColors.bgCard],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
          border: Border.all(
            color: color.withValues(alpha: 0.28),
            width: 1.2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 14.r,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
              blurRadius: 6.r,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDecorations.radiusLg - 1.2),
          child: Stack(
            children: [
              // Bottom Subtle Accent Glow Line
              Positioned(
                bottom: 0,
                left: 12.w,
                right: 12.w,
                height: 2.h,
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(2.r),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4.r,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: 3D-Styled Floating Icon Pod + Tag & Micro Action Arrow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 38.r,
                          height: 38.r,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.22),
                                color.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11.r),
                            border: Border.all(
                              color: color.withValues(alpha: 0.35),
                              width: 1.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.16),
                                blurRadius: 6.r,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 19.sp, color: color),
                        ),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppDecorations.radiusPill,
                                    ),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.32),
                                      width: 0.8.w,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 4.5.r,
                                        height: 4.5.r,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 3.5.w),
                                      Flexible(
                                        child: Text(
                                          tag,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 8.5.sp,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Icon(
                                Icons.north_east_rounded,
                                size: 12.sp,
                                color: color.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom Column: Bold High-Contrast Title + Descriptive Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockWarningCarousel(
    BuildContext context,
    LedgerController controller,
  ) {
    final lowStockItems = controller.stockItems
        .where((i) => i.isLowStock)
        .toList();

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.amberWarningBg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        border: Border.all(
          color: AppColors.amberWarning.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18.sp,
                color: AppColors.amberWarning,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${AppStrings.lowStockAlert} (${lowStockItems.length} critical)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amberWarningLight,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: onNavigateToInventory,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.amberWarning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      AppDecorations.radiusPill,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Manage',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amberWarningDark,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14.sp,
                        color: AppColors.amberWarningDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: lowStockItems.map((item) {
                return Container(
                  margin: EdgeInsets.only(right: 10.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(
                      AppDecorations.radiusSm,
                    ),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${item.batchNumber} • ${item.isNearExpiry ? "NEAR EXPIRY (${item.expiryDate})" : "Stock: ${item.currentQty} left"}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: item.isNearExpiry
                                  ? AppColors.nearExpiryColor
                                  : AppColors.amberWarningLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 10.w),
                      Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 16.sp,
                        color: AppColors.primaryCyan,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
    BuildContext context,
    LedgerController controller,
    ShopModel activeShop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                AppStrings.recentTransactions,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h4,
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: onNavigateToVouchers,
              child: Text(
                AppStrings.viewAll,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.primaryCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (controller.transactions.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
            decoration: AppDecorations.card(bgColor: AppColors.bgCard),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 28.sp,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'No recent daybook bills yet',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Generate your first sale or purchase bill',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.transactions.take(4).length,
            separatorBuilder: (context, index) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final tx = controller.transactions[index];
              final isInflow = tx.isInflow;
              final isCash = tx.paymentMode == PaymentMode.cash;

              return GestureDetector(
                onTap: () {
                  BillPreviewModal.show(
                    context,
                    transaction: tx,
                    shop: activeShop,
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: AppDecorations.card(bgColor: AppColors.bgCard),
                  child: Row(
                    children: [
                      Container(
                        width: 38.r,
                        height: 38.r,
                        decoration: BoxDecoration(
                          color:
                              (isInflow
                                      ? AppColors.creditGreen
                                      : AppColors.debitRose)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppDecorations.radiusSm,
                          ),
                        ),
                        child: Icon(
                          isInflow
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: isInflow
                              ? AppColors.creditGreenLight
                              : AppColors.debitRoseLight,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.partyName,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${tx.invoiceNo} • ${Formatters.formatTime(tx.date)}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isInflow ? "+" : "-"} ${Formatters.formatCurrency(tx.amount)}',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: isInflow
                                  ? AppColors.creditGreenLight
                                  : AppColors.debitRoseLight,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: tx.paymentMode == PaymentMode.credit
                                  ? AppColors.debitRose.withValues(alpha: 0.12)
                                  : (isCash
                                      ? AppColors.cashGold.withValues(alpha: 0.12)
                                      : AppColors.onlineBlue.withValues(
                                          alpha: 0.12,
                                        )),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              tx.paymentMode == PaymentMode.credit
                                  ? 'UDHAR'
                                  : (isCash ? 'CASH' : 'ONLINE'),
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                color: tx.paymentMode == PaymentMode.credit
                                    ? AppColors.debitRose
                                    : (isCash
                                        ? AppColors.cashGold
                                        : AppColors.onlineBlue),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
