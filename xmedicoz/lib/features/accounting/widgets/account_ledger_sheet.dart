import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_app/core/theme/app_decorations.dart';

import '../../../core/models/accounting_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../controllers/accounting_controller.dart';

class AccountLedgerSheet extends StatefulWidget {
  final String? initialAccountId;

  const AccountLedgerSheet({super.key, this.initialAccountId});

  static void show(BuildContext context, {String? initialAccountId}) {
    AppBottomSheet.show(
      context: context,
      builder: (_) => AccountLedgerSheet(initialAccountId: initialAccountId),
    );
  }

  @override
  State<AccountLedgerSheet> createState() => _AccountLedgerSheetState();
}

class _AccountLedgerSheetState extends State<AccountLedgerSheet> {
  final AccountingController controller = Get.find<AccountingController>();

  String? _selectedAccountId;
  bool _isLoading = false;
  GeneralLedgerModel? _ledgerData;
  String _dateFilter = 'ALL'; // ALL, TODAY, THIS_MONTH

  @override
  void initState() {
    super.initState();
    _initSelectedAccount();
  }

  void _initSelectedAccount() {
    if (widget.initialAccountId != null &&
        widget.initialAccountId!.isNotEmpty) {
      _selectedAccountId = widget.initialAccountId;
    } else {
      final cashAcc = controller.accounts.firstWhereOrNull(
        (a) => a.code == '1010',
      );
      _selectedAccountId =
          cashAcc?.id ??
          (controller.accounts.isNotEmpty
              ? controller.accounts.first.id
              : null);
    }
    if (_selectedAccountId != null) {
      _loadLedger();
    }
  }

  Future<void> _loadLedger() {
    if (_selectedAccountId == null) return Future.value();
    setState(() => _isLoading = true);

    DateTime? start;
    DateTime? end;
    final now = DateTime.now();

    if (_dateFilter == 'TODAY') {
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_dateFilter == 'THIS_MONTH') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    final sStr = start != null ? DateFormat('yyyy-MM-dd').format(start) : null;
    final eStr = end != null ? DateFormat('yyyy-MM-dd').format(end) : null;

    return controller
        .fetchGeneralLedger(_selectedAccountId!, startDate: sStr, endDate: eStr)
        .then((data) {
          if (mounted) {
            setState(() {
              _ledgerData = data;
              _isLoading = false;
            });
          }
        })
        .catchError((_) {
          if (mounted) setState(() => _isLoading = false);
        });
  }

  @override
  Widget build(BuildContext context) {
    final accList = controller.accounts;

    return AppBottomSheetWrapper(
      showDragHandle: true,
      maxHeightFactor: 0.92,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
      child: Column(
        children: [
          // 1. Futuristic Cockpit Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryCyan, AppColors.primaryBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryCyan.withValues(alpha: 0.35),
                          blurRadius: 8.r,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.white,
                        size: 18.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'General Ledger Cockpit',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Real-time Double-Entry Audit Trail',
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
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _loadLedger();
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
                    color: AppColors.primaryCyan,
                    size: 18.sp,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // 2. Account Selector Dropdown
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            height: 42.h,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedAccountId,
                dropdownColor: AppColors.bgSurface,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryCyan,
                  size: 20.sp,
                ),
                hint: Text(
                  'Select Account',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5.sp,
                  ),
                ),
                items: accList.map((acc) {
                  return DropdownMenuItem<String>(
                    value: acc.id,
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            acc.code,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryCyan,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            acc.name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(acc.currentBalance),
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: acc.currentBalance >= 0
                                ? AppColors.creditGreen
                                : AppColors.debitRose,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null && newId != _selectedAccountId) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedAccountId = newId);
                    _loadLedger();
                  }
                },
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // 3. Date Filter Chips
          Row(
            children: [
              _buildFilterChip('ALL', 'All Entries'),
              SizedBox(width: 6.w),
              _buildFilterChip('THIS_MONTH', 'This Month'),
              SizedBox(width: 6.w),
              _buildFilterChip('TODAY', 'Today'),
            ],
          ),

          SizedBox(height: 8.h),

          // 4. Content body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryCyan,
                    ),
                  )
                : _ledgerData == null
                ? Center(
                    child: Text(
                      'Select an account to view ledger statement',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.sp,
                      ),
                    ),
                  )
                : _buildLedgerView(_ledgerData!),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _dateFilter == key;
    return InkWell(
      onTap: () {
        if (_dateFilter != key) {
          HapticFeedback.selectionClick();
          setState(() => _dateFilter = key);
          _loadLedger();
        }
      },
      borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryCyan.withValues(alpha: 0.15)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          border: Border.all(
            color: isSelected ? AppColors.primaryCyan : AppColors.borderSubtle,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5.sp,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerView(GeneralLedgerModel data) {
    final txs = data.transactions;

    return Column(
      children: [
        // Slim Balance Header Banner
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryCyan.withValues(alpha: 0.12),
                AppColors.bgCard,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.primaryCyan.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.account.code} • ${data.account.type}',
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    data.account.name,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Closing Balance',
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    Formatters.formatCurrency(data.account.currentBalance),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: data.account.currentBalance >= 0
                          ? AppColors.creditGreen
                          : AppColors.debitRose,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Slim Column Legend Strip
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'DATE & TRANSACTION',
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'DEBIT / CREDIT',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'BALANCE',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Slim Transactions List
        Expanded(
          child: txs.isEmpty
              ? Center(
                  child: Text(
                    'No ledger entries found for this period',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5.sp,
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  itemCount: txs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 8.h,
                    color: AppColors.borderLight.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (ctx, idx) {
                    final tx = txs[idx];
                    final isDebit = tx.debit > 0;
                    final amt = isDebit ? tx.debit : tx.credit;
                    final dateStr = tx.date != null
                        ? DateFormat('dd MMM').format(tx.date!)
                        : '—';

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Details
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4.w,
                                        vertical: 1.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgInput,
                                        borderRadius: BorderRadius.circular(
                                          3.r,
                                        ),
                                      ),
                                      child: Text(
                                        tx.referenceType.isNotEmpty
                                            ? tx.referenceType
                                            : 'JOURNAL',
                                        style: TextStyle(
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  tx.narration.isNotEmpty
                                      ? tx.narration
                                      : tx.entryNumber,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Dr / Cr
                          Expanded(
                            flex: 3,
                            child: Text(
                              isDebit
                                  ? '+₹${amt.toStringAsFixed(0)} Dr'
                                  : '-₹${amt.toStringAsFixed(0)} Cr',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                                color: isDebit
                                    ? AppColors.creditGreen
                                    : AppColors.debitRose,
                              ),
                            ),
                          ),
                          // Running balance
                          Expanded(
                            flex: 3,
                            child: Text(
                              Formatters.formatCurrency(tx.runningBalance),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w600,
                                color: tx.runningBalance >= 0
                                    ? AppColors.textPrimary
                                    : AppColors.debitRose,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
