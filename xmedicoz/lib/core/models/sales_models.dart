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

class SalesInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String? customerId;
  final String customerName;
  final String? customerMobile;
  final DateTime? invoiceDate;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String paymentStatus; // PAID, PARTIALLY_PAID, UNPAID
  final String? doctorName;
  final String? doctorRegNo;
  final String? notes;
  final String status; // COMPLETED, CANCELLED
  final String? cashierId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CustomerModel? customer;
  final String? cashierName;
  final List<SalesInvoiceItemModel> items;
  final List<SalesPaymentModel> payments;
  final List<SalesReturnModel> returns;
  final int itemCount;

  SalesInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    required this.customerName,
    this.customerMobile,
    this.invoiceDate,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentStatus,
    this.doctorName,
    this.doctorRegNo,
    this.notes,
    required this.status,
    this.cashierId,
    this.createdAt,
    this.updatedAt,
    this.customer,
    this.cashierName,
    required this.items,
    required this.payments,
    required this.returns,
    this.itemCount = 0,
  });

  factory SalesInvoiceModel.fromJson(Map<String, dynamic> json) {
    final custJson = json['customer'] as Map<String, dynamic>?;
    final cashierJson = json['cashier'] as Map<String, dynamic>?;
    final itemsList = json['items'] as List?;
    final paymentsList = json['payments'] as List?;
    final returnsList = json['returns'] as List?;
    final countJson = json['_count'] as Map<String, dynamic>?;

    String? cashier;
    if (cashierJson != null) {
      final f = cashierJson['firstName'] ?? '';
      final l = cashierJson['lastName'] ?? '';
      cashier = ('$f $l').trim();
      if (cashier.isEmpty) cashier = cashierJson['email'];
    }

    return SalesInvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      customerId: json['customerId'],
      customerName: json['customerName'] ?? custJson?['name'] ?? 'Walk-in Customer',
      customerMobile: json['customerMobile'] ?? custJson?['mobile'],
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.tryParse(json['invoiceDate'])
          : null,
      subtotal: _parseDouble(json['subtotal']),
      discountAmount: _parseDouble(json['discountAmount']),
      taxAmount: _parseDouble(json['taxAmount']),
      totalAmount: _parseDouble(json['totalAmount']),
      paidAmount: _parseDouble(json['paidAmount']),
      balanceAmount: _parseDouble(json['balanceAmount']),
      paymentStatus: json['paymentStatus'] ?? 'PAID',
      doctorName: json['doctorName'],
      doctorRegNo: json['doctorRegNo'],
      notes: json['notes'],
      status: json['status'] ?? 'COMPLETED',
      cashierId: json['cashierId'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      customer: custJson != null ? CustomerModel.fromJson(custJson) : null,
      cashierName: cashier,
      items: itemsList != null
          ? itemsList.map((e) => SalesInvoiceItemModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      payments: paymentsList != null
          ? paymentsList.map((e) => SalesPaymentModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      returns: returnsList != null
          ? returnsList.map((e) => SalesReturnModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      itemCount: countJson != null
          ? _parseInt(countJson['items'])
          : (itemsList?.length ?? 0),
    );
  }

  bool get isCreditSale =>
      payments.any((p) => p.paymentMode.toUpperCase() == 'CREDIT') ||
      (notes != null &&
          (notes!.toUpperCase().contains('UDHAR') ||
              notes!.toUpperCase().contains('CREDIT')));
  bool get isPaid => paymentStatus == 'PAID' && !isCreditSale;
  bool get isUnpaid => paymentStatus == 'UNPAID' || isCreditSale;
  bool get isPartiallyPaid => paymentStatus == 'PARTIALLY_PAID';
  String get displayPaymentStatus => isCreditSale ? 'UDHAR' : paymentStatus;
}

class SalesInvoiceItemModel {
  final String id;
  final String salesInvoiceId;
  final String medicineId;
  final String batchId;
  final String batchNumber;
  final int quantity;
  final double unitPrice;
  final double mrp;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final String medicineName;
  final String? genericName;
  final String? dosageForm;
  final DateTime? expiryDate;
  final int? currentQuantity;

  SalesInvoiceItemModel({
    required this.id,
    required this.salesInvoiceId,
    required this.medicineId,
    required this.batchId,
    required this.batchNumber,
    required this.quantity,
    required this.unitPrice,
    required this.mrp,
    required this.discountAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    required this.medicineName,
    this.genericName,
    this.dosageForm,
    this.expiryDate,
    this.currentQuantity,
  });

  factory SalesInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    final med = json['medicine'] as Map<String, dynamic>?;
    final batch = json['batch'] as Map<String, dynamic>?;

    return SalesInvoiceItemModel(
      id: json['id'] ?? '',
      salesInvoiceId: json['salesInvoiceId'] ?? '',
      medicineId: json['medicineId'] ?? '',
      batchId: json['batchId'] ?? '',
      batchNumber: json['batchNumber'] ?? batch?['batchNumber'] ?? '',
      quantity: _parseInt(json['quantity']),
      unitPrice: _parseDouble(json['unitPrice']),
      mrp: _parseDouble(json['mrp']),
      discountAmount: _parseDouble(json['discountAmount']),
      taxRate: _parseDouble(json['taxRate']),
      taxAmount: _parseDouble(json['taxAmount']),
      totalAmount: _parseDouble(json['totalAmount']),
      medicineName: med?['name'] ?? '',
      genericName: med?['genericName'],
      dosageForm: med?['dosageForm'],
      expiryDate: batch?['expiryDate'] != null
          ? DateTime.tryParse(batch!['expiryDate'])
          : null,
      currentQuantity: batch != null ? _parseInt(batch['currentQuantity']) : null,
    );
  }
}

class SalesPaymentModel {
  final String id;
  final String salesInvoiceId;
  final double amount;
  final String paymentMode; // CASH, UPI, CARD, CREDIT
  final String? referenceNumber;
  final DateTime? createdAt;

  SalesPaymentModel({
    required this.id,
    required this.salesInvoiceId,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    this.createdAt,
  });

  factory SalesPaymentModel.fromJson(Map<String, dynamic> json) {
    return SalesPaymentModel(
      id: json['id'] ?? '',
      salesInvoiceId: json['salesInvoiceId'] ?? '',
      amount: _parseDouble(json['amount']),
      paymentMode: json['paymentMode'] ?? 'CASH',
      referenceNumber: json['referenceNumber'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class SalesReturnModel {
  final String id;
  final String returnNumber;
  final String salesInvoiceId;
  final String? customerId;
  final DateTime? returnDate;
  final double totalAmount;
  final String refundMode; // CASH, UPI, CREDIT_NOTE
  final String reason;
  final String? createdById;
  final DateTime? createdAt;
  final List<SalesReturnItemModel> items;

  SalesReturnModel({
    required this.id,
    required this.returnNumber,
    required this.salesInvoiceId,
    this.customerId,
    this.returnDate,
    required this.totalAmount,
    required this.refundMode,
    required this.reason,
    this.createdById,
    this.createdAt,
    required this.items,
  });

  factory SalesReturnModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List?;
    return SalesReturnModel(
      id: json['id'] ?? '',
      returnNumber: json['returnNumber'] ?? '',
      salesInvoiceId: json['salesInvoiceId'] ?? '',
      customerId: json['customerId'],
      returnDate: json['returnDate'] != null
          ? DateTime.tryParse(json['returnDate'])
          : null,
      totalAmount: _parseDouble(json['totalAmount']),
      refundMode: json['refundMode'] ?? 'CASH',
      reason: json['reason'] ?? '',
      createdById: json['createdById'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      items: itemsList != null
          ? itemsList.map((e) => SalesReturnItemModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class SalesReturnItemModel {
  final String id;
  final String salesReturnId;
  final String medicineId;
  final String batchId;
  final int quantity;
  final double refundRate;
  final double totalAmount;

  SalesReturnItemModel({
    required this.id,
    required this.salesReturnId,
    required this.medicineId,
    required this.batchId,
    required this.quantity,
    required this.refundRate,
    required this.totalAmount,
  });

  factory SalesReturnItemModel.fromJson(Map<String, dynamic> json) {
    return SalesReturnItemModel(
      id: json['id'] ?? '',
      salesReturnId: json['salesReturnId'] ?? '',
      medicineId: json['medicineId'] ?? '',
      batchId: json['batchId'] ?? '',
      quantity: _parseInt(json['quantity']),
      refundRate: _parseDouble(json['refundRate']),
      totalAmount: _parseDouble(json['totalAmount']),
    );
  }
}
