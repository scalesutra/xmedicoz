import 'package:ledger_app/core/widgets/app_bottom_sheet.dart';
import 'package:ledger_app/core/widgets/searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/master_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../../../core/models/ocr_models.dart';
import '../../ocr/widgets/ocr_scanner_modal.dart';
import '../controllers/batch_controller.dart';
import '../controllers/master_data_controller.dart';
import '../add_stock_sheet.dart';

class AddBatchModal extends StatefulWidget {
  final MedicineModel? initialMedicine;
  final OcrScanResultModel? initialOcrResult;

  const AddBatchModal({super.key, this.initialMedicine, this.initialOcrResult});

  static void show(
    BuildContext context, {
    MedicineModel? initialMedicine,
    OcrScanResultModel? initialOcrResult,
  }) {
    AppBottomSheet.show(
      context: context,
      builder: (_) => AddBatchModal(
        initialMedicine: initialMedicine,
        initialOcrResult: initialOcrResult,
      ),
    );
  }

  @override
  State<AddBatchModal> createState() => _AddBatchModalState();
}

class _AddBatchModalState extends State<AddBatchModal> {
  final _formKey = GlobalKey<FormState>();
  final MasterDataController masterController =
      Get.find<MasterDataController>();
  final BatchController batchController = Get.find<BatchController>();

