import 'package:intl/intl.dart';
import '../../../../core/models/batch_models.dart';
import '../../../../core/models/master_models.dart';

class SaleItemDraft {
  final MedicineModel medicine;
  final EligibleBatchModel batch;
  int quantity;
  double discountPercent;

  SaleItemDraft({
    required this.medicine,
    required this.batch,
    required this.quantity,
    this.discountPercent = 0.0,
  });

  double get unitPrice {
    if (batch.sellingPrice > 0) return batch.sellingPrice;
    if (medicine.sellingPrice > 0) return medicine.sellingPrice;
    return 0.0;
  }

  double get itemSubtotal => unitPrice * quantity;
  double get discountAmount => itemSubtotal * (discountPercent / 100);
  double get taxableValue => itemSubtotal - discountAmount;
  double get gstRate => medicine.gstRate;
  double get gstAmount => taxableValue * (gstRate / 100);
  double get totalAmount => taxableValue + gstAmount;

  Map<String, dynamic> toApiJson() {
    return {
      'medicineId': medicine.id,
      'batchId': batch.id,
      'medicineName': medicine.name,
      'batchNumber': batch.batchNumber,
      if (batch.expiryDate != null)
        'expiryDate': DateFormat('yyyy-MM-dd').format(batch.expiryDate!),
      'quantity': quantity,
      'mrp': batch.mrp,
      'unitPrice': unitPrice,
      'gstRate': gstRate,
      'taxRate': gstRate,
      'discountPercent': discountPercent,
      'itemSubtotal': itemSubtotal,
      'discountAmount': discountAmount,
      'taxableValue': taxableValue,
      'gstAmount': gstAmount,
      'taxAmount': gstAmount,
      'totalAmount': totalAmount,
    };
  }
}
