double _ocrParseDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}

double? _ocrParseDoubleNullable(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

int _ocrParseInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? fallback);
  return fallback;
}

int? _ocrParseIntNullable(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? double.tryParse(val)?.toInt();
  return null;
}

enum OcrDocumentType {
  medicine('MEDICINE', 'Medicine Strip / Box', 'Strip, foil or pack details'),
  prescription('BILL_PRESCRIPTION', 'Doctor Prescription', 'Doctor Rx slip with prescribed drugs'),
  purchaseBill('BILL_PURCHASE', 'Purchase Tax Invoice', 'Vendor inward bill with batches & rates'),
  batch('BATCH', 'Batch Stamp / Lot', 'Strip stamp, B.No, Expiry & MRP'),
  customer('CUSTOMER', 'Customer / Patient Slip', 'Patient name, mobile & Rx info'),
  supplier('SUPPLIER', 'Supplier / Visiting Card', 'Distributor visiting card, GSTIN & DL');

  final String apiValue;
  final String label;
  final String description;

  const OcrDocumentType(this.apiValue, this.label, this.description);

  static OcrDocumentType fromString(String val) {
    return OcrDocumentType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == val.toUpperCase(),
      orElse: () => OcrDocumentType.medicine,
    );
  }
}

class OcrCandidateBatchModel {
  final String id;
  final String batchNumber;
  final String expiryDate;
  final int currentQuantity;
  final double mrp;
  final double sellingPrice;

  OcrCandidateBatchModel({
    required this.id,
    required this.batchNumber,
    required this.expiryDate,
    required this.currentQuantity,
    required this.mrp,
    required this.sellingPrice,
  });

  factory OcrCandidateBatchModel.fromJson(Map<String, dynamic> json) {
    return OcrCandidateBatchModel(
      id: json['id']?.toString() ?? '',
      batchNumber: json['batchNumber']?.toString() ?? '',
      expiryDate: json['expiryDate']?.toString() ?? '',
      currentQuantity: _ocrParseInt(json['currentQuantity']),
      mrp: _ocrParseDouble(json['mrp']),
      sellingPrice: _ocrParseDouble(json['sellingPrice']),
    );
  }
}

class OcrMedicineCandidateModel {
  final String id;
  final String name;
  final String? genericName;
  final String? dosageForm;
  final String? strength;
  final double? mrp;
  final List<OcrCandidateBatchModel> batches;

  OcrMedicineCandidateModel({
    required this.id,
    required this.name,
    this.genericName,
    this.dosageForm,
    this.strength,
    this.mrp,
    this.batches = const [],
  });

  factory OcrMedicineCandidateModel.fromJson(Map<String, dynamic> json) {
    final rawBatches = json['batches'] as List? ?? [];
    return OcrMedicineCandidateModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      genericName: json['genericName']?.toString(),
      dosageForm: json['dosageForm']?.toString(),
      strength: json['strength']?.toString(),
      mrp: _ocrParseDoubleNullable(json['mrp']),
      batches: rawBatches
          .whereType<Map<String, dynamic>>()
          .map(OcrCandidateBatchModel.fromJson)
          .toList(),
    );
  }
}

class OcrItemModel {
  final String medicineName;
  final String? dosage;
  final double quantity;
  final double freeQuantity;
  final String? batchNumber;
  final String? expiryDate;
  final double? purchaseRate;
  final double? mrp;
  final double? gstRate;
  final List<OcrMedicineCandidateModel> candidates;
  final Map<String, dynamic>? matchedMedicine;

  OcrItemModel({
    required this.medicineName,
    this.dosage,
    required this.quantity,
    this.freeQuantity = 0.0,
    this.batchNumber,
    this.expiryDate,
    this.purchaseRate,
    this.mrp,
    this.gstRate,
    this.candidates = const [],
    this.matchedMedicine,
  });

  factory OcrItemModel.fromJson(Map<String, dynamic> json) {
    final rawCandidates = json['candidates'] as List? ?? [];
    return OcrItemModel(
      medicineName: json['medicineName']?.toString() ?? json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? json['dosageForm']?.toString(),
      quantity: _ocrParseDouble(json['quantity'], _ocrParseDouble(json['qty'], 1.0)),
      freeQuantity: _ocrParseDouble(json['freeQty'], _ocrParseDouble(json['freeQuantity'])),
      batchNumber: json['batchNumber']?.toString() ?? json['batch']?.toString(),
      expiryDate: json['expiryDate']?.toString() ?? json['expiry']?.toString(),
      purchaseRate: _ocrParseDoubleNullable(json['purchaseRate']) ?? _ocrParseDoubleNullable(json['rate']),
      mrp: _ocrParseDoubleNullable(json['mrp']),
      gstRate: _ocrParseDoubleNullable(json['gstRate']) ??
          _ocrParseDoubleNullable(json['taxRate']) ??
          _ocrParseDoubleNullable(json['taxPercent']),
      candidates: rawCandidates
          .whereType<Map<String, dynamic>>()
          .map(OcrMedicineCandidateModel.fromJson)
          .toList(),
      matchedMedicine: json['matchedMedicine'] as Map<String, dynamic>?,
    );
  }
}

