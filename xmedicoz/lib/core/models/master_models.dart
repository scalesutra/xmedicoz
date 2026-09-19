class PaginationModel {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginationModel({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PaginationModel(total: 0, page: 1, limit: 20, totalPages: 1);
    }
    return PaginationModel(
      total: _asInt(json['total']),
      page: _asInt(json['page'], fallback: 1),
      limit: _asInt(json['limit'], fallback: 20),
      totalPages: _asInt(json['totalPages'], fallback: 1),
    );
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    if (v is double) return v.toInt();
    return fallback;
  }
}

class CategoryLookupModel {
  final String id;
  final String name;
  final String? description;

  CategoryLookupModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory CategoryLookupModel.fromJson(Map<String, dynamic> json) {
    return CategoryLookupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
      };
}

class ManufacturerLookupModel {
  final String id;
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;

  ManufacturerLookupModel({
    required this.id,
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
  });

  factory ManufacturerLookupModel.fromJson(Map<String, dynamic> json) {
    return ManufacturerLookupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (contactPerson != null) 'contactPerson': contactPerson,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      };
}

class UnitLookupModel {
  final String id;
  final String name;
  final String abbreviation;

  UnitLookupModel({
    required this.id,
    required this.name,
    required this.abbreviation,
  });

  factory UnitLookupModel.fromJson(Map<String, dynamic> json) {
    return UnitLookupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      abbreviation: json['abbreviation']?.toString() ?? 'UNIT',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'abbreviation': abbreviation,
      };
}

class TaxLookupModel {
  final String id;
  final String name;
  final double rate;

  TaxLookupModel({
    required this.id,
    required this.name,
    required this.rate,
  });

  factory TaxLookupModel.fromJson(Map<String, dynamic> json) {
    return TaxLookupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      rate: _asDouble(json['rate']),
    );
  }

  static double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }
}

class MedicineModel {
  final String id;
  final String name;
  final String genericName;
  final String brand;
  final String dosageForm;
  final String strength;
  final String hsnCode;
  final double gstRate;
  final double mrp;
  final double purchaseRate;
  final double sellingPrice;
  final int reorderLevel;
  final bool prescriptionRequired;
  final String status;
  final CategoryLookupModel? category;
  final ManufacturerLookupModel? manufacturer;
  final UnitLookupModel? unit;

  MedicineModel({
    required this.id,
    required this.name,
    required this.genericName,
    required this.brand,
    required this.dosageForm,
    required this.strength,
    required this.hsnCode,
    required this.gstRate,
    required this.mrp,
    required this.purchaseRate,
    required this.sellingPrice,
    required this.reorderLevel,
    required this.prescriptionRequired,
    required this.status,
    this.category,
    this.manufacturer,
    this.unit,
  });

  double get profitMargin =>
      purchaseRate > 0 ? ((sellingPrice - purchaseRate) / purchaseRate) * 100 : 0.0;

  double get marginAmount => sellingPrice - purchaseRate;

  bool get isLowStockAlert => reorderLevel > 0;

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      genericName: json['genericName']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      dosageForm: json['dosageForm']?.toString() ?? 'Tablet',
      strength: json['strength']?.toString() ?? '',
      hsnCode: json['hsnCode']?.toString() ?? '',
      gstRate: _asDouble(json['gstRate']),
      mrp: _asDouble(json['mrp']),
      purchaseRate: _asDouble(json['purchaseRate']),
      sellingPrice: _asDouble(json['sellingPrice']),
      reorderLevel: _asInt(json['reorderLevel']),
      prescriptionRequired: json['prescriptionRequired'] == true ||
          json['prescriptionRequired']?.toString() == 'true',
      status: json['status']?.toString() ?? 'ACTIVE',
      category: json['category'] != null && json['category'] is Map
          ? CategoryLookupModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      manufacturer: json['manufacturer'] != null && json['manufacturer'] is Map
          ? ManufacturerLookupModel.fromJson(
              json['manufacturer'] as Map<String, dynamic>)
          : null,
      unit: json['unit'] != null && json['unit'] is Map
          ? UnitLookupModel.fromJson(json['unit'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'genericName': genericName,
        'brand': brand,
        'dosageForm': dosageForm,
        'strength': strength,
        'hsnCode': hsnCode,
        'gstRate': gstRate,
        'mrp': mrp,
        'purchaseRate': purchaseRate,
        'sellingPrice': sellingPrice,
        'reorderLevel': reorderLevel,
        'prescriptionRequired': prescriptionRequired,
        if (category != null) 'categoryId': category!.id,
        if (manufacturer != null) 'manufacturerId': manufacturer!.id,
        if (unit != null) 'unitId': unit!.id,
      };

  static double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    if (v is double) return v.toInt();
    return fallback;
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String? address;
  final String? dob;
  final String customerType; // WALK_IN, REGULAR, PERMANENT
  final bool isPermanent;
  final double creditLimit;
  final double currentBalance;
  final bool notificationOptOut;
  final String status;

  CustomerModel({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.address,
    this.dob,
    this.customerType = 'REGULAR',
    this.isPermanent = false,
    this.creditLimit = 0.0,
    this.currentBalance = 0.0,
    this.notificationOptOut = false,
    this.status = 'ACTIVE',
  });

  bool get hasOutstanding => currentBalance > 0;
  String? get phone => mobile.isNotEmpty ? mobile : null;
  double get outstandingBalance => currentBalance;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      dob: json['dob']?.toString(),
      customerType: json['customerType']?.toString() ?? 'REGULAR',
      isPermanent: json['isPermanent'] == true ||
          json['isPermanent']?.toString() == 'true',
      creditLimit: _asDouble(json['creditLimit']),
      currentBalance: _asDouble(json['currentBalance'] ?? json['outstandingBalance']),
      notificationOptOut: json['notificationOptOut'] == true,
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'mobile': mobile,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (dob != null && dob!.isNotEmpty) 'dob': dob,
        'customerType': customerType,
        'isPermanent': isPermanent,
        'creditLimit': creditLimit,
        'notificationOptOut': notificationOptOut,
      };

  static double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }
}

class SupplierModel {
  final String id;
  final String name;
  final String? contactPerson;
  final String mobile;
  final String? email;
  final String? gstin;
  final String? dlNumber;
  final String? address;
  final int paymentTermsDays;
  final double outstandingBalance;
  final String status;

  SupplierModel({
    required this.id,
    required this.name,
    this.contactPerson,
    required this.mobile,
    this.email,
    this.gstin,
    this.dlNumber,
    this.address,
    this.paymentTermsDays = 30,
    this.outstandingBalance = 0.0,
    this.status = 'ACTIVE',
  });

  bool get hasPayable => outstandingBalance > 0;

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString(),
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString(),
      gstin: json['gstin']?.toString(),
      dlNumber: json['dlNumber']?.toString(),
      address: json['address']?.toString(),
      paymentTermsDays: _asInt(json['paymentTermsDays'], fallback: 30),
      outstandingBalance: _asDouble(json['outstandingBalance']),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (contactPerson != null) 'contactPerson': contactPerson,
        'mobile': mobile,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (gstin != null && gstin!.isNotEmpty) 'gstin': gstin,
        if (dlNumber != null && dlNumber!.isNotEmpty) 'dlNumber': dlNumber,
        if (address != null && address!.isNotEmpty) 'address': address,
        'paymentTermsDays': paymentTermsDays,
        'outstandingBalance': outstandingBalance,
      };

  static double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    if (v is double) return v.toInt();
    return fallback;
  }
}
