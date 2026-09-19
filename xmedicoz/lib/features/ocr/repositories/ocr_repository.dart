import 'package:dio/dio.dart';
import '../../../core/models/ocr_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';

class OcrRepository {
  final ApiClient _apiClient;

  OcrRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Scans an image against the OCR engine and returns structured pharma entities
  Future<OcrScanResultModel> scanDocument({
    required String documentType,
    required String base64Image,
    String? hints,
  }) async {
    final Map<String, dynamic> body = {
      'documentType': documentType,
      'image': base64Image,
    };

    if (hints != null && hints.trim().isNotEmpty) {
      body['options'] = {'hints': hints.trim()};
    }

    final response = await _apiClient.post(
      ApiConstants.ocrScan,
      data: body,
      options: Options(
        sendTimeout: ApiConstants.ocrSendTimeout,
        receiveTimeout: ApiConstants.ocrReceiveTimeout,
      ),
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return OcrScanResultModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw Exception(response['message'] ?? 'Failed to parse OCR response');
  }
}
