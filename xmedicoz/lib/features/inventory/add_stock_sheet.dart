import 'package:ledger_app/core/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/ocr_models.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/unique_snackbar.dart';
import '../ocr/widgets/ocr_scanner_modal.dart';
import 'controllers/master_data_controller.dart';

class AddStockSheet extends StatefulWidget {
  final VoidCallback? onMedicineCreated;
  final OcrScanResultModel? initialOcrResult;

  const AddStockSheet({
    super.key,
    this.onMedicineCreated,
    this.initialOcrResult,
  });

  static void show(
    BuildContext context, {
    VoidCallback? onMedicineCreated,
    OcrScanResultModel? initialOcrResult,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddStockSheet(
        onMedicineCreated: onMedicineCreated,
        initialOcrResult: initialOcrResult,
      ),
    );
  }

  @override
  State<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<AddStockSheet> {
  final masterController = Get.find<MasterDataController>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _genericNameCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _dosageFormCtrl = TextEditingController(
    text: 'Tablet',
  );
  final TextEditingController _strengthCtrl = TextEditingController(
    text: '500mg',
  );
  final TextEditingController _hsnCtrl = TextEditingController();
  final TextEditingController _gstRateCtrl = TextEditingController(text: '12');
  final TextEditingController _mrpCtrl = TextEditingController();
  final TextEditingController _purchaseCtrl = TextEditingController();
  final TextEditingController _sellingCtrl = TextEditingController();
  final TextEditingController _reorderCtrl = TextEditingController(text: '20');

  bool _prescriptionRequired = false;
  bool _isSubmitting = false;
  bool _showAdvancedDetails = false;

  String? _selectedCategoryId;
  String? _selectedManufacturerId;
  String? _selectedUnitId;

  final List<String> _dosageForms = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Suspension',
    'Injection',
    'Ointment',
    'Cream',
    'Drops',
    'Inhaler',
    'Gel',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialOcrResult != null) {
      _applyOcrMedicine(widget.initialOcrResult!);
      _showAdvancedDetails = true;
    }
  }

  void _applyOcrMedicine(OcrScanResultModel r) {
    if (r.medicineName != null && r.medicineName!.isNotEmpty) {
      _nameCtrl.text = r.medicineName!;
      _brandCtrl.text = r.medicineName!;
    }
    if (r.genericName != null && r.genericName!.isNotEmpty) {
      _genericNameCtrl.text = r.genericName!;
    }
    if (r.dosageForm != null && r.dosageForm!.isNotEmpty) {
      _dosageFormCtrl.text = r.dosageForm!;
    }
    if (r.strength != null && r.strength!.isNotEmpty) {
      _strengthCtrl.text = r.strength!;
    }
    if (r.hsnCode != null && r.hsnCode!.isNotEmpty) {
      _hsnCtrl.text = r.hsnCode!;
    }
    if (r.gstRate != null) {
      _gstRateCtrl.text = '${r.gstRate!.toInt()}';
    }
    if (r.mrp != null) {
      _mrpCtrl.text = r.mrp!.toStringAsFixed(2);
      _purchaseCtrl.text = (r.mrp! * 0.70).toStringAsFixed(2);
      _sellingCtrl.text = (r.mrp! * 0.95).toStringAsFixed(2);
    }
    if (r.scheduleType != null) {
      _prescriptionRequired = r.scheduleType!.toUpperCase().contains('H');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genericNameCtrl.dispose();
    _brandCtrl.dispose();
    _dosageFormCtrl.dispose();
    _strengthCtrl.dispose();
    _hsnCtrl.dispose();
    _gstRateCtrl.dispose();
    _mrpCtrl.dispose();
    _purchaseCtrl.dispose();
    _sellingCtrl.dispose();
    _reorderCtrl.dispose();
    super.dispose();
  }

  void _onMrpChanged(String val) {
    final mrp = double.tryParse(val.trim());
    if (mrp != null && mrp > 0) {
      if (_purchaseCtrl.text.isEmpty ||
          _purchaseCtrl.text == '0.00' ||
          _purchaseCtrl.text == '0') {
        _purchaseCtrl.text = (mrp * 0.70).toStringAsFixed(2);
      }
      if (_sellingCtrl.text.isEmpty ||
          _sellingCtrl.text == '0.00' ||
          _sellingCtrl.text == '0') {
        _sellingCtrl.text = (mrp * 0.95).toStringAsFixed(2);
      }
    }
  }

  Future<void> _handleSubmit() async {
    final name = _nameCtrl.text.trim();
    final generic = _genericNameCtrl.text.trim().isNotEmpty
        ? _genericNameCtrl.text.trim()
        : name;
    final brand = _brandCtrl.text.trim();
    final mrp = double.tryParse(_mrpCtrl.text.trim()) ?? 0.0;
    final purchase = double.tryParse(_purchaseCtrl.text.trim()) ?? 0.0;
    final selling = double.tryParse(_sellingCtrl.text.trim()) ?? 0.0;
    final reorder = int.tryParse(_reorderCtrl.text.trim()) ?? 10;
    final gst = double.tryParse(_gstRateCtrl.text.trim()) ?? 12.0;

    if (name.isEmpty) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Medicine Name Required',
        message: 'Please enter the medicine trade or commercial name.',
      );
      return;
    }
    if (mrp <= 0) {
      UniqueSnackbar.showWarning(
        context,
        title: 'MRP Required',
        message: 'Please enter a valid Maximum Retail Price.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = <String, dynamic>{
      'name': name,
      'genericName': generic,
      'brand': brand.isNotEmpty ? brand : name,
      'dosageForm': _dosageFormCtrl.text.trim(),
      'strength': _strengthCtrl.text.trim(),
      'hsnCode': _hsnCtrl.text.trim(),
      'gstRate': gst,
      'mrp': mrp,
      'purchaseRate': purchase > 0 ? purchase : (mrp * 0.70),
      'sellingPrice': selling > 0 ? selling : (mrp * 0.95),
      'reorderLevel': reorder,
      'prescriptionRequired': _prescriptionRequired,
      if (_selectedCategoryId != null) 'categoryId': _selectedCategoryId,
      if (_selectedManufacturerId != null)
        'manufacturerId': _selectedManufacturerId,
      if (_selectedUnitId != null) 'unitId': _selectedUnitId,
    };

    final success = await masterController.createMedicine(payload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      widget.onMedicineCreated?.call();
      UniqueSnackbar.showSuccess(
        context,
        title: 'Medicine Added',
        message: '$name registered to inventory successfully.',
      );
    } else {
      UniqueSnackbar.showError(
        context,
        title: 'Creation Failed',
        message: masterController.errorMessage.value.isNotEmpty
            ? masterController.errorMessage.value
            : 'Unable to save medicine to server.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKeyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: !hasKeyboard,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
        child: AppKeyboardPadding(
          child: Column(
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Medicine Master',
                          style: AppTypography.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Master Catalog • Synced with Drug Database',
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  InkWell(
                    onTap: () async {
                      final result = await OcrScannerModal.show(
                        context,
                        initialType: OcrDocumentType.medicine,
                      );
                      if (result != null && mounted) {
                        _applyOcrMedicine(result);
                        UniqueSnackbar.showSuccess(
                          this.context,
                          title: 'Medicine Strip Recognized',
                          message:
                              'Catalog fields auto-populated from strip.',
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.primaryEmerald.withValues(
                            alpha: 0.5,
                          ),
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.document_scanner_rounded,
                            size: 15.sp,
                            color: AppColors.primaryEmerald,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Scan Strip',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Medicine Name
                AppTextField(
                  controller: _nameCtrl,
                  hintText: 'e.g. Amoxicillin 500mg',
                  labelText: 'Medicine Commercial Name *',
                  prefixIcon: const Icon(
                    Icons.medication_rounded,
                    color: AppColors.primaryEmerald,
                  ),
                ),
                SizedBox(height: 12.h),

                // 2. Pricing Row (MRP auto-calculates Sale & Purchase rates)
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _mrpCtrl,
                        hintText: '0.00',
                        labelText: 'MRP (₹) *',
                        prefixText: '₹ ',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: _onMrpChanged,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AppTextField(
                        controller: _sellingCtrl,
                        hintText: '0.00',
                        labelText: 'Sale Price (₹)',
                        prefixText: '₹ ',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AppTextField(
                        controller: _purchaseCtrl,
                        hintText: '0.00',
                        labelText: 'Purchase (₹)',
                        prefixText: '₹ ',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // 3. Dosage Form Selection Chips
                Text('Dosage Form', style: AppTypography.label),
                SizedBox(height: 6.h),
                SizedBox(
                  height: 36.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _dosageForms.map((df) {
                      final isSelected = _dosageFormCtrl.text == df;
                      return Padding(
                        padding: EdgeInsets.only(right: 6.w),
                        child: ChoiceChip(
                          label: Text(df),
                          selected: isSelected,
                          selectedColor: AppColors.primaryEmerald.withValues(
                            alpha: 0.18,
                          ),
                          backgroundColor: AppColors.bgCard,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primaryEmerald
                                : AppColors.textSecondary,
                            fontSize: 11.5.sp,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _dosageFormCtrl.text = df);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 14.h),

                // 4. Progressive Disclosure Accordion: Advanced & Regulatory Details
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(
                      () => _showAdvancedDetails = !_showAdvancedDetails,
                    );
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: _showAdvancedDetails
                            ? AppColors.primaryEmerald.withValues(alpha: 0.4)
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _showAdvancedDetails
                                  ? Icons.tune_rounded
                                  : Icons.add_circle_outline_rounded,
                              size: 16.sp,
                              color: _showAdvancedDetails
                                  ? AppColors.primaryEmerald
                                  : AppColors.textSecondary,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _showAdvancedDetails
                                  ? 'Hide Advanced Details'
                                  : '+ More Details (Generic Salt, HSN, Category, Rx)',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                                color: _showAdvancedDetails
                                    ? AppColors.primaryEmerald
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          _showAdvancedDetails
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18.sp,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showAdvancedDetails) ...[
                  SizedBox(height: 12.h),

                  // Generic Composition
                  AppTextField(
                    controller: _genericNameCtrl,
                    hintText: 'e.g. Amoxicillin Trihydrate (defaults to Name)',
                    labelText: 'Generic Name / Active Salt',
                    prefixIcon: const Icon(
                      Icons.science_rounded,
                      color: AppColors.clinicalCyan,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Brand & Strength Row
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _brandCtrl,
                          hintText: 'e.g. Mox 500 / Dolo',
                          labelText: 'Brand / Label',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: AppTextField(
                          controller: _strengthCtrl,
                          hintText: 'e.g. 500mg / 100ml',
                          labelText: 'Strength',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),

                  // Live Category Dropdown
                  Obx(() {
                    final cats = masterController.categories;
                    if (cats.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category', style: AppTypography.label),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(
                              AppDecorations.radiusMd,
                            ),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value:
                                  cats.any((c) => c.id == _selectedCategoryId)
                                  ? _selectedCategoryId
                                  : null,
                              hint: Text(
                                'Select category',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              items: cats.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    style: AppTypography.bodyMedium,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedCategoryId = val),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                      ],
                    );
                  }),

                  // Live Manufacturer & Unit Dropdowns Row
                  Obx(() {
                    final mfgs = masterController.manufacturers;
                    final units = masterController.units;

                    if (mfgs.isEmpty && units.isEmpty)
                      return const SizedBox.shrink();

                    return Row(
                      children: [
                        if (mfgs.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manufacturer',
                                  style: AppTypography.label,
                                ),
                                SizedBox(height: 6.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgCard,
                                    borderRadius: BorderRadius.circular(
                                      AppDecorations.radiusMd,
                                    ),
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value:
                                          mfgs.any(
                                            (m) =>
                                                m.id == _selectedManufacturerId,
                                          )
                                          ? _selectedManufacturerId
                                          : null,
                                      hint: Text(
                                        'Select manufacturer',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      items: mfgs.map((m) {
                                        return DropdownMenuItem<String>(
                                          value: m.id,
                                          child: Text(
                                            m.name,
                                            style: AppTypography.bodySmall,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(
                                        () => _selectedManufacturerId = val,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (mfgs.isNotEmpty && units.isNotEmpty)
                          SizedBox(width: 10.w),
                        if (units.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unit Package',
                                  style: AppTypography.label,
                                ),
                                SizedBox(height: 6.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgCard,
                                    borderRadius: BorderRadius.circular(
                                      AppDecorations.radiusMd,
                                    ),
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value:
                                          units.any(
                                            (u) => u.id == _selectedUnitId,
                                          )
                                          ? _selectedUnitId
                                          : null,
                                      hint: Text(
                                        'Select unit',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      items: units.map((u) {
                                        return DropdownMenuItem<String>(
                                          value: u.id,
                                          child: Text(
                                            u.name,
                                            style: AppTypography.bodySmall,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) =>
                                          setState(() => _selectedUnitId = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }),
                  SizedBox(height: 10.h),

                  // HSN, GST & Reorder Level
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _hsnCtrl,
                          hintText: '300410',
                          labelText: 'HSN Code',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: AppTextField(
                          controller: _gstRateCtrl,
                          hintText: '12',
                          labelText: 'GST Rate %',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: AppTextField(
                          controller: _reorderCtrl,
                          hintText: '20',
                          labelText: 'Reorder Qty',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Prescription Required Toggle
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(
                        AppDecorations.radiusMd,
                      ),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: _prescriptionRequired
                              ? AppColors.debitRose
                              : AppColors.textSecondary,
                          size: 20.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Doctor Prescription Required (Rx)',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Schedule H / H1 medicine compliance',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _prescriptionRequired,
                          activeThumbColor: AppColors.debitRose,
                          onChanged: (val) =>
                              setState(() => _prescriptionRequired = val),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 20.h),

                // Submit Button
                AppButton(
                  title: 'Save Medicine to Database',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
              ],
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
}
