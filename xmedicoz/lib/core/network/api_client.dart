// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, kDebugMode;
import 'package:get/get.dart' hide Response;
import '../storage/storage_service.dart';
import '../../features/auth/controllers/auth_controller.dart';
import 'api_constants.dart';
import 'api_exception.dart';
import 'connectivity_controller.dart';

class ApiClient {
  late final Dio dio;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  Completer<String?>? _refreshCompleter;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  /// Checks if a JWT token is expired or about to expire within [thresholdSeconds]
  bool _isJwtExpiredOrExpiring(String token, {int thresholdSeconds = 45}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is Map<String, dynamic> && payload['exp'] != null) {
        final expSeconds = payload['exp'] as int;
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(
          expSeconds * 1000,
        );
        return DateTime.now().isAfter(
          expiryTime.subtract(Duration(seconds: thresholdSeconds)),
        );
      }
    } catch (_) {}
    return false;
  }

  /// Silently refreshes the access token using a mutex queue.
  /// Prevents multiple concurrent 401s from triggering multiple /auth/refresh calls.
  Future<String?> _silentRefreshToken() async {
    // If another request is already refreshing, await its result
    if (_refreshCompleter != null) {
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = StorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('⚠️ [API REFRESH] No stored refresh token available.');
        _refreshCompleter!.complete(null);
        _refreshCompleter = null;
        return null;
      }

      debugPrint(
        '🔄 [API REFRESH] Requesting fresh access token from ${ApiConstants.refreshToken}...',
      );

      // Use a clean, unintercepted Dio instance for refresh request
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['data'] != null) {
        final data = response.data['data'];
        final newAccessToken = data['accessToken']?.toString();
        final newRefreshToken = data['refreshToken']?.toString();

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await StorageService.saveAccessToken(newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await StorageService.saveRefreshToken(newRefreshToken);
          }

          debugPrint('✅ [API REFRESH] New access token stored successfully!');
          _refreshCompleter!.complete(newAccessToken);
          final result = newAccessToken;
          _refreshCompleter = null;
          return result;
        }
      }

      debugPrint('❌ [API REFRESH] Invalid refresh response format.');
      _refreshCompleter!.complete(null);
      _refreshCompleter = null;
      return null;
    } catch (err) {
      debugPrint('❌ [API REFRESH] Refresh error: $err');
      _refreshCompleter?.complete(null);
      _refreshCompleter = null;
      return null;
    }
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.extra['requestStartTime'] =
              DateTime.now().millisecondsSinceEpoch;

          final isAuthPath =
              options.path == ApiConstants.refreshToken ||
              options.path == ApiConstants.login ||
              options.path == ApiConstants.requestOtp ||
              options.path == ApiConstants.verifyOtp;

          if (!isAuthPath) {
            final token = StorageService.getAccessToken();
            if (token != null && token.isNotEmpty) {
              // Proactive refresh: if token is about to expire or already expired,
              // refresh it silently before sending this request to avoid a 401 roundtrip
              if (_isJwtExpiredOrExpiring(token)) {
                debugPrint(
                  '⚠️ [API] Token expiring soon. Initiating proactive refresh...',
                );
                final freshToken = await _silentRefreshToken();
                if (freshToken != null) {
                  options.headers['Authorization'] = 'Bearer $freshToken';
                  _logRequest(options);
                  return handler.next(options);
                }
              }
              options.headers['Authorization'] = 'Bearer $token';
            }
            final shop = StorageService.getShop();
            if (shop != null && shop.id.isNotEmpty) {
              options.headers['x-shop-id'] = shop.id;
            }
          }

          _logRequest(options);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);

          if (Get.isRegistered<ConnectivityController>()) {
            Get.find<ConnectivityController>().onNetworkSuccess();
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          _logError(error);

          // Notify ConnectivityController on network / connection drop
          // Skip on web — browser handles connectivity; API errors are normal server issues
          if (!kIsWeb &&
              (error.type == DioExceptionType.connectionError ||
                  error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.sendTimeout ||
                  error.type == DioExceptionType.receiveTimeout)) {
            if (Get.isRegistered<ConnectivityController>()) {
              Get.find<ConnectivityController>().onNetworkError(
                error.type == DioExceptionType.connectionTimeout
                    ? 'Connection timed out. Server unreachable.'
                    : 'No internet connection. Sync is paused.',
              );
            }
          }

          // Reactive refresh: Handle 401 Unauthorized seamlessly in the background
          if (error.response?.statusCode == 401) {
            final isAuthPath =
                error.requestOptions.path == ApiConstants.refreshToken ||
                error.requestOptions.path == ApiConstants.login ||
                error.requestOptions.path == ApiConstants.verifyOtp;

            if (!isAuthPath) {
              debugPrint(
                '🔄 [API] Received 401 Unauthorized. Attempting token recovery...',
              );
              final freshToken = await _silentRefreshToken();
              if (freshToken != null) {
                // Token refreshed silently in background!
                // Update Authorization header and retry the failed request
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $freshToken';

                try {
                  debugPrint(
                    '🔁 [API RETRY] Retrying ${retryOptions.method} ${retryOptions.path} with new token...',
                  );
                  final retryResponse = await dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                } on DioException catch (retryError) {
                  return handler.next(retryError);
                }
              } else {
                // Refresh failed completely
                debugPrint('🚨 [API] Session expired. Clearing credentials.');
                if (Get.isRegistered<AuthController>()) {
                  Get.find<AuthController>().clearAllAppData();
                }
                await StorageService.clearSession();
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // Large catalog bodies must not be encoded and printed on the UI isolate
  // during selection. Enable explicitly when diagnosing API payloads.
  static const _verboseBodies =
      kDebugMode &&
      bool.fromEnvironment('VERBOSE_API_LOGS', defaultValue: false);

  // --- Debug Console Logger ---
  void _logRequest(RequestOptions options) {
    if (!kDebugMode) return;
    final fullUrl = options.uri.toString();
    final method = options.method.toUpperCase();
    final authHeader = options.headers['Authorization']?.toString();
    final maskedAuth = authHeader != null && authHeader.length > 22
        ? '${authHeader.substring(0, 15)}...${authHeader.substring(authHeader.length - 6)}'
        : (authHeader ?? 'None');

    print(
      '══════════════════════════════════════════════════════════════════════════════',
    );
    print('🌐 [API REQUEST] $method $fullUrl');
    print(
      '──────────────────────────────────────────────────────────────────────────────',
    );
    print('🔑 Authorization: $maskedAuth');
    if (options.queryParameters.isNotEmpty) {
      print('🔍 Query Params: ${options.queryParameters}');
    }
    if (options.data != null) {
      print('📦 Request Body:');
      _printFullBody(options.data);
    }
    print(
      '══════════════════════════════════════════════════════════════════════════════',
    );
  }

  void _logResponse(Response response) {
    if (!kDebugMode) return;
    final fullUrl = response.requestOptions.uri.toString();
    final method = response.requestOptions.method.toUpperCase();
    final status = response.statusCode ?? 0;
    final startTime = response.requestOptions.extra['requestStartTime'] as int?;
    final latency = startTime != null
        ? ' (${DateTime.now().millisecondsSinceEpoch - startTime} ms)'
        : '';

    print(
      '══════════════════════════════════════════════════════════════════════════════',
    );
    print('✅ [API RESPONSE] [$status] $method $fullUrl$latency');
    print(
      '──────────────────────────── RESPONSE BODY ───────────────────────────────────',
    );
    _printFullBody(response.data);
    print(
      '══════════════════════════════════════════════════════════════════════════════',
    );
  }

  void _logError(DioException error) {
    if (!kDebugMode) return;
    final fullUrl = error.requestOptions.uri.toString();
    final method = error.requestOptions.method.toUpperCase();
    final status = error.response?.statusCode != null
        ? '[${error.response?.statusCode}] '
        : '';
    final startTime = error.requestOptions.extra['requestStartTime'] as int?;
    final latency = startTime != null
        ? ' (${DateTime.now().millisecondsSinceEpoch - startTime} ms)'
        : '';

    print(
      '══════════════════════════════════════════════════════════════════════════════',
    );
    print('❌ [API ERROR] $status$method $fullUrl$latency');
    print(
      '──────────────────────────────────────────────────────────────────────────────',
    );
    print('🛑 Error Type: ${error.type}');
    print('💬 Message: ${error.message}');
    if (error.response?.data != null) {
      print('💥 Server Error Response Body:');
      _printFullBody(error.response?.data);
    }
    print(
      '══════════════════════════════════════════════════════════════════════════════',
    );
  }

  void _printFullBody(dynamic data) {
    if (!_verboseBodies) return;
    if (data == null) {
      print('  null');
      return;
    }
    try {
      if (data is Map) {
        final sanitized = Map<String, dynamic>.from(data);
        if (sanitized.containsKey('image') && sanitized['image'] is String) {
          final imgStr = sanitized['image'] as String;
          if (imgStr.length > 100) {
            sanitized['image'] =
                '${imgStr.substring(0, 30)}... [Base64 Image: ${imgStr.length} chars]';
          }
        }
        const encoder = JsonEncoder.withIndent('  ');
        final prettyString = encoder.convert(sanitized);
        for (final line in prettyString.split('\n')) {
          print('  $line');
        }
        return;
      }
      if (data is List) {
        const encoder = JsonEncoder.withIndent('  ');
        final prettyString = encoder.convert(data);
        for (final line in prettyString.split('\n')) {
          print('  $line');
        }
        return;
      }
      if (data is String) {
        try {
          final decoded = jsonDecode(data);
          const encoder = JsonEncoder.withIndent('  ');
          final prettyString = encoder.convert(decoded);
          for (final line in prettyString.split('\n')) {
            print('  $line');
          }
          return;
        } catch (_) {
          for (final line in data.split('\n')) {
            print('  $line');
          }
          return;
        }
      }
      print('  $data');
    } catch (_) {
      print('  $data');
    }
  }

  // --- HTTP Methods ---
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException(code: 'UNKNOWN', message: e.toString());
    }
  }
}
