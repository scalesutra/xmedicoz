import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:ledger_app/core/theme/app_decorations.dart';
import '../../core/models/master_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/unique_snackbar.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../crm/widgets/customer_medical_history_sheet.dart';
import '../accounting/widgets/customer_debt_payment_modal.dart';
import '../purchases/controllers/purchases_controller.dart';
import '../purchases/widgets/supplier_payment_modal.dart';
import '../sales/controllers/sales_controller.dart';
import '../inventory/controllers/master_data_controller.dart';

class PartyDetailSheet extends StatelessWidget {
  final CustomerModel? customer;
  final SupplierModel? supplier;
  final VoidCallback? onPaymentSettled;

  const PartyDetailSheet({
    super.key,
    this.customer,
    this.supplier,
    this.onPaymentSettled,
  });

  static void showCustomer(
    BuildContext context, {
    required CustomerModel customer,
    VoidCallback? onPaymentSettled,
  }) {
    AppBottomSheet.show(
      context: context,
      builder: (context) => PartyDetailSheet(
        customer: customer,
        onPaymentSettled: onPaymentSettled,
      ),
    );
  }

  static void showSupplier(
    BuildContext context, {
    required SupplierModel supplier,
    VoidCallback? onPaymentSettled,
  }) {
    AppBottomSheet.show(
      context: context,
      builder: (context) => PartyDetailSheet(
        supplier: supplier,
        onPaymentSettled: onPaymentSettled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = customer != null;
    final name = isCustomer ? customer!.name : supplier!.name;
    final mobile = isCustomer ? customer!.mobile : supplier!.mobile;
    final email = isCustomer ? customer!.email : supplier!.email;
    final address = isCustomer ? customer!.address : supplier!.address;
    // Use live instance from MasterDataController if available
    CustomerModel? liveCustomer = customer;
    SupplierModel? liveSupplier = supplier;
    if (Get.isRegistered<MasterDataController>()) {
      final master = Get.find<MasterDataController>();
      if (isCustomer && customer != null) {
        liveCustomer = master.customers.firstWhereOrNull((c) => c.id == customer!.id) ?? customer;
      } else if (!isCustomer && supplier != null) {
        liveSupplier = master.suppliers.firstWhereOrNull((s) => s.id == supplier!.id) ?? supplier;
      }
    }

    double effectiveBalance = isCustomer
        ? (liveCustomer!.currentBalance > 0 ? liveCustomer.currentBalance : liveCustomer.outstandingBalance)
        : liveSupplier!.outstandingBalance;

    if (isCustomer && effectiveBalance <= 0 && Get.isRegistered<SalesController>()) {
      final sales = Get.find<SalesController>().salesInvoices;
      final unpaid = sales.where((s) =>
          (s.customerId == liveCustomer!.id || (liveCustomer.mobile.isNotEmpty && s.customerMobile == liveCustomer.mobile)) &&
          (s.isCreditSale || s.isUnpaid)).fold(0.0, (sum, s) => sum + (s.balanceAmount > 0 ? s.balanceAmount : s.totalAmount));
      if (unpaid > 0) effectiveBalance = unpaid;
    } else if (!isCustomer && effectiveBalance <= 0 && Get.isRegistered<PurchasesController>()) {
      final purchases = Get.find<PurchasesController>().purchases;
      final unpaid = purchases
          .where((p) => p.supplierId == liveSupplier!.id && (p.isUnpaid || p.isPartiallyPaid))
          .fold(0.0, (sum, p) => sum + (p.balanceAmount > 0 ? p.balanceAmount : p.totalAmount));
      if (unpaid > 0) effectiveBalance = unpaid;
    }

    final balance = effectiveBalance;

    final statusColor = isCustomer
        ? AppColors.creditGreen
        : AppColors.debitRose;
    final hasBalance = balance > 0;

    return AppBottomSheetWrapper(
      showDragHandle: true,
      maxHeightFactor: 0.90,
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 24.h),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Futuristic Cyber Identity Header
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.12),
                    AppColors.bgCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.30),
                  width: 1.w,
                ),
              ),
              child: Row(
                children: [
                  // 3D Avatar Squircle
                  Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor,
                          statusColor.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.35),
                          blurRadius: 10.r,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isCustomer
                            ? Icons.person_rounded
                            : Icons.local_shipping_rounded,
                        color: AppColors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: AppTypography.h3.copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.4),
                                  width: 0.8.w,
                                ),
                              ),
                              child: Text(
                                isCustomer
                                    ? customer!.customerType
                                    : 'SUPPLIER',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.sp,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_iphone_rounded,
                              size: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              mobile,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Clipboard.setData(ClipboardData(text: mobile));
                                UniqueSnackbar.showSuccess(
                                  context,
                                  title: 'Copied',
                                  message: '$mobile copied.',
                                );
                              },
                              child: Icon(
                                Icons.copy_rounded,
                                size: 12.sp,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // 2. Financial Radar Cockpit Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.15),
                    AppColors.bgSurface,
                    AppColors.bgCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.35),
                  width: 1.2.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.08),
                    blurRadius: 12.r,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCustomer
                            ? 'Outstanding Udhar Balance'
                            : 'Supplier Payables (Khaata)',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: hasBalance
                              ? statusColor.withValues(alpha: 0.18)
                              : AppColors.bgInput,
                          borderRadius: BorderRadius.circular(
                            AppDecorations.radiusPill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5.r,
                              height: 5.r,
                              decoration: BoxDecoration(
                                color: hasBalance
                                    ? statusColor
                                    : AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              hasBalance
                                  ? (isCustomer ? 'DUE NOW' : 'PENDING')
                                  : 'SETTLED',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w900,
                                color: hasBalance
                                    ? statusColor
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        Formatters.formatCurrency(balance),
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        isCustomer ? 'Receivable' : 'Payable to vendor',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // 3. Compact Details & Compliance Matrix
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _compactRow(
                    icon: Icons.phone_outlined,
                    label: 'Contact',
                    value: mobile,
                    canCopy: true,
                    context: context,
                  ),
                  if (email != null && email.isNotEmpty) ...[
                    Divider(height: 14.h, color: AppColors.borderLight),
                    _compactRow(
                      icon: Icons.alternate_email_rounded,
                      label: 'Email',
                      value: email,
                      canCopy: true,
                      context: context,
                    ),
                  ],
                  if (address != null && address.isNotEmpty) ...[
                    Divider(height: 14.h, color: AppColors.borderLight),
                    _compactRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: address,
                      canCopy: true,
                      context: context,
                    ),
                  ],
                  if (!isCustomer) ...[
                    if (supplier!.contactPerson != null &&
                        supplier!.contactPerson!.isNotEmpty) ...[
                      Divider(height: 14.h, color: AppColors.borderLight),
                      _compactRow(
                        icon: Icons.badge_outlined,
                        label: 'Representative',
                        value: supplier!.contactPerson!,
                        canCopy: false,
                        context: context,
                      ),
                    ],
                    if (supplier!.gstin != null &&
                        supplier!.gstin!.isNotEmpty) ...[
                      Divider(height: 14.h, color: AppColors.borderLight),
                      _compactRow(
                        icon: Icons.verified_user_outlined,
                        label: 'GSTIN',
                        value: supplier!.gstin!,
                        canCopy: true,
                        context: context,
                      ),
                    ],
                    if (supplier!.dlNumber != null &&
                        supplier!.dlNumber!.isNotEmpty) ...[
                      Divider(height: 14.h, color: AppColors.borderLight),
                      _compactRow(
                        icon: Icons.health_and_safety_outlined,
                        label: 'Drug License',
                        value: supplier!.dlNumber!,
                        canCopy: true,
                        context: context,
                      ),
                    ],
                    Divider(height: 14.h, color: AppColors.borderLight),
                    _compactRow(
                      icon: Icons.event_available_rounded,
                      label: 'Payment Terms',
                      value: '${supplier!.paymentTermsDays} Days Credit',
                      canCopy: false,
                      context: context,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // 4. Instant Action Cockpit Dock
            if (isCustomer) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    CustomerDebtPaymentModal.show(
                      context,
                      customer: customer!,
                      initialDebt: balance,
                      onSuccess: () {
                        Navigator.of(context).pop();
                        onPaymentSettled?.call();
                      },
                    );
                  },
                  icon: Icon(
                    Icons.payments_rounded,
                    size: 18.sp,
                    color: Colors.white,
                  ),
                  label: Text(
                    balance > 0
                        ? 'Receive Payment / Udhar Jama (Due: ₹${balance.toStringAsFixed(0)})'
                        : 'Receive Payment / Settle Khata',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    elevation: 4,
                    shadowColor: AppColors.primaryEmerald.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    CustomerMedicalHistorySheet.show(
                      context,
                      customerId: customer!.id,
                      customerName: customer!.name,
                      customer: customer,
                    );
                  },
                  icon: Icon(
                    Icons.medication_liquid_rounded,
                    size: 17.sp,
                    color: AppColors.primaryCyan,
                  ),
                  label: Text(
                    'Patient Rx & Chronic Refill History',
                    style: TextStyle(
                      color: AppColors.primaryCyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5.sp,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.primaryCyan.withValues(alpha: 0.4),
                      width: 1.w,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
            if (!isCustomer && supplier != null && balance > 0) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleSupplierPayment(context),
                  icon: Icon(
                    Icons.payments_rounded,
                    size: 18.sp,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Pay Supplier / Settle Bill (₹${balance.toStringAsFixed(0)})',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.debitRose,
                    elevation: 4,
                    shadowColor: AppColors.debitRose.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],

            // Close & Dismiss Button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                title: 'Done',
                icon: Icons.check_rounded,
                variant: ButtonVariant.outlined,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSupplierPayment(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final purchasesCtrl = Get.isRegistered<PurchasesController>()
        ? Get.find<PurchasesController>()
        : Get.put(PurchasesController());

    if (purchasesCtrl.purchases.isEmpty) {
      await purchasesCtrl.fetchPurchases();
    }

    final unpaidInvoices = purchasesCtrl.purchases
        .where((p) => p.supplierId == supplier!.id && (p.isUnpaid || p.isPartiallyPaid))
        .toList();

    if (!context.mounted) return;

    if (unpaidInvoices.isNotEmpty) {
      Navigator.of(context).pop();
      SupplierPaymentModal.show(context, unpaidInvoices.first);
    } else {
      final anyInvoices = purchasesCtrl.purchases
          .where((p) => p.supplierId == supplier!.id)
          .toList();
      if (anyInvoices.isNotEmpty) {
        Navigator.of(context).pop();
        SupplierPaymentModal.show(context, anyInvoices.first);
      } else {
        UniqueSnackbar.showWarning(
          context,
          title: 'Stockist Purchase Bill Required',
          message:
              'No active purchase bill found for ${supplier!.name}. You can also record from Vouchers -> Stockist Inward.',
        );
      }
    }
  }

  Widget _compactRow({
    required IconData icon,
    required String label,
    required String value,
    required bool canCopy,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: AppColors.textMuted),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (canCopy) ...[
          SizedBox(width: 6.w),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Clipboard.setData(ClipboardData(text: value));
              UniqueSnackbar.showSuccess(
                context,
                title: 'Copied',
                message: '$value copied.',
              );
            },
            child: Icon(
              Icons.copy_rounded,
              size: 12.sp,
              color: AppColors.primaryEmerald,
            ),
          ),
        ],
      ],
    );
  }
}
