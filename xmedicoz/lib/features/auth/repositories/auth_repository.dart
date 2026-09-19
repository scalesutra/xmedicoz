import '../../../core/models/auth_models.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// 1. Password Login (Email or Phone)
  Future<AuthDataModel> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {
        'identifier': identifier,
        'password': password,
      },
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return AuthDataModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Invalid response received from server.');
  }

  /// 2. Request OTP (Phone or Email)
  Future<Map<String, dynamic>> requestOtp({
    required String identifier,
    required String channel,
    String purpose = 'LOGIN',
  }) async {
    final response = await _apiClient.post(
      ApiConstants.requestOtp,
      data: {
        'identifier': identifier,
        'channel': channel,
        'purpose': purpose,
      },
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }

  /// 3. Verify OTP
  Future<AuthDataModel> verifyOtp({
    required String identifier,
    required String code,
    required String channel,
    String purpose = 'LOGIN',
  }) async {
    final response = await _apiClient.post(
      ApiConstants.verifyOtp,
      data: {
        'identifier': identifier,
        'code': code,
        'channel': channel,
        'purpose': purpose,
      },
    );

    if (response is Map<String, dynamic>) {
      print('===================================================================');
      print('🚨 RAW LOGIN RESPONSE: $response');
      print('===================================================================');

      // Merge root response and data object in case tokens are outside data
      final mergedData = <String, dynamic>{};
      mergedData.addAll(response);
      if (response['data'] is Map<String, dynamic>) {
        mergedData.addAll(response['data'] as Map<String, dynamic>);
      }
      
      final authData = AuthDataModel.fromJson(mergedData);
      print('🚨 EXTRACTED TOKEN: ${authData.tokens?.accessToken}');
      print('===================================================================');
      
      return authData;
    }
    throw Exception('Failed to verify OTP code.');
  }

  /// 4. Refresh Token
  Future<TokensModel> refreshToken({required String refreshToken}) async {
    final response = await _apiClient.post(
      ApiConstants.refreshToken,
      data: {'refreshToken': refreshToken},
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return TokensModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to refresh tokens.');
  }

  /// 5. Forgot / Reset Password
  Future<String> resetPassword({
    required String identifier,
    required String code,
    required String channel,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.resetPassword,
      data: {
        'identifier': identifier,
        'code': code,
        'channel': channel,
        'newPassword': newPassword,
      },
    );

    return response['message']?.toString() ?? 'Password reset successfully.';
  }

  /// 6. Logout
  Future<void> logout({required String refreshToken}) async {
    await _apiClient.post(
      ApiConstants.logout,
      data: {'refreshToken': refreshToken},
    );
  }

  /// 7. Get User Profile
  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiConstants.profile);

    if (response is Map<String, dynamic> && response['data'] != null) {
      return UserModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load profile.');
  }

  /// 8. Update User Profile
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (phone != null) body['phone'] = phone;

    final response = await _apiClient.patch(
      ApiConstants.profile,
      data: body,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return UserModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to update profile.');
  }

  /// 9. Change Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiConstants.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// 10. Get Shops
  Future<List<ShopModel>> getShops() async {
    final response = await _apiClient.get(ApiConstants.shops);
    if (response is Map<String, dynamic> && response['data'] != null) {
      final data = response['data'] as List;
      return data.map((e) => ShopModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 11. Register Shop
  Future<ShopModel> registerShop(Map<String, dynamic> shopData) async {
    final response = await _apiClient.post(
      ApiConstants.shops,
      data: shopData,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return ShopModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to register medical store.');
  }
}
