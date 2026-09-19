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

class PurchaseInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String internalNumber;
  final String supplierId;
  final String? purchaseOrderId;
  final DateTime? invoiceDate;
  final DateTime? receivedDate;
  final int paymentTermsDays;
  final DateTime? dueDate;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String paymentStatus; // UNPAID, PARTIALLY_PAID, PAID
  final String status; // RECEIVED, CANCELLED, etc.
  final String notes;
  final String? receivedById;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SupplierModel? supplier;
  final List<PurchaseInvoiceItemModel> items;
  final List<PurchasePaymentModel> payments;
  final List<PurchaseReturnModel> returns;
  final int itemCount;

  PurchaseInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.internalNumber,
    required this.supplierId,
    this.purchaseOrderId,
    this.invoiceDate,
    this.receivedDate,
    required this.paymentTermsDays,
    this.dueDate,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentStatus,
    required this.status,
    required this.notes,
    this.receivedById,
    this.createdAt,
    this.updatedAt,
    this.supplier,
    required this.items,
    required this.payments,
    required this.returns,
    this.itemCount = 0,
  });

  factory PurchaseInvoiceModel.fromJson(Map<String, dynamic> json) {
    final supplierJson = json['supplier'] as Map<String, dynamic>?;
    final itemsList = json['items'] as List?;
    final paymentsList = json['payments'] as List?;
    final returnsList = json['returns'] as List?;
    final countJson = json['_count'] as Map<String, dynamic>?;

    return PurchaseInvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      internalNumber: json['internalNumber'] ?? '',
      supplierId: json['supplierId'] ?? '',
      purchaseOrderId: json['purchaseOrderId'],
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.tryParse(json['invoiceDate'])
          : null,
      receivedDate: json['receivedDate'] != null
          ? DateTime.tryParse(json['receivedDate'])
          : null,
      paymentTermsDays: _parseInt(json['paymentTermsDays']),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'])
          : null,
      subtotal: _parseDouble(json['subtotal']),
      discountAmount: _parseDouble(json['discountAmount']),
      taxAmount: _parseDouble(json['taxAmount']),
      totalAmount: _parseDouble(json['totalAmount']),
      paidAmount: _parseDouble(json['paidAmount']),
      balanceAmount: _parseDouble(json['balanceAmount']),
      paymentStatus: json['paymentStatus'] ?? 'UNPAID',
      status: json['status'] ?? 'RECEIVED',
      notes: json['notes'] ?? '',
      receivedById: json['receivedById'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      supplier: supplierJson != null ? SupplierModel.fromJson(supplierJson) : null,
      items: itemsList != null
          ? itemsList.map((e) => PurchaseInvoiceItemModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      payments: paymentsList != null
          ? paymentsList.map((e) => PurchasePaymentModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      returns: returnsList != null
          ? returnsList.map((e) => PurchaseReturnModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      itemCount: countJson != null
          ? _parseInt(countJson['items'])
          : (itemsList?.length ?? 0),
    );
  }

  bool get isPaid => paymentStatus == 'PAID';
  bool get isUnpaid => paymentStatus == 'UNPAID';
  bool get isPartiallyPaid => paymentStatus == 'PARTIALLY_PAID';
}

class PurchaseInvoiceItemModel {
  final String id;
  final String purchaseInvoiceId;
  final String medicineId;
  final String? batchId;
  final String batchNumber;
  final DateTime? expiryDate;
  final int quantity;
  final int freeQuantity;
  final double purchaseRate;
  final double mrp;
  final double sellingPrice;
  final double discountPercent;
  final double taxRate;
  final double totalAmount;
  final String medicineName;
  final String? genericName;
  final String? dosageForm;
  final int? batchCurrentQuantity;

  PurchaseInvoiceItemModel({
    required this.id,
    required this.purchaseInvoiceId,
    required this.medicineId,
    this.batchId,
    required this.batchNumber,
    this.expiryDate,
    required this.quantity,
    required this.freeQuantity,
    required this.purchaseRate,
    required this.mrp,
    required this.sellingPrice,
    required this.discountPercent,
    required this.taxRate,
    required this.totalAmount,
    required this.medicineName,
    this.genericName,
    this.dosageForm,
    this.batchCurrentQuantity,
  });

  factory PurchaseInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    final med = json['medicine'] as Map<String, dynamic>?;
    final batch = json['batch'] as Map<String, dynamic>?;

    return PurchaseInvoiceItemModel(
      id: json['id'] ?? '',
      purchaseInvoiceId: json['purchaseInvoiceId'] ?? '',
      medicineId: json['medicineId'] ?? '',
      batchId: json['batchId'],
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'])
          : null,
      quantity: _parseInt(json['quantity']),
      freeQuantity: _parseInt(json['freeQuantity']),
      purchaseRate: _parseDouble(json['purchaseRate']),
      mrp: _parseDouble(json['mrp']),
      sellingPrice: _parseDouble(json['sellingPrice']),
      discountPercent: _parseDouble(json['discountPercent']),
      taxRate: _parseDouble(json['taxRate']),
      totalAmount: _parseDouble(json['totalAmount']),
      medicineName: med?['name'] ?? '',
      genericName: med?['genericName'],
      dosageForm: med?['dosageForm'],
      batchCurrentQuantity: batch != null ? _parseInt(batch['currentQuantity']) : null,
    );
  }

  int get totalUnits => quantity + freeQuantity;
}

class PurchasePaymentModel {
  final String id;
  final String paymentNumber;
  final String supplierId;
  final String purchaseInvoiceId;
  final DateTime? paymentDate;
  final double amount;
  final String paymentMode; // CASH, BANK_TRANSFER, UPI, CHEQUE
  final String? referenceNumber;
  final String notes;
  final DateTime? createdAt;

  PurchasePaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.supplierId,
    required this.purchaseInvoiceId,
    this.paymentDate,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    required this.notes,
    this.createdAt,
  });

  factory PurchasePaymentModel.fromJson(Map<String, dynamic> json) {
    return PurchasePaymentModel(
      id: json['id'] ?? '',
      paymentNumber: json['paymentNumber'] ?? '',
      supplierId: json['supplierId'] ?? '',
      purchaseInvoiceId: json['purchaseInvoiceId'] ?? '',
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'])
          : null,
      amount: _parseDouble(json['amount']),
      paymentMode: json['paymentMode'] ?? 'BANK_TRANSFER',
      referenceNumber: json['referenceNumber'],
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class PurchaseReturnModel {
  final String id;
  final String returnNumber;
  final String supplierId;
  final String? purchaseInvoiceId;
  final DateTime? returnDate;
  final String reason; // DAMAGED, EXPIRED, RECALLED, OVERSTOCK
  final double totalAmount;
  final String status;
  final List<PurchaseReturnItemModel> items;

  PurchaseReturnModel({
    required this.id,
    required this.returnNumber,
    required this.supplierId,
    this.purchaseInvoiceId,
    this.returnDate,
    required this.reason,
    required this.totalAmount,
    required this.status,
    required this.items,
  });

  factory PurchaseReturnModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List?;
    return PurchaseReturnModel(
      id: json['id'] ?? '',
      returnNumber: json['returnNumber'] ?? '',
      supplierId: json['supplierId'] ?? '',
      purchaseInvoiceId: json['purchaseInvoiceId'],
      returnDate: json['returnDate'] != null
          ? DateTime.tryParse(json['returnDate'])
          : null,
      reason: json['reason'] ?? 'DAMAGED',
      totalAmount: _parseDouble(json['totalAmount']),
      status: json['status'] ?? 'CONFIRMED',
      items: itemsList != null
          ? itemsList.map((e) => PurchaseReturnItemModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class PurchaseReturnItemModel {
  final String id;
  final String purchaseReturnId;
  final String medicineId;
  final String batchId;
  final int quantity;
  final double returnRate;
  final double totalAmount;

  PurchaseReturnItemModel({
    required this.id,
    required this.purchaseReturnId,
    required this.medicineId,
    required this.batchId,
    required this.quantity,
    required this.returnRate,
    required this.totalAmount,
  });

  factory PurchaseReturnItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnItemModel(
      id: json['id'] ?? '',
      purchaseReturnId: json['purchaseReturnId'] ?? '',
      medicineId: json['medicineId'] ?? '',
      batchId: json['batchId'] ?? '',
      quantity: _parseInt(json['quantity']),
      returnRate: _parseDouble(json['returnRate']),
      totalAmount: _parseDouble(json['totalAmount']),
    );
  }
}

class PurchaseOrderModel {
  final String id;
  final String orderNumber;
  final String supplierId;
  final DateTime? orderDate;
  final DateTime? expectedDate;
  final String status; // PLACED, COMPLETED, CANCELLED
  final double totalAmount;
  final String notes;
  final SupplierModel? supplier;
  final List<PurchaseOrderItemModel> items;
  final int itemCount;

  PurchaseOrderModel({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    this.orderDate,
    this.expectedDate,
    required this.status,
    required this.totalAmount,
    required this.notes,
    this.supplier,
    required this.items,
    this.itemCount = 0,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    final supplierJson = json['supplier'] as Map<String, dynamic>?;
    final itemsList = json['items'] as List?;
    final countJson = json['_count'] as Map<String, dynamic>?;

    return PurchaseOrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      supplierId: json['supplierId'] ?? '',
      orderDate: json['orderDate'] != null
          ? DateTime.tryParse(json['orderDate'])
          : null,
      expectedDate: json['expectedDate'] != null
          ? DateTime.tryParse(json['expectedDate'])
          : null,
      status: json['status'] ?? 'PLACED',
      totalAmount: _parseDouble(json['totalAmount']),
      notes: json['notes'] ?? '',
      supplier: supplierJson != null ? SupplierModel.fromJson(supplierJson) : null,
      items: itemsList != null
          ? itemsList.map((e) => PurchaseOrderItemModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      itemCount: countJson != null
          ? _parseInt(countJson['items'])
          : (itemsList?.length ?? 0),
    );
  }
}

class PurchaseOrderItemModel {
  final String id;
  final String purchaseOrderId;
  final String medicineId;
  final int quantity;
  final double expectedRate;
  final double totalAmount;
  final String medicineName;
  final String? genericName;

  PurchaseOrderItemModel({
    required this.id,
    required this.purchaseOrderId,
    required this.medicineId,
    required this.quantity,
    required this.expectedRate,
    required this.totalAmount,
    required this.medicineName,
    this.genericName,
  });

  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) {
    final med = json['medicine'] as Map<String, dynamic>?;

    return PurchaseOrderItemModel(
      id: json['id'] ?? '',
      purchaseOrderId: json['purchaseOrderId'] ?? '',
      medicineId: json['medicineId'] ?? '',
      quantity: _parseInt(json['quantity']),
      expectedRate: _parseDouble(json['expectedRate']),
      totalAmount: _parseDouble(json['totalAmount']),
      medicineName: med?['name'] ?? '',
      genericName: med?['genericName'],
    );
  }
}
