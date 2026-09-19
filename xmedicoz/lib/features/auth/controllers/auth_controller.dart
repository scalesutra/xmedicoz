import 'package:get/get.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/storage_service.dart';
import '../../accounting/controllers/accounting_controller.dart';
import '../../crm/controllers/crm_controller.dart';
import '../../inventory/controllers/batch_controller.dart';
import '../../inventory/controllers/master_data_controller.dart';
import '../../purchases/controllers/purchases_controller.dart';
import '../../sales/controllers/sales_controller.dart';
import '../../../core/controllers/ledger_controller.dart';
import '../repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _repository;

  AuthController({AuthRepository? repository})
    : _repository = repository ?? AuthRepository();

  // Reactive State
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isLoggedIn = false.obs;
  final RxString currentIdentifier = ''.obs;
  final RxString serverDevOtp = ''.obs;
  final RxList<ShopModel> userShops = <ShopModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _checkInitialAuth();
  }

  void _checkInitialAuth() {
    final cached = StorageService.getUser();
    if (cached != null) {
      currentUser.value = cached;
      isLoggedIn.value = StorageService.hasToken();
    }
  }

  /// 1. Login with Password (Email or Phone)
  Future<bool> loginWithPassword(String identifier, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final authData = await _repository.loginWithPassword(
        identifier: identifier.trim(),
        password: password,
      );

      if (authData.tokens != null) {
        await StorageService.saveTokens(authData.tokens!);
      }
      if (authData.user != null) {
        await StorageService.saveUser(authData.user!);
        currentUser.value = authData.user;
      }
      isLoggedIn.value = true;
      syncAllAppData();
      return true;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      errorMessage.value = 'Failed to login. Please check credentials.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 2. Request OTP (Phone or Email)
  Future<bool> requestOtp(
    String identifier, {
    String channel = 'PHONE',
    String purpose = 'LOGIN',
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      serverDevOtp.value = '';
      currentIdentifier.value = identifier.trim();

      final response = await _repository.requestOtp(
        identifier: identifier.trim(),
        channel: channel,
        purpose: purpose,
      );

      // Check if backend returned the dev OTP in response
      if (response['data'] != null && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        final code =
            data['code'] ?? data['otp'] ?? data['devCode'] ?? data['devOtp'];
        if (code != null) {
          serverDevOtp.value = code.toString().trim();
        }
      }
      if (serverDevOtp.isEmpty && response['message'] != null) {
        final msg = response['message'].toString();
        final match = RegExp(r'\b\d{4}\b').firstMatch(msg);
        if (match != null) {
          serverDevOtp.value = match.group(0)!;
        }
      }

      return true;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      errorMessage.value = 'Unable to send OTP. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 3. Verify OTP Code
  Future<bool> verifyOtp(
    String code, {
    String channel = 'PHONE',
    String purpose = 'LOGIN',
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final authData = await _repository.verifyOtp(
        identifier: currentIdentifier.value,
        code: code.trim(),
        channel: channel,
        purpose: purpose,
      );

      if (authData.tokens != null) {
        await StorageService.saveTokens(authData.tokens!);
      }
      if (authData.user != null) {
        await StorageService.saveUser(authData.user!);
        currentUser.value = authData.user;
      }
      isLoggedIn.value = true;

      // Give the backend a moment to synchronize the newly provisioned Keycloak user to PostgreSQL
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Fetch shops immediately upon verification
      await fetchShops();

      if (userShops.isNotEmpty) {
        syncAllAppData();
      }
      return true;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      errorMessage.value = 'Verification failed. Please check the code.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 4. Logout
  Future<void> logout() async {
    final refresh = StorageService.getRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _repository.logout(refreshToken: refresh);
      } catch (_) {
        // Ignore remote logout error and clear local session
      }
    }
    clearAllAppData();
    await StorageService.clearSession();
    currentUser.value = null;
    userShops.clear();
    isLoggedIn.value = false;
    Get.offAllNamed(AppRoutes.login);
  }

  /// Clears all in-memory application data across all controllers on logout
  void clearAllAppData() {
    if (Get.isRegistered<MasterDataController>()) {
      Get.find<MasterDataController>().clearData();
    }
    if (Get.isRegistered<BatchController>()) {
      Get.find<BatchController>().clearData();
    }
    if (Get.isRegistered<PurchasesController>()) {
      Get.find<PurchasesController>().clearData();
    }
    if (Get.isRegistered<SalesController>()) {
      Get.find<SalesController>().clearData();
    }
    if (Get.isRegistered<CrmController>()) {
      Get.find<CrmController>().clearData();
    }
    if (Get.isRegistered<AccountingController>()) {
      Get.find<AccountingController>().clearData();
    }
    if (Get.isRegistered<LedgerController>()) {
      Get.find<LedgerController>().clearData();
    }
  }

  /// 5. Fetch fresh user profile
  Future<void> fetchProfile() async {
    try {
      final user = await _repository.getProfile();
      currentUser.value = user;
      await StorageService.saveUser(user);
    } catch (_) {}
  }

  /// Triggers full sync across inventory, ledger, sales, purchases, and accounting
  void syncAllAppData() {
    if (Get.isRegistered<MasterDataController>()) {
      Get.find<MasterDataController>().fetchAllData();
    }
    if (Get.isRegistered<BatchController>()) {
      Get.find<BatchController>().refreshAll();
    }
    if (Get.isRegistered<PurchasesController>()) {
      Get.find<PurchasesController>().fetchPurchases(resetPage: true);
      Get.find<PurchasesController>().fetchOrders();
    }
    if (Get.isRegistered<SalesController>()) {
      Get.find<SalesController>().fetchSales(resetPage: true);
    }
    if (Get.isRegistered<CrmController>()) {
      Get.find<CrmController>().loadCrmDashboardData();
    }
    if (Get.isRegistered<AccountingController>()) {
      Get.find<AccountingController>().loadAccountingCore();
    }
  }

  /// Check Existing Stores
  Future<void> fetchShops() async {
    try {
      final shops = await _repository.getShops();
      userShops.assignAll(shops);
      if (shops.isNotEmpty) {
        // Set first shop as active if none is set
        if (StorageService.getShop() == null) {
          await StorageService.saveShop(shops.first);
        }
      }
    } catch (_) {}
  }

  /// Register New Medical Store
  Future<ShopModel?> registerShop(Map<String, dynamic> shopData) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final newShop = await _repository.registerShop(shopData);
      
      // Save it & add to active session
      userShops.insert(0, newShop);
      await StorageService.saveShop(newShop);
      
      if (Get.isRegistered<LedgerController>()) {
        Get.find<LedgerController>().addShop(newShop);
      }

      // Now that the shop is created, sync all data
      syncAllAppData();

      return newShop;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      return null;
    } catch (e) {
      errorMessage.value = 'Store registration failed.';
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
