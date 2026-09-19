import 'master_models.dart';

Map<String, dynamic> rackMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Map<String, dynamic>> rackMaps(Object? value) => value is List
    ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
    : [];
int rackInt(Object? value) => num.tryParse('$value')?.toInt() ?? 0;
double rackDouble(Object? value) => double.tryParse('$value') ?? 0;
String rackText(Object? value) => value?.toString() ?? '';

class RackShelfModel {
  RackShelfModel.fromJson(Map<String, dynamic> json)
    : id = rackText(json['id']),
      number = rackInt(json['shelfNumber']),
      label = rackText(json['shelfLabel']),
      maxCapacity = rackInt(json['maxCapacity']),
      barcode = rackText(json['barcode']),
      temperature = double.tryParse('${json['temperature']}');
  final String id, label, barcode;
  final int number, maxCapacity;
  final double? temperature;
  String get displayName => label.isEmpty ? 'Shelf $number' : label;
}

class RackBatchModel {
  RackBatchModel.fromJson(Map<String, dynamic> json)
    : id = rackText(json['id']),
      number = rackText(json['batchNumber']),
      expiry = DateTime.tryParse(rackText(json['expiryDate'])),
      quantity = rackInt(json['currentQuantity']),
      status = rackText(json['status']);
  final String id, number, status;
  final DateTime? expiry;
  final int quantity;
}

class RackMedicineModel {
  RackMedicineModel.fromJson(Map<String, dynamic> json)
    : medicine = MedicineModel.fromJson(json),
      shelf = rackText(json['shelf']),
      box = rackText(json['box']),
      batches = rackMaps(json['batches']).map(RackBatchModel.fromJson).toList();
  final MedicineModel medicine;
  final String shelf, box;
  final List<RackBatchModel> batches;
  int get stock => batches.fold(0, (sum, batch) => sum + batch.quantity);
}

class RackModel {
  RackModel.fromJson(Map<String, dynamic> json)
    : id = rackText(json['id']),
      code = rackText(json['code']),
      name = rackText(json['name']),
      zone = rackText(json['zone']),
      storageType = rackText(json['storageType']),
      description = rackText(json['description']),
      status = rackText(json['status']),
      qrCode = rackText(json['qrCode']),
      totalShelves = rackInt(json['totalShelves']),
      row = rackInt(json['rowNumber']),
      column = rackInt(json['columnNumber']),
      medicineCount = rackInt(json['activeMedicinesCount'] ?? json['totalMedicines'] ?? rackMap(json['_count'])['medicines']),
      totalCapacity = rackInt(json['totalCapacity']),
      occupancy = rackDouble(json['occupancyPercentage']),
      shelves = rackMaps(json['shelves']).map(RackShelfModel.fromJson).toList(),
      medicinesByShelf = rackMap(json['medicinesByShelf']).map((key, value) => MapEntry(key, rackMaps(value).map(RackMedicineModel.fromJson).toList()));
  final String id, code, name, zone, storageType, description, status, qrCode;
  final int totalShelves, row, column, medicineCount, totalCapacity;
  final double occupancy;
  final List<RackShelfModel> shelves;
  final Map<String, List<RackMedicineModel>> medicinesByShelf;
  String get displayName => '$code • $name';
}

class MedicineLocationModel {
  MedicineLocationModel.fromJson(Map<String, dynamic> json)
    : medicineId = rackText(json['medicineId']),
      name = rackText(json['name']),
      coordinates = rackMap(json['coordinates']),
      totalStock = rackInt(rackMap(json['stock'])['totalStock']),
      batches = rackMaps(rackMap(json['stock'])['batches']).map(RackBatchModel.fromJson).toList();
  final String medicineId, name;
  final Map<String, dynamic> coordinates;
  final int totalStock;
  final List<RackBatchModel> batches;
  String get formatted {
    if (rackText(coordinates['formatted']).isNotEmpty) return rackText(coordinates['formatted']);
    final parts = [
      if (rackText(coordinates['rackCode']).isNotEmpty) 'Rack ${coordinates['rackCode']}',
      if (rackText(coordinates['shelf']).isNotEmpty) 'Shelf ${coordinates['shelf']}',
      if (rackText(coordinates['box']).isNotEmpty) 'Box ${coordinates['box']}',
    ];
    return parts.isEmpty ? 'Location not assigned' : parts.join(' • ');
  }
}

class UnassignedMedicinesPage {
  UnassignedMedicinesPage.fromJson(Map<String, dynamic> json)
    : medicines = rackMaps(json['medicines']).map(MedicineModel.fromJson).toList(),
      total = rackInt(json['total']),
      page = rackInt(json['page']),
      totalPages = rackInt(json['totalPages']);
  final List<MedicineModel> medicines;
  final int total, page, totalPages;
}

class RackAssignment {
  const RackAssignment({required this.medicineId, required this.rackCode, required this.shelfNumber, this.boxCode = ''});
  final String medicineId, rackCode, shelfNumber, boxCode;
  Map<String, dynamic> toJson() => {
    'medicineId': medicineId,
    'rackCode': rackCode,
    'shelfNumber': shelfNumber,
    'boxCode': boxCode,
  };
}

class RackAuditItem {
  RackAuditItem.fromJson(Map<String, dynamic> json)
    : medicineId = rackText(json['medicineId']),
      medicineName = rackText(json['medicineName']),
      batchId = rackText(json['batchId']),
      batchNumber = rackText(json['batchNumber']),
      shelf = rackText(json['shelf']),
      box = rackText(json['box']),
      systemStock = rackInt(json['systemStock']),
      expiry = DateTime.tryParse(rackText(json['expiryDate']));
  final String medicineId, medicineName, batchId, batchNumber, shelf, box;
  final int systemStock;
  final DateTime? expiry;
}

class RackAuditSheet {
  RackAuditSheet.fromJson(Map<String, dynamic> json)
    : rackId = rackText(json['rackId']),
      rackName = rackText(json['rackName']),
      generatedAt = DateTime.tryParse(rackText(json['generatedAt'])),
      items = rackMaps(json['items']).map(RackAuditItem.fromJson).toList();
  final String rackId, rackName;
  final DateTime? generatedAt;
  final List<RackAuditItem> items;
}

class RackAuditCount {
  const RackAuditCount({required this.batchId, required this.physicalCount, required this.systemCount, this.notes});
  final String batchId;
  final int physicalCount, systemCount;
  final String? notes;
  Map<String, dynamic> toJson() => {'batchId': batchId, 'physicalCount': physicalCount, 'systemCount': systemCount, 'notes': notes};
}
