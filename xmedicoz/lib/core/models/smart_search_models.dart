double _parseDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}

int _parseInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is num) return val.toInt();
  if (val is String) {
    return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? fallback);
  }
  return fallback;
}

class SmartSearchLocationModel {
  final String rack;
  final String shelf;
  final String box;
  final String formatted;

  SmartSearchLocationModel({
    required this.rack,
    required this.shelf,
    required this.box,
    required this.formatted,
  });

  factory SmartSearchLocationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SmartSearchLocationModel(
        rack: 'A',
        shelf: '1',
        box: '01',
        formatted: 'Rack A • Shelf 1 • Box 01',
      );
    }
    final rack = json['rack']?.toString() ?? 'A';
    final shelf = json['shelf']?.toString() ?? '1';
    final box = json['box']?.toString() ?? '01';
    final formatted = json['formatted']?.toString() ??
        'Rack $rack • Shelf $shelf • Box $box';

    return SmartSearchLocationModel(
      rack: rack,
      shelf: shelf,
      box: box,
      formatted: formatted,
    );
  }

  Map<String, dynamic> toJson() => {
        'rack': rack,
        'shelf': shelf,
        'box': box,
        'formatted': formatted,
      };
}

class SmartSearchBatchModel {
  final String id;
  final String batchNumber;
  final String expiryDate;
  final int currentQuantity;
  final double mrp;
  final double sellingPrice;

  SmartSearchBatchModel({
    required this.id,
    required this.batchNumber,
    required this.expiryDate,
    required this.currentQuantity,
    required this.mrp,
    required this.sellingPrice,
  });

  factory SmartSearchBatchModel.fromJson(Map<String, dynamic> json) {
    return SmartSearchBatchModel(
      id: json['id']?.toString() ?? '',
      batchNumber: json['batchNumber']?.toString() ?? '',
      expiryDate: json['expiryDate']?.toString() ?? '',
      currentQuantity: _parseInt(json['currentQuantity']),
      mrp: _parseDouble(json['mrp']),
      sellingPrice: _parseDouble(json['sellingPrice']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'batchNumber': batchNumber,
        'expiryDate': expiryDate,
        'currentQuantity': currentQuantity,
        'mrp': mrp,
        'sellingPrice': sellingPrice,
      };
}

class SmartSearchItemModel {
  final String id;
  final String name;
  final String genericName;
  final String brand;
  final String dosageForm;
  final String strength;
  final String symptoms;
  final String saltComposition;
  final double mrp;
  final double sellingPrice;
  final double purchaseRate;
  final int marginPercent;
  final bool isHighMargin;
  final int totalStock;
  final String stockStatus; // IN_STOCK, LOW_STOCK, OUT_OF_STOCK
  final SmartSearchLocationModel location;
  final String? category;
  final String? manufacturer;
  final String? packing;
  final int batchesCount;
  final List<SmartSearchBatchModel> batches;

  SmartSearchItemModel({
    required this.id,
    required this.name,
    required this.genericName,
    required this.brand,
    required this.dosageForm,
    required this.strength,
    required this.symptoms,
    required this.saltComposition,
    required this.mrp,
    required this.sellingPrice,
    required this.purchaseRate,
    required this.marginPercent,
    required this.isHighMargin,
    required this.totalStock,
    required this.stockStatus,
    required this.location,
    this.category,
    this.manufacturer,
    this.packing,
    this.batchesCount = 0,
    this.batches = const [],
  });

  bool get isOutOfStock => totalStock <= 0;
  bool get isLowStock => totalStock > 0 && totalStock <= 5;
  bool get isInStock => totalStock > 5;

  factory SmartSearchItemModel.fromJson(Map<String, dynamic> json) {
    final rawBatches = json['batches'] as List? ?? [];
    final pRate = _parseDouble(json['purchaseRate']);
    final sPrice = _parseDouble(
      json['sellingPrice'],
      _parseDouble(json['mrp']),
    );

    final defaultMargin = sPrice > 0 && pRate > 0
        ? (((sPrice - pRate) / sPrice) * 100).round()
        : 20;
    final calculatedMargin = _parseInt(json['marginPercent'], defaultMargin);

    final isHigh = json['isHighMargin'] == true || calculatedMargin >= 25;

    final stock = _parseInt(json['totalStock']);
    final status = json['stockStatus']?.toString() ??
        (stock > 5 ? 'IN_STOCK' : (stock > 0 ? 'LOW_STOCK' : 'OUT_OF_STOCK'));

    Map<String, dynamic>? locMap;
    if (json['location'] is Map<String, dynamic>) {
      locMap = json['location'] as Map<String, dynamic>;
    } else if (json['rack'] != null || json['locationFormatted'] != null) {
      locMap = {
        'rack': json['rack'],
        'shelf': json['shelf'],
        'box': json['box'],
        'formatted': json['locationFormatted'],
      };
    }

    return SmartSearchItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      genericName: json['genericName']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      dosageForm: json['dosageForm']?.toString() ?? 'Tablet',
      strength: json['strength']?.toString() ?? 'Standard',
      symptoms: json['symptoms']?.toString() ?? '',
      saltComposition: json['saltComposition']?.toString() ?? '',
      mrp: _parseDouble(json['mrp'], sPrice),
      sellingPrice: sPrice,
      purchaseRate: pRate,
      marginPercent: calculatedMargin,
      isHighMargin: isHigh,
      totalStock: stock,
      stockStatus: status,
      location: SmartSearchLocationModel.fromJson(locMap),
      category: json['category']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      packing: json['packing']?.toString(),
      batchesCount: _parseInt(json['batchesCount'], rawBatches.length),
      batches: rawBatches
          .whereType<Map<String, dynamic>>()
          .map(SmartSearchBatchModel.fromJson)
          .toList(),
    );
  }
}

class SmartSearchResponseModel {
  final String query;
  final String? detectedSymptom;
  final int totalMatches;
  final List<SmartSearchItemModel> items;

