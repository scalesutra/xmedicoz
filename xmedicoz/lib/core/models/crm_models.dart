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

DateTime? _parseDateTime(dynamic val) {
  if (val == null) return null;
  if (val is DateTime) return val;
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  if (val is String) return DateTime.tryParse(val);
  return null;
}

Map<String, dynamic> _toMap(dynamic val) {
  if (val is Map<String, dynamic>) return val;
  if (val is Map) return Map<String, dynamic>.from(val);
  return <String, dynamic>{};
}

/// ---------------------------------------------------------------------------
/// Customer History & Analytics Models
/// ---------------------------------------------------------------------------
class CustomerHistoryModel {
  final CustomerModel customer;
  final CustomerHistoryStatsModel stats;
  final List<FrequentlyPurchasedMedicineModel> frequentlyPurchasedMedicines;
  final List<CustomerHistoryInvoiceModel> invoices;

  CustomerHistoryModel({
    required this.customer,
    required this.stats,
    required this.frequentlyPurchasedMedicines,
    required this.invoices,
  });

  factory CustomerHistoryModel.fromJson(Map<String, dynamic> json) {
    return CustomerHistoryModel(
      customer: CustomerModel.fromJson(_toMap(json['customer'])),
      stats: CustomerHistoryStatsModel.fromJson(_toMap(json['stats'])),
      frequentlyPurchasedMedicines: (json['frequentlyPurchasedMedicines'] as List?)
              ?.map((item) => FrequentlyPurchasedMedicineModel.fromJson(_toMap(item)))
              .toList() ??
          [],
      invoices: (json['invoices'] as List?)
              ?.map((item) => CustomerHistoryInvoiceModel.fromJson(_toMap(item)))
              .toList() ??
          [],
    );
  }
}

class CustomerHistoryStatsModel {
  final int totalInvoices;
  final double totalSpent;
  final double currentDebt;
  final DateTime? firstVisit;
  final DateTime? lastVisit;

  CustomerHistoryStatsModel({
    required this.totalInvoices,
    required this.totalSpent,
    required this.currentDebt,
    this.firstVisit,
    this.lastVisit,
  });

  String? get lastVisitDate => lastVisit?.toIso8601String();

  factory CustomerHistoryStatsModel.fromJson(Map<String, dynamic> json) {
    return CustomerHistoryStatsModel(
      totalInvoices: _parseInt(json['totalInvoices']),
      totalSpent: _parseDouble(json['totalSpent']),
      currentDebt: _parseDouble(json['currentDebt']),
      firstVisit: _parseDateTime(json['firstVisit']),
      lastVisit: _parseDateTime(json['lastVisit']),
    );
  }
}

typedef CustomerHistoryCustomerModel = CustomerModel;

class FrequentlyPurchasedMedicineModel {
  final String medicineId;
  final String name;
  final String genericName;
  final String dosageForm;
  final int totalQuantity;
  final double totalSpent;
  final DateTime? lastPurchasedDate;
  final int purchaseCount;
  final String category;

  FrequentlyPurchasedMedicineModel({
    required this.medicineId,
    required this.name,
    required this.genericName,
    required this.dosageForm,
    required this.totalQuantity,
    required this.totalSpent,
    this.lastPurchasedDate,
    required this.purchaseCount,
    this.category = 'PHARMA',
  });

  factory FrequentlyPurchasedMedicineModel.fromJson(Map<String, dynamic> json) {
    return FrequentlyPurchasedMedicineModel(
      medicineId: json['medicineId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      genericName: json['genericName']?.toString() ?? '',
      dosageForm: json['dosageForm']?.toString() ?? '',
      totalQuantity: _parseInt(json['totalQuantity']),
      totalSpent: _parseDouble(json['totalSpent']),
      lastPurchasedDate: _parseDateTime(json['lastPurchasedDate']),
      purchaseCount: _parseInt(json['purchaseCount']),
      category: json['category']?.toString() ?? 'PHARMA',
    );
  }
}

class CustomerHistoryInvoiceModel {
  final String id;
  final String invoiceNumber;
  final DateTime? invoiceDate;
  final double totalAmount;
  final String paymentStatus;
  final List<CustomerHistoryInvoiceItemModel> items;

  double get netAmount => totalAmount;

  CustomerHistoryInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    this.invoiceDate,
    required this.totalAmount,
    required this.paymentStatus,
    required this.items,
  });

  factory CustomerHistoryInvoiceModel.fromJson(Map<String, dynamic> json) {
    return CustomerHistoryInvoiceModel(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      invoiceDate: _parseDateTime(json['invoiceDate']),
      totalAmount: _parseDouble(json['totalAmount']),
      paymentStatus: json['paymentStatus']?.toString() ?? 'PAID',
      items: (json['items'] as List?)
              ?.map((item) => CustomerHistoryInvoiceItemModel.fromJson(_toMap(item)))
              .toList() ??
          [],
    );
  }
}

class CustomerHistoryInvoiceItemModel {
  final String id;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String medicineName;
  final String genericName;
  final String dosageForm;
  final String batchNumber;
  final DateTime? expiryDate;

  CustomerHistoryInvoiceItemModel({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.medicineName,
    required this.genericName,
    required this.dosageForm,
    required this.batchNumber,
    this.expiryDate,
  });

  factory CustomerHistoryInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    final medJson = _toMap(json['medicine']);
    final batchJson = _toMap(json['batch']);

