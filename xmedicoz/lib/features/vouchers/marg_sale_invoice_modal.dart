import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/controllers/ledger_controller.dart';
import '../../core/models/master_models.dart';
import '../../core/models/models.dart';
import '../../core/models/ocr_models.dart';
import '../../core/widgets/unique_snackbar.dart';
import '../inventory/controllers/batch_controller.dart';
import '../inventory/controllers/master_data_controller.dart';
import '../inventory/controllers/smart_search_controller.dart';
import '../inventory/widgets/substitute_alert_modal.dart';
import '../sales/controllers/sales_controller.dart';
import '../../core/models/batch_models.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/marg_action_buttons.dart';
import 'widgets/marg_bill_summary_hud.dart';
import 'widgets/marg_cart_list.dart';
import 'widgets/marg_doctor_strip.dart';
import 'widgets/marg_medicine_cockpit_card.dart';
import 'widgets/marg_ocr_prescription_strip.dart';
import 'widgets/marg_patient_switcher.dart';
import 'widgets/marg_payment_chips.dart';
import 'widgets/marg_pos_header_card.dart';
import 'widgets/marg_quantity_row.dart';
import 'widgets/sale_item_draft.dart';

class MargSaleInvoiceModal extends StatefulWidget {
  final OcrScanResultModel? initialOcrResult;

  const MargSaleInvoiceModal({super.key, this.initialOcrResult});

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
      builder: (_) => MargSaleInvoiceModal(initialOcrResult: initialOcrResult),
    );
  }

  @override
  State<MargSaleInvoiceModal> createState() => _MargSaleInvoiceModalState();
}

class _MargSaleInvoiceModalState extends State<MargSaleInvoiceModal> {
  final controller = Get.find<LedgerController>();
  late final MasterDataController masterController;
  late final BatchController batchController;
  late final SalesController salesController;
  late final SmartSearchController smartSearchController;

  bool _isWalkIn = true;
  CustomerModel? _selectedCustomer;

  MedicineModel? _selectedMedicine;
  EligibleBatchModel? _selectedBatch;
  List<EligibleBatchModel> _eligibleBatches = [];
  bool _isLoadingBatches = false;

  final _quantityValue = 1.obs;
  int get _quantity => _quantityValue.value;
  set _quantity(int value) => _quantityValue.value = value;
  final _discountValue = 0.0.obs;
  double get _discountPercent => _discountValue.value;
  set _discountPercent(double value) => _discountValue.value = value;
  int _batchRequest = 0;
  String _paymentModeString = 'UPI';

  final TextEditingController _doctorCtrl = TextEditingController();
  final TextEditingController _doctorRegCtrl = TextEditingController();
  final TextEditingController _patientCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final FocusNode _qtyFocusNode = FocusNode();
  bool _showDoctorDetails = false;

  List<OcrItemModel> _ocrPrescriptionItems = [];
  int _selectedOcrItemIndex = 0;

  final List<SaleItemDraft> _cartItems = [];

  // -- Computed getters --------------------------------------------------------
  double get _unitPrice {
    if (_selectedBatch != null && _selectedBatch!.sellingPrice > 0) {
      return _selectedBatch!.sellingPrice;
    }
    if (_selectedMedicine != null && _selectedMedicine!.sellingPrice > 0) {
      return _selectedMedicine!.sellingPrice;
    }
    return 0.0;
  }

  double get _itemSubtotal => _unitPrice * _quantity;
  double get _discountAmount => _itemSubtotal * (_discountPercent / 100);
  double get _taxableValue => _itemSubtotal - _discountAmount;
  double get _gstRate => _selectedMedicine?.gstRate ?? 0.0;
  double get _gstAmount => _taxableValue * (_gstRate / 100);

  double get _totalSubtotal => _cartItems.isNotEmpty
      ? _cartItems.fold(0.0, (s, i) => s + i.itemSubtotal)
      : _itemSubtotal;

  double get _totalDiscount => _cartItems.isNotEmpty
      ? _cartItems.fold(0.0, (s, i) => s + i.discountAmount)
      : _discountAmount;

  double get _totalTaxable => _cartItems.isNotEmpty
      ? _cartItems.fold(0.0, (s, i) => s + i.taxableValue)
      : _taxableValue;

  double get _totalGst => _cartItems.isNotEmpty
      ? _cartItems.fold(0.0, (s, i) => s + i.gstAmount)
      : _gstAmount;

