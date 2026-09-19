import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/ocr_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../../ocr/widgets/ocr_scanner_modal.dart';
import '../../ocr/controllers/ocr_controller.dart';
import '../controllers/purchases_controller.dart';
import 'purchase_success_modal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Editable draft for a single OCR line item
// ─────────────────────────────────────────────────────────────────────────────
class _ItemDraft {
  final TextEditingController nameCtrl;
  final TextEditingController batchCtrl;
  final TextEditingController expiryCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController freeQtyCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController mrpCtrl;
  final TextEditingController taxCtrl;
  final String? matchedMedicineId;

  _ItemDraft({
    String name = '',
    String batch = '',
    String expiry = '',
    String qty = '1',
    String freeQty = '0',
    String rate = '0.00',
    String mrp = '0.00',
    String tax = '12',
    this.matchedMedicineId,
  }) : nameCtrl = TextEditingController(text: name),
       batchCtrl = TextEditingController(text: batch),
       expiryCtrl = TextEditingController(text: expiry),
       qtyCtrl = TextEditingController(text: qty),
       freeQtyCtrl = TextEditingController(text: freeQty),
       rateCtrl = TextEditingController(text: rate),
       mrpCtrl = TextEditingController(text: mrp),
       taxCtrl = TextEditingController(text: tax);

  double get quantity => double.tryParse(qtyCtrl.text.trim()) ?? 0;
  double get freeQuantity => double.tryParse(freeQtyCtrl.text.trim()) ?? 0;
  double get purchaseRate => double.tryParse(rateCtrl.text.trim()) ?? 0;
  double get mrpVal => double.tryParse(mrpCtrl.text.trim()) ?? 0;
  double get taxRate => double.tryParse(taxCtrl.text.trim()) ?? 12;
  double get lineTotal => quantity * purchaseRate * (1 + taxRate / 100);

  void dispose() {
    nameCtrl.dispose();
    batchCtrl.dispose();
    expiryCtrl.dispose();
    qtyCtrl.dispose();
    freeQtyCtrl.dispose();
    rateCtrl.dispose();
    mrpCtrl.dispose();
    taxCtrl.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OcrPurchaseReviewSheet
// ─────────────────────────────────────────────────────────────────────────────
class OcrPurchaseReviewSheet extends StatefulWidget {
  final OcrScanResultModel? ocrResult;
  const OcrPurchaseReviewSheet({super.key, this.ocrResult});

  static void show(
    BuildContext context, {
    OcrScanResultModel? ocrResult,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OcrPurchaseReviewSheet(ocrResult: ocrResult),
    );
  }

  @override
  State<OcrPurchaseReviewSheet> createState() => _OcrPurchaseReviewSheetState();
}

class _OcrPurchaseReviewSheetState extends State<OcrPurchaseReviewSheet>
    with SingleTickerProviderStateMixin {
  late final PurchasesController _ctrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  // Supplier
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _gstinCtrl = TextEditingController();
  final TextEditingController _dlCtrl = TextEditingController();
  final TextEditingController _termsCtrl = TextEditingController(text: '30');

  // Invoice
  final TextEditingController _invoiceNoCtrl = TextEditingController();
  final TextEditingController _invoiceDateCtrl = TextEditingController();

  final List<_ItemDraft> _items = [];
  bool _supplierExpanded = true;

  final _currFmt = NumberFormat('#,##,##0.00', 'en_IN');
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _ctrl = Get.isRegistered<PurchasesController>()
        ? Get.find<PurchasesController>()
        : Get.put(PurchasesController());
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    if (widget.ocrResult != null) {
      _populate(widget.ocrResult!);
    } else {
      _items.add(_ItemDraft());
      _invoiceDateCtrl.text = _dateFmt.format(DateTime.now());
    }
  }

  String _ymd(String raw) {
    if (raw.isEmpty) return '';
    if (raw.contains('T')) raw = raw.split('T')[0];
    return raw;
  }

  void _populate(OcrScanResultModel r) {
    for (final i in _items) {
      i.dispose();
    }
    _items.clear();

    final sup = r.fields['supplier'] as Map<String, dynamic>? ?? {};
    _nameCtrl.text = sup['name']?.toString() ?? r.supplierName ?? '';
    _mobileCtrl.text = sup['mobile']?.toString() ?? r.supplierMobile ?? '';
    _gstinCtrl.text = sup['gstin']?.toString() ?? r.gstin ?? '';
    _dlCtrl.text = sup['dlNumber']?.toString() ?? r.dlNumber ?? '';
    _termsCtrl.text = (sup['paymentTermsDays'] ?? 30).toString();
    _invoiceNoCtrl.text = r.invoiceNumber ?? '';
    _invoiceDateCtrl.text = _ymd(r.invoiceDate ?? '');

    for (final item in r.items) {
      _items.add(
        _ItemDraft(
          name: item.medicineName,
          batch: item.batchNumber ?? '',
          expiry: _ymd(item.expiryDate ?? ''),
          qty: item.quantity.toStringAsFixed(0),
          freeQty: item.freeQuantity.toStringAsFixed(0),
          rate: item.purchaseRate?.toStringAsFixed(2) ?? '0.00',
          mrp: item.mrp?.toStringAsFixed(2) ?? '0.00',
          tax: (item.gstRate ?? 12).toStringAsFixed(0),
          matchedMedicineId: item.matchedMedicine?['id']?.toString(),
        ),
      );
    }
    if (_items.isEmpty) _items.add(_ItemDraft());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _gstinCtrl.dispose();
    _dlCtrl.dispose();
    _termsCtrl.dispose();
    _invoiceNoCtrl.dispose();
    _invoiceDateCtrl.dispose();
    for (final i in _items) { i.dispose(); }
    super.dispose();
  }

  double get _grandTotal => _items.fold(0.0, (s, i) => s + i.lineTotal);

  Future<void> _pickDate() async {
    DateTime init = DateTime.now();
    try {
      init = DateTime.parse(_invoiceDateCtrl.text);
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _invoiceDateCtrl.text = _dateFmt.format(picked));
    }
  }

