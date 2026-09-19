import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_app/features/purchases/widgets/ocr_purchase_review_sheet.dart';

import '../../core/constants/app_strings.dart';
import '../../core/controllers/ledger_controller.dart';
import '../../core/models/models.dart';
import '../../core/models/purchase_models.dart';
import '../../core/models/sales_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/bill_preview_modal.dart';
import '../purchases/controllers/purchases_controller.dart';
import '../purchases/widgets/purchase_detail_sheet.dart';
import '../sales/controllers/sales_controller.dart';
import '../sales/widgets/sales_invoice_detail_sheet.dart';
import 'marg_sale_invoice_modal.dart';

class VouchersScreen extends StatefulWidget {
  final ShopModel activeShop;

  const VouchersScreen({super.key, required this.activeShop});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final controller = Get.find<LedgerController>();
  late final PurchasesController purchasesController;
  late final SalesController salesController;

  // 0 = Rx Sales (POS), 1 = Stockist Inward Bills, 2 = Daybook Vouchers
  int _selectedSection = 0;

  TransactionType? _filterType;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final DateFormat _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    purchasesController = Get.isRegistered<PurchasesController>()
        ? Get.find<PurchasesController>()
        : Get.put(PurchasesController());
    salesController = Get.isRegistered<SalesController>()
        ? Get.find<SalesController>()
        : Get.put(SalesController());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val.trim());
    if (_selectedSection == 0) {
      salesController.searchQuery.value = val.trim();
      salesController.fetchSales(resetPage: true);
    } else if (_selectedSection == 1) {
      purchasesController.searchQuery.value = val.trim();
      purchasesController.fetchPurchases(resetPage: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: SafeArea(
        child: Obx(() {
          return Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.vouchersTitle,
                              style: AppTypography.h2,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _selectedSection == 0
                                  ? '${salesController.salesInvoices.length} Invoices • Fast Counter POS'
                                  : _selectedSection == 1
                                  ? '${purchasesController.purchases.length} Purchase Bills • Inward Register'
                                  : 'Pharmacy Daybook • ${controller.transactions.length} Vouchers',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (_selectedSection == 0) ...[
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: AppColors.primaryEmerald,
                                ),
                                onPressed: () =>
                                    salesController.fetchSales(resetPage: true),
                              ),
                            ] else if (_selectedSection == 1) ...[
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: AppColors.primaryBlue,
                                ),
                                onPressed: () => purchasesController
                                    .fetchPurchases(resetPage: true),
                              ),
                            ] else ...[
                              IconButton(
                                icon: const Icon(
                                  Icons.sync_rounded,
                                  color: AppColors.primaryPurple,
                                ),
                                tooltip: 'Sync Daybook',
                                onPressed: () {
                                  controller.syncLiveTransactions();
                                  HapticFeedback.lightImpact();
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // Section Switcher: Rx Sales vs Stockist Inward vs Daybook
                    Container(
                      height: 42.h,
                      padding: EdgeInsets.all(3.r),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(
                          AppDecorations.radiusMd,
                        ),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          _buildSectionTab(
                            0,
                            'Rx Sales',
                            Icons.point_of_sale_rounded,
                            AppColors.primaryEmerald,
                          ),
                          SizedBox(width: 4.w),
                          _buildSectionTab(
                            1,
                            'Stockist Inward',
                            Icons.local_shipping_outlined,
                            AppColors.primaryBlue,
                          ),
                          SizedBox(width: 4.w),
                          _buildSectionTab(
                            2,
                            'Daybook',
                            Icons.receipt_long_rounded,
                            AppColors.primaryPurple,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Search Field
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: AppTypography.bodyMedium,
                      decoration: AppDecorations.searchDecoration(
                        hintText: _selectedSection == 0
                            ? 'Search sales...'
                            : _selectedSection == 1
                            ? 'Search purchases...'
                            : 'Search day book...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                        ),
                        focusColor: _selectedSection == 0
                            ? AppColors.primaryEmerald
                            : _selectedSection == 1
                            ? AppColors.primaryBlue
                            : AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              if (_selectedSection == 0)
                _buildSalesStatusFilters()
              else if (_selectedSection == 1)
                _buildPurchaseStatusFilters()
              else ...[
                _buildDaybookTelemetryBar(),
                SizedBox(height: 8.h),
                _buildDaybookFilterChips(),
              ],

              SizedBox(height: 10.h),

              // Main List Content
              Expanded(
                child: _selectedSection == 0
                    ? _buildSalesList()
                    : _selectedSection == 1
                    ? _buildPurchasesList()
                    : _buildDaybookList(),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: _selectedSection == 0
          ? AppFloatingButton(
              label: 'New POS Bill',
              icon: Icons.receipt_long_rounded,
              gradient: const LinearGradient(
                colors: [AppColors.primaryEmerald, AppColors.clinicalCyan],
              ),
              glowColor: AppColors.primaryEmerald,
              onPressed: () => MargSaleInvoiceModal.show(context),
            )
          : _selectedSection == 1
          ? AppFloatingButton(
              label: 'Enter Purchase Bill',
              icon: Icons.add_shopping_cart,
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.clinicalCyan],
              ),
              glowColor: AppColors.primaryBlue,
              onPressed: () => OcrPurchaseReviewSheet.show(context),
            )
          : null,
    );
  }

  Widget _buildSectionTab(
    int index,
    String title,
    IconData icon,
    Color activeColor,
  ) {
    final isSelected = _selectedSection == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedSection = index;
            _searchCtrl.clear();
            if (index == 0) salesController.fetchSales();
            if (index == 1) purchasesController.fetchPurchases();
            if (index == 2) controller.syncLiveTransactions();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      activeColor.withValues(alpha: 0.22),
                      activeColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : AppColors.transparent,
            borderRadius: BorderRadius.circular(AppDecorations.radiusMd - 2),
            border: isSelected
                ? Border.all(
                    color: activeColor.withValues(alpha: 0.7),
                    width: 1.w,
                  )
                : Border.all(color: AppColors.transparent),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 8.r,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13.5.sp,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 11.5.sp,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Sales POS Invoices Tab Views
  // --------------------------------------------------------------------------
  Widget _buildSalesStatusFilters() {
    return SizedBox(
      height: 38.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        children: [
          _salesStatusChip('', 'All Sales'),
          _salesStatusChip(
            'PAID',
            'Settled (Paid) (${salesController.paidCount})',
          ),
          _salesStatusChip('PARTIALLY_PAID', 'Partially Paid'),
          _salesStatusChip(
            'UNPAID',
            'Unpaid / Due (${salesController.unpaidCount})',
          ),
        ],
      ),
    );
  }

  Widget _salesStatusChip(String status, String label) {
    final isSelected = salesController.paymentStatusFilter.value == status;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          salesController.paymentStatusFilter.value = val ? status : '';
        },
        backgroundColor: AppColors.bgCard,
        selectedColor: AppColors.primaryEmerald.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          fontSize: 11.5.sp,
          color: isSelected
              ? AppColors.primaryEmerald
              : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          side: BorderSide(
            color: isSelected
                ? AppColors.primaryEmerald
                : AppColors.borderSubtle,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildSalesList() {
    final isBusy = salesController.isLoadingSales.value;
    final invoices = salesController.filteredSalesInvoices;

    if (isBusy && invoices.isEmpty && salesController.salesInvoices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryEmerald),
      );
    }

    if (invoices.isEmpty) {
      final isFiltered = salesController.paymentStatusFilter.value.isNotEmpty;
      return RefreshIndicator(
        color: AppColors.primaryEmerald,
        onRefresh: () => salesController.fetchSales(resetPage: true),
        child: ListView(
          children: [
            SizedBox(height: 80.h),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.point_of_sale_rounded,
                    size: 48.sp,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    isFiltered
                        ? 'No ${salesController.paymentStatusFilter.value == "UNPAID" ? "Unpaid / Credit" : "Paid"} invoices found'
                        : 'No counter POS sales invoices found',
                    style: AppTypography.bodyMedium,
                  ),
                  SizedBox(height: 6.h),
                  if (isFiltered)
                    TextButton.icon(
                      onPressed: () =>
                          salesController.paymentStatusFilter.value = '',
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      label: const Text('Show All Sales'),
                    )
                  else
                    Text(
                      'Tap "New POS Bill" below to create your first invoice',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryEmerald,
      onRefresh: () => salesController.fetchSales(resetPage: true),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          18.w,
          4.h,
          18.w,
          80.h + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: invoices.length,
        separatorBuilder: (_, _) => SizedBox(height: 7.h),
        itemBuilder: (ctx, i) => _buildSalesCard(invoices[i]),
      ),
    );
  }

  Widget _buildSalesCard(SalesInvoiceModel inv) {
    Color statusColor = AppColors.debitRose;
    if (inv.isCreditSale) {
      statusColor = AppColors.debitRose;
    } else if (inv.paymentStatus == 'PAID') {
      statusColor = AppColors.creditGreen;
    } else if (inv.paymentStatus == 'PARTIALLY_PAID') {
      statusColor = Colors.orange.shade800;
    }

    final hasReturns = inv.returns.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        SalesInvoiceDetailSheet.show(context, inv.id);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4.r,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. Sleek Squircle Icon Badge
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primaryEmerald,
                  size: 18.sp,
                ),
              ),
            ),
            SizedBox(width: 10.w),

            // 2. Middle Content (Customer/Patient, Invoice No, Doctor/Items, Date)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          inv.customerName.isNotEmpty
                              ? inv.customerName
                              : 'Walk-in Retail Patient',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      if (hasReturns) ...[
                        SizedBox(width: 4.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.debitRose.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                          child: Text(
                            'RET',
                            style: TextStyle(
                              fontSize: 7.5.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.debitRose,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          inv.invoiceNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        '${inv.items.length} ${inv.items.length == 1 ? "Item" : "Items"}',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        inv.invoiceDate != null
                            ? _dateFmt.format(inv.invoiceDate!)
                            : (inv.createdAt != null
                                  ? _dateFmt.format(inv.createdAt!)
                                  : ''),
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // 3. Trailing Amount & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(inv.totalAmount),
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        inv.isCreditSale
                            ? 'UDHAR'
                            : (inv.balanceAmount > 0
                                  ? 'DUE ${Formatters.formatCompact(inv.balanceAmount)}'
                                  : inv.paymentStatus),
                        style: TextStyle(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11.sp,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Purchase Bills Tab Views
  // --------------------------------------------------------------------------
  Widget _buildPurchaseStatusFilters() {
    return SizedBox(
      height: 38.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        children: [
          _statusChip('', 'All Bills'),
          _statusChip(
            'UNPAID',
            'Unpaid (${purchasesController.unpaidInvoicesCount})',
          ),
          _statusChip('PARTIALLY_PAID', 'Partially Paid'),
          _statusChip('PAID', 'Settled (Paid)'),
        ],
      ),
    );
  }

  Widget _statusChip(String status, String label) {
    final isSelected = purchasesController.paymentStatusFilter.value == status;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          purchasesController.paymentStatusFilter.value = val ? status : '';
          purchasesController.fetchPurchases(resetPage: true);
        },
        backgroundColor: AppColors.bgCard,
        selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          fontSize: 11.5.sp,
          color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          side: BorderSide(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderSubtle,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildPurchasesList() {
    final isBusy = purchasesController.isLoadingPurchases.value;
    final purchases = purchasesController.purchases;

    if (isBusy && purchases.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (purchases.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: () => purchasesController.fetchPurchases(resetPage: true),
        child: ListView(
          children: [
            SizedBox(height: 80.h),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48.sp,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'No stockist purchase bills found',
                    style: AppTypography.bodyMedium,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Tap "Enter Purchase Bill" below to record inward stock',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: () => purchasesController.fetchPurchases(resetPage: true),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          18.w,
          4.h,
          18.w,
          80.h + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: purchases.length,
        separatorBuilder: (_, _) => SizedBox(height: 7.h),
        itemBuilder: (ctx, i) => _buildPurchaseCard(purchases[i]),
      ),
    );
  }

  Widget _buildPurchaseCard(PurchaseInvoiceModel inv) {
    Color statusColor = AppColors.debitRose;
    if (inv.isPaid) {
      statusColor = AppColors.creditGreen;
    } else if (inv.isPartiallyPaid) {
      statusColor = Colors.orange.shade800;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        PurchaseDetailSheet.show(context, inv.id);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4.r,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. Sleek Squircle Icon Badge
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.25),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primaryBlue,
                  size: 18.sp,
                ),
              ),
            ),
            SizedBox(width: 10.w),

            // 2. Middle Content (Supplier, Bill No, Inward Items, Date)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inv.supplier?.name ?? 'Stockist Supplier',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          inv.invoiceNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.clinicalCyan,
                          ),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        '${inv.itemCount} ${inv.itemCount == 1 ? "Item" : "Items"}',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (inv.invoiceDate != null) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10.sp,
                          ),
                        ),
                        Text(
                          _dateFmt.format(inv.invoiceDate!),
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // 3. Trailing Amount & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(inv.totalAmount),
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        inv.balanceAmount > 0
                            ? 'DUE ${Formatters.formatCompact(inv.balanceAmount)}'
                            : inv.paymentStatus,
                        style: TextStyle(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11.sp,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Daybook Vouchers Tab Views
  // --------------------------------------------------------------------------

  Widget _buildDaybookTelemetryBar() {
    final transactions = controller.transactions;
    final totalIn = transactions
        .where((t) => t.isInflow)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalOut = transactions
        .where((t) => !t.isInflow)
        .fold(0.0, (sum, t) => sum + t.amount);
    final netCashflow = totalIn - totalOut;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6.r,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildDaybookMetric(
                label: 'RECEIPTS (IN)',
                value: '+ ${Formatters.formatCompact(totalIn)}',
                color: AppColors.creditGreen,
                icon: Icons.south_west_rounded,
              ),
            ),
            Container(width: 1.w, height: 26.h, color: AppColors.borderLight),
            Expanded(
              child: _buildDaybookMetric(
                label: 'PAYOUTS (OUT)',
                value: '- ${Formatters.formatCompact(totalOut)}',
                color: AppColors.debitRose,
                icon: Icons.north_east_rounded,
              ),
            ),
            Container(width: 1.w, height: 26.h, color: AppColors.borderLight),
            Expanded(
              child: _buildDaybookMetric(
                label: 'NET CASHFLOW',
                value: Formatters.formatCompact(netCashflow),
                color: netCashflow >= 0
                    ? AppColors.clinicalCyan
                    : AppColors.amberWarning,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaybookMetric({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11.sp, color: color),
            SizedBox(width: 3.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5.sp,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDaybookFilterChips() {
    final transactions = controller.transactions;
    final salesCount = transactions
        .where((t) => t.type == TransactionType.sale)
        .length;
    final purchaseCount = transactions
        .where((t) => t.type == TransactionType.purchase)
        .length;
    final inCount = transactions
        .where((t) => t.type == TransactionType.paymentIn)
        .length;
    final outCount = transactions
        .where((t) => t.type == TransactionType.paymentOut)
        .length;

    return SizedBox(
      height: 32.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        physics: const BouncingScrollPhysics(),
        children: [
          _daybookFilterChip(null, 'All (${transactions.length})'),
          _daybookFilterChip(TransactionType.sale, 'Rx Sales ($salesCount)'),
          _daybookFilterChip(
            TransactionType.purchase,
            'Inward ($purchaseCount)',
          ),
          _daybookFilterChip(TransactionType.paymentIn, 'Receipts ($inCount)'),
          _daybookFilterChip(TransactionType.paymentOut, 'Payouts ($outCount)'),
        ],
      ),
    );
  }

  Widget _daybookFilterChip(TransactionType? type, String label) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filterType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(right: 6.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryEmerald.withValues(alpha: 0.15)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryEmerald
                : AppColors.borderSubtle,
            width: isSelected ? 1.2.w : 1.w,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? AppColors.primaryEmerald
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaybookList() {
    final filteredTransactions = controller.transactions.where((tx) {
      final matchesType = _filterType == null || tx.type == _filterType;
      final matchesSearch =
          _searchQuery.isEmpty ||
          tx.partyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.invoiceNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.notes.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    }).toList();

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  color: AppColors.clinicalCyan.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.clinicalCyan.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 28.sp,
                  color: AppColors.clinicalCyan,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'No Daybook Records',
                style: AppTypography.h3.copyWith(fontSize: 16.sp),
              ),
              SizedBox(height: 6.h),
              Text(
                'Counter sales and stock purchases will automatically record in today\'s daybook register.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        18.w,
        4.h,
        18.w,
        80.h + MediaQuery.of(context).padding.bottom,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filteredTransactions.length,
      separatorBuilder: (_, _) => SizedBox(height: 7.h),
      itemBuilder: (ctx, index) =>
          _buildVoucherCard(filteredTransactions[index]),
    );
  }

  Widget _buildVoucherCard(TransactionModel tx) {
    final isInflow = tx.isInflow;
    final isCash = tx.paymentMode == PaymentMode.cash;

    Color typeColor = AppColors.primaryEmerald;
    IconData typeIcon = Icons.point_of_sale_rounded;
    String typeLabel = 'RX SALE';
    if (tx.type == TransactionType.purchase) {
      typeColor = AppColors.primaryBlue;
      typeIcon = Icons.local_shipping_outlined;
      typeLabel = 'STOCK INWARD';
    } else if (tx.type == TransactionType.paymentIn) {
      typeColor = AppColors.creditGreen;
      typeIcon = Icons.south_west_rounded;
      typeLabel = 'PAYMENT IN';
    } else if (tx.type == TransactionType.paymentOut) {
      typeColor = AppColors.debitRose;
      typeIcon = Icons.north_east_rounded;
      typeLabel = 'PAYMENT OUT';
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        BillPreviewModal.show(
          context,
          transaction: tx,
          shop: widget.activeShop,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4.r,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. Sleek Squircle Icon Badge
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: typeColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Icon(typeIcon, color: typeColor, size: 18.sp),
              ),
            ),
            SizedBox(width: 10.w),

            // 2. Middle Content (Party, Invoice No, Time)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.partyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 1.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.w800,
                            color: typeColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          tx.invoiceNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10.sp,
                        ),
                      ),
                      Text(
                        Formatters.formatTime(tx.date),
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // 3. Trailing Amount & Payment Mode
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isInflow ? "+" : "-"} ${Formatters.formatCurrency(tx.amount)}',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: isInflow
                        ? AppColors.creditGreen
                        : AppColors.debitRose,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: tx.paymentMode == PaymentMode.credit
                            ? AppColors.debitRose.withValues(alpha: 0.12)
                            : (isCash
                                  ? AppColors.cashGold.withValues(alpha: 0.12)
                                  : AppColors.clinicalCyan.withValues(
                                      alpha: 0.12,
                                    )),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        tx.paymentMode == PaymentMode.credit
                            ? 'UDHAR'
                            : (isCash ? 'CASH' : 'UPI/BANK'),
                        style: TextStyle(
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w800,
                          color: tx.paymentMode == PaymentMode.credit
                              ? AppColors.debitRose
                              : (isCash
                                    ? AppColors.cashGold
                                    : AppColors.clinicalCyan),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.receipt_outlined,
                      size: 14.sp,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
