import 'package:ledger_app/core/widgets/searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_app/core/models/master_models.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../../inventory/controllers/master_data_controller.dart';
import '../../inventory/add_stock_sheet.dart';
import '../controllers/purchases_controller.dart';
import '../../../core/models/ocr_models.dart';
import '../../ocr/widgets/ocr_scanner_modal.dart';
import 'ocr_purchase_review_sheet.dart';
import 'purchase_success_modal.dart';

class _PurchaseItemDraft {
  String? medicineId;
  final TextEditingController batchCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: '100');
  final TextEditingController freeQtyCtrl = TextEditingController(text: '0');
  final TextEditingController purchaseRateCtrl = TextEditingController();
  final TextEditingController mrpCtrl = TextEditingController();
  final TextEditingController sellingPriceCtrl = TextEditingController();
  final TextEditingController discountCtrl = TextEditingController(text: '0');
  final TextEditingController taxRateCtrl = TextEditingController(text: '12');

  DateTime? mfgDate;
  DateTime? expDate;
  bool showPricingDetails = false;

  double get quantity => double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
  double get freeQuantity => double.tryParse(freeQtyCtrl.text.trim()) ?? 0.0;
  double get purchaseRate =>
      double.tryParse(purchaseRateCtrl.text.trim()) ?? 0.0;
  double get discountPercent =>
      double.tryParse(discountCtrl.text.trim()) ?? 0.0;
  double get taxRate => double.tryParse(taxRateCtrl.text.trim()) ?? 0.0;

  double get itemSubtotal => quantity * purchaseRate;
  double get discountAmount => itemSubtotal * (discountPercent / 100);
  double get taxableAmount => itemSubtotal - discountAmount;
  double get taxAmount => taxableAmount * (taxRate / 100);
  double get totalAmount => taxableAmount + taxAmount;

  void dispose() {
    batchCtrl.dispose();
    qtyCtrl.dispose();
    freeQtyCtrl.dispose();
    purchaseRateCtrl.dispose();
    mrpCtrl.dispose();
    sellingPriceCtrl.dispose();
    discountCtrl.dispose();
    taxRateCtrl.dispose();
  }
}

class CreatePurchaseSheet extends StatefulWidget {
  final OcrScanResultModel? initialOcrResult;

  const CreatePurchaseSheet({super.key, this.initialOcrResult});

  static void show(
    BuildContext context, {
    OcrScanResultModel? initialOcrResult,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => CreatePurchaseSheet(initialOcrResult: initialOcrResult),
    );
  }

  @override
  State<CreatePurchaseSheet> createState() => _CreatePurchaseSheetState();
}

class _CreatePurchaseSheetState extends State<CreatePurchaseSheet> {
  final _formKey = GlobalKey<FormState>();
  final MasterDataController masterController =
      Get.find<MasterDataController>();
  final PurchasesController purchasesController =
      Get.find<PurchasesController>();

  String? _selectedSupplierId;
  SupplierModel? get _selectedSupplier => masterController.supplierChoices
      .firstWhereOrNull((s) => s.id == _selectedSupplierId);
  final TextEditingController _invoiceNoCtrl = TextEditingController();
  final TextEditingController _termsCtrl = TextEditingController(text: '30');
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  bool _showDeliveryNotes = false;

  final List<_PurchaseItemDraft> _items = [];
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');
  final _billTotalsVersion = 0.obs;

  @override
  void initState() {
    super.initState();
    // Default 1 blank line item (no pre-selected medicine)
    _addItem();
    if (widget.initialOcrResult != null) {
      _applyOcrPurchaseBill(widget.initialOcrResult!);
    }
  }

  bool _isAutoIngestingOcr = false;

