import 'package:get_storage/get_storage.dart';
import '../models/auth_models.dart';
import '../models/models.dart';

class StorageService {
  static final GetStorage _box = GetStorage();

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'cached_user';

  static Future<void> init() async {
    await GetStorage.init();
  }

  // Token management
  static Future<void> saveTokens(TokensModel tokens) async {
    await _box.write(_keyAccessToken, tokens.accessToken);
    await _box.write(_keyRefreshToken, tokens.refreshToken);
  }

  static Future<void> saveAccessToken(String token) async {
    await _box.write(_keyAccessToken, token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _box.write(_keyRefreshToken, token);
  }

  static String? getAccessToken() {
    return _box.read<String>(_keyAccessToken);
  }

  static String? getRefreshToken() {
    return _box.read<String>(_keyRefreshToken);
  }

  static bool hasToken() {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // User profile caching
  static Future<void> saveUser(UserModel user) async {
    await _box.write(_keyUser, user.toJson());
  }

  static UserModel? getUser() {
    final raw = _box.read<Map<String, dynamic>>(_keyUser);
    if (raw != null) {
      return UserModel.fromJson(raw);
    }
    return null;
  }

  static const String _keyShop = 'cached_active_shop';

  // Shop profile caching
  static Future<void> saveShop(ShopModel shop) async {
    await _box.write(_keyShop, shop.toJson());
  }

  static ShopModel? getShop() {
    final raw = _box.read<Map<String, dynamic>>(_keyShop);
    if (raw != null) {
      return ShopModel.fromJson(raw);
    }
    return null;
  }

  static const String _keySeenOnboarding = 'seen_onboarding';

  static bool hasSeenOnboarding() {
    return _box.read<bool>(_keySeenOnboarding) ?? false;
  }

  static Future<void> setSeenOnboarding() async {
    await _box.write(_keySeenOnboarding, true);
  }

  // Clear session on logout
  static Future<void> clearSession() async {
    await _box.remove(_keyAccessToken);
    await _box.remove(_keyRefreshToken);
    await _box.remove(_keyUser);
    await _box.remove(_keyShop);
  }
}
