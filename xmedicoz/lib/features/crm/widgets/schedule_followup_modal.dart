import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_app/core/widgets/searchable_dropdown.dart';

import '../../../core/models/master_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_calendar_picker.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../../inventory/controllers/master_data_controller.dart';
import '../controllers/crm_controller.dart';

class ScheduleFollowupModal extends StatefulWidget {
  final CustomerModel? initialCustomer;

  const ScheduleFollowupModal({super.key, this.initialCustomer});

  @override
  State<ScheduleFollowupModal> createState() => _ScheduleFollowupModalState();
}

class _ScheduleFollowupModalState extends State<ScheduleFollowupModal> {
  final _formKey = GlobalKey<FormState>();
  final CrmController crmController = Get.find<CrmController>();
  final MasterDataController masterController =
      Get.find<MasterDataController>();

  CustomerModel? _selectedCustomer;
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime _followUpDate = DateTime.now().add(const Duration(days: 3));

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.initialCustomer;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await UniqueCalendarPicker.show(
      context,
      initialDate: _followUpDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      title: 'Schedule Follow-up',
      subtitle: 'Select date for patient callback',
    );
    if (picked != null) {
      setState(() {
        _followUpDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      UniqueSnackbar.showWarning(context, message: 'Please select a customer');
      return;
    }

    final success = await crmController.scheduleFollowUp(
      customerId: _selectedCustomer!.id,
      followUpDate: DateFormat('yyyy-MM-dd').format(_followUpDate),
      notes: _notesCtrl.text.trim(),
    );

    if (success) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.88,
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 48.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.phone_callback_rounded,
                    color: AppColors.accentTeal,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule Patient Follow-up',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track patient health callbacks and inquiries',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.borderSubtle),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 24.h,
                  ),
                  children: [
                    // Customer Selection
                    Text(
                      'Customer / Patient',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  SizedBox(height: 6.h),
                  if (widget.initialCustomer != null)
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: AppDecorations.cardDecoration,
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: AppColors.accentTeal,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              '${widget.initialCustomer!.name} (${widget.initialCustomer!.phone ?? "No phone"})',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Obx(() {
                      final customers = masterController.customerChoices;
                      return SearchableDropdown<CustomerModel>(
                        value: _selectedCustomer,
                        items: customers,
                        itemName: 'customer',
                        itemPlural: 'customers',
                        itemIcon: Icons.person_outline_rounded,
                        label: (c) => c.mobile.isNotEmpty
                            ? '${c.name} • ${c.mobile}'
                            : c.name,
                        loadItems: masterController.loadCustomerChoices,
                        decoration: AppDecorations.inputDecoration(
                          hintText: 'Search & select registered patient...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_search_rounded,
                            color: AppColors.primaryEmerald,
                            size: 19,
                          ),
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCustomer = val;
                            });
                          }
                        },
                        validator: (v) =>
                            v == null ? 'Customer is required' : null,
                      );
                    }),
                  SizedBox(height: 16.h),

                  // Follow-up Date Header & Quick Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Follow-up Date',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(6.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 14.sp,
                                color: AppColors.accentTeal,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                DateFormat('dd MMM yyyy').format(_followUpDate),
                                style: AppTypography.bodySmall.copyWith(
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
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      _buildDateChip(
                        label: 'In 3 Days',
                        isSelected: _isSameDay(_followUpDate, DateTime.now().add(const Duration(days: 3))),
                        onTap: () => setState(() => _followUpDate = DateTime.now().add(const Duration(days: 3))),
                      ),
                      SizedBox(width: 6.w),
                      _buildDateChip(
                        label: 'In 5 Days',
                        isSelected: _isSameDay(_followUpDate, DateTime.now().add(const Duration(days: 5))),
                        onTap: () => setState(() => _followUpDate = DateTime.now().add(const Duration(days: 5))),
                      ),
                      SizedBox(width: 6.w),
                      _buildDateChip(
                        label: 'In 1 Week',
                        isSelected: _isSameDay(_followUpDate, DateTime.now().add(const Duration(days: 7))),
                        onTap: () => setState(() => _followUpDate = DateTime.now().add(const Duration(days: 7))),
                      ),
                      SizedBox(width: 6.w),
                      _buildDateChip(
                        label: 'In 2 Wks',
                        isSelected: _isSameDay(_followUpDate, DateTime.now().add(const Duration(days: 14))),
                        onTap: () => setState(() => _followUpDate = DateTime.now().add(const Duration(days: 14))),
                      ),
                      SizedBox(width: 6.w),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '📅',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Reason & Notes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Callback Purpose / Clinical Note',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_notesCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _notesCtrl.clear()),
                          child: Text(
                            'Clear',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.debitRose,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  // Quick Purpose Pill Tags
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: [
                      _buildPurposeTag('Fever & symptom check'),
                      _buildPurposeTag('BP & Sugar monitor'),
                      _buildPurposeTag('Tolerance & Side effects'),
                      _buildPurposeTag('Refill confirmation'),
                      _buildPurposeTag('Lab report follow-up'),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Call patient to verify fever reduction or select a quick tag above',
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      contentPadding: EdgeInsets.all(12.r),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppColors.borderLight,
                        ),
                      ),
                    ),
                    validator: (v) {
                      // Non-blocking: if empty, default will be populated in submit
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),

                  // Submit Button
                  Obx(() {
                    return AppButton(
                        title:
                            'Confirm Follow-up (${DateFormat('dd MMM').format(_followUpDate)})',
                        icon: Icons.check_circle_outline_rounded,
                        isLoading: crmController.isSubmitting.value,
                        onPressed: () {
                          if (_notesCtrl.text.trim().isEmpty) {
                            _notesCtrl.text =
                                'Routine patient wellness callback';
                          }
                          _handleSubmit();
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentTeal.withValues(alpha: 0.15)
                : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? AppColors.accentTeal : AppColors.borderLight,
              width: isSelected ? 1.2.w : 1.w,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isSelected ? AppColors.accentTeal : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurposeTag(String text) {
    final isSelected = _notesCtrl.text.contains(text);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _notesCtrl.text = _notesCtrl.text.replaceAll(text, '').trim();
          } else {
            if (_notesCtrl.text.isEmpty) {
              _notesCtrl.text = text;
            } else {
              _notesCtrl.text = '${_notesCtrl.text}, $text';
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentTeal.withValues(alpha: 0.12)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isSelected
                ? AppColors.accentTeal.withValues(alpha: 0.5)
                : AppColors.borderLight,
          ),
        ),
        child: Text(
          '+ $text',
          style: TextStyle(
            fontSize: 10.sp,
            color: isSelected ? AppColors.accentTeal : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
