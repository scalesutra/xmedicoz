import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_app/features/inventory/controllers/master_data_controller.dart';

import '../../../core/models/crm_models.dart';
import '../../../core/models/master_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../sales/controllers/sales_controller.dart';
import '../controllers/crm_controller.dart';
import 'create_refill_modal.dart';
import 'schedule_followup_modal.dart';

class CustomerMedicalHistorySheet extends StatefulWidget {
  final String customerId;
  final String? customerName;
  final CustomerModel? customer;

  const CustomerMedicalHistorySheet({
    super.key,
    required this.customerId,
    this.customerName,
    this.customer,
  });

  static void show(
    BuildContext context, {
    required String customerId,
    String? customerName,
    CustomerModel? customer,
  }) {
    AppBottomSheet.show(
      context: context,
      builder: (_) => CustomerMedicalHistorySheet(
        customerId: customerId,
        customerName: customerName,
        customer: customer,
      ),
    );
  }

  @override
  State<CustomerMedicalHistorySheet> createState() =>
      _CustomerMedicalHistorySheetState();
}

class _CustomerMedicalHistorySheetState
    extends State<CustomerMedicalHistorySheet> {
  final CrmController crmController = Get.find<CrmController>();

  @override
  void initState() {
    super.initState();
    crmController.fetchCustomerHistory(widget.customerId);
  }

  void _openCreateRefill(
    CustomerModel customer, [
    FrequentlyPurchasedMedicineModel? med,
  ]) {
    HapticFeedback.selectionClick();
    MedicineModel? medicineModel;
    if (med != null && Get.isRegistered<MasterDataController>()) {
      final master = Get.find<MasterDataController>();
      medicineModel = master.medicines.firstWhereOrNull(
        (m) => m.id == med.medicineId,
      );
    }

    AppBottomSheet.show(
      context: context,
      builder: (_) => CreateRefillModal(
        initialCustomer: customer,
        initialMedicine: medicineModel,
      ),
    );
  }

  void _openScheduleFollowup(CustomerModel customer) {
    HapticFeedback.selectionClick();
    AppBottomSheet.show(
      context: context,
      builder: (_) => ScheduleFollowupModal(initialCustomer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetWrapper(
      showDragHandle: true,
      maxHeightFactor: 0.94,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Futuristic Clinical Header
          Row(
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryEmerald, AppColors.clinicalCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                      blurRadius: 10.r,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.medication_liquid_rounded,
                    color: AppColors.white,
                    size: 22.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customerName ?? 'Patient Clinical Dossier',
                      style: AppTypography.h3.copyWith(
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Container(
                          width: 5.r,
                          height: 5.r,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryEmerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Rx Repeat History & Dispensing Log',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  crmController.fetchCustomerHistory(widget.customerId);
                },
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primaryEmerald,
                    size: 18.sp,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // 2. Content Area
          Expanded(
            child: Obx(() {
              if (crmController.isLoadingHistory.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryEmerald,
                  ),
                );
              }

              var history = crmController.currentCustomerHistory.value;
              if (history == null) {
                // If backend history is not available yet, resolve from widget or MasterDataController
                CustomerModel? cust = widget.customer;
                if (cust == null && Get.isRegistered<MasterDataController>()) {
                  cust = Get.find<MasterDataController>()
                      .customers
                      .firstWhereOrNull((c) => c.id == widget.customerId);
                }

                if (cust != null) {
                  history = CustomerHistoryModel(
                    customer: cust,
                    stats: CustomerHistoryStatsModel(
                      totalInvoices: 0,
                      totalSpent: 0.0,
                      currentDebt: cust.currentBalance,
                    ),
                    frequentlyPurchasedMedicines: const [],
                    invoices: const [],
                  );
                }
              }

              if (history == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_off_outlined,
                        size: 44.sp,
                        color: AppColors.textTertiary,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Unable to load medical profile',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      ElevatedButton(
                        onPressed: () => crmController.fetchCustomerHistory(
                          widget.customerId,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryEmerald,
                        ),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              final customer = history.customer;
              final stats = history.stats;
              final frequentMeds = history.frequentlyPurchasedMedicines;
              final invoices = history.invoices;

              // Convert history.customer to CustomerModel for refill/followup modals
              final customerModel = CustomerModel(
                id: customer.id,
                name: customer.name,
                mobile: customer.phone ?? '',
                email: customer.email,
                address: customer.address,
                customerType: 'PATIENT',
                currentBalance: customer.outstandingBalance,
              );

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Quick Dossier Card
                    Container(
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
                          color: AppColors.primaryEmerald.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34.r,
                                height: 34.r,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryEmerald.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Center(
                                  child: Text(
                                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'P',
                                    style: TextStyle(
                                      color: AppColors.primaryEmerald,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      style: TextStyle(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      customer.phone ?? 'No phone registered',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (customer.notificationOptOut)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'DND OPT-OUT',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          SizedBox(height: 10.h),

                          // Quick Action Buttons: Refill & Follow-up
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openCreateRefill(customerModel),
                                  icon: Icon(Icons.autorenew_rounded, size: 15.sp, color: Colors.white),
                                  label: Text(
                                    'Setup Auto-Refill',
                                    style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryEmerald,
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openScheduleFollowup(customerModel),
                                  icon: Icon(Icons.phone_callback_rounded, size: 14.sp, color: AppColors.clinicalCyan),
                                  label: Text(
                                    'Log Callback',
                                    style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: AppColors.clinicalCyan),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.clinicalCyan.withValues(alpha: 0.5)),
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // 4-Grid Telemetry Matrix
                    Row(
                      children: [
                        Expanded(
                          child: _telemetryCard(
                            title: 'Total Invoices',
                            value: '${stats.totalInvoices}',
                            icon: Icons.receipt_long_rounded,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _telemetryCard(
                            title: 'Lifetime Spend',
                            value: Formatters.formatCurrency(stats.totalSpent, showDecimals: false),
                            icon: Icons.currency_rupee_rounded,
                            color: AppColors.creditGreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (_) {
                              double dueBalance = customer.outstandingBalance;
                              if (dueBalance <= 0 && Get.isRegistered<SalesController>()) {
                                final sales = Get.find<SalesController>().salesInvoices;
                                final unpaid = sales.where((s) =>
                                    (s.customerId == customer.id ||
                                        (customer.mobile.isNotEmpty && s.customerMobile == customer.mobile)) &&
                                    (s.isCreditSale || s.isUnpaid)).fold(0.0, (sum, s) => sum + (s.balanceAmount > 0 ? s.balanceAmount : s.totalAmount));
                                if (unpaid > 0) dueBalance = unpaid;
                              }
                              return _telemetryCard(
                                title: 'Ledger Due',
                                value: Formatters.formatCurrency(dueBalance, showDecimals: false),
                                icon: Icons.account_balance_wallet_rounded,
                                color: dueBalance > 0 ? AppColors.debitRose : AppColors.textMuted,
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _telemetryCard(
                            title: 'Last Visit',
                            value: stats.lastVisit != null
                                ? DateFormat('dd MMM yy').format(stats.lastVisit!)
                                : 'N/A',
                            icon: Icons.event_available_rounded,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // 3. Frequently Dispensed Chronic Rx
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'Frequently Dispensed Chronic Rx',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    if (frequentMeds.isEmpty)
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Center(
                          child: Text(
                            'No repeat medicine purchase history logged',
                            style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      ...frequentMeds.map(
                        (med) => _buildFrequentMedTile(customerModel, med),
                      ),

                    SizedBox(height: 16.h),

                    // 4. Past Invoices & Dispensing History
                    Row(
                      children: [
                        Icon(Icons.history_rounded, color: AppColors.clinicalCyan, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'Past Invoices & Dispensing History',
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    if (invoices.isEmpty)
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Center(
                          child: Text(
                            'No billing records found for this patient',
                            style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      ...invoices.map((inv) => _buildInvoiceTile(inv)),

                    SizedBox(height: 12.h),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _telemetryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(icon, size: 14.sp, color: color),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 9.5.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequentMedTile(
    CustomerModel customer,
    FrequentlyPurchasedMedicineModel med,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(Icons.medication_rounded, color: AppColors.primaryEmerald, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  med.name,
                  style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  '${med.totalQuantity} units • ${med.purchaseCount} repeat orders',
                  style: TextStyle(fontSize: 10.5.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _openCreateRefill(customer, med),
            borderRadius: BorderRadius.circular(6.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.35)),
              ),
              child: Text(
                '+ Refill',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTile(CustomerHistoryInvoiceModel inv) {
    final dateStr = inv.invoiceDate != null
        ? DateFormat('dd MMM yy').format(inv.invoiceDate!)
        : 'N/A';
    final isPaid = inv.paymentStatus == 'PAID';

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10.r),
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
                  Text(
                    inv.invoiceNumber,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.creditGreen.withValues(alpha: 0.15)
                          : AppColors.debitRose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      inv.paymentStatus,
                      style: TextStyle(
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? AppColors.creditGreen : AppColors.debitRose,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                Formatters.formatCurrency(inv.netAmount),
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryEmerald,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            dateStr,
            style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted),
          ),
          if (inv.items.isNotEmpty) ...[
            Divider(height: 10.h, color: AppColors.borderLight.withValues(alpha: 0.5)),
            ...inv.items.map(
              (item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.medicineName} (${item.batchNumber})',
                        style: TextStyle(fontSize: 10.5.sp, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${item.quantity}x • ${Formatters.formatCurrency(item.totalAmount)}',
                      style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
