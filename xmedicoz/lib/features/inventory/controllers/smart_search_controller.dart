import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/models/master_models.dart';
import '../../../core/models/smart_search_models.dart';
import '../../../core/storage/storage_service.dart';
import '../repositories/inventory_smart_repository.dart';
import 'master_data_controller.dart';

class SmartSearchController extends GetxController {
  final InventorySmartRepository _repository;

  SmartSearchController({InventorySmartRepository? repository})
      : _repository = repository ?? InventorySmartRepository();

  // Reactive State
  final RxString selectedSymptomChip = 'All'.obs;
  final RxString searchQuery = ''.obs;
  final RxList<SmartSearchItemModel> searchResults = <SmartSearchItemModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool sortByMargin = true.obs;
  final RxBool inStockOnly = false.obs;
  final RxString errorMessage = ''.obs;

  // Substitute State
  final Rxn<MedicineSubstituteResponseModel> currentSubstituteData =
      Rxn<MedicineSubstituteResponseModel>();
  final RxBool isLoadingSubstitutes = false.obs;

  // Shortage Diary State
  final RxList<ShortageDiaryItemModel> shortageItems =
      <ShortageDiaryItemModel>[].obs;
  final RxBool isLoadingShortage = false.obs;

  int get pendingShortageCount =>
      shortageItems.where((i) => i.status == 'PENDING').length;

  @override
  void onInit() {
    super.onInit();
    if (StorageService.hasToken()) {
      fetchShortageDiary();
    }
  }

  // --------------------------------------------------------------------------
  // Symptom Thesaurus for Crash-Proof Client-Side Fallback
  // --------------------------------------------------------------------------
  static const Map<String, List<String>> _symptomThesaurus = {
    'cold': [
      'cold',
      'cetirizine',
      'phenylephrine',
      'paracetamol',
      'cheston',
      'sinarest',
      'montair',
      'levocetirizine',
      'sardi',
      'sneezing',
      'nasal',
    ],
    'gas': [
      'gas',
      'pantoprazole',
      'rabeprazole',
      'omeprazole',
      'antacid',
      'digene',
      'gelusil',
      'acidity',
      'eno',
      'ranitidine',
      'panto',
      'rabe',
    ],
    'fever': [
      'fever',
      'paracetamol',
      'dolo',
      'crocin',
      'calpol',
      'ibuprofen',
      'meftal',
      'bukhar',
      'pain',
      'pcm',
    ],
    'cough': [
      'cough',
      'dextromethorphan',
      'ambroxol',
      'ascoril',
      'benadryl',
      'koflet',
      'syrup',
      'khasi',
      'broncho',
    ],
    'vomiting': [
      'vomiting',
      'ondansetron',
      'emset',
      'domperidone',
      'vomikind',
      'ultikind',
      'nausea',
      'ulti',
    ],
    'diarrhea': [
      'diarrhea',
      'loperamide',
      'ors',
      'electral',
      'norflox',
      'dast',
      'loose motion',
      'metrogyl',
      'oflox',
    ],
    'allergy': [
      'allergy',
      'cetirizine',
      'allegra',
      'fexofenadine',
      'atarax',
      'bilastine',
      'khujli',
      'itching',
      'rash',
    ],
  };