  DateTime? _parseFlexibleDate(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    try {
      return DateTime.parse(s);
    } catch (_) {}

    // MM/YY or MM/YYYY (e.g., "12/28", "10/27", "12/2028")
    final slashExp = RegExp(r'^(\d{1,2})[/.-](\d{2,4})$');
    final slashMatch = slashExp.firstMatch(s);
    if (slashMatch != null) {
      final month = int.tryParse(slashMatch.group(1)!) ?? 1;
      var year = int.tryParse(slashMatch.group(2)!) ?? DateTime.now().year;
      if (year < 100) year += 2000;
      final clampedMonth = month.clamp(1, 12);
      final lastDay = DateTime(year, clampedMonth + 1, 0).day;
      return DateTime(year, clampedMonth, lastDay);
    }

    // DD/MM/YYYY or DD-MM-YYYY
    final dmyExp = RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})$');
    final dmyMatch = dmyExp.firstMatch(s);
    if (dmyMatch != null) {
      final d = int.tryParse(dmyMatch.group(1)!) ?? 1;
      final m = int.tryParse(dmyMatch.group(2)!) ?? 1;
      var y = int.tryParse(dmyMatch.group(3)!) ?? DateTime.now().year;
      if (y < 100) y += 2000;
      final clampedMonth = m.clamp(1, 12);
      final lastDay = DateTime(y, clampedMonth + 1, 0).day;
      return DateTime(y, clampedMonth, d.clamp(1, lastDay));
    }

    return null;
  }

  Future<void> _applyOcrPurchaseBill(OcrScanResultModel r) async {
    setState(() => _isAutoIngestingOcr = true);
    try {
      int newSuppliersCount = 0;
      int newMedicinesCount = 0;

      if (r.invoiceNumber != null && r.invoiceNumber!.isNotEmpty) {
        _invoiceNoCtrl.text = r.invoiceNumber!;
      }
      if (r.invoiceDate != null && r.invoiceDate!.isNotEmpty) {
        final parsed = _parseFlexibleDate(r.invoiceDate);
        if (parsed != null) {
          _invoiceDate = parsed;
        }
      }

      // ----------------------------------------------------------------------
      // Step 1: Atomic Supplier Resolution (On-The-Fly)
      // ----------------------------------------------------------------------
      SupplierModel? matchedSupplier = await masterController
          .findOrSearchSupplier(gstin: r.gstin, name: r.supplierName);

      // If unregistered distributor, auto-register on-the-fly (Step 1)
      if (matchedSupplier == null &&
          r.supplierName != null &&
          r.supplierName!.trim().isNotEmpty) {
        final supplierPayload = {
          'name': r.supplierName!.trim(),
          if (r.gstin != null && r.gstin!.trim().isNotEmpty)
            'gstin': r.gstin!.trim(),
          if (r.dlNumber != null && r.dlNumber!.trim().isNotEmpty) ...{
            'dlNumber': r.dlNumber!.trim(),
            'drugLicenseNumber': r.dlNumber!.trim(),
          },
          'mobile':
              (r.supplierMobile != null && r.supplierMobile!.trim().isNotEmpty)
              ? r.supplierMobile!.trim()
              : '',
          'phone':
              (r.supplierMobile != null && r.supplierMobile!.trim().isNotEmpty)
              ? r.supplierMobile!.trim()
              : '',
          'address':
              (r.supplierAddress != null &&
                  r.supplierAddress!.trim().isNotEmpty)
              ? r.supplierAddress!.trim()
              : (r.address != null && r.address!.trim().isNotEmpty)
              ? r.address!.trim()
              : 'Local Distributor',
          'paymentTerms': '${int.tryParse(_termsCtrl.text.trim()) ?? 30} Days',
          'paymentTermsDays': int.tryParse(_termsCtrl.text.trim()) ?? 30,
          'isActive': true,
        };
        matchedSupplier = await masterController.registerSupplier(
          supplierPayload,
        );
        if (matchedSupplier != null) {
          newSuppliersCount++;
        }
      }

      if (matchedSupplier != null) {
        setState(() => _selectedSupplierId = matchedSupplier!.id);
      }

      // ----------------------------------------------------------------------
      // Step 2 & 3: Atomic Medicine Catalog Resolution & Draft Population
      // ----------------------------------------------------------------------
      if (r.items.isNotEmpty) {
        final List<_PurchaseItemDraft> generatedDrafts = [];

        for (final item in r.items) {
          final draft = _PurchaseItemDraft();

          MedicineModel? matchedMed = await masterController
              .findOrSearchMedicine(item.medicineName);

          // If uncataloged medicine, auto-register on-the-fly (Step 2 - Statutory HSN 3004.90)
          if (matchedMed == null && item.medicineName.trim().isNotEmpty) {
            final medPayload = {
              'name': item.medicineName.trim(),
              'genericName': item.medicineName.trim(),
              'dosageForm': item.dosage ?? 'Tablet',
              'strength': 'Standard',
              'hsnCode': '3004.90',
              'gstRate': (item.gstRate ?? 12).toInt(),
              'taxRate': (item.gstRate ?? 12).toDouble(),
              'mrp': item.mrp ?? 0.0,
              'purchaseRate': item.purchaseRate ?? 0.0,
              'sellingPrice': (item.mrp != null && item.mrp! > 0)
                  ? (item.mrp! * 0.95)
                  : (item.purchaseRate ?? 0.0),
              'reorderLevel': 10,
              'prescriptionRequired': false,
              'isActive': true,
            };
            matchedMed = await masterController.registerMedicine(medPayload);
            if (matchedMed != null) {
              newMedicinesCount++;
            }
          }

          if (matchedMed != null) {
            draft.medicineId = matchedMed.id;
          }

          if (item.batchNumber != null && item.batchNumber!.isNotEmpty) {
            draft.batchCtrl.text = item.batchNumber!;
          }
          if (item.expiryDate != null && item.expiryDate!.isNotEmpty) {
            final parsedExp = _parseFlexibleDate(item.expiryDate);
            if (parsedExp != null) {
              draft.expDate = parsedExp;
            }
          }
          draft.qtyCtrl.text = item.quantity.toStringAsFixed(0);
          draft.freeQtyCtrl.text = item.freeQuantity.toStringAsFixed(0);

          if (item.purchaseRate != null && item.purchaseRate! > 0) {
            draft.purchaseRateCtrl.text = item.purchaseRate!.toStringAsFixed(2);
          } else if (matchedMed != null && matchedMed.purchaseRate > 0) {
            draft.purchaseRateCtrl.text = matchedMed.purchaseRate
                .toStringAsFixed(2);
          }

          if (item.mrp != null && item.mrp! > 0) {
            draft.mrpCtrl.text = item.mrp!.toStringAsFixed(2);
            draft.sellingPriceCtrl.text = (item.mrp! * 0.95).toStringAsFixed(2);
          } else if (matchedMed != null && matchedMed.mrp > 0) {
            draft.mrpCtrl.text = matchedMed.mrp.toStringAsFixed(2);
            draft.sellingPriceCtrl.text = (matchedMed.mrp * 0.95)
                .toStringAsFixed(2);
          }

          if (item.gstRate != null) {
            draft.taxRateCtrl.text = item.gstRate!.toStringAsFixed(0);
          } else if (matchedMed != null) {
            draft.taxRateCtrl.text = matchedMed.gstRate.toStringAsFixed(0);
          }

          generatedDrafts.add(draft);
        }

        setState(() {
          _items.clear();
          _items.addAll(generatedDrafts);
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          String toastMessage;
          if (newSuppliersCount > 0 || newMedicinesCount > 0) {
            toastMessage =
                '✨ Zero-Touch: $newSuppliersCount new supplier and $newMedicinesCount new medicines auto-added to your catalog.';
          } else {
            toastMessage =
                'Supplier verified & ${r.items.length} medicines cataloged. Ready for atomic ingestion!';
          }
          UniqueSnackbar.showSuccess(
            context,
            title: 'Zero-Touch Wholesale Inwarding Ready',
            message: toastMessage,
          );
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isAutoIngestingOcr = false);
      }
    }
  }

  @override
  void dispose() {
    _invoiceNoCtrl.dispose();
    _termsCtrl.dispose();
    _notesCtrl.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      final draft = _PurchaseItemDraft();
      // Do not auto-select any medicine; display "Select medicine" placeholder
      _items.add(draft);
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  double get _billSubtotal =>
      _items.fold(0.0, (sum, i) => sum + i.itemSubtotal);
  double get _billDiscount =>
      _items.fold(0.0, (sum, i) => sum + i.discountAmount);
  double get _billTax => _items.fold(0.0, (sum, i) => sum + i.taxAmount);
  double get _billGrandTotal =>
      _items.fold(0.0, (sum, i) => sum + i.totalAmount);

  Future<void> _pickInvoiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null || _selectedSupplierId!.isEmpty) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Validation',
        message: 'Please select a supplier',
      );
      return;
    }

    // Build payload matching POST /purchases
    final List<Map<String, dynamic>> itemsPayload = [];
    for (var draft in _items) {
      if (draft.medicineId == null || draft.medicineId!.isEmpty) {
        UniqueSnackbar.showWarning(
          context,
          title: 'Validation',
          message: 'Please choose medicine for all items',
        );
        return;
      }
      if (draft.batchCtrl.text.trim().isEmpty) {
        UniqueSnackbar.showWarning(
          context,
          title: 'Validation',
          message: 'Batch number is required for all items',
        );
        return;
      }

      final qty = int.tryParse(draft.qtyCtrl.text.trim()) ?? 0;
      final freeQty = int.tryParse(draft.freeQtyCtrl.text.trim()) ?? 0;
      final pRate = double.tryParse(draft.purchaseRateCtrl.text.trim()) ?? 0.0;
      final mrp = double.tryParse(draft.mrpCtrl.text.trim()) ?? 0.0;
      final sPrice = double.tryParse(draft.sellingPriceCtrl.text.trim()) ?? 0.0;
      final disc = double.tryParse(draft.discountCtrl.text.trim()) ?? 0.0;
      final tax = double.tryParse(draft.taxRateCtrl.text.trim()) ?? 12.0;
      final lineAmount = draft.totalAmount;

      itemsPayload.add({
        'medicineId': draft.medicineId,
        'batchNumber': draft.batchCtrl.text.trim(),
        'manufacturingDate': draft.mfgDate != null
            ? draft.mfgDate!.toIso8601String()
            : DateTime.now().toIso8601String(),
        'expiryDate': draft.expDate != null
            ? draft.expDate!.toIso8601String()
            : DateTime.now().add(const Duration(days: 730)).toIso8601String(),
        'quantity': qty,
        'freeQuantity': freeQty,
        'freeQty': freeQty,
        'purchaseRate': pRate,
        'mrp': mrp,
        'sellingPrice': sPrice,
        'discountPercent': disc,
        'taxRate': tax,
        'hsnCode': '3004.90',
        'amount': lineAmount,
      });
    }

    final payload = {
      'supplierId': _selectedSupplierId,
      'invoiceNumber': _invoiceNoCtrl.text.trim(),
      'invoiceDate': _invoiceDate.toIso8601String(),
      'totalAmount': _billGrandTotal,
      'paymentTermsDays': int.tryParse(_termsCtrl.text.trim()) ?? 30,
      'notes': _notesCtrl.text.trim().isNotEmpty
          ? _notesCtrl.text.trim()
          : 'Received in good condition',
      'items': itemsPayload,
      'lines': itemsPayload,
    };

    final invoice = await purchasesController.createPurchaseInvoice(payload);
    if (invoice != null && mounted) {
      final nav = Navigator.of(context);
      nav.pop();
      if (nav.context.mounted) {
        PurchaseSuccessModal.show(
          nav.context,
          invoice: invoice,
          invoiceNumber: _invoiceNoCtrl.text.trim(),
          supplierName: invoice.supplier?.name ?? _selectedSupplier?.name,
          totalAmount: _billGrandTotal,
          itemCount: itemsPayload.length,
        );
      }
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
        height: MediaQuery.sizeOf(context).height * 0.92,
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Form(
          key: _formKey,
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
              SizedBox(height: 12.h),

              // Pinned Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Stockist Purchase Bill',
                          style: AppTypography.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Receive Stock & Ingest Batches Atomically',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryEmerald,
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
                          final nav = Navigator.of(context);
                          final result = await OcrScannerModal.show(
                            context,
                            initialType: OcrDocumentType.purchaseBill,
                            onResult: (_) {},
                          );
                          if (result != null && mounted) {
                            nav.pop();
                            if (nav.context.mounted) {
                              OcrPurchaseReviewSheet.show(
                                nav.context,
                                ocrResult: result,
                              );
                            }
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
                                'Scan Bill',
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
              if (_isAutoIngestingOcr) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Zero-Touch: Auto-registering distributor & cataloging medicines on-the-fly...',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryEmerald,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 16, color: AppColors.borderSubtle),

              // Scrollable Body
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 24.h,
                  ),
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    // Supplier Selector
                    Text(
                      'Supplier / Stockist *',
                      style: AppTypography.labelBold,
                    ),
                    SizedBox(height: 6.h),
                    Obx(() {
                      final suppliers = masterController.supplierChoices;
                      return SearchableDropdown<SupplierModel>(
                        value: _selectedSupplier,
                        decoration: AppDecorations.inputDecoration(
                          hintText: 'Select distributor / wholesaler',
                          prefixIcon: const Icon(
                            Icons.local_shipping_outlined,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        items: suppliers,
                        label: (s) =>
                            '${s.name} (Due: ₹${s.outstandingBalance.toInt()})',
                        loadItems: masterController.loadSupplierChoices,
                        itemName: 'supplier / stockist',
                        itemPlural: 'suppliers / stockists',
                        itemIcon: Icons.local_shipping_outlined,
                        onChanged: (val) =>
                            setState(() => _selectedSupplierId = val?.id),
                        validator: (val) => val == null ? 'Required' : null,
                      );
                    }),
                    SizedBox(height: 12.h),

                    // Invoice Number & Date & Payment Terms Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice No *',
                                style: AppTypography.labelBold,
                              ),
                              SizedBox(height: 6.h),
                              TextFormField(
                                controller: _invoiceNoCtrl,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: AppDecorations.inputDecoration(
                                  hintText: 'INV-SUPP-2229',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terms (Days)',
                                style: AppTypography.labelBold,
                              ),
                              SizedBox(height: 6.h),
                              TextFormField(
                                controller: _termsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: AppDecorations.inputDecoration(
                                  hintText: '30',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Invoice Date Selector
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice Date *',
                                style: AppTypography.labelBold,
                              ),
                              SizedBox(height: 6.h),
                              InkWell(
                                onTap: _pickInvoiceDate,
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
                                        _dateFmt.format(_invoiceDate),
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: AppColors.primaryEmerald,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Items Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Purchase Items (${_items.length})',
                          style: AppTypography.h4,
                        ),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(
                            Icons.add_circle,
                            size: 18,
                            color: AppColors.primaryEmerald,
                          ),
                          label: const Text(
                            'Add Medicine',
                            style: TextStyle(
                              color: AppColors.primaryEmerald,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    // Dynamic Items List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => SizedBox(height: 12.h),
                      itemBuilder: (ctx, idx) => _buildItemCard(idx),
                    ),
                    SizedBox(height: 14.h),

                    // Delivery Notes Progressive Disclosure
                    if (_showDeliveryNotes ||
                        _notesCtrl.text.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery / Receiver Notes',
                            style: AppTypography.labelBold,
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showDeliveryNotes = false;
                                _notesCtrl.clear();
                              });
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.debitRose,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      TextFormField(
                        controller: _notesCtrl,
                        decoration: AppDecorations.inputDecoration(
                          hintText: 'e.g. Received delivery in good condition',
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ] else ...[
                      InkWell(
                        onTap: () =>
                            setState(() => _showDeliveryNotes = true),
                        borderRadius: BorderRadius.circular(6.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 15.sp,
                                color: AppColors.primaryBlue,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '+ Add Delivery / Receiver Notes (Optional)',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],

                    // Bill Summary Container
                    Obx(() {
                      _billTotalsVersion.value;
                      return Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(
                            AppDecorations.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.primaryEmerald.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            _sumRow(
                              'Subtotal',
                              Formatters.formatCurrency(_billSubtotal),
                            ),
                            SizedBox(height: 4.h),
                            _sumRow(
                              'Discount (-)',
                              Formatters.formatCurrency(_billDiscount),
                              color: AppColors.debitRose,
                            ),
                            SizedBox(height: 4.h),
                            _sumRow(
                              'Tax / GST (+)',
                              Formatters.formatCurrency(_billTax),
                              color: AppColors.clinicalCyan,
                            ),
                            const Divider(
                              height: 16,
                              color: AppColors.borderSubtle,
                            ),
                            _sumRow(
                              'Net Bill Amount',
                              Formatters.formatCurrency(_billGrandTotal),
                              isBold: true,
                              color: AppColors.primaryEmerald,
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: 16.h),

                    // Submit Button inside list
                    Obx(() {
                      return AppButton(
                        title: 'Confirm Bill & Ingest Stock',
                        icon: Icons.inventory_2_outlined,
                        isLoading: purchasesController.isSubmitting.value,
                        onPressed: _handleSubmit,
                      );
                    }),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Item Title & Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item #${index + 1}',
                style: AppTypography.labelBold.copyWith(
                  color: AppColors.clinicalCyan,
                ),
              ),
              if (_items.length > 1)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.debitRose,
                  ),
                  onPressed: () => _removeItem(index),
                ),
            ],
          ),
          SizedBox(height: 8.h),

          // Medicine Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Medicine *', style: AppTypography.labelBold),
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
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Obx(() {
            final medicines = masterController.medicineChoices;
            return SearchableDropdown<MedicineModel>(
              value: medicines.firstWhereOrNull((m) => m.id == item.medicineId),
              decoration: AppDecorations.inputDecoration(
                hintText: 'Select medicine',
              ),
              items: medicines,
              label: (m) => '${m.name} (${m.dosageForm})',
              loadItems: masterController.loadMedicineChoices,
              onChanged: (val) {
                setState(() {
                  item.medicineId = val?.id;
                  if (val != null) {
                    try {
                      final med = val;
                      item.purchaseRateCtrl.text = med.purchaseRate
                          .toStringAsFixed(2);
                      item.mrpCtrl.text = med.mrp.toStringAsFixed(2);
                      item.sellingPriceCtrl.text = med.sellingPrice
                          .toStringAsFixed(2);
                      item.taxRateCtrl.text = med.gstRate.toStringAsFixed(0);
                    } catch (_) {}
                  }
                });
              },
            );
          }),
          SizedBox(height: 10.h),

          // Batch No & Expiry
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: item.batchCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: AppDecorations.inputDecoration(
                    hintText: 'Batch No (e.g. BAT-2026-P4)',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          item.expDate ??
                          DateTime.now().add(const Duration(days: 730)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => item.expDate = picked);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(
                        AppDecorations.radiusSm,
                      ),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      item.expDate != null
                          ? _dateFmt.format(item.expDate!)
                          : 'Expiry Date',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: item.expDate != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Qty & Purchase Rate (Primary)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qty *', style: AppTypography.bodySmall),
                    SizedBox(height: 4.h),
                    TextFormField(
                      controller: item.qtyCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _billTotalsVersion.value++,
                      decoration: AppDecorations.inputDecoration(
                        hintText: '100',
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 4.w,
                      children: [10, 50, 100].map((q) {
                        return InkWell(
                          onTap: () {
                            item.qtyCtrl.text = q.toString();
                            _billTotalsVersion.value++;
                          },
                          borderRadius: BorderRadius.circular(4.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(4.r),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              '+$q',
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost Rate (₹) *', style: AppTypography.bodySmall),
                    SizedBox(height: 4.h),
                    TextFormField(
                      controller: item.purchaseRateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _billTotalsVersion.value++,
                      decoration: AppDecorations.inputDecoration(
                        hintText: '80.00',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),

          // Progressive Disclosure for Free Qty, MRP, Selling Price, Disc %, GST %
          InkWell(
            onTap: () {
              setState(() {
                item.showPricingDetails = !item.showPricingDetails;
              });
            },
            borderRadius: BorderRadius.circular(6.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                children: [
                  Icon(
                    item.showPricingDetails
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16.sp,
                    color: AppColors.primaryEmerald,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    item.showPricingDetails
                        ? 'Hide Free Units, MRP & Tax'
                        : '+ Free Bonus, MRP, Sale Price & GST (Optional)',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryEmerald,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (item.showPricingDetails) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Free Qty', style: AppTypography.bodySmall),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: item.freeQtyCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _billTotalsVersion.value++,
                        decoration: AppDecorations.inputDecoration(
                          hintText: '0',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MRP (₹)', style: AppTypography.bodySmall),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: item.mrpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: AppDecorations.inputDecoration(
                          hintText: '120.00',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sale Price (₹)', style: AppTypography.bodySmall),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: item.sellingPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: AppDecorations.inputDecoration(
                          hintText: '110.00',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Disc %', style: AppTypography.bodySmall),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: item.discountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => _billTotalsVersion.value++,
                        decoration: AppDecorations.inputDecoration(
                          hintText: '0',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GST %', style: AppTypography.bodySmall),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: item.taxRateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => _billTotalsVersion.value++,
                        decoration: AppDecorations.inputDecoration(
                          hintText: '12',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 8.h),

          // Item line subtotal
          Obx(() {
            _billTotalsVersion.value;
            return Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Line Total: ${Formatters.formatCurrency(item.totalAmount)} (${item.quantity.toInt()} + ${item.freeQuantity.toInt()} units)',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryEmerald,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sumRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14.sp : 12.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15.sp : 12.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