  SmartSearchResponseModel({
    required this.query,
    this.detectedSymptom,
    required this.totalMatches,
    required this.items,
  });

  factory SmartSearchResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return SmartSearchResponseModel(
      query: json['query']?.toString() ?? '',
      detectedSymptom: json['detectedSymptom']?.toString(),
      totalMatches: _parseInt(json['totalMatches'], rawItems.length),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(SmartSearchItemModel.fromJson)
          .toList(),
    );
  }
}

class TargetMedicineModel {
  final String id;
  final String name;
  final String genericName;
  final double mrp;
  final int totalStock;
  final bool isOutOfStock;
  final String rack;
  final String shelf;
  final String box;
  final String locationFormatted;

  TargetMedicineModel({
    required this.id,
    required this.name,
    required this.genericName,
    required this.mrp,
    required this.totalStock,
    required this.isOutOfStock,
    required this.rack,
    required this.shelf,
    required this.box,
    required this.locationFormatted,
  });

  factory TargetMedicineModel.fromJson(Map<String, dynamic> json) {
    final rack = json['rack']?.toString() ?? 'A';
    final shelf = json['shelf']?.toString() ?? '1';
    final box = json['box']?.toString() ?? '01';
    final totalStock = _parseInt(json['totalStock']);

    return TargetMedicineModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      genericName: json['genericName']?.toString() ?? '',
      mrp: _parseDouble(json['mrp']),
      totalStock: totalStock,
      isOutOfStock: json['isOutOfStock'] == true || totalStock <= 0,
      rack: rack,
      shelf: shelf,
      box: box,
      locationFormatted: json['locationFormatted']?.toString() ??
          'Rack $rack • Shelf $shelf • Box $box',
    );
  }
}

class MedicineSubstituteModel {
  final String id;
  final String name;
  final String genericName;
  final String brand;
  final String saltComposition;
  final String manufacturer;
  final String dosageForm;
  final double mrp;
  final double sellingPrice;
  final int totalStock;
  final String stockStatus;
  final double priceDifference;
  final bool isCheaper;
  final double savingsAmount;
  final String pitchScript;
  final int marginPercent;
  final bool isHighMargin;
  final SmartSearchLocationModel location;
  final SmartSearchBatchModel? eligibleBatch;

  MedicineSubstituteModel({
    required this.id,
    required this.name,
    required this.genericName,
    required this.brand,
    required this.saltComposition,
    required this.manufacturer,
    required this.dosageForm,
    required this.mrp,
    required this.sellingPrice,
    required this.totalStock,
    required this.stockStatus,
    required this.priceDifference,
    required this.isCheaper,
    required this.savingsAmount,
    required this.pitchScript,
    required this.marginPercent,
    required this.isHighMargin,
    required this.location,
    this.eligibleBatch,
  });

