import 'master_models.dart';

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? 0;
  return 0;
}

class BatchModel {
  final String id;
  final String medicineId;
  final String batchNumber;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;
  final double mrp;
  final double purchaseRate;
  final double sellingPrice;
  final int currentQuantity;
  final String status;
  final BatchMedicineInfo? medicine;

  BatchModel({
    required this.id,
    required this.medicineId,
    required this.batchNumber,
    this.manufacturingDate,
    this.expiryDate,
    required this.mrp,
    required this.purchaseRate,
    required this.sellingPrice,
    required this.currentQuantity,
    required this.status,
    this.medicine,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] ?? '',
      medicineId: json['medicineId'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      manufacturingDate: json['manufacturingDate'] != null
          ? DateTime.tryParse(json['manufacturingDate'])
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'])
          : null,
      mrp: _parseDouble(json['mrp']),
      purchaseRate: _parseDouble(json['purchaseRate']),
      sellingPrice: _parseDouble(json['sellingPrice']),
      currentQuantity: _parseInt(json['currentQuantity']),
      status: json['status'] ?? 'ACTIVE',
      medicine: json['medicine'] != null
          ? BatchMedicineInfo.fromJson(json['medicine'])
          : null,
    );
  }

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  int get daysUntilExpiry => expiryDate != null
      ? expiryDate!.difference(DateTime.now()).inDays
      : 9999;
}

class BatchMedicineInfo {
  final String id;
  final String name;
  final String? genericName;
  final String? brand;
  final String? dosageForm;
  final UnitLookupModel? unit;

  BatchMedicineInfo({
    required this.id,
    required this.name,
    this.genericName,
    this.brand,
    this.dosageForm,
    this.unit,
  });

  factory BatchMedicineInfo.fromJson(Map<String, dynamic> json) {
    return BatchMedicineInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      genericName: json['genericName'],
      brand: json['brand'],
      dosageForm: json['dosageForm'],
      unit: json['unit'] != null ? UnitLookupModel.fromJson(json['unit']) : null,
    );
  }
}

class EligibleBatchModel {
  final String id;
  final String batchNumber;
  final DateTime? expiryDate;
  final double mrp;
  final double sellingPrice;
  final int currentQuantity;
  final String medicineName;
  final String? genericName;

  EligibleBatchModel({
    required this.id,
    required this.batchNumber,
    this.expiryDate,
    required this.mrp,
    required this.sellingPrice,
    required this.currentQuantity,
    required this.medicineName,
    this.genericName,
  });

  factory EligibleBatchModel.fromJson(Map<String, dynamic> json) {
    final med = json['medicine'] as Map<String, dynamic>?;
    return EligibleBatchModel(
      id: json['id'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'])
          : null,
      mrp: _parseDouble(json['mrp']),
      sellingPrice: _parseDouble(json['sellingPrice']),
      currentQuantity: _parseInt(json['currentQuantity']),
      medicineName: med?['name'] ?? '',
      genericName: med?['genericName'],
    );
  }
}

class NearExpiryBatchModel {
  final String id;
  final String batchNumber;
  final DateTime? expiryDate;
  final int currentQuantity;
  final bool isExpired;
  final int daysRemaining;
  final String condition;
  final String medicineId;
  final String medicineName;

  NearExpiryBatchModel({
    required this.id,
    required this.batchNumber,
    this.expiryDate,
    required this.currentQuantity,
    required this.isExpired,
    required this.daysRemaining,
    required this.condition,
    required this.medicineId,
    required this.medicineName,
  });

  factory NearExpiryBatchModel.fromJson(Map<String, dynamic> json) {
    final med = json['medicine'] as Map<String, dynamic>?;
    return NearExpiryBatchModel(
      id: json['id'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'])
          : null,
      currentQuantity: _parseInt(json['currentQuantity']),
      isExpired: json['isExpired'] == true,
      daysRemaining: _parseInt(json['daysRemaining']),
      condition: json['condition'] ?? 'NEAR_EXPIRY',
      medicineId: med?['id'] ?? '',
      medicineName: med?['name'] ?? '',
    );
  }
}

class LowStockMedicineModel {
  final String id;
  final String name;
  final String? genericName;
  final String? dosageForm;
  final String? unit;
  final String? category;
  final int reorderLevel;
  final int totalStock;
  final bool isLowStock;
  final int deficit;