  void _addItem() => setState(() => _items.add(_ItemDraft()));
  void _removeItem(int i) {
    if (_items.length <= 1) return;
    setState(() {
      _items[i].dispose();
      _items.removeAt(i);
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Validation',
        message: 'Supplier name required',
      );
      return;
    }
    if (_invoiceNoCtrl.text.trim().isEmpty) {
      UniqueSnackbar.showWarning(
        context,
        title: 'Validation',
        message: 'Invoice number required',
      );
      return;
    }

    final List<Map<String, dynamic>> payload = [];
    for (int i = 0; i < _items.length; i++) {
      final d = _items[i];
      final name = d.nameCtrl.text.trim();
      if (name.isEmpty) {
        UniqueSnackbar.showWarning(
          context,
          title: 'Validation',
          message: 'Medicine name required for item ${i + 1}',
        );
        return;
      }
      final expiry = d.expiryCtrl.text.trim().isEmpty
          ? _dateFmt.format(DateTime.now().add(const Duration(days: 730)))
          : d.expiryCtrl.text.trim();
      final item = <String, dynamic>{
        'medicineName': name,
        'batchNumber': d.batchCtrl.text.trim().isEmpty
            ? 'BATCH-${i + 1}'
            : d.batchCtrl.text.trim(),
        'expiryDate': expiry,
        'quantity': d.quantity.toInt(),
        'freeQuantity': d.freeQuantity.toInt(),
        'purchaseRate': d.purchaseRate,
        'mrp': d.mrpVal,
        'taxRate': d.taxRate,
      };
      if (d.matchedMedicineId?.isNotEmpty == true) {
        item['medicineId'] = d.matchedMedicineId;
      }
      payload.add(item);
    }

    final terms = int.tryParse(_termsCtrl.text.trim()) ?? 30;
    final invDate = _invoiceDateCtrl.text.trim().isEmpty
        ? _dateFmt.format(DateTime.now())
        : _invoiceDateCtrl.text.trim();

    final invoice = await _ctrl.createOcrPurchaseInvoice(
      supplier: {
        'name': _nameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'gstin': _gstinCtrl.text.trim(),
        'dlNumber': _dlCtrl.text.trim(),
        'paymentTermsDays': terms,
      },
      invoiceNumber: _invoiceNoCtrl.text.trim(),
      invoiceDate: invDate,
      paymentTermsDays: terms,
      items: payload,
    );
    if (invoice != null && mounted) {
      if (Get.isRegistered<OcrController>()) {
        Get.find<OcrController>().clear();
      }
      final nav = Navigator.of(context);
      nav.pop();
      if (nav.context.mounted) {
        PurchaseSuccessModal.show(
          nav.context,
          invoice: invoice,
          invoiceNumber: _invoiceNoCtrl.text.trim(),
          supplierName: _nameCtrl.text.trim(),
          totalAmount: invoice.totalAmount > 0 ? invoice.totalAmount : _grandTotal,
          itemCount: payload.length,
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        height: 0.93.sh,
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            _handle(),
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  14.w,
                  0,
                  14.w,
                  MediaQuery.viewInsetsOf(context).bottom + 24.h,
                ),
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_confidenceBadge() != null) ...[
                      SizedBox(height: 10.h),
                      _confidenceBadge()!,
                    ],
                    SizedBox(height: 12.h),
                    _supplierSection(),
                    SizedBox(height: 12.h),
                    _invoiceSection(),
                    SizedBox(height: 12.h),
                    _itemsSection(),
                    SizedBox(height: 12.h),
                    _totalCard(),
                    SizedBox(height: 16.h),
                    _bottomBar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Padding(
    padding: EdgeInsets.only(top: 10.h, bottom: 4.h),
    child: Center(
      child: Container(
        width: 40.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: AppColors.borderMedium,
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    ),
  );

  Widget _header() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.clinicalCyan],
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            widget.ocrResult != null
                ? Icons.rate_review_rounded
                : Icons.inventory_2_rounded,
            color: AppColors.white,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.ocrResult != null
                    ? 'Review Scanned Purchase'
                    : 'Stockist Purchase Inward',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.ocrResult != null
                    ? 'Verify OCR items & save inward'
                    : 'Enter distributor bill & batch stock',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Fast Scan Button in Header
        InkWell(
          onTap: () async {
            final result = await OcrScannerModal.show(
              context,
              initialType: OcrDocumentType.purchaseBill,
              onResult: (_) {},
            );
            if (result != null && mounted) {
              setState(() {
                _populate(result);
              });
            }
          },
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.primaryEmerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.primaryEmerald.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.document_scanner_rounded,
                  size: 14.sp,
                  color: AppColors.primaryEmerald,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Scan Bill',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryEmerald,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 6.w),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );

  Widget? _confidenceBadge() {
    if (widget.ocrResult == null) return null;
    final pct = (widget.ocrResult!.confidence * 100).toStringAsFixed(0);
    final count = widget.ocrResult!.items.length;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.document_scanner_rounded,
            color: AppColors.primaryBlue,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'OCR extracted $count items · $pct% confidence. Review all fields before saving.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
    bool collapsible = false,
    bool expanded = true,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.borderSubtle.withValues(alpha: 0.5),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: collapsible ? onToggle : null,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primaryEmerald, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (collapsible)
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                      size: 20.sp,
                    ),
                ],
              ),
            ),
          ),
          if (!collapsible || expanded) ...[
            Divider(height: 1, color: AppColors.borderSubtle),
            Padding(padding: EdgeInsets.all(14.r), child: child),
          ],
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    TextInputType kb = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffix,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      SizedBox(height: 4.h),
      TextFormField(
        controller: ctrl,
        keyboardType: kb,
        readOnly: readOnly,
        onTap: onTap,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint ?? label,
          hintStyle: AppTypography.bodySmall.copyWith(
            color: AppColors.textDisabled,
          ),
          filled: true,
          fillColor: AppColors.bgInput,
          suffixIcon: suffix,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 10.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(
              color: AppColors.primaryEmerald,
              width: 1.5,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _supplierSection() => _card(
    title: 'Supplier',
    icon: Icons.business_rounded,
    collapsible: true,
    expanded: _supplierExpanded,
    onToggle: () => setState(() => _supplierExpanded = !_supplierExpanded),
    child: Column(
      children: [
        _field(
          _nameCtrl,
          'Supplier Name *',
          hint: 'e.g. Balaji Pharma Distributors',
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _field(_mobileCtrl, 'Mobile', kb: TextInputType.phone),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _field(
                _termsCtrl,
                'Payment Terms (days)',
                kb: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(child: _field(_gstinCtrl, 'GSTIN')),
            SizedBox(width: 10.w),
            Expanded(child: _field(_dlCtrl, 'DL Number')),
          ],
        ),
      ],
    ),
  );

  Widget _invoiceSection() => _card(
    title: 'Invoice Details',
    icon: Icons.receipt_long_rounded,
    child: Row(
      children: [
        Expanded(
          child: _field(_invoiceNoCtrl, 'Invoice No. *', hint: 'INV-2024-XXXX'),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _field(
            _invoiceDateCtrl,
            'Invoice Date',
            hint: 'YYYY-MM-DD',
            readOnly: true,
            onTap: _pickDate,
            suffix: Icon(
              Icons.calendar_today_rounded,
              size: 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _itemsSection() => _card(
    title: 'Items (${_items.length})',
    icon: Icons.inventory_2_rounded,
    child: Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (_, idx2) =>
              Divider(height: 18.h, color: AppColors.borderSubtle),
          itemBuilder: (_, i) => _itemRow(i),
        ),
        SizedBox(height: 12.h),
        InkWell(
          onTap: _addItem,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primaryEmerald.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primaryEmerald,
                  size: 18.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Add Item',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primaryEmerald,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _itemRow(int idx) {
    final d = _items[idx];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22.w,
              height: 22.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${idx + 1}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primaryBlue,
                  fontSize: 10.sp,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: d.nameCtrl,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Medicine name',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ),
            if (_items.length > 1)
              GestureDetector(
                onTap: () => _removeItem(idx),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.debitRose,
                  size: 18.sp,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(child: _miniField(d.batchCtrl, 'Batch No.')),
            SizedBox(width: 8.w),
            Expanded(child: _miniField(d.expiryCtrl, 'Expiry YYYY-MM-DD')),
          ],
        ),
        SizedBox(height: 6.h),
        Row(
          children: [
            _numField(d.qtyCtrl, 'Qty', flex: 1),
            SizedBox(width: 5.w),
            _numField(d.freeQtyCtrl, 'Free', flex: 1),
            SizedBox(width: 5.w),
            _numField(d.rateCtrl, 'Rate ₹', flex: 2),
            SizedBox(width: 5.w),
            _numField(d.mrpCtrl, 'MRP ₹', flex: 2),
            SizedBox(width: 5.w),
            _numField(d.taxCtrl, 'GST%', flex: 1),
          ],
        ),
      ],
    );
  }

  Widget _miniField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.labelSmall.copyWith(
        color: AppColors.textDisabled,
      ),
      filled: true,
      fillColor: AppColors.bgInput,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: AppColors.primaryEmerald),
      ),
    ),
  );

  Widget _numField(
    TextEditingController ctrl,
    String label, {
    int flex = 1,
  }) => Expanded(
    flex: flex,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 9.sp,
          ),
        ),
        SizedBox(height: 2.h),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgInput,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 8.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.primaryEmerald),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _totalCard() => Container(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primaryEmerald, AppColors.primaryTeal],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14.r),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grand Total (incl. GST)',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.85),
              ),
            ),
            Text(
              '${_items.length} items',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        Text(
          '₹${_currFmt.format(_grandTotal)}',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _bottomBar() => Container(
    padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 24.h),
    decoration: BoxDecoration(
      color: AppColors.bgSurface,
      border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      boxShadow: [
        BoxShadow(
          color: AppColors.borderSubtle.withValues(alpha: 0.6),
          blurRadius: 10,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              side: const BorderSide(color: AppColors.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Cancel',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: Obx(
            () => AppButton(
              title: '💾  Save Purchase',
              isLoading: _ctrl.isSubmitting.value,
              onPressed: _ctrl.isSubmitting.value ? null : _save,
            ),
          ),
        ),
      ],
    ),
  );
}