  factory MedicineSubstituteModel.fromJson(Map<String, dynamic> json) {
    final sPrice = _parseDouble(
      json['sellingPrice'],
      _parseDouble(json['mrp']),
    );
    final diff = _parseDouble(json['priceDifference']);
    final savings = _parseDouble(json['savingsAmount'], (diff > 0 ? diff : 0.0));
    final margin = _parseInt(json['marginPercent'], 20);
    final genericName = json['genericName']?.toString() ?? '';

    return MedicineSubstituteModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      genericName: genericName,
      brand: json['brand']?.toString() ?? '',
      saltComposition: json['saltComposition']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      dosageForm: json['dosageForm']?.toString() ?? 'Tablet',
      mrp: _parseDouble(json['mrp'], sPrice),
      sellingPrice: sPrice,
      totalStock: _parseInt(json['totalStock']),
      stockStatus: json['stockStatus']?.toString() ?? 'IN_STOCK',
      priceDifference: diff,
      isCheaper: json['isCheaper'] == true || diff > 0,
      savingsAmount: savings,
      pitchScript: json['pitchScript']?.toString() ??
          (genericName.isNotEmpty
              ? 'Same composition ($genericName)${savings > 0 ? " • Saves ₹${savings.toInt()}" : " • In-stock alternative"}'
              : 'Same active salt${savings > 0 ? " • Saves ₹${savings.toInt()}" : " • In-stock alternative"}'),
      marginPercent: margin,
      isHighMargin: json['isHighMargin'] == true || margin >= 25,
      location: SmartSearchLocationModel.fromJson(
        json['location'] as Map<String, dynamic>?,
      ),
      eligibleBatch: json['eligibleBatch'] != null &&
              json['eligibleBatch'] is Map<String, dynamic>
          ? SmartSearchBatchModel.fromJson(
              json['eligibleBatch'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class MedicineSubstituteResponseModel {
  final TargetMedicineModel targetMedicine;
  final int substitutesCount;
  final int inStockSubstitutesCount;
  final List<MedicineSubstituteModel> substitutes;

  MedicineSubstituteResponseModel({
    required this.targetMedicine,
    required this.substitutesCount,
    required this.inStockSubstitutesCount,
    required this.substitutes,
  });

  factory MedicineSubstituteResponseModel.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['substitutes'] as List? ?? [];
    return MedicineSubstituteResponseModel(
      targetMedicine: TargetMedicineModel.fromJson(
        (json['targetMedicine'] as Map<String, dynamic>?) ?? {},
      ),
      substitutesCount: _parseInt(json['substitutesCount'], rawSubs.length),
      inStockSubstitutesCount:
          _parseInt(json['inStockSubstitutesCount'], rawSubs.length),
      substitutes: rawSubs
          .whereType<Map<String, dynamic>>()
          .map(MedicineSubstituteModel.fromJson)
          .toList(),
    );
  }
}

class PreferredSupplierModel {
  final String id;
  final String name;
  final String mobile;
  final String contactPerson;

  PreferredSupplierModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.contactPerson,
  });

  factory PreferredSupplierModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PreferredSupplierModel(
        id: '',
        name: 'Distributor N/A',
        mobile: '',
        contactPerson: '',
      );
    }
    return PreferredSupplierModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Distributor',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
    );
  }
}

class ShortageDiaryItemModel {
  final String id;
  final String medicineId;
  final String medicineName;
  final String genericName;
  final String manufacturer;
  final String packing;
  final int currentStock;
  final int customerCount;
  final int suggestedReorderQty;
  final String? lastRequestedAt;
  final String status; // PENDING, PO_CREATED, RESOLVED, DISMISSED
  final String notes;
  final PreferredSupplierModel preferredSupplier;
  final double mrp;
  final double purchaseRate;
  final String rackLocation;

  ShortageDiaryItemModel({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.genericName,
    required this.manufacturer,
    required this.packing,
    required this.currentStock,
    required this.customerCount,
    required this.suggestedReorderQty,
    this.lastRequestedAt,
    required this.status,
    required this.notes,
    required this.preferredSupplier,
    required this.mrp,
    required this.purchaseRate,
    required this.rackLocation,
  });

  factory ShortageDiaryItemModel.fromJson(Map<String, dynamic> json) {
    return ShortageDiaryItemModel(
      id: json['id']?.toString() ?? '',
      medicineId: json['medicineId']?.toString() ?? '',
      medicineName: json['medicineName']?.toString() ?? 'Unnamed Medicine',
      genericName: json['genericName']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      packing: json['packing']?.toString() ?? 'Tablet',
      currentStock: _parseInt(json['currentStock']),
      customerCount: _parseInt(json['customerCount'], 1),
      suggestedReorderQty: _parseInt(json['suggestedReorderQty'], 30),
      lastRequestedAt: json['lastRequestedAt']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      notes: json['notes']?.toString() ?? '',
      preferredSupplier: PreferredSupplierModel.fromJson(
        json['preferredSupplier'] as Map<String, dynamic>?,
      ),
      mrp: _parseDouble(json['mrp']),
      purchaseRate: _parseDouble(json['purchaseRate']),
      rackLocation: json['rackLocation']?.toString() ?? 'Rack A • Shelf 1',
    );
  }
}
