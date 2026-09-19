import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/models/ocr_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../controllers/ocr_controller.dart';
import '../../vouchers/marg_sale_invoice_modal.dart';
import '../../purchases/widgets/ocr_purchase_review_sheet.dart';
import '../../inventory/add_stock_sheet.dart';
import '../../inventory/widgets/add_batch_modal.dart';

class OcrScannerModal extends StatefulWidget {
  final OcrDocumentType initialType;
  final ValueChanged<OcrScanResultModel>? onResult;

  const OcrScannerModal({
    super.key,
    this.initialType = OcrDocumentType.medicine,
    this.onResult,
  });

  static Future<OcrScanResultModel?> show(
    BuildContext context, {
    OcrDocumentType initialType = OcrDocumentType.medicine,
    ValueChanged<OcrScanResultModel>? onResult,
  }) {
    return showModalBottomSheet<OcrScanResultModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OcrScannerModal(
        initialType: initialType,
        onResult: onResult,
      ),
    );
  }

  @override
  State<OcrScannerModal> createState() => _OcrScannerModalState();
}

class _OcrScannerModalState extends State<OcrScannerModal> with SingleTickerProviderStateMixin {
  late final OcrController ocrController;
  late final AnimationController _pulseController;
  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<OcrController>()) {
      ocrController = Get.put(OcrController());
    } else {
      ocrController = Get.find<OcrController>();
    }
    ocrController.clear();
    ocrController.setDocumentType(widget.initialType);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.88.sh,
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          // Drag Handle
          SizedBox(height: 10.h),
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Modal Title Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.document_scanner_rounded,
                        color: AppColors.primaryEmerald,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical AI OCR Engine',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Indian Pharma Document & Rx Recognition',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // Document Type Selector Chips
          _buildDocumentTypeSelector(),
          SizedBox(height: 12.h),

          // Main Scrollable Stage
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 18.w,
                right: 18.w,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 24.h,
              ),
              child: Obx(() {
                final isScanning = ocrController.isScanning.value;
                final image = ocrController.pickedImage.value;
                final result = ocrController.scanResult.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Capture & Preview Area
                    _buildImagePickerStage(image, isScanning),
                    SizedBox(height: 16.h),

                    // Scanning Indicator Banner
                    if (isScanning) _buildScanningHud(),

                    // Extracted Results Section
                    if (result != null && !isScanning) ...[
                      _buildResultsHeader(result),
                      SizedBox(height: 14.h),
                      _buildExtractedFieldsCard(result),
                      SizedBox(height: 14.h),
                      if (result.items.isNotEmpty) ...[
                        _buildItemsTable(result),
                        SizedBox(height: 14.h),
                      ],
                      _buildRawTextAccordion(result),
                      SizedBox(height: 20.h),
                    ],
                  ],
                );
              }),
            ),
          ),

          // Bottom Action Bar
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Document Type Selector
  // --------------------------------------------------------------------------
  Widget _buildDocumentTypeSelector() {
    return SizedBox(
      height: 40.h,
      child: Obx(() {
        final current = ocrController.selectedDocType.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          itemCount: OcrDocumentType.values.length,
          separatorBuilder: (_, _) => SizedBox(width: 8.w),
          itemBuilder: (context, index) {
            final type = OcrDocumentType.values[index];
            final isSelected = current == type;

            return InkWell(
              onTap: () {
                ocrController.setDocumentType(type);
                if (ocrController.pickedImage.value != null) {
                  ocrController.scanImage();
                }
              },
              borderRadius: BorderRadius.circular(20.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryEmerald : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryEmerald : AppColors.borderSubtle,
                    width: 1.2.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForDocType(type),
                      size: 15.sp,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  IconData _iconForDocType(OcrDocumentType type) {
    switch (type) {
      case OcrDocumentType.medicine:
        return Icons.medication_rounded;
      case OcrDocumentType.prescription:
        return Icons.receipt_long_rounded;
      case OcrDocumentType.purchaseBill:
        return Icons.inventory_2_rounded;
      case OcrDocumentType.batch:
        return Icons.qr_code_scanner_rounded;
      case OcrDocumentType.customer:
        return Icons.person_search_rounded;
      case OcrDocumentType.supplier:
        return Icons.store_rounded;
    }
  }

  // --------------------------------------------------------------------------
  // Image Capture & Stage
  // --------------------------------------------------------------------------
  Widget _buildImagePickerStage(dynamic pickedImage, bool isScanning) {
    if (pickedImage == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderLight, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.center_focus_strong_rounded,
                color: AppColors.primaryEmerald,
                size: 38.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Upload or Snap Pharma Document',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Obx(() => Text(
                  ocrController.selectedDocType.value.description,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                )),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ocrController.pickFromCamera(),
                    icon: Icon(Icons.camera_alt_rounded, size: 18.sp, color: AppColors.primaryEmerald),
                    label: Text(
                      'Camera',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmerald, fontSize: 13.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: const BorderSide(color: AppColors.primaryEmerald),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ocrController.pickFromGallery(),
                    icon: Icon(Icons.photo_library_rounded, size: 18.sp, color: Colors.white),
                    label: Text(
                      'Gallery',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryEmerald,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Image is picked - display preview frame
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: Stack(
              children: [
                Container(
                  height: 170.h,
                  width: double.infinity,
                  color: Colors.black87,
                  child: Image.file(
                    File(pickedImage.path),
                    fit: BoxFit.contain,
                  ),
                ),
                if (isScanning)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return Container(
                              width: 140.w + (_pulseController.value * 20.w),
                              height: 2.h,
                              decoration: BoxDecoration(
                                color: AppColors.primaryEmeraldLight,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryEmeraldLight.withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Captured Document',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: isScanning ? null : () => ocrController.pickFromCamera(),
                      icon: Icon(Icons.camera_alt_outlined, size: 16.sp),
                      label: const Text('Camera'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryEmerald,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    TextButton.icon(
                      onPressed: isScanning ? null : () => ocrController.pickFromGallery(),
                      icon: Icon(Icons.photo_library_outlined, size: 16.sp),
                      label: const Text('Gallery'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryEmerald,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Scanning HUD
  // --------------------------------------------------------------------------
  Widget _buildScanningHud() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22.sp,
            height: 22.sp,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryEmerald,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Processing Image',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
                Obx(() => Text(
                      ocrController.scanningStatus.value,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: AppColors.textSecondary,
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Results Header & Confidence Meter
  // --------------------------------------------------------------------------
  Widget _buildResultsHeader(OcrScanResultModel result) {
    final confPercent = (result.confidence * 100).clamp(0, 100).toStringAsFixed(0);
    final isHigh = result.confidence >= 0.85;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.primaryEmerald, size: 18.sp),
            SizedBox(width: 6.w),
            Text(
              'Extracted Entities',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isHigh
                ? AppColors.creditGreen.withValues(alpha: 0.12)
                : AppColors.amberWarning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isHigh ? AppColors.creditGreen : AppColors.amberWarning,
              width: 1.w,
            ),
          ),
          child: Text(
            'Confidence $confPercent%',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: isHigh ? AppColors.creditGreen : AppColors.amberWarning,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Extracted Fields Card
  // --------------------------------------------------------------------------
  Widget _buildExtractedFieldsCard(OcrScanResultModel result) {
    final docType = ocrController.selectedDocType.value;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render specific field groups based on document type
          if (docType == OcrDocumentType.medicine) ..._buildMedicineFields(result),
          if (docType == OcrDocumentType.prescription) ..._buildPrescriptionFields(result),
          if (docType == OcrDocumentType.purchaseBill) ..._buildPurchaseBillFields(result),
          if (docType == OcrDocumentType.batch) ..._buildBatchFields(result),
          if (docType == OcrDocumentType.customer) ..._buildCustomerFields(result),
          if (docType == OcrDocumentType.supplier) ..._buildSupplierFields(result),
        ],
      ),
    );
  }

  List<Widget> _buildMedicineFields(OcrScanResultModel r) {
    return [
      _buildDetailRow('Medicine Brand', r.medicineName ?? '—', isPrimary: true),
      _buildDetailRow('Active Generic Salt', r.genericName ?? '—'),
      Row(
        children: [
          Expanded(child: _buildDetailRow('Dosage Form', r.dosageForm ?? '—')),
          Expanded(child: _buildDetailRow('Strength', r.strength ?? '—')),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildDetailRow('Schedule', r.scheduleType ?? '—')),
          Expanded(child: _buildDetailRow('Pack Size', r.packSize != null ? '${r.packSize}' : '—')),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildDetailRow('MRP', r.mrp != null ? '₹${r.mrp!.toStringAsFixed(2)}' : '—')),
          Expanded(child: _buildDetailRow('HSN / GST', '${r.hsnCode ?? "—"} / ${r.gstRate ?? 12}%')),
        ],
      ),
      if (r.existingMedicine != null) ...[
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: AppColors.creditGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.creditGreen, size: 16.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Matched in store catalog: ${r.existingMedicine!['name'] ?? ""}',
                  style: TextStyle(fontSize: 11.5.sp, color: AppColors.creditGreen, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildPrescriptionFields(OcrScanResultModel r) {
    return [
      Row(
        children: [
          Expanded(child: _buildDetailRow('Doctor Name', r.doctorName ?? '—', isPrimary: true)),
          Expanded(child: _buildDetailRow('Reg No', r.doctorRegNo ?? '—')),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildDetailRow('Patient Name', r.customerName ?? '—')),
          Expanded(child: _buildDetailRow('Patient Phone', r.customerMobile ?? '—')),
        ],
      ),
    ];
  }

  List<Widget> _buildPurchaseBillFields(OcrScanResultModel r) {
    return [
      Row(
        children: [
          Expanded(child: _buildDetailRow('Invoice Number', r.invoiceNumber ?? '—', isPrimary: true)),
          Expanded(child: _buildDetailRow('Invoice Date', r.invoiceDate ?? '—')),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildDetailRow('Supplier Name', r.supplierName ?? '—')),
          Expanded(child: _buildDetailRow('Supplier GSTIN', r.gstin ?? '—')),
        ],
      ),
    ];
  }

  List<Widget> _buildBatchFields(OcrScanResultModel r) {
    return [
      Row(
        children: [
          Expanded(child: _buildDetailRow('Batch Number', r.batchNumber ?? '—', isPrimary: true)),
          Expanded(child: _buildDetailRow('Expiry Date', r.expiryDate ?? '—')),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildDetailRow('Mfg Date', r.manufacturingDate ?? '—')),
          Expanded(child: _buildDetailRow('Pack MRP', r.mrp != null ? '₹${r.mrp!.toStringAsFixed(2)}' : '—')),
        ],
      ),
      if (r.matchedMedicineName != null || r.candidateMedicine != null)
        _buildDetailRow('Candidate Medicine', r.matchedMedicineName ?? r.candidateMedicine ?? '—'),
    ];
  }

  List<Widget> _buildCustomerFields(OcrScanResultModel r) {
    return [
      _buildDetailRow('Patient / Customer', r.customerName ?? '—', isPrimary: true),
      Row(
        children: [
          Expanded(child: _buildDetailRow('Mobile No', r.customerMobile ?? '—')),
          Expanded(child: _buildDetailRow('Email', r.customerEmail ?? '—')),
        ],
      ),
      if (r.doctorName != null) _buildDetailRow('Consulting Doctor', r.doctorName!),
      if (r.address != null) _buildDetailRow('Address', r.address!),
    ];
  }

  List<Widget> _buildSupplierFields(OcrScanResultModel r) {
    return [
      _buildDetailRow('Distributor Name', r.supplierName ?? '—', isPrimary: true),
      Row(
        children: [
          Expanded(child: _buildDetailRow('GSTIN', r.gstin ?? '—')),
          Expanded(child: _buildDetailRow('Drug License (DL)', r.dlNumber ?? '—')),
        ],
      ),
      Row(
        children: [
          Expanded(child: _buildDetailRow('Contact Phone', r.supplierMobile ?? '—')),
          Expanded(child: _buildDetailRow('Email', r.supplierEmail ?? '—')),
        ],
      ),
    ];
  }

  Widget _buildDetailRow(String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary)),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: isPrimary ? 14.sp : 12.5.sp,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Items Table (for Prescription or Purchase Bill)
  // --------------------------------------------------------------------------
  Widget _buildItemsTable(OcrScanResultModel r) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Extracted Items (${r.items.length})',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Auto-Matched',
                style: TextStyle(fontSize: 11.sp, color: AppColors.primaryEmerald, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...r.items.map((item) {
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.medication_liquid_rounded, size: 16.sp, color: AppColors.primaryEmerald),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.medicineName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: AppColors.textPrimary),
                        ),
                        if (item.batchNumber != null || item.expiryDate != null)
                          Text(
                            'B: ${item.batchNumber ?? "—"} • Exp: ${item.expiryDate ?? "—"}',
                            style: TextStyle(fontSize: 10.5.sp, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Qty: ${item.quantity.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: AppColors.primaryEmerald),
                      ),
                      if (item.purchaseRate != null)
                        Text(
                          'Rate: ₹${item.purchaseRate!.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Raw Text Accordion
  // --------------------------------------------------------------------------
  Widget _buildRawTextAccordion(OcrScanResultModel r) {
    return InkWell(
      onTap: () => setState(() => _showRawText = !_showRawText),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12.r),
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
                    Icon(Icons.text_snippet_rounded, size: 16.sp, color: AppColors.textSecondary),
                    SizedBox(width: 6.w),
                    Text(
                      'OCR Raw Extracted Text',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Icon(
                  _showRawText ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            if (_showRawText) ...[
              SizedBox(height: 8.h),
              SelectableText(
                r.rawText.isNotEmpty ? r.rawText : '(No raw text detected)',
                style: TextStyle(fontSize: 11.sp, fontFamily: 'monospace', color: AppColors.textPrimary),
              ),
              SizedBox(height: 6.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: r.rawText));
                    UniqueSnackbar.showSuccess(context, message: 'Raw OCR text copied');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy Raw Text'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Bottom Action Bar
  // --------------------------------------------------------------------------
  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Obx(() {
        final result = ocrController.scanResult.value;
        final hasResult = result != null;

        if (!hasResult) {
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ocrController.pickFromCamera(),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Capture Rx / Bill'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: const BorderSide(color: AppColors.primaryEmerald),
                    foregroundColor: AppColors.primaryEmerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ocrController.pickFromGallery(),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Upload Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          );
        }

        final docType = result.documentType.toUpperCase();
        String ctaTitle = 'Apply & Use Extracted Data';
        if (docType == 'BILL_PRESCRIPTION') {
          ctaTitle = 'Auto-Fill in POS Sale Bill';
        } else if (docType == 'BILL_PURCHASE') {
          ctaTitle = '📋 Review & Save Purchase';
        } else if (docType == 'MEDICINE') {
          ctaTitle = 'Auto-Fill in Medicine Catalog';
        } else if (docType == 'BATCH') {
          ctaTitle = 'Auto-Fill in Medicine Batch';
        }

        VoidCallback ctaAction;
        if (widget.onResult != null) {
          ctaAction = () {
            final scanResult = result;
            ocrController.clear();
            Navigator.of(context).pop(scanResult);
            widget.onResult!(scanResult);
          };
        } else {
          ctaAction = () {
            final scanResult = result;
            ocrController.clear();
            if (docType == 'BILL_PRESCRIPTION') {
              Navigator.of(context).pop(scanResult);
              MargSaleInvoiceModal.show(context, initialOcrResult: scanResult);
            } else if (docType == 'BILL_PURCHASE') {
              Navigator.of(context).pop(scanResult);
              OcrPurchaseReviewSheet.show(context, ocrResult: scanResult);
            } else if (docType == 'MEDICINE') {
              Navigator.of(context).pop(scanResult);
              AddStockSheet.show(context, initialOcrResult: scanResult);
            } else if (docType == 'BATCH') {
              Navigator.of(context).pop(scanResult);
              AddBatchModal.show(context, initialOcrResult: scanResult);
            } else {
              Navigator.of(context).pop(scanResult);
            }
          };
        }

        return Row(
          children: [
            OutlinedButton(
              onPressed: () => ocrController.clear(),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                side: const BorderSide(color: AppColors.borderLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: AppButton(
                title: ctaTitle,
                onPressed: ctaAction,
              ),
            ),
          ],
        );
      }),
    );
  }
}
