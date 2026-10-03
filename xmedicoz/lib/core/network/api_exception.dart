import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  ApiException({
    this.code = 'ERROR',
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromDioException(DioException error) => ApiException.fromDioError(error);

  factory ApiException.fromDioError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final data = error.response!.data as Map<String, dynamic>;
      if (data['message'] != null) {
        final rawMsg = data['message'];
        final msgStr = rawMsg is List ? rawMsg.join(', ') : rawMsg.toString();
        return ApiException(
          code: data['code']?.toString() ?? 'SERVER_ERROR',
          message: msgStr,
          statusCode: error.response?.statusCode,
        );
      }
      if (data.containsKey('error')) {
        if (data['error'] is Map) {
          final errObj = data['error'] as Map<String, dynamic>;
          final code = errObj['code']?.toString() ?? 'SERVER_ERROR';
          final rawMsg = errObj['message']?.toString() ?? 'Something went wrong';
          return ApiException(
            code: code,
            message: _mapFriendlyMessage(code, rawMsg),
            statusCode: error.response?.statusCode,
          );
        } else if (data['error'] is String) {
          return ApiException(
            code: 'SERVER_ERROR',
            message: data['error'] as String,
            statusCode: error.response?.statusCode,
          );
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          code: 'TIMEOUT',
          message: 'Connection timed out. Please check your internet connection.',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          code: 'CONNECTION_ERROR',
          message: 'Unable to reach the server. Please verify your network.',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          code: 'HTTP_${error.response?.statusCode ?? 500}',
          message: error.response?.statusMessage ?? 'Server error occurred',
          statusCode: error.response?.statusCode,
        );
      default:
        return ApiException(
          code: 'UNKNOWN_ERROR',
          message: error.message ?? 'An unexpected error occurred.',
        );
    }
  }

  static String _mapFriendlyMessage(String code, String serverMessage) {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return 'Incorrect email/phone or password.';
      case 'INVALID_OTP':
        return 'Incorrect OTP code. Please try again.';
      case 'OTP_EXPIRED':
        return 'OTP has expired. Please request a new one.';
      case 'RATE_LIMITED':
        return 'Too many attempts. Please wait a few minutes.';
      case 'UNAUTHORIZED':
        return 'Session expired. Please log in again.';
      case 'INTERNAL_SERVER_ERROR':
        return serverMessage.isNotEmpty
            ? serverMessage
            : 'Server is currently experiencing issues. Please try again.';
      default:
        return serverMessage.isNotEmpty ? serverMessage : 'Operation failed.';
    }
  }

  @override
  String toString() => message;
}