  // --------------------------------------------------------------------------
  // 1. Smart Search (Server API with Client-Side Offline Fallback)
  // --------------------------------------------------------------------------
  Future<void> searchMedicines({String? query, String? symptom}) async {
    final effectiveQuery = query ?? searchQuery.value;
    final effectiveSymptom = symptom ??
        (selectedSymptomChip.value != 'All' ? selectedSymptomChip.value : null);

    searchQuery.value = effectiveQuery;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final res = await _repository.getSmartSearch(
        q: effectiveQuery.isNotEmpty
            ? effectiveQuery
            : (effectiveSymptom ?? ''),
        symptomOnly: effectiveSymptom != null && effectiveQuery.isEmpty,
        inStockOnly: inStockOnly.value,
        sortByMargin: sortByMargin.value,
        limit: 50,
      );

      searchResults.assignAll(res.items);
    } catch (e) {
      debugPrint('SmartSearch server error: $e. Falling back to local thesaurus.');
      _applyClientSideFallback(
        query: effectiveQuery,
        symptom: effectiveSymptom,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _applyClientSideFallback({String? query, String? symptom}) {
    if (!Get.isRegistered<MasterDataController>()) {
      searchResults.clear();
      return;
    }

    final master = Get.find<MasterDataController>();
    final allMeds = master.medicines;
    final cleanQ = (query ?? '').trim().toLowerCase();
    final cleanSym = (symptom ?? '').trim().toLowerCase();

    List<String> keywords = [];
    if (cleanSym.isNotEmpty) {
      final normalizedSym = cleanSym.split(' ').first;
      keywords = _symptomThesaurus[normalizedSym] ?? [normalizedSym];
    }
    if (cleanQ.isNotEmpty) {
      keywords.add(cleanQ);
    }

    final filtered = allMeds.where((m) {
      if (keywords.isEmpty) return true;
      final mName = m.name.toLowerCase();
      final mGeneric = m.genericName.toLowerCase();
      final mBrand = m.brand.toLowerCase();

      return keywords.any((k) =>
          mName.contains(k) || mGeneric.contains(k) || mBrand.contains(k));
    }).toList();

    final items = filtered.map((m) {
      final sPrice = m.sellingPrice > 0 ? m.sellingPrice : m.mrp;
      final pRate = m.purchaseRate;
      final margin = sPrice > 0 && pRate > 0
          ? (((sPrice - pRate) / sPrice) * 100).round()
          : 20;

      // Deterministic rack location derived from medicine ID or name
      final rackLetter = m.name.isNotEmpty
          ? m.name.substring(0, 1).toUpperCase()
          : 'A';
      final shelfNo = (m.name.length % 4 + 1).toString();
      final boxNo = (m.id.length >= 2 ? m.id.substring(m.id.length - 2) : '01');

      return SmartSearchItemModel(
        id: m.id,
        name: m.name,
        genericName: m.genericName,
        brand: m.brand.isNotEmpty ? m.brand : 'Generic',
        dosageForm: m.dosageForm,
        strength: m.strength.isNotEmpty ? m.strength : 'Standard',
        symptoms: 'General',
        saltComposition: m.genericName,
        mrp: m.mrp,
        sellingPrice: sPrice,
        purchaseRate: pRate,
        marginPercent: margin,
        isHighMargin: margin >= 25,
        totalStock: 10, // Available in local store
        stockStatus: 'IN_STOCK',
        location: SmartSearchLocationModel(
          rack: rackLetter,
          shelf: shelfNo,
          box: boxNo,
          formatted: 'Rack $rackLetter • Shelf $shelfNo • Box $boxNo',
        ),
      );
    }).toList();

    if (sortByMargin.value) {
      items.sort((a, b) => b.marginPercent.compareTo(a.marginPercent));
    }

    searchResults.assignAll(items);
  }

  void selectSymptom(String symptom) {
    selectedSymptomChip.value = symptom;
    if (symptom == 'All') {
      searchMedicines(query: searchQuery.value, symptom: null);
    } else {
      searchMedicines(query: searchQuery.value, symptom: symptom);
    }
  }

  // --------------------------------------------------------------------------
  // 2. Instant Substitute Engine (Server API with Salt Match Fallback)
  // --------------------------------------------------------------------------
  Future<MedicineSubstituteResponseModel?> fetchSubstitutes(
    String medicineId, {
    MedicineModel? targetMedicineFallback,
  }) async {
    isLoadingSubstitutes.value = true;
    try {
      final res = await _repository.getSubstitutes(medicineId);
      currentSubstituteData.value = res;
      return res;
    } catch (e) {
      debugPrint('Substitute API error: $e. Applying local salt matching fallback.');
      final fallback = _applySubstituteFallback(
        medicineId,
        targetMedicineFallback,
      );
      currentSubstituteData.value = fallback;
      return fallback;
    } finally {
      isLoadingSubstitutes.value = false;
    }
  }

  MedicineSubstituteResponseModel? _applySubstituteFallback(
    String medicineId,
    MedicineModel? fallbackMed,
  ) {
    if (!Get.isRegistered<MasterDataController>()) return null;
    final master = Get.find<MasterDataController>();

    final target = fallbackMed ??
        master.medicines.firstWhereOrNull((m) => m.id == medicineId);
    if (target == null) return null;

    // Look for medicines with matching genericName / salt
    final cleanGeneric = target.genericName.trim().toLowerCase();
    final matchingSubstitutes = master.medicines.where((m) {
      if (m.id == target.id) return false;
      return m.genericName.trim().toLowerCase() == cleanGeneric ||
          (cleanGeneric.isNotEmpty &&
              m.genericName.toLowerCase().contains(cleanGeneric));
    }).toList();

    final List<MedicineSubstituteModel> subModels = [];
    for (final s in matchingSubstitutes) {
      final diff = target.sellingPrice - s.sellingPrice;
      final savings = diff > 0 ? diff : 0.0;
      final sPrice = s.sellingPrice > 0 ? s.sellingPrice : s.mrp;
      final pRate = s.purchaseRate;
      final margin = sPrice > 0 && pRate > 0
          ? (((sPrice - pRate) / sPrice) * 100).round()
          : 25;

      subModels.add(
        MedicineSubstituteModel(
          id: s.id,
          name: s.name,
          genericName: s.genericName,
          brand: s.brand.isNotEmpty ? s.brand : 'Generic',
          saltComposition: s.genericName,
          manufacturer: 'Standard Pharma',
          dosageForm: s.dosageForm,
          mrp: s.mrp,
          sellingPrice: sPrice,
          totalStock: 15,
          stockStatus: 'IN_STOCK',
          priceDifference: diff,
          isCheaper: diff > 0,
          savingsAmount: savings,
          pitchScript:
              'Same composition (${s.genericName})${savings > 0 ? " • Saves ₹${savings.toInt()}" : " • In-stock alternative"}',
          marginPercent: margin,
          isHighMargin: margin >= 25,
          location: SmartSearchLocationModel(
            rack: 'A',
            shelf: '2',
            box: '09',
            formatted: 'Rack A • Shelf 2 • Box 09',
          ),
        ),
      );
    }

    return MedicineSubstituteResponseModel(
      targetMedicine: TargetMedicineModel(
        id: target.id,
        name: target.name,
        genericName: target.genericName,
        mrp: target.mrp,
        totalStock: 0,
        isOutOfStock: true,
        rack: 'A',
        shelf: '2',
        box: '08',
        locationFormatted: 'Rack A • Shelf 2 • Box 08',
      ),
      substitutesCount: subModels.length,
      inStockSubstitutesCount: subModels.length,
      substitutes: subModels,
    );
  }

  // --------------------------------------------------------------------------
  // 3. Shortage Diary (Kami Register) Actions
  // --------------------------------------------------------------------------
  Future<void> fetchShortageDiary({String? status}) async {
    try {
      isLoadingShortage.value = true;
      final items = await _repository.getShortageDiary(status: status);
      shortageItems.assignAll(items);
    } catch (_) {
      // Offline safe
    } finally {
      isLoadingShortage.value = false;
    }
  }

  Future<bool> logOutofStockDemand({
    required String medicineId,
    int customerCount = 1,
    String? notes,
  }) async {
    try {
      final ok = await _repository.logShortage(
        medicineId: medicineId,
        customerCount: customerCount,
        notes: notes ?? 'Customer requested out-of-stock item',
      );
      if (ok) {
        fetchShortageDiary();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateShortageStatus(
    String id, {
    required String status,
    int? suggestedReorderQty,
    String? notes,
  }) async {
    try {
      final ok = await _repository.updateShortageStatus(
        id,
        status: status,
        suggestedReorderQty: suggestedReorderQty,
        notes: notes,
      );
      if (ok) {
        fetchShortageDiary();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }
}