  LowStockMedicineModel({
    required this.id,
    required this.name,
    this.genericName,
    this.dosageForm,
    this.unit,
    this.category,
    required this.reorderLevel,
    required this.totalStock,
    required this.isLowStock,
    required this.deficit,
  });

  factory LowStockMedicineModel.fromJson(Map<String, dynamic> json) {
    return LowStockMedicineModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      genericName: json['genericName'],
      dosageForm: json['dosageForm'],
      unit: json['unit'] is Map ? json['unit']['name'] : json['unit']?.toString(),
      category: json['category'] is Map ? json['category']['name'] : json['category']?.toString(),
      reorderLevel: _parseInt(json['reorderLevel']),
      totalStock: _parseInt(json['totalStock']),
      isLowStock: json['isLowStock'] == true,
      deficit: _parseInt(json['deficit']),
    );
  }
}

class StockValuationModel {
  final int totalBatchesWithStock;
  final int totalUnitsInStock;
  final double totalCostValue;
  final double totalRetailValue;
  final double totalMrpValue;
  final double potentialProfitMargin;
  final double marginPercentage;

  StockValuationModel({
    required this.totalBatchesWithStock,
    required this.totalUnitsInStock,
    required this.totalCostValue,
    required this.totalRetailValue,
    required this.totalMrpValue,
    required this.potentialProfitMargin,
    required this.marginPercentage,
  });

  factory StockValuationModel.fromJson(Map<String, dynamic> json) {
    return StockValuationModel(
      totalBatchesWithStock: _parseInt(json['totalBatchesWithStock']),
      totalUnitsInStock: _parseInt(json['totalUnitsInStock']),
      totalCostValue: _parseDouble(json['totalCostValue']),
      totalRetailValue: _parseDouble(json['totalRetailValue']),
      totalMrpValue: _parseDouble(json['totalMrpValue']),
      potentialProfitMargin: _parseDouble(json['potentialProfitMargin']),
      marginPercentage: _parseDouble(json['marginPercentage']),
    );
  }

  factory StockValuationModel.empty() {
    return StockValuationModel(
      totalBatchesWithStock: 0,
      totalUnitsInStock: 0,
      totalCostValue: 0,
      totalRetailValue: 0,
      totalMrpValue: 0,
      potentialProfitMargin: 0,
      marginPercentage: 0,
    );
  }
}

class StockAuditModel {
  final String id;
  final String batchId;
  final String transactionType;
  final int quantityDelta;
  final int balanceAfter;
  final String referenceType;
  final String notes;
  final DateTime? createdAt;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? medicineName;
  final String? genericName;
  final String? performedByName;

  StockAuditModel({
    required this.id,
    required this.batchId,
    required this.transactionType,
    required this.quantityDelta,
    required this.balanceAfter,
    required this.referenceType,
    required this.notes,
    this.createdAt,
    this.batchNumber,
    this.expiryDate,
    this.medicineName,
    this.genericName,
    this.performedByName,
  });

  factory StockAuditModel.fromJson(Map<String, dynamic> json) {
    final batch = json['batch'] as Map<String, dynamic>?;
    final med = json['medicine'] as Map<String, dynamic>?;
    final perf = json['performedBy'] as Map<String, dynamic>?;
    String? perfName;
    if (perf != null) {
      final first = perf['firstName'] ?? '';
      final last = perf['lastName'] ?? '';
      perfName = ('$first $last').trim();
      if (perfName.isEmpty) perfName = perf['email'];
    }

    return StockAuditModel(
      id: json['id'] ?? '',
      batchId: json['batchId'] ?? '',
      transactionType: json['transactionType'] ?? '',
      quantityDelta: _parseInt(json['quantityDelta']),
      balanceAfter: _parseInt(json['balanceAfter']),
      referenceType: json['referenceType'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      batchNumber: batch?['batchNumber'],
      expiryDate: batch?['expiryDate'] != null
          ? DateTime.tryParse(batch!['expiryDate'])
          : null,
      medicineName: med?['name'],
      genericName: med?['genericName'],
      performedByName: perfName,
    );
  }
}
