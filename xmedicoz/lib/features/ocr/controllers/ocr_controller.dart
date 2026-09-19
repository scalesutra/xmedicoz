import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/ocr_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../repositories/ocr_repository.dart';

class OcrController extends GetxController {
  final OcrRepository _repository;

  OcrController({OcrRepository? repository})
      : _repository = repository ?? OcrRepository();

  final ImagePicker _picker = ImagePicker();

  // Reactive States
  final Rx<OcrDocumentType> selectedDocType = OcrDocumentType.medicine.obs;
  final Rxn<XFile> pickedImage = Rxn<XFile>();
  final RxBool isScanning = false.obs;
  final RxString scanningStatus = ''.obs;
  final Rxn<OcrScanResultModel> scanResult = Rxn<OcrScanResultModel>();
  final RxString errorMessage = ''.obs;
  final RxString hints = ''.obs;

  void setDocumentType(OcrDocumentType type) {
    selectedDocType.value = type;
  }

  void clear() {
    pickedImage.value = null;
    scanResult.value = null;
    errorMessage.value = '';
    scanningStatus.value = '';
    isScanning.value = false;
  }

  /// Pick from Camera and auto-trigger scan
  Future<void> pickFromCamera({OcrDocumentType? type, bool autoScan = true}) async {
    await _pickImage(ImageSource.camera, type: type, autoScan: autoScan);
  }

  /// Pick from Gallery and auto-trigger scan
  Future<void> pickFromGallery({OcrDocumentType? type, bool autoScan = true}) async {
    await _pickImage(ImageSource.gallery, type: type, autoScan: autoScan);
  }

  Future<void> _pickImage(
    ImageSource source, {
    OcrDocumentType? type,
    bool autoScan = true,
  }) async {
    try {
      if (type != null) {
        selectedDocType.value = type;
      }
      errorMessage.value = '';

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return;

      pickedImage.value = image;
      scanResult.value = null;

      if (autoScan) {
        await scanImage();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      errorMessage.value = 'Failed to pick image: $e';
      UniqueSnackbar.showError(
        null,
        title: 'Image Selection Failed',
        message: 'Could not access the ${source == ImageSource.camera ? "camera" : "gallery"}.',
      );
    }
  }

  /// Convert picked image to base64 and invoke the OCR API
  Future<bool> scanImage() async {
    final image = pickedImage.value;
    if (image == null) {
      errorMessage.value = 'Please select or capture an image first';
      return false;
    }

    try {
      isScanning.value = true;
      errorMessage.value = '';
      scanningStatus.value = 'Encoding document...';

      final bytes = await image.readAsBytes();
      final base64Raw = base64Encode(bytes);
      final extension = image.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
      final dataUri = 'data:$mimeType;base64,$base64Raw';

      scanningStatus.value = 'Analyzing with Pharma OCR Engine...';

      final result = await _repository.scanDocument(
        documentType: selectedDocType.value.apiValue,
        base64Image: dataUri,
        hints: hints.value.trim().isNotEmpty ? hints.value.trim() : null,
      );

      scanResult.value = result;
      scanningStatus.value = 'Recognition complete!';

      UniqueSnackbar.showSuccess(
        null,
        title: 'OCR Scan Success',
        message: 'Extracted ${result.documentType} with ${(result.confidence * 100).toStringAsFixed(0)}% confidence',
      );
      return true;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      UniqueSnackbar.showError(
        null,
        title: 'Scan Error',
        message: e.message,
      );
      return false;
    } catch (e) {
      errorMessage.value = 'OCR Processing failed. Please retry with a clearer photo.';
      UniqueSnackbar.showError(
        null,
        title: 'Scan Failed',
        message: 'Could not recognize document. Ensure good lighting.',
      );
      return false;
    } finally {
      isScanning.value = false;
    }
  }
}
