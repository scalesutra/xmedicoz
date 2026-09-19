import 'package:ledger_app/core/widgets/app_bottom_sheet.dart';
import 'package:ledger_app/core/widgets/searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/master_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_calendar_picker.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../../inventory/controllers/master_data_controller.dart';
import '../controllers/crm_controller.dart';

class CreateRefillModal extends StatefulWidget {
  final CustomerModel? initialCustomer;
  final MedicineModel? initialMedicine;

  const CreateRefillModal({
    super.key,
    this.initialCustomer,
    this.initialMedicine,
  });

  @override
  State<CreateRefillModal> createState() => _CreateRefillModalState();
}

class _CreateRefillModalState extends State<CreateRefillModal> {
  final _formKey = GlobalKey<FormState>();
  final CrmController crmController = Get.find<CrmController>();
  final MasterDataController masterController =
      Get.find<MasterDataController>();

  CustomerModel? _selectedCustomer;
  MedicineModel? _selectedMedicine;

  final TextEditingController _dosageCtrl = TextEditingController(text: '1.0');
  final TextEditingController _daysSupplyCtrl = TextEditingController(
    text: '30',
  );
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime _lastPurchaseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.initialCustomer;
    _selectedMedicine = widget.initialMedicine;
  }

  @override
  void dispose() {
    _dosageCtrl.dispose();
    _daysSupplyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  DateTime? get _calculatedNextDate {
    final dosage = double.tryParse(_dosageCtrl.text.trim()) ?? 0;
    final days = int.tryParse(_daysSupplyCtrl.text.trim()) ?? 0;
    if (dosage <= 0 || days <= 0) return null;
    final totalDays = (days / dosage).round();
    return _lastPurchaseDate.add(Duration(days: totalDays));
  }

  Future<void> _pickDate() async {
    final picked = await UniqueCalendarPicker.show(
      context,
      initialDate: _lastPurchaseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      title: 'Last Purchase Date',
      subtitle: 'Select date to calculate next refill',
    );
    if (picked != null) {
      setState(() {
        _lastPurchaseDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      UniqueSnackbar.showWarning(context, message: 'Please select a customer');
      return;
    }
    if (_selectedMedicine == null) {
      UniqueSnackbar.showWarning(context, message: 'Please select a medicine');
      return;
    }

    final dosage = double.tryParse(_dosageCtrl.text.trim()) ?? 1.0;
    final days = int.tryParse(_daysSupplyCtrl.text.trim()) ?? 30;

    final success = await crmController.createRefillRule(
      customerId: _selectedCustomer!.id,
      medicineId: _selectedMedicine!.id,
      dailyDosage: dosage,
      daysSupply: days,
      lastPurchaseDate: DateFormat('yyyy-MM-dd').format(_lastPurchaseDate),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (success) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextDate = _calculatedNextDate;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.88,
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: AppKeyboardPadding(
          child: Form(
            key: _formKey,
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

                // Pinned Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.autorenew_rounded,
                        color: AppColors.primaryEmerald,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule Chronic Refill',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Automated refill reminder rules for repeat medicines',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Scrollable Body
                Expanded(
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                                color: AppColors.primaryEmerald,
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
                              hintText:
                                  'Search & select registered patient...',
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

                      // Medicine Selection
                      Text(
                        'Medicine',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      if (widget.initialMedicine != null)
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: AppDecorations.cardDecoration,
                          child: Row(
                            children: [
                              Icon(
                                Icons.medication,
                                color: AppColors.primaryEmerald,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  widget.initialMedicine!.name,
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
                          final meds = masterController.medicineChoices;
                          return SearchableDropdown<MedicineModel>(
                            value: _selectedMedicine,
                            items: meds,
                            itemName: 'medicine',
                            itemPlural: 'medicines',
                            itemIcon: Icons.medication_liquid_rounded,
                            label: (m) => m.name,
                            loadItems: masterController.loadMedicineChoices,
                            decoration: AppDecorations.inputDecoration(
                              hintText: 'Search & select medicine...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              prefixIcon: const Icon(
                                Icons.medication,
                                color: AppColors.primaryEmerald,
                                size: 19,
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedMedicine = val;
                                });
                              }
                            },
                            validator: (v) =>
                                v == null ? 'Medicine is required' : null,
                          );
                        }),
                      SizedBox(height: 16.h),

                      // Daily Dosage & Days Supply
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Dosage (units)',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                TextFormField(
                                  controller: _dosageCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 1.0',
                                    filled: true,
                                    fillColor: AppColors.bgSurface,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 10.h,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(
                                        color: AppColors.borderLight,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    final d = double.tryParse(v ?? '');
                                    if (d == null || d <= 0) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Days Supply',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                TextFormField(
                                  controller: _daysSupplyCtrl,
                                  keyboardType: TextInputType.number,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 30',
                                    filled: true,
                                    fillColor: AppColors.bgSurface,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 10.h,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                      borderSide: const BorderSide(
                                        color: AppColors.borderLight,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    final d = int.tryParse(v ?? '');
                                    if (d == null || d <= 0) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),

                      // Quick Presets: Dosage & Days Supply Chips
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: [
                          _buildPresetChip(
                            label: '1 / day (OD)',
                            isSelected:
                                _dosageCtrl.text.trim() == '1.0' ||
                                _dosageCtrl.text.trim() == '1',
                            onTap: () {
                              setState(() {
                                _dosageCtrl.text = '1.0';
                              });
                            },
                          ),
                          _buildPresetChip(
                            label: '2 / day (BD)',
                            isSelected:
                                _dosageCtrl.text.trim() == '2.0' ||
                                _dosageCtrl.text.trim() == '2',
                            onTap: () {
                              setState(() {
                                _dosageCtrl.text = '2.0';
                              });
                            },
                          ),
                          _buildPresetChip(
                            label: '3 / day (TDS)',
                            isSelected:
                                _dosageCtrl.text.trim() == '3.0' ||
                                _dosageCtrl.text.trim() == '3',
                            onTap: () {
                              setState(() {
                                _dosageCtrl.text = '3.0';
                              });
                            },
                          ),
                          _buildPresetChip(
                            label: '15 Days',
                            isSelected: _daysSupplyCtrl.text.trim() == '15',
                            onTap: () {
                              setState(() {
                                _daysSupplyCtrl.text = '15';
                              });
                            },
                          ),
                          _buildPresetChip(
                            label: '30 Days (1M)',
                            isSelected: _daysSupplyCtrl.text.trim() == '30',
                            onTap: () {
                              setState(() {
                                _daysSupplyCtrl.text = '30';
                              });
                            },
                          ),
                          _buildPresetChip(
                            label: '60 Days (2M)',
                            isSelected: _daysSupplyCtrl.text.trim() == '60',
                            onTap: () {
                              setState(() {
                                _daysSupplyCtrl.text = '60';
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Last Purchase Date Quick Selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Last Purchase Date',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(6.r),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4.w,
                                    vertical: 2.h,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        size: 14.sp,
                                        color: AppColors.primaryEmerald,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_lastPurchaseDate),
                                        style:
                                            AppTypography.bodySmall.copyWith(
                                          color: AppColors.primaryEmerald,
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
                                label: 'Today',
                                isSelected: _isSameDay(
                                  _lastPurchaseDate,
                                  DateTime.now(),
                                ),
                                onTap: () => setState(
                                  () => _lastPurchaseDate = DateTime.now(),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              _buildDateChip(
                                label: 'Yesterday',
                                isSelected: _isSameDay(
                                  _lastPurchaseDate,
                                  DateTime.now().subtract(
                                    const Duration(days: 1),
                                  ),
                                ),
                                onTap: () => setState(
                                  () => _lastPurchaseDate =
                                      DateTime.now().subtract(
                                        const Duration(days: 1),
                                      ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              _buildDateChip(
                                label: '7d Ago',
                                isSelected: _isSameDay(
                                  _lastPurchaseDate,
                                  DateTime.now().subtract(
                                    const Duration(days: 7),
                                  ),
                                ),
                                onTap: () => setState(
                                  () => _lastPurchaseDate =
                                      DateTime.now().subtract(
                                        const Duration(days: 7),
                                      ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgSurface,
                                      borderRadius:
                                          BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: AppColors.borderLight,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Custom 📅',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),

                      // Dynamic Calculation Banner
                      if (nextDate != null)
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppColors.primaryEmerald.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.primaryEmerald.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_repeat_rounded,
                                color: AppColors.primaryEmerald,
                                size: 22.sp,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Next Computed Refill Reminder:',
                                      style:
                                          AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      DateFormat(
                                        'EEEE, dd MMMM yyyy',
                                      ).format(nextDate),
                                      style:
                                          AppTypography.bodyMedium.copyWith(
                                        color: AppColors.primaryEmerald,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 14.h),

                      // Clinical Notes (Optional with Quick Tags)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Clinical Notes (Optional)',
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
                      // Quick tags for notes
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 4.h,
                        children: [
                          _buildNoteTag('Monthly maintenance'),
                          _buildNoteTag('Doctor repeat Rx'),
                          _buildNoteTag('Fasting check needed'),
                          _buildNoteTag('Call before dispatch'),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _notesCtrl,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              'Optional clinical remarks or delivery instructions...',
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
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),

                // Pinned Submit Button
                Obx(() {
                  return AppButton(
                    title: nextDate != null
                        ? 'Activate Refill (${DateFormat('dd MMM').format(nextDate)})'
                        : 'Activate Refill Rule',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: crmController.isSubmitting.value,
                    onPressed: _handleSubmit,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildPresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryEmerald.withValues(alpha: 0.15)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryEmerald : AppColors.borderLight,
            width: isSelected ? 1.2.w : 1.w,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? AppColors.primaryEmerald : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
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
                ? AppColors.primaryEmerald.withValues(alpha: 0.15)
                : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? AppColors.primaryEmerald : AppColors.borderLight,
              width: isSelected ? 1.2.w : 1.w,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isSelected ? AppColors.primaryEmerald : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTag(String text) {
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
              ? AppColors.primaryEmerald.withValues(alpha: 0.12)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryEmerald.withValues(alpha: 0.5)
                : AppColors.borderLight,
          ),
        ),
        child: Text(
          '+ $text',
          style: TextStyle(
            fontSize: 10.sp,
            color: isSelected ? AppColors.primaryEmerald : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