  double get _grandTotal => _cartItems.isNotEmpty
      ? _cartItems.fold(0.0, (s, i) => s + i.totalAmount)
      : _taxableValue + _gstAmount;

  int get _totalUnitsCount => _cartItems.isNotEmpty
      ? _cartItems.fold(0, (s, i) => s + i.quantity)
      : _quantity;

  // -- Lifecycle ----------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    masterController = Get.isRegistered<MasterDataController>()
        ? Get.find<MasterDataController>()
        : Get.put(MasterDataController());
    batchController = Get.isRegistered<BatchController>()
        ? Get.find<BatchController>()
        : Get.put(BatchController());
    salesController = Get.isRegistered<SalesController>()
        ? Get.find<SalesController>()
        : Get.put(SalesController());
    smartSearchController = Get.isRegistered<SmartSearchController>()
        ? Get.find<SmartSearchController>()
        : Get.put(SmartSearchController());

    if (masterController.customers.isEmpty) {
      masterController.fetchCustomers();
    }
    if (widget.initialOcrResult != null) {
      _applyOcrPrescription(widget.initialOcrResult!);
    }
  }

  @override
  void dispose() {
    _doctorCtrl.dispose();
    _doctorRegCtrl.dispose();
    _patientCtrl.dispose();
    _mobileCtrl.dispose();
    _qtyCtrl.dispose();
    _qtyFocusNode.dispose();
    _quantityValue.close();
    _discountValue.close();
    super.dispose();
  }

  // -- State helpers ---------------------------------------------------------
  void _updateQuantity(int newQty) {
    final maxQty = _selectedBatch?.currentQuantity ?? 9999;
    newQty = newQty.clamp(1, maxQty > 0 ? maxQty : 9999);
    _quantity = newQty;
    final text = '$newQty';
    if (_qtyCtrl.text != text) {
      _qtyCtrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  Future<void> _loadBatchesForMedicine(String medicineId) async {
    final request = ++_batchRequest;
    setState(() => _isLoadingBatches = true);
    final batches = await batchController.getEligibleBatches(medicineId);
    if (mounted &&
        request == _batchRequest &&
        _selectedMedicine?.id == medicineId) {
      setState(() {
        _eligibleBatches = batches;
        _selectedBatch = batches.isNotEmpty ? batches.first : null;
        _isLoadingBatches = false;
        if (_selectedBatch != null &&
            _quantity > _selectedBatch!.currentQuantity) {
          _quantity = _selectedBatch!.currentQuantity > 0 ? 1 : 0;
          _qtyCtrl.text = '$_quantity';
        }
      });
      if (batches.isEmpty && _selectedMedicine != null) {
        _handleOutOfStockSubstitute(_selectedMedicine!);
      }
    }
  }

  Future<void> _handleOutOfStockSubstitute(MedicineModel outOfStockMed) async {
    final subResponse = await smartSearchController.fetchSubstitutes(
      outOfStockMed.id,
      targetMedicineFallback: outOfStockMed,
    );
    if (!mounted || _selectedMedicine?.id != outOfStockMed.id) return;
    if (subResponse != null && subResponse.substitutes.isNotEmpty) {
      SubstituteAlertModal.show(
        context,
        data: subResponse,
        onSwapSelected: (sub) async {
          if (!mounted) return;
          MedicineModel? swapMed = masterController.medicines.firstWhereOrNull(
            (m) => m.id == sub.id,
          );
          swapMed ??= MedicineModel(
            id: sub.id,
            name: sub.name,
            genericName: sub.genericName,
            brand: sub.brand,
            dosageForm: sub.dosageForm,
            strength: 'Standard',
            hsnCode: '3004.90',
            gstRate: 12.0,
            mrp: sub.mrp,
            purchaseRate: sub.mrp * 0.7,
            sellingPrice: sub.sellingPrice,
            reorderLevel: 10,
            prescriptionRequired: false,
            status: 'ACTIVE',
          );
          setState(() {
            _selectedMedicine = swapMed;
            _selectedBatch = null;
          });
          await _loadBatchesForMedicine(swapMed.id);
        },
      );
    } else {
      smartSearchController.logOutofStockDemand(
        medicineId: outOfStockMed.id,
        notes: 'Out of stock at billing counter',
      );
    }
  }

  Future<void> _applyOcrPrescription(OcrScanResultModel r) async {
    if (r.doctorName != null && r.doctorName!.isNotEmpty) {
      _doctorCtrl.text = r.doctorName!;
      _showDoctorDetails = true;
    }
    if (r.doctorRegNo != null && r.doctorRegNo!.isNotEmpty) {
      _doctorRegCtrl.text = r.doctorRegNo!;
      _showDoctorDetails = true;
    }
    if (r.customerName != null && r.customerName!.isNotEmpty) {
      _patientCtrl.text = r.customerName!;
    }
    if (r.customerMobile != null && r.customerMobile!.isNotEmpty) {
      _mobileCtrl.text = r.customerMobile!;
    }

    final mobile = r.customerMobile?.trim();
    if (mobile != null && mobile.isNotEmpty) {
      CustomerModel? matched = masterController.customers.firstWhereOrNull(
        (c) => c.mobile == mobile,
      );
      if (matched == null) {
        final patientName =
            (r.customerName != null && r.customerName!.trim().isNotEmpty)
            ? r.customerName!.trim()
            : 'Rx Patient';
        matched = await masterController.registerCustomer({
          'name': patientName,
          'mobile': mobile,
          'customerType': 'REGULAR',
          'isPermanent': false,
        });
      }
      if (matched != null) {
        setState(() {
          _selectedCustomer = matched;
          _isWalkIn = false;
        });
      }
    }

    if (r.items.isNotEmpty) {
      _ocrPrescriptionItems = List.from(r.items);
      _selectOcrItem(0);

      final List<SaleItemDraft> autoLoadedItems = [];
      for (final ocrItem in r.items) {
        final med = masterController.medicines.firstWhereOrNull(
          (m) =>
              m.name.toLowerCase().contains(
                ocrItem.medicineName.toLowerCase(),
              ) ||
              ocrItem.medicineName.toLowerCase().contains(m.name.toLowerCase()),
        );
        if (med != null) {
          try {
            final batches = await batchController.getEligibleBatches(med.id);
            if (batches.isNotEmpty) {
              final fefoBatch = batches.first;
              final reqQty = ocrItem.quantity.toInt().clamp(
                1,
                fefoBatch.currentQuantity > 0 ? fefoBatch.currentQuantity : 1,
              );
              autoLoadedItems.add(
                SaleItemDraft(
                  medicine: med,
                  batch: fefoBatch,
                  quantity: reqQty,
                  discountPercent: 0.0,
                ),
              );
            }
          } catch (_) {}
        }
      }

      if (autoLoadedItems.isNotEmpty && mounted) {
        setState(() {
          _cartItems.clear();
          _cartItems.addAll(autoLoadedItems);
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UniqueSnackbar.showSuccess(
          context,
          title: 'Zero-Touch Prescription Loaded',
          message:
              '${_cartItems.length} items matched with FEFO batches & patient attached. Ready to bill (F2)!',
        );
      }
    });
  }

  void _selectOcrItem(int index) {
    if (index < 0 || index >= _ocrPrescriptionItems.length) return;
    _selectedOcrItemIndex = index;
    final item = _ocrPrescriptionItems[index];
    final matched = masterController.medicines.firstWhereOrNull(
      (m) =>
          m.name.toLowerCase().contains(item.medicineName.toLowerCase()) ||
          item.medicineName.toLowerCase().contains(m.name.toLowerCase()),
    );
    if (matched != null) {
      setState(() {
        _selectedMedicine = matched;
        _quantity = item.quantity.toInt().clamp(1, 9999);
        _qtyCtrl.text = '$_quantity';
      });
      _loadBatchesForMedicine(matched.id);
    } else {
      setState(() {
        _quantity = item.quantity.toInt().clamp(1, 9999);
        _qtyCtrl.text = '$_quantity';
      });
    }
  }

  void _addItemToCart() {
    if (_isLoadingBatches || salesController.isSubmitting.value) return;
    final manualVal = int.tryParse(_qtyCtrl.text.trim());
    _quantity = manualVal ?? 0;

    if (_selectedMedicine == null) {
      UniqueSnackbar.showError(
        context,
        title: 'Medicine Required',
        message: 'Please select a medicine formulation to add.',
      );
      return;
    }
    if (_selectedBatch == null) {
      UniqueSnackbar.showError(
        context,
        title: 'Batch Required',
        message: 'Please select an active in-stock batch.',
      );
      return;
    }
    if (_quantity <= 0) {
      UniqueSnackbar.showError(
        context,
        title: 'Invalid Quantity',
        message: 'Quantity must be at least 1 unit.',
      );
      return;
    }
    if (_quantity > _selectedBatch!.currentQuantity) {
      UniqueSnackbar.showError(
        context,
        title: 'Insufficient Stock',
        message:
            'Selected batch only has ${_selectedBatch!.currentQuantity} units available.',
      );
      return;
    }

    final existingIndex = _cartItems.indexWhere(
      (item) =>
          item.medicine.id == _selectedMedicine!.id &&
          item.batch.id == _selectedBatch!.id,
    );

    setState(() {
      if (existingIndex >= 0) {
        final current = _cartItems[existingIndex];
        final newQty = current.quantity + _quantity;
        if (newQty > _selectedBatch!.currentQuantity) {
          current.quantity = _selectedBatch!.currentQuantity;
          UniqueSnackbar.showError(
            context,
            title: 'Stock Limit Reached',
            message:
                'Cannot exceed total batch stock of ${_selectedBatch!.currentQuantity}.',
          );
        } else {
          current.quantity = newQty;
        }
        current.discountPercent = _discountPercent;
      } else {
        _cartItems.add(
          SaleItemDraft(
            medicine: _selectedMedicine!,
            batch: _selectedBatch!,
            quantity: _quantity,
            discountPercent: _discountPercent,
          ),
        );
      }
    });

    HapticFeedback.mediumImpact();
    UniqueSnackbar.showSuccess(
      context,
      title: 'Added to Bill',
      message:
          '${_selectedMedicine!.name} (${_quantity}x) added. Total ${_cartItems.length} items in cart.',
    );
  }

  void _removeItemFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      final removed = _cartItems.removeAt(index);
      setState(() {});
      UniqueSnackbar.showSuccess(
        context,
        title: 'Item Removed',
        message: '${removed.medicine.name} removed from bill.',
      );
    }
  }

  Future<void> _completeBill({bool printReceipt = false}) async {
    if (salesController.isSubmitting.value) return;
    if (_cartItems.isEmpty) {
      if (_isLoadingBatches) return;
      final manualVal = int.tryParse(_qtyCtrl.text.trim());
      _quantity = manualVal ?? 0;

      if (_selectedMedicine == null) {
        UniqueSnackbar.showError(
          context,
          title: 'Medicine Required',
          message: 'Please select a medicine formulation to dispense.',
        );
        return;
      }
      if (_selectedBatch == null) {
        UniqueSnackbar.showError(
          context,
          title: 'Batch Required',
          message: 'No eligible batch selected with in-stock inventory.',
        );
        return;
      }
      if (_quantity <= 0) {
        UniqueSnackbar.showError(
          context,
          title: 'Invalid Quantity',
          message: 'Quantity must be at least 1 unit.',
        );
        return;
      }
      if (_quantity > _selectedBatch!.currentQuantity) {
        UniqueSnackbar.showError(
          context,
          title: 'Insufficient Stock',
          message:
              'Selected batch only has ${_selectedBatch!.currentQuantity} units remaining.',
        );
        return;
      }
      _cartItems.add(
        SaleItemDraft(
          medicine: _selectedMedicine!,
          batch: _selectedBatch!,
          quantity: _quantity,
          discountPercent: _discountPercent,
        ),
      );
    }

    if (_paymentModeString == 'CREDIT') {
      if (_isWalkIn || _selectedCustomer == null) {
        UniqueSnackbar.showError(
          context,
          title: 'Customer Required for Credit',
          message:
              'Credit billing requires selecting a registered customer to track ledger debt.',
        );
        return;
      }
    } else if (!_isWalkIn && _selectedCustomer == null) {
      UniqueSnackbar.showError(
        context,
        title: 'Customer Required',
        message: 'Please select a registered customer or use walk-in billing.',
      );
      return;
    }

    final customerName = _isWalkIn
        ? (_patientCtrl.text.trim().isEmpty
              ? 'Walk-in Retail Patient'
              : _patientCtrl.text.trim())
        : _selectedCustomer!.name;
    final customerPhone = _isWalkIn
        ? _mobileCtrl.text.trim()
        : _selectedCustomer!.mobile;
    final doctorName = _doctorCtrl.text.trim();
    final doctorRegNo = _doctorRegCtrl.text.trim();

    final payload = {
      if (!_isWalkIn && _selectedCustomer != null)
        'customerId': _selectedCustomer!.id,
      'customerName': customerName,
      if (customerPhone.isNotEmpty) 'customerPhone': customerPhone,
      if (doctorName.isNotEmpty) 'doctorName': doctorName,
      if (doctorRegNo.isNotEmpty) 'doctorRegNo': doctorRegNo,
      'patientName': customerName,
      'items': _cartItems.map((item) => item.toApiJson()).toList(),
      'payments': _paymentModeString == 'CREDIT'
          ? []
          : [
              {'paymentMode': _paymentModeString, 'amount': _grandTotal},
            ],
      'subtotal': _totalSubtotal,
      'taxableAmount': _totalTaxable,
      'discountAmount': _totalDiscount,
      'taxAmount': _totalGst,
      'totalAmount': _grandTotal,
      'notes': _paymentModeString == 'CREDIT'
          ? 'POS Credit Bill'
          : 'POS Multi-Item Counter Checkout',
    };

    final createdInvoice = await salesController.checkoutPOS(payload);

    if (createdInvoice != null && mounted) {
      if (_paymentModeString == 'CREDIT' && _selectedCustomer != null) {
        final newBalance =
            _selectedCustomer!.currentBalance + createdInvoice.totalAmount;
        try {
          await masterController.updateCustomer(_selectedCustomer!.id, {
            'currentBalance': newBalance,
          });
        } catch (_) {}
      }

      final newTx = TransactionModel(
        id: createdInvoice.id,
        invoiceNo: createdInvoice.invoiceNumber,
        partyName: customerName,
        date: createdInvoice.invoiceDate ?? DateTime.now(),
        amount: createdInvoice.totalAmount,
        type: TransactionType.sale,
        paymentMode: _paymentModeString == 'CREDIT'
            ? PaymentMode.credit
            : (_paymentModeString == 'CASH'
                  ? PaymentMode.cash
                  : PaymentMode.onlineUpi),
        itemsCount: _totalUnitsCount,
        notes:
            'Rx Sale POS � ${_cartItems.length} items ($_totalUnitsCount units)${_paymentModeString == 'CREDIT' ? ' � [CREDIT]' : ''}',
        doctorName: _doctorCtrl.text.trim(),
        patientName: customerName,
      );
      controller.addTransaction(newTx);

      batchController.refreshAll();
      masterController.fetchMedicines();
      masterController.fetchCustomers();

      if (!mounted) return;
      Navigator.of(context).pop();

      UniqueSnackbar.showSuccess(
        context,
        title: _paymentModeString == 'CREDIT'
            ? 'Credit Bill Recorded'
            : (printReceipt
                  ? 'Thermal Print Dispatched'
                  : 'Rx Invoice Generated'),
        message: _paymentModeString == 'CREDIT'
            ? 'Rx Bill ${createdInvoice.invoiceNumber} (${_cartItems.length} items) recorded as UNPAID. Customer debt updated!'
            : (printReceipt
                  ? 'Printing Rx Cash Memo ${createdInvoice.invoiceNumber} on Bluetooth ESC/POS printer...'
                  : 'Counter POS Invoice ${createdInvoice.invoiceNumber} (${_cartItems.length} items) recorded atomically & stock deducted!'),
      );
    }
  }

  // -- Build --------------------------------------------------------------------
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
        child: Column(
          children: [
            // Drag Handle
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

            // 1. Pinned POS Header
            MargPosHeaderCard(
              onOcrScanned: (result) => _applyOcrPrescription(result),
            ),
            SizedBox(height: 10.h),

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
                  // 2. Doctor Strip
                  MargDoctorStrip(
                    doctorCtrl: _doctorCtrl,
                    doctorRegCtrl: _doctorRegCtrl,
                    showDoctorDetails: _showDoctorDetails,
                    onToggleShow: () =>
                        setState(() => _showDoctorDetails = true),
                    onClear: () => setState(() {
                      _showDoctorDetails = false;
                      _doctorCtrl.clear();
                      _doctorRegCtrl.clear();
                    }),
                  ),
                  SizedBox(height: 8.h),

                  // 3. Patient Switcher
                  MargPatientSwitcher(
                    isWalkIn: _isWalkIn,
                    selectedCustomer: _selectedCustomer,
                    patientCtrl: _patientCtrl,
                    mobileCtrl: _mobileCtrl,
                    masterController: masterController,
                    onToggle: (val) => setState(() => _isWalkIn = val),
                    onCustomerSelected: (val) => setState(() {
                      _selectedCustomer = val;
                      _patientCtrl.text = val.name;
                      if (val.mobile.isNotEmpty)
                        _mobileCtrl.text = val.mobile;
                    }),
                  ),
                  SizedBox(height: 10.h),

                  // 4. OCR Prescription Strip
                  MargOcrPrescriptionStrip(
                    ocrItems: _ocrPrescriptionItems,
                    selectedIndex: _selectedOcrItemIndex,
                    onItemSelected: _selectOcrItem,
                  ),

                  // 5. Medicine Cockpit
                  MargMedicineCockpitCard(
                    selectedMedicine: _selectedMedicine,
                    selectedBatch: _selectedBatch,
                    eligibleBatches: _eligibleBatches,
                    isLoadingBatches: _isLoadingBatches,
                    masterController: masterController,
                    smartSearchController: smartSearchController,
                    onMedicineChanged: (val) {
                      setState(() {
                        _selectedMedicine = val;
                        _selectedBatch = null;
                      });
                      if (val != null) _loadBatchesForMedicine(val.id);
                    },
                    onBatchChanged: (val) => setState(() {
                      _selectedBatch = val;
                      if (val != null &&
                          _quantity > val.currentQuantity) {
                        _quantity = val.currentQuantity > 0 ? 1 : 0;
                        _qtyCtrl.text = '$_quantity';
                      }
                    }),
                    onMedicineFocusReady: () {
                      if (mounted) {
                        _qtyFocusNode.requestFocus();
                        _qtyCtrl.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _qtyCtrl.text.length,
                        );
                      }
                    },
                  ),
                  SizedBox(height: 10.h),

                  // 6. Quantity & Discount Row
                  Obx(
                    () => MargQuantityRow(
                      quantity: _quantity,
                      discountPercent: _discountPercent,
                      maxQty: _selectedBatch?.currentQuantity ?? 9999,
                      qtyCtrl: _qtyCtrl,
                      qtyFocusNode: _qtyFocusNode,
                      onQuantityChanged: _updateQuantity,
                      onQuantityTyped: (text) =>
                          _quantity = int.tryParse(text) ?? 0,
                      onDiscountChanged: (d) => _discountPercent = d,
                      onAddToCart: _addItemToCart,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // 7. Add to cart button
                  InkWell(
                    onTap: _addItemToCart,
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 9.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.primaryEmerald.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_shopping_cart_rounded,
                            size: 16.sp,
                            color: AppColors.primaryEmerald,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '+ Add This Medicine to Bill',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 8. Cart List
                  MargCartList(
                    cartItems: _cartItems,
                    totalUnitsCount: _cartItems.fold(
                      0,
                      (sum, item) => sum + item.quantity,
                    ),
                    onRemoveItem: _removeItemFromCart,
                  ),
                  SizedBox(height: 10.h),

                  // 9. Payment Chips
                  MargPaymentChips(
                    selectedMode: _paymentModeString,
                    isWalkIn: _isWalkIn,
                    selectedCustomer: _selectedCustomer,
                    customerChoices: masterController.customerChoices,
                    onModeChanged: (
                      mode, {
                      forceRegistered = false,
                      firstCustomer,
                    }) {
                      setState(() {
                        _paymentModeString = mode;
                        if (forceRegistered) {
                          _isWalkIn = false;
                          if (_selectedCustomer == null &&
                              firstCustomer != null) {
                            _selectedCustomer = firstCustomer;
                          }
                        }
                      });
                    },
                  ),
                  SizedBox(height: 12.h),

                  // 10. Bill Summary HUD
                  Obx(() {
                    _quantityValue.value;
                    _discountValue.value;
                    return MargBillSummaryHud(
                      itemCount: _cartItems.isEmpty ? 1 : _cartItems.length,
                      totalUnits: _totalUnitsCount,
                      totalSubtotal: _totalSubtotal,
                      totalDiscount: _totalDiscount,
                      totalGst: _totalGst,
                      grandTotal: _grandTotal,
                      paymentMode: _paymentModeString,
                    );
                  }),
                  SizedBox(height: 14.h),

                  // 11. Action Buttons
                  Obx(
                    () => MargActionButtons(
                      isSubmitting: salesController.isSubmitting.value,
                      paymentMode: _paymentModeString,
                      onPrint: () => _completeBill(printReceipt: true),
                      onComplete: () => _completeBill(printReceipt: false),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