  String? _selectedMedicineId;
  String? _selectedSupplierId;
  final TextEditingController _batchNumberCtrl = TextEditingController();
  final TextEditingController _mrpCtrl = TextEditingController();
  final TextEditingController _purchaseRateCtrl = TextEditingController();
  final TextEditingController _sellingPriceCtrl = TextEditingController();
  final TextEditingController _initialQtyCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  DateTime? _mfgDate;
  DateTime? _expDate;
  bool _showAdvancedDetails = false;

  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _mrpCtrl.addListener(_onMrpChanged);
    if (widget.initialMedicine != null) {
      _selectedMedicineId = widget.initialMedicine!.id;
      _mrpCtrl.text = widget.initialMedicine!.mrp > 0
          ? widget.initialMedicine!.mrp.toStringAsFixed(2)
          : '';
      _purchaseRateCtrl.text = widget.initialMedicine!.purchaseRate > 0
          ? widget.initialMedicine!.purchaseRate.toStringAsFixed(2)
          : '';
      _sellingPriceCtrl.text = widget.initialMedicine!.sellingPrice > 0
          ? widget.initialMedicine!.sellingPrice.toStringAsFixed(2)
          : '';
    }
    if (widget.initialOcrResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyOcrBatch(widget.initialOcrResult!);
        }
      });
    }
  }

  void _onMrpChanged() {
    final mrpVal = double.tryParse(_mrpCtrl.text.trim());
    if (mrpVal != null && mrpVal > 0) {
      if (_purchaseRateCtrl.text.isEmpty) {
        _purchaseRateCtrl.text = (mrpVal * 0.70).toStringAsFixed(2);
      }
      if (_sellingPriceCtrl.text.isEmpty) {
        _sellingPriceCtrl.text = (mrpVal * 0.95).toStringAsFixed(2);
      }
    }
  }

  void _applyOcrBatch(OcrScanResultModel r) {
    final bNo =
        r.fields['batchNumber']?.toString() ??
        (r.items.isNotEmpty ? r.items.first.batchNumber : null);
    if (bNo != null && bNo.isNotEmpty) {
      _batchNumberCtrl.text = bNo;
    }

    final expStr =
        r.fields['expiryDate']?.toString() ??
        r.fields['expDate']?.toString() ??
        (r.items.isNotEmpty ? r.items.first.expiryDate : null);
    if (expStr != null && expStr.isNotEmpty) {
      try {
        _expDate = DateTime.parse(expStr);
      } catch (_) {}
    }

    final mfgStr = r.fields['mfgDate']?.toString();
    if (mfgStr != null && mfgStr.isNotEmpty) {
      try {
        _mfgDate = DateTime.parse(mfgStr);
      } catch (_) {}
    }

    final mrpVal =
        r.mrp ??
        (r.fields['mrp'] as num?)?.toDouble() ??
        (r.items.isNotEmpty ? r.items.first.mrp : null);
    if (mrpVal != null && mrpVal > 0) {
      _mrpCtrl.text = mrpVal.toStringAsFixed(2);
      if (_sellingPriceCtrl.text.isEmpty) {
        _sellingPriceCtrl.text = (mrpVal * 0.95).toStringAsFixed(2);
      }
      if (_purchaseRateCtrl.text.isEmpty) {
        _purchaseRateCtrl.text = (mrpVal * 0.70).toStringAsFixed(2);
      }
    }

    final pRate =
        (r.fields['purchaseRate'] as num?)?.toDouble() ??
        (r.items.isNotEmpty ? r.items.first.purchaseRate : null);
    if (pRate != null && pRate > 0) {
      _purchaseRateCtrl.text = pRate.toStringAsFixed(2);
    }

    final sPrice = (r.fields['sellingPrice'] as num?)?.toDouble();
    if (sPrice != null && sPrice > 0) {
      _sellingPriceCtrl.text = sPrice.toStringAsFixed(2);
    }

    final qty =
        (r.fields['quantity'] ??
                r.fields['currentQuantity'] ??
                r.fields['packSize'] as num?)
            ?.toDouble() ??
        (r.items.isNotEmpty ? r.items.first.quantity : null);
    if (qty != null && qty > 0) {
      _initialQtyCtrl.text = qty.toInt().toString();
    } else if (_initialQtyCtrl.text.isEmpty) {
      _initialQtyCtrl.text = '100';
    }

    if (_selectedMedicineId == null) {
      final searchName =
          r.medicineName ??
          r.fields['name']?.toString() ??
          (r.items.isNotEmpty ? r.items.first.medicineName : null);
      if (searchName != null && searchName.isNotEmpty) {
        final matched = masterController.medicines.firstWhereOrNull(
          (m) =>
              m.name.toLowerCase().contains(searchName.toLowerCase()) ||
              searchName.toLowerCase().contains(m.name.toLowerCase()),
        );
        if (matched != null) {
          _selectedMedicineId = matched.id;
        }
      }
    }

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UniqueSnackbar.showSuccess(
          context,
          title: 'Batch Extracted via AI OCR',
          message: 'B.No, Expiry & Rates populated from strip stamp.',
        );
      }
    });
  }

  @override
  void dispose() {
    _mrpCtrl.removeListener(_onMrpChanged);
    _batchNumberCtrl.dispose();
    _mrpCtrl.dispose();
    _purchaseRateCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _initialQtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMfgDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _mfgDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _mfgDate = picked);
    }
  }

  Future<void> _pickExpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _expDate = picked);
    }
  }

  void _onMedicineChanged(String? medId) {
    setState(() => _selectedMedicineId = medId);
    if (medId != null) {
      try {
        final med = masterController.medicineChoices.firstWhere(
          (m) => m.id == medId,
        );
        if (_mrpCtrl.text.isEmpty && med.mrp > 0) {
          _mrpCtrl.text = med.mrp.toStringAsFixed(2);
        }
        if (_purchaseRateCtrl.text.isEmpty && med.purchaseRate > 0) {
          _purchaseRateCtrl.text = med.purchaseRate.toStringAsFixed(2);
        }
        if (_sellingPriceCtrl.text.isEmpty && med.sellingPrice > 0) {
          _sellingPriceCtrl.text = med.sellingPrice.toStringAsFixed(2);
        }
      } catch (_) {}
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMedicineId == null || _selectedMedicineId!.isEmpty) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Validation',
        message: 'Please select a medicine',
      );
      return;
    }
    if (_expDate == null) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Expiry Date Required',
        message: 'Please select a valid expiry date for this batch.',
      );
      return;
    }
    if (_mfgDate != null && !_expDate!.isAfter(_mfgDate!)) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Invalid Batch Dates',
        message: 'Expiry date must be later than the manufacturing date.',
      );
      return;
    }

    final success = await batchController.createBatch(
      medicineId: _selectedMedicineId!,
      supplierId: _selectedSupplierId,
      batchNumber: _batchNumberCtrl.text.trim(),
      mrp: double.tryParse(_mrpCtrl.text.trim()) ?? 0.0,
      purchaseRate: double.tryParse(_purchaseRateCtrl.text.trim()) ?? 0.0,
      sellingPrice: double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0.0,
      initialQuantity: int.tryParse(_initialQtyCtrl.text.trim()) ?? 0,
      manufacturingDate: _mfgDate,
      expiryDate: _expDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
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
        height: MediaQuery.sizeOf(context).height * 0.90,
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
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
                        'Create Medicine Batch',
                        style: AppTypography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Atomic opening inventory entry',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        final result = await OcrScannerModal.show(
                          context,
                          initialType: OcrDocumentType.batch,
                        );
                        if (result != null) {
                          _applyOcrBatch(result);
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
                              'Scan Stamp',
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
                    SizedBox(width: 6.w),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.borderSubtle),

            // Scrollable Form Body
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: 24.h),
                  children: [
                    // Medicine Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Medicine *',
                          style: AppTypography.labelBold,
                        ),
                        TextButton.icon(
                          onPressed: () {
                            AddStockSheet.show(
                              context,
                              onMedicineCreated: () {
                                masterController.fetchMedicines();
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 16,
                            color: AppColors.primaryEmerald,
                          ),
                          label: Text(
                            'New Medicine',
                            style: AppTypography.labelBold.copyWith(
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Obx(() {
                      final meds = masterController.medicineChoices;
                      return SearchableDropdown<MedicineModel>(
                        value: meds.firstWhereOrNull(
                          (m) => m.id == _selectedMedicineId,
                        ),
                        decoration: AppDecorations.inputDecoration(
                          hintText: 'Choose from active medicines',
                          prefixIcon: const Icon(
                            Icons.medication_outlined,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                        items: meds,
                        label: (m) => '${m.name} (${m.dosageForm})',
                        loadItems: masterController.loadMedicineChoices,
                        onChanged: (medicine) =>
                            _onMedicineChanged(medicine?.id),
                        validator: (val) => val == null ? 'Required' : null,
                      );
                    }),
                    SizedBox(height: 14.h),

                    // Supplier Selector
                    Text('Supplier (Optional)', style: AppTypography.labelBold),
                    SizedBox(height: 6.h),
                    Obx(() {
                      final suppliers = masterController.supplierChoices;
                      return SearchableDropdown<SupplierModel>(
                        value: suppliers.firstWhereOrNull(
                          (s) => s.id == _selectedSupplierId,
                        ),
                        decoration: AppDecorations.inputDecoration(
                          hintText: 'Select supplier / distributor',
                          prefixIcon: const Icon(
                            Icons.local_shipping_outlined,
                            color: AppColors.clinicalCyan,
                          ),
                        ),
                        items: suppliers,
                        label: (s) => s.name,
                        loadItems: masterController.loadSupplierChoices,
                        itemName: 'supplier / stockist',
                        itemPlural: 'suppliers / stockists',
                        itemIcon: Icons.local_shipping_outlined,
                        onChanged: (val) =>
                            setState(() => _selectedSupplierId = val?.id),
                      );
                    }),
                    SizedBox(height: 14.h),

                    // Batch Number & Initial Qty
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Batch Number *',
                                style: AppTypography.labelBold,
                              ),
                              SizedBox(height: 6.h),
                              TextFormField(
                                controller: _batchNumberCtrl,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: AppDecorations.inputDecoration(
                                  hintText: 'e.g. BAT-2026-02',
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Opening Qty *',
                                style: AppTypography.labelBold,
                              ),
                              SizedBox(height: 6.h),
                              TextFormField(
                                controller: _initialQtyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: AppDecorations.inputDecoration(
                                  hintText: 'e.g. 50',
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (int.tryParse(val.trim()) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),

                    // Expiry Date & MRP (Primary Required Values)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expiry Date *',
                                style: AppTypography.labelBold,
                              ),
                              SizedBox(height: 6.h),
                              InkWell(
                                onTap: _pickExpDate,
                                borderRadius: BorderRadius.circular(
                                  AppDecorations.radiusSm,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 13.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgInput,
                                    borderRadius: BorderRadius.circular(
                                      AppDecorations.radiusSm,
                                    ),
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _expDate != null
                                            ? _dateFmt.format(_expDate!)
                                            : 'Select Expiry',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: _expDate != null
                                              ? AppColors.debitRose
                                              : AppColors.textMuted,
                                          fontWeight: _expDate != null
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.event_busy_outlined,
                                        size: 16,
                                        color: AppColors.debitRose,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MRP (₹) *', style: AppTypography.labelBold),
                              SizedBox(height: 6.h),
                              TextFormField(
                                controller: _mrpCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: AppDecorations.inputDecoration(
                                  hintText: '120.00',
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Progressive Disclosure Toggle
                    InkWell(
                      onTap: () => setState(
                        () => _showAdvancedDetails = !_showAdvancedDetails,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _showAdvancedDetails
                                      ? Icons.tune
                                      : Icons.tune_outlined,
                                  size: 16.sp,
                                  color: AppColors.primaryEmerald,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  _showAdvancedDetails
                                      ? 'Hide Cost, Sale Price & Mfg'
                                      : '+ Cost, Sale Price, Mfg Date & Notes',
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryEmerald,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _showAdvancedDetails
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 18.sp,
                              color: AppColors.primaryEmerald,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showAdvancedDetails) ...[
                      SizedBox(height: 12.h),
                      // Manufacturing Date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mfg Date (Optional)',
                            style: AppTypography.labelBold,
                          ),
                          SizedBox(height: 6.h),
                          InkWell(
                            onTap: _pickMfgDate,
                            borderRadius: BorderRadius.circular(
                              AppDecorations.radiusSm,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bgInput,
                                borderRadius: BorderRadius.circular(
                                  AppDecorations.radiusSm,
                                ),
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _mfgDate != null
                                        ? _dateFmt.format(_mfgDate!)
                                        : 'Select Mfg Date',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: _mfgDate != null
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Financials: Purchase Rate & Selling Price
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cost / Purchase *',
                                  style: AppTypography.labelBold,
                                ),
                                SizedBox(height: 6.h),
                                TextFormField(
                                  controller: _purchaseRateCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: AppDecorations.inputDecoration(
                                    hintText: 'Auto-calculated 70%',
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sale Price *',
                                  style: AppTypography.labelBold,
                                ),
                                SizedBox(height: 6.h),
                                TextFormField(
                                  controller: _sellingPriceCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: AppDecorations.inputDecoration(
                                    hintText: 'Auto-calculated 95%',
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Notes
                      Text(
                        'Notes / Memo (Optional)',
                        style: AppTypography.labelBold,
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        decoration: AppDecorations.inputDecoration(
                          hintText: 'e.g. Opening stock from central warehouse',
                        ),
                      ),
                    ],
                    SizedBox(height: 24.h),

                    // Submit Button
                    Obx(() {
                      return AppButton(
                        title: 'Save Batch & Credit Opening Stock',
                        icon: Icons.check_circle_outline,
                        isLoading: batchController.isSubmitting.value,
                        onPressed: _handleSubmit,
                      );
                    }),
                  ],
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}
