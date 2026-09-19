import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/core/models/smart_search_models.dart';

void main() {
  group('SmartSearchModels Serialization & Fallbacks', () {
    test('SmartSearchItemModel parses properly with complete backend data', () {
      final json = {
        'id': 'med-123',
        'name': 'Cheston Cold Tablet',
        'genericName': 'Cetirizine + Phenylephrine + Paracetamol',
        'brand': 'Cipla',
        'dosageForm': 'Tablet',
        'strength': 'Standard',
        'symptoms': 'Cold, Sardi, Runny Nose',
        'saltComposition': 'Cetirizine (5mg) + Paracetamol (325mg)',
        'mrp': 64.0,
        'sellingPrice': 64.0,
        'purchaseRate': 39.04,
        'marginPercent': 39,
        'isHighMargin': true,
        'totalStock': 20,
        'stockStatus': 'IN_STOCK',
        'location': {
          'rack': 'C',
          'shelf': '1',
          'box': '05',
          'formatted': 'Rack C • Shelf 1 • Box 05',
        },
        'batches': [
          {
            'id': 'b-1',
            'batchNumber': 'CHST-882',
            'expiryDate': '2028-09-15T00:00:00.000Z',
            'currentQuantity': 20,
            'mrp': 64.0,
            'sellingPrice': 64.0,
          }
        ],
      };

      final item = SmartSearchItemModel.fromJson(json);

      expect(item.id, 'med-123');
      expect(item.name, 'Cheston Cold Tablet');
      expect(item.marginPercent, 39);
      expect(item.isHighMargin, isTrue);
      expect(item.totalStock, 20);
      expect(item.location.formatted, 'Rack C • Shelf 1 • Box 05');
      expect(item.batches.length, 1);
      expect(item.batches.first.batchNumber, 'CHST-882');
    });

    test('SmartSearchItemModel provides crash-proof fallbacks for missing location & margin', () {
      final incompleteJson = {
        'id': 'med-999',
        'name': 'Generic Paracetamol',
        'sellingPrice': 50.0,
        'purchaseRate': 25.0,
        // location and marginPercent missing
      };

      final item = SmartSearchItemModel.fromJson(incompleteJson);

      expect(item.marginPercent, 50); // ((50 - 25) / 50) * 100 = 50%
      expect(item.isHighMargin, isTrue);
      expect(item.location.formatted, 'Rack A • Shelf 1 • Box 01');
      expect(item.totalStock, 0);
      expect(item.isOutOfStock, isTrue);
    });

    test('MedicineSubstituteResponseModel parses target medicine and substitutes with savings', () {
      final json = {
        'targetMedicine': {
          'id': 'target-1',
          'name': 'Augmentin 625 Duo',
          'genericName': 'Amoxicillin + Clavulanic Acid 625mg',
          'mrp': 203.50,
          'totalStock': 0,
          'isOutOfStock': true,
          'rack': 'A',
          'shelf': '2',
          'box': '08',
        },
        'substitutesCount': 1,
        'substitutes': [
          {
            'id': 'sub-1',
            'name': 'Moxikind-CV 625',
            'genericName': 'Amoxicillin + Clavulanic Acid 625mg',
            'brand': 'Mankind',
            'mrp': 168.0,
            'sellingPrice': 168.0,
            'totalStock': 18,
            'stockStatus': 'IN_STOCK',
            'priceDifference': 35.5,
            'isCheaper': true,
            'savingsAmount': 35.5,
            'pitchScript': 'Sir same formula hai, ₹35 sasta bhi hai',
            'marginPercent': 32,
            'location': {
              'rack': 'A',
              'shelf': '2',
              'box': '09',
              'formatted': 'Rack A • Shelf 2 • Box 09',
            },
            'eligibleBatch': {
              'id': 'b-moxi',
              'batchNumber': 'MKCV-902',
              'expiryDate': '2028-09-15T00:00:00.000Z',
              'currentQuantity': 18,
              'mrp': 168.0,
              'sellingPrice': 168.0,
            },
          }
        ],
      };

      final res = MedicineSubstituteResponseModel.fromJson(json);

      expect(res.targetMedicine.name, 'Augmentin 625 Duo');
      expect(res.targetMedicine.isOutOfStock, isTrue);
      expect(res.substitutes.length, 1);
      final sub = res.substitutes.first;
      expect(sub.name, 'Moxikind-CV 625');
      expect(sub.savingsAmount, 35.5);
      expect(sub.isCheaper, isTrue);
      expect(sub.pitchScript, contains('₹35 sasta bhi hai'));
      expect(sub.eligibleBatch?.batchNumber, 'MKCV-902');
    });

    test('ShortageDiaryItemModel parses shortage demand with customer count', () {
      final json = {
        'id': 'shortage-1',
        'medicineId': 'med-1',
        'medicineName': 'Augmentin 625 Duo',
        'genericName': 'Amoxicillin + Clavulanic Acid 625mg',
        'currentStock': 0,
        'customerCount': 5,
        'suggestedReorderQty': 30,
        'status': 'PENDING',
        'preferredSupplier': {
          'id': 'supp-1',
          'name': 'Apex Pharma',
          'mobile': '9811122233',
        },
        'rackLocation': 'Rack A • Shelf 2',
      };

      final shortage = ShortageDiaryItemModel.fromJson(json);

      expect(shortage.id, 'shortage-1');
      expect(shortage.customerCount, 5);
      expect(shortage.status, 'PENDING');
      expect(shortage.preferredSupplier.name, 'Apex Pharma');
      expect(shortage.rackLocation, 'Rack A • Shelf 2');
    });
  });
}