class OcrScanResultModel {
  final String rawText;
  final double confidence;
  final String documentType;
  final Map<String, dynamic> fields;
  final List<OcrItemModel> items;

  OcrScanResultModel({
    required this.rawText,
    required this.confidence,
    required this.documentType,
    required this.fields,
    required this.items,
  });

  factory OcrScanResultModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return OcrScanResultModel(
      rawText: json['rawText']?.toString() ?? '',
      confidence: _ocrParseDouble(json['confidence']),
      documentType: json['documentType']?.toString() ?? 'MEDICINE',
      fields: (json['fields'] as Map<String, dynamic>?) ?? {},
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(OcrItemModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> get extractedFields => fields;

  // --- Convenience Getters for MEDICINE ---
  String? get medicineName => fields['name']?.toString();
  String? get genericName => fields['genericName']?.toString();
  String? get dosageForm => fields['dosageForm']?.toString();
  String? get strength => fields['strength']?.toString();
  String? get scheduleType => fields['scheduleType']?.toString();
  String? get hsnCode => fields['hsnCode']?.toString();
  double? get gstRate => _ocrParseDoubleNullable(fields['gstRate']);
  double? get mrp => _ocrParseDoubleNullable(fields['mrp']);
  int? get packSize => _ocrParseIntNullable(fields['packSize']);
  Map<String, dynamic>? get existingMedicine =>
      fields['existingMedicine'] as Map<String, dynamic>?;

  // --- Convenience Getters for CUSTOMER ---
  String? get customerName =>
      fields['name']?.toString() ??
      fields['customerName']?.toString() ??
      (fields['customer'] is Map ? fields['customer']['name']?.toString() : null);
  String? get customerMobile =>
      fields['mobile']?.toString() ??
      fields['customerPhone']?.toString() ??
      (fields['customer'] is Map ? fields['customer']['mobile']?.toString() : null);
  String? get customerEmail =>
      fields['email']?.toString() ??
      (fields['customer'] is Map ? fields['customer']['email']?.toString() : null);
  String? get doctorName => fields['doctorName']?.toString();
  String? get doctorRegNo => fields['doctorRegNo']?.toString();
  String? get address => fields['address']?.toString();
  Map<String, dynamic>? get existingCustomer =>
      fields['existingCustomer'] as Map<String, dynamic>?;

  // --- Convenience Getters for SUPPLIER ---
  String? get supplierName =>
      fields['supplierName']?.toString() ??
      fields['name']?.toString() ??
      fields['vendorName']?.toString() ??
      (fields['supplier'] is Map ? fields['supplier']['name']?.toString() : null);

  String? get gstin =>
      fields['gstin']?.toString() ??
      fields['gstNo']?.toString() ??
      (fields['supplier'] is Map ? fields['supplier']['gstin']?.toString() : null);

  String? get dlNumber =>
      fields['dlNo']?.toString() ??
      fields['dlNumber']?.toString() ??
      fields['drugLicenseNumber']?.toString() ??
      (fields['supplier'] is Map ? (fields['supplier']['dlNumber']?.toString() ?? fields['supplier']['dlNo']?.toString()) : null);

  String? get supplierMobile =>
      fields['phone']?.toString() ??
      fields['supplierPhone']?.toString() ??
      fields['mobile']?.toString() ??
      (fields['supplier'] is Map ? fields['supplier']['mobile']?.toString() : null);

  String? get supplierEmail =>
      fields['email']?.toString() ??
      fields['supplierEmail']?.toString() ??
      (fields['supplier'] is Map ? fields['supplier']['email']?.toString() : null);

  String? get supplierAddress =>
      fields['address']?.toString() ??
      fields['supplierAddress']?.toString() ??
      fields['vendorAddress']?.toString() ??
      (fields['supplier'] is Map ? fields['supplier']['address']?.toString() : null);

  Map<String, dynamic>? get existingSupplier =>
      (fields['existingSupplier'] ?? fields['matchedSupplier']) as Map<String, dynamic>?;

  // --- Convenience Getters for BATCH ---
  String? get batchNumber => fields['batchNumber']?.toString();
  String? get expiryDate => fields['expiryDate']?.toString();
  String? get manufacturingDate => fields['manufacturingDate']?.toString();
  String? get candidateMedicine => fields['candidateMedicine']?.toString();
  String? get matchedMedicineId => fields['matchedMedicineId']?.toString();
  String? get matchedMedicineName => fields['matchedMedicineName']?.toString();
  List<dynamic> get matchedMedicines => (fields['matchedMedicines'] as List?) ?? [];

  // --- Convenience Getters for BILLS ---
  String? get invoiceNumber => fields['invoiceNumber']?.toString() ?? fields['billNumber']?.toString();
  String? get invoiceDate => fields['invoiceDate']?.toString() ?? fields['billDate']?.toString();
}
