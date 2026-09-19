import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/core/models/master_models.dart';
import 'package:ledger_app/features/inventory/controllers/master_data_controller.dart';
import 'package:ledger_app/features/inventory/repositories/masters_repository.dart';

class _PagedRepository extends MastersRepository {
  final pages = <int>[];
  final supplierPages = <int>[];
  bool fail = false;
  bool empty = false;
  Completer<void>? gate;

  @override
  Future<void> deleteMedicine(String id) async {}

  @override
  Future<MedicineModel> createMedicine(Map<String, dynamic> data) async =>
      MedicineModel.fromJson(data);

  @override
  Future<Map<String, dynamic>> getSuppliers({
    String? search,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    supplierPages.add(page);
    expect(search, isNull);
    return {
      'items': [
        SupplierModel.fromJson({'id': '$page', 'name': 'Stockist $page'}),
      ],
      'pagination': PaginationModel(
        total: 2,
        page: page,
        limit: 1,
        totalPages: 2,
      ),
    };
  }

  @override
  Future<Map<String, dynamic>> getMedicines({
    int page = 1,
    int limit = 20,
    String? search,
    String? categoryId,
    String? manufacturerId,
    String? status,
    bool? prescriptionRequired,
  }) async {
    pages.add(page);
    await gate?.future;
    if (fail) throw Exception('Catalog unavailable');
    expect(search, isNull);
    return {
      'items': List.generate(
        empty ? 0 : 100,
        (index) => MedicineModel.fromJson({
          'id': '${(page - 1) * 100 + index}',
          'name': 'Medicine ${(page - 1) * 100 + index}',
        }),
      ),
      'pagination': PaginationModel(
        total: 600,
        page: page,
        limit: limit,
        totalPages: 6,
      ),
    };
  }
}

void main() {
  test('reopening and concurrent selectors reuse one complete load', () async {
    final repository = _PagedRepository();
    final controller = MasterDataController(repository: repository);
    final results = await Future.wait([
      controller.loadMedicineChoices(),
      controller.loadMedicineChoices(),
    ]);
    expect(results.every((items) => items.length == 600), isTrue);
    await controller.loadMedicineChoices();
    expect(repository.pages, [1, 2, 3, 4, 5, 6]);
  });

  test('empty catalogs are cached and failed requests can retry', () async {
    final repository = _PagedRepository()..fail = true;
    final controller = MasterDataController(repository: repository);
    await expectLater(controller.loadMedicineChoices(), throwsException);
    repository
      ..fail = false
      ..empty = true;
    expect(await controller.loadMedicineChoices(), isEmpty);
    expect(await controller.loadMedicineChoices(), isEmpty);
    expect(repository.pages, [1, 1]);
  });

  test('catalog mutations and inventory refresh invalidate choices', () async {
    final repository = _PagedRepository();
    final controller = MasterDataController(repository: repository);
    await controller.loadMedicineChoices();
    await controller.registerMedicine({'id': 'new', 'name': 'New medicine'});
    expect(controller.medicineChoices.any((m) => m.id == 'new'), isTrue);
    await controller.loadMedicineChoices();
    expect(repository.pages.length, 12);
    await controller.deleteMedicine('599');
    expect(controller.medicineChoices.any((m) => m.id == '599'), isFalse);
    await controller.loadMedicineChoices();
    expect(repository.pages.length, 18);
    await controller.fetchMedicines();
    await controller.loadMedicineChoices();
    expect(repository.pages.length, 25);
  });

  test('logout discards a pending catalog and permits a fresh load', () async {
    final repository = _PagedRepository()..gate = Completer<void>();
    final controller = MasterDataController(repository: repository);
    final pending = controller.loadMedicineChoices();
    controller.clearData();
    repository.gate!.complete();
    expect(await pending, isEmpty);
    expect(controller.medicineChoices, isEmpty);
    expect((await controller.loadMedicineChoices()).length, 600);
    expect(repository.pages, [1, 1, 2, 3, 4, 5, 6]);
  });

  test(
    'supplier choices include every page and preserve ledger filters',
    () async {
      final repository = _PagedRepository();
      final controller = MasterDataController(repository: repository);
      controller.supplierSearch.value = 'Ledger filter';
      final choices = await controller.loadSupplierChoices();
      expect(repository.supplierPages, [1, 2]);
      expect(choices.map((s) => s.id), ['1', '2']);
      expect(controller.suppliers, isEmpty);
      expect(controller.supplierSearch.value, 'Ledger filter');
      controller.clearData();
      expect(controller.supplierChoices, isEmpty);
    },
  );
  test(
    'loads every catalog page without changing inventory search or rows',
    () async {
      final repository = _PagedRepository();
      final controller = MasterDataController(repository: repository);
      controller.medicineSearch.value = 'Inventory filter';
      final choices = await controller.loadMedicineChoices();
      expect(repository.pages, [1, 2, 3, 4, 5, 6]);
      expect(choices.length, 600);
      expect(choices.last.id, '599');
      expect(controller.medicines, isEmpty);
      expect(controller.medicineSearch.value, 'Inventory filter');
      controller.clearData();
      expect(controller.medicineChoices, isEmpty);
    },
  );
}
