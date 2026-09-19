import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_app/core/widgets/app_button.dart';

import '../../core/models/crm_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'controllers/crm_controller.dart';
import '../../core/widgets/unique_3d_refresh_indicator.dart';
import 'widgets/create_refill_modal.dart';
import 'widgets/customer_medical_history_sheet.dart';
import 'widgets/schedule_followup_modal.dart';

class CrmHubScreen extends StatefulWidget {
  const CrmHubScreen({super.key});

  @override
  State<CrmHubScreen> createState() => _CrmHubScreenState();
}

class _CrmHubScreenState extends State<CrmHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CrmController crmController = Get.find<CrmController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    crmController.loadCrmDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openHistory(String customerId, String customerName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerMedicalHistorySheet(
        customerId: customerId,
        customerName: customerName,
      ),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text('New CRM Schedule', style: AppTypography.h3),
            SizedBox(height: 16.h),
            AppButton(
              title: 'Schedule Chronic Refill',
              icon: Icons.autorenew,
              onPressed: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  enableDrag: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CreateRefillModal(),
                );
              },
            ),
            SizedBox(height: 12.h),
            AppButton(
              title: 'Schedule Patient Follow-up',
              icon: Icons.phone_callback,
              variant: ButtonVariant.outlined,
              onPressed: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  enableDrag: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const ScheduleFollowupModal(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient CRM & Refills',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Automated Refills & Clinical Callbacks',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => crmController.loadCrmDashboardData(),
            icon: const Icon(Icons.refresh, color: AppColors.primaryEmerald),
            tooltip: 'Refresh CRM',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryEmerald,
          labelColor: AppColors.primaryEmerald,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          tabs: [
            Obx(
              () =>
                  Tab(text: 'Due Refills (${crmController.dueRefills.length})'),
            ),
            Obx(
              () => Tab(
                text: 'Follow-ups (${crmController.pendingFollowUpsCount})',
              ),
            ),
            const Tab(text: 'Audit Logs'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top KPI Summary Banner
          _buildKpiSummaryBar(),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDueRefillsTab(),
                _buildFollowUpsTab(),
                _buildNotificationLogsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AppFloatingButton(
        label: 'Create Schedule',
        icon: Icons.add_circle_outline,
        onPressed: _showAddMenu,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildKpiSummaryBar() {
    return Obx(() {
      final overdue = crmController.overdueCount;
      final upcoming = crmController.upcomingDueCount;
      final callbacks = crmController.pendingFollowUpsCount;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        margin: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildMiniKpi(
                label: 'Overdue',
                value: '$overdue',
                color: overdue > 0 ? Colors.redAccent : AppColors.textSecondary,
              ),
            ),
            Container(width: 1, height: 28.h, color: AppColors.borderLight),
            Expanded(
              child: _buildMiniKpi(
                label: 'Due in 7 Days',
                value: '$upcoming',
                color: AppColors.primaryEmerald,
              ),
            ),
            Container(width: 1, height: 28.h, color: AppColors.borderLight),
            Expanded(
              child: _buildMiniKpi(
                label: 'Callbacks',
                value: '$callbacks',
                color: AppColors.accentTeal,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMiniKpi({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: Due & Overdue Refills
  // --------------------------------------------------------------------------
  Widget _buildDueRefillsTab() {
    return Obx(() {
      if (crmController.isLoadingDueRefills.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryEmerald),
        );
      }

      final items = crmController.dueRefills;
      if (items.isEmpty) {
        return Unique3DRefreshIndicator(
          title: 'Syncing Due Refills...',
          primaryColor: AppColors.primaryEmerald,
          secondaryColor: AppColors.clinicalCyan,
          onRefresh: () => crmController.fetchDueRefills(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 80.h),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 54.sp,
                      color: AppColors.primaryEmerald,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No Pending Refills',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'All chronic patients are currently stocked up.',
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

      return Unique3DRefreshIndicator(
        title: 'Syncing Due Refills...',
        primaryColor: AppColors.primaryEmerald,
        secondaryColor: AppColors.clinicalCyan,
        onRefresh: () => crmController.fetchDueRefills(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final alert = items[index];
            return _buildRefillAlertCard(alert);
          },
        ),
      );
    });
  }

  Widget _buildRefillAlertCard(DueRefillAlertModel alert) {
    final daysLeft = alert.daysLeft ?? 0;
    final isOverdue = alert.isOverdue;
    final customer = alert.customer;
    final medicine = alert.medicine;
    final customerName = customer?.name ?? 'Patient';
    final customerPhone = customer?.phone ?? 'No phone';
    final isOptedOut = customer?.notificationOptOut == true;
    final medicineName = medicine?.name ?? 'Prescribed Medicine';
    final dateStr = alert.expectedRefillDate != null
        ? DateFormat('dd MMM yyyy').format(alert.expectedRefillDate!)
        : 'Auto-computed';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isOverdue
              ? Colors.redAccent.withValues(alpha: 0.5)
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _openHistory(alert.customerId, customerName),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14.r,
                      backgroundColor: AppColors.primaryEmerald.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        customerName.isNotEmpty
                            ? customerName[0].toUpperCase()
                            : 'P',
                        style: TextStyle(
                          color: AppColors.primaryEmerald,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        Text(
                          customerPhone,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  isOverdue ? '${-daysLeft}d Overdue' : 'Due in $daysLeft d',
                  style: TextStyle(
                    color: isOverdue ? Colors.redAccent : Colors.amber.shade300,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: AppColors.borderLight, height: 16.h),

          // Medicine & Dosage Details
          Row(
            children: [
              Icon(
                Icons.medication,
                size: 16.sp,
                color: AppColors.primaryEmerald,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  medicineName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Dosage: ${alert.dailyDosage}/day',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expected Date: $dateStr',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
              Text(
                'Supply: ${alert.daysSupply} days',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // 1-Tap Trigger WhatsApp Reminder Button
          Row(
            children: [
              Expanded(
                child: AppButton(
                  title: isOptedOut
                      ? 'Customer Opted Out'
                      : 'Send WhatsApp Reminder',
                  icon: Icons.send_rounded,
                  variant: ButtonVariant.success,
                  onPressed: isOptedOut
                      ? null
                      : () => crmController.triggerReminder(
                          alert.id,
                          channel: 'WHATSAPP',
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: Follow-Ups
  // --------------------------------------------------------------------------
  Widget _buildFollowUpsTab() {
    return Obx(() {
      if (crmController.isLoadingFollowUps.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accentTeal),
        );
      }

      final items = crmController.followUps;
      if (items.isEmpty) {
        return Unique3DRefreshIndicator(
          title: 'Syncing Patient Follow-ups...',
          primaryColor: AppColors.accentTeal,
          secondaryColor: AppColors.primaryEmerald,
          onRefresh: () => crmController.fetchFollowUps(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 80.h),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_callback_rounded,
                      size: 54.sp,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No Follow-ups Logged',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Schedule customer callbacks after dispensing critical medicines.',
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

      return Unique3DRefreshIndicator(
        title: 'Syncing Patient Follow-ups...',
        primaryColor: AppColors.accentTeal,
        secondaryColor: AppColors.primaryEmerald,
        onRefresh: () => crmController.fetchFollowUps(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final f = items[index];
            return _buildFollowUpCard(f);
          },
        ),
      );
    });
  }

  Widget _buildFollowUpCard(FollowUpModel f) {
    final isPending = f.status == 'PENDING';
    final dateFormatted = f.followUpDate != null
        ? DateFormat('dd MMM yyyy').format(f.followUpDate!)
        : 'N/A';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                f.customer != null ? f.customer!.name : 'Patient Call',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.blue.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  f.status,
                  style: TextStyle(
                    color: isPending
                        ? Colors.blue.shade300
                        : Colors.green.shade300,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (f.customer?.phone != null) ...[
            SizedBox(height: 2.h),
            Text(
              f.customer!.phone!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14.sp,
                color: AppColors.accentTeal,
              ),
              SizedBox(width: 6.w),
              Text(
                'Follow-up Date: $dateFormatted',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.accentTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            f.notes ?? '',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (isPending) ...[
            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () =>
                    crmController.resolveFollowUp(f.id, status: 'COMPLETED'),
                icon: const Icon(
                  Icons.check,
                  size: 16,
                  color: AppColors.primaryEmerald,
                ),
                label: const Text(
                  'Mark Done',
                  style: TextStyle(color: AppColors.primaryEmerald),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryEmerald),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: Notification Audit Logs
  // --------------------------------------------------------------------------
  Widget _buildNotificationLogsTab() {
    return Obx(() {
      if (crmController.isLoadingNotifications.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryEmerald),
        );
      }

      final items = crmController.notificationLogs;
      if (items.isEmpty) {
        return Unique3DRefreshIndicator(
          title: 'Syncing Communication Logs...',
          primaryColor: AppColors.primaryEmerald,
          secondaryColor: AppColors.clinicalCyan,
          onRefresh: () => crmController.fetchNotificationLogs(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 80.h),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 54.sp,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No Notifications Dispatched',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Dispatched WhatsApp & SMS logs will be audited here.',
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

      return Unique3DRefreshIndicator(
        title: 'Syncing Communication Logs...',
        primaryColor: AppColors.primaryEmerald,
        secondaryColor: AppColors.clinicalCyan,
        onRefresh: () => crmController.fetchNotificationLogs(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final log = items[index];
            return _buildNotificationLogCard(log);
          },
        ),
      );
    });
  }

  Widget _buildNotificationLogCard(NotificationLogModel log) {
    final isSuccess = log.status == 'SENT';
    final sentAtStr = log.sentAt != null
        ? DateFormat('dd MMM, hh:mm a').format(log.sentAt!)
        : 'Pending';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderLight),
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
                    log.channel == 'WHATSAPP'
                        ? Icons.chat_rounded
                        : Icons.sms_rounded,
                    size: 16.sp,
                    color: log.channel == 'WHATSAPP'
                        ? const Color(0xFF25D366)
                        : Colors.blueAccent,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    log.recipient,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  log.status,
                  style: TextStyle(
                    color: isSuccess
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            log.message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              sentAtStr,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