    return CustomerHistoryInvoiceItemModel(
      id: json['id']?.toString() ?? '',
      quantity: _parseInt(json['quantity']),
      unitPrice: _parseDouble(json['unitPrice']),
      totalAmount: _parseDouble(json['totalAmount']),
      medicineName: json['medicineName']?.toString() ?? medJson['name']?.toString() ?? '',
      genericName: json['genericName']?.toString() ?? medJson['genericName']?.toString() ?? '',
      dosageForm: json['dosageForm']?.toString() ?? medJson['dosageForm']?.toString() ?? '',
      batchNumber: json['batchNumber']?.toString() ?? batchJson['batchNumber']?.toString() ?? '',
      expiryDate: _parseDateTime(json['expiryDate'] ?? batchJson['expiryDate']),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Chronic Disease Refill Rule Model
/// ---------------------------------------------------------------------------
class RefillRuleModel {
  final String id;
  final String customerId;
  final String medicineId;
  final double dailyDosage;
  final int daysSupply;
  final DateTime? lastPurchaseDate;
  final DateTime? expectedRefillDate;
  final String status; // ACTIVE, PAUSED, COMPLETED
  final String? notes;
  final String? createdById;
  final DateTime? createdAt;
  final int? daysLeft;
  final bool isOverdue;
  final CustomerModel? customer;
  final MedicineSummaryModel? medicine;

  RefillRuleModel({
    required this.id,
    required this.customerId,
    required this.medicineId,
    required this.dailyDosage,
    required this.daysSupply,
    this.lastPurchaseDate,
    this.expectedRefillDate,
    required this.status,
    this.notes,
    this.createdById,
    this.createdAt,
    this.daysLeft,
    this.isOverdue = false,
    this.customer,
    this.medicine,
  });

  factory RefillRuleModel.fromJson(Map<String, dynamic> json) {
    final custJson = json['customer'] as Map<String, dynamic>?;
    final medJson = json['medicine'] as Map<String, dynamic>?;

    return RefillRuleModel(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      medicineId: json['medicineId'] ?? '',
      dailyDosage: _parseDouble(json['dailyDosage']),
      daysSupply: _parseInt(json['daysSupply']),
      lastPurchaseDate: json['lastPurchaseDate'] != null ? DateTime.tryParse(json['lastPurchaseDate']) : null,
      expectedRefillDate: json['expectedRefillDate'] != null ? DateTime.tryParse(json['expectedRefillDate']) : null,
      status: json['status'] ?? 'ACTIVE',
      notes: json['notes'],
      createdById: json['createdById'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      daysLeft: json['daysLeft'] != null ? _parseInt(json['daysLeft']) : null,
      isOverdue: json['isOverdue'] == true,
      customer: custJson != null ? CustomerModel.fromJson(custJson) : null,
      medicine: medJson != null ? MedicineSummaryModel.fromJson(medJson) : null,
    );
  }
}

class MedicineSummaryModel {
  final String id;
  final String name;
  final String genericName;
  final String? dosageForm;

  MedicineSummaryModel({
    required this.id,
    required this.name,
    required this.genericName,
    this.dosageForm,
  });

  factory MedicineSummaryModel.fromJson(Map<String, dynamic> json) {
    return MedicineSummaryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      genericName: json['genericName'] ?? '',
      dosageForm: json['dosageForm'],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Notification Audit Log Model
/// ---------------------------------------------------------------------------
class NotificationLogModel {
  final String id;
  final String customerId;
  final String channel; // WHATSAPP, SMS, EMAIL
  final String recipient;
  final String? templateName;
  final String message;
  final String status; // SENT, FAILED
  final DateTime? sentAt;
  final CustomerModel? customer;

  NotificationLogModel({
    required this.id,
    required this.customerId,
    required this.channel,
    required this.recipient,
    this.templateName,
    required this.message,
    required this.status,
    this.sentAt,
    this.customer,
  });

  factory NotificationLogModel.fromJson(Map<String, dynamic> json) {
    final custJson = json['customer'] as Map<String, dynamic>?;

    return NotificationLogModel(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      channel: json['channel'] ?? 'WHATSAPP',
      recipient: json['recipient'] ?? '',
      templateName: json['templateName'],
      message: json['message'] ?? '',
      status: json['status'] ?? 'SENT',
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt']) : null,
      customer: custJson != null ? CustomerModel.fromJson(custJson) : null,
    );
  }
}

/// ---------------------------------------------------------------------------
/// Follow-up & Pharmacist Callback Model
/// ---------------------------------------------------------------------------
class FollowUpModel {
  final String id;
  final String customerId;
  final DateTime? followUpDate;
  final String? notes;
  final String status; // PENDING, COMPLETED, CANCELLED
  final String? createdById;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final CustomerModel? customer;

  FollowUpModel({
    required this.id,
    required this.customerId,
    this.followUpDate,
    this.notes,
    required this.status,
    this.createdById,
    this.createdAt,
    this.completedAt,
    this.customer,
  });

  factory FollowUpModel.fromJson(Map<String, dynamic> json) {
    final custJson = json['customer'] as Map<String, dynamic>?;

    return FollowUpModel(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      followUpDate: json['followUpDate'] != null ? DateTime.tryParse(json['followUpDate']) : null,
      notes: json['notes'],
      status: json['status'] ?? 'PENDING',
      createdById: json['createdById'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
      customer: custJson != null ? CustomerModel.fromJson(custJson) : null,
    );
  }
}

typedef DueRefillAlertModel = RefillRuleModel;
