import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';

// Conditional import for dart:io (not available on web)
import 'connectivity_io.dart' if (dart.library.html) 'connectivity_web.dart'
    as platform_check;

class ConnectivityController extends GetxController {
  static ConnectivityController get to => Get.find<ConnectivityController>();

  final RxBool isOffline = false.obs;
  final RxBool isChecking = false.obs;
  final RxBool showBackOnline = false.obs;
  final RxString statusMessage =
      'Unable to reach server. Please check your internet.'.obs;

  Timer? _pollingTimer;
  Timer? _backOnlineDismissTimer;

  @override
  void onInit() {
    super.onInit();

    if (kIsWeb) {
      // On web: The app loaded successfully = internet is working.
      // We rely on ApiClient callbacks (onNetworkError/onNetworkSuccess)
      // for real-time status updates. No polling needed.
      isOffline.value = false;
    } else {
      // Mobile/Desktop: Use dart:io based proactive checks
      checkConnectivity();
      _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        checkConnectivity(silent: true);
      });
    }
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    _backOnlineDismissTimer?.cancel();
    super.onClose();
  }

  /// Proactively test network & backend reachability
  Future<bool> checkConnectivity({bool silent = false}) async {
    // On web, skip proactive checking — rely on API callbacks
    if (kIsWeb) return true;

    if (!silent) isChecking.value = true;

    bool hasInternet = false;

    try {
      hasInternet = await platform_check.checkInternetIO();
    } catch (_) {
      hasInternet = false;
    }

    if (hasInternet) {
      if (isOffline.value) {
        _triggerBackOnlineToast();
      }
      isOffline.value = false;
    } else {
      isOffline.value = true;
      statusMessage.value = 'Internet disconnected. Sync is paused.';
    }

    if (!silent) isChecking.value = false;
    return hasInternet;
  }

  /// Called directly by ApiClient when network error occurs
  void onNetworkError(String message) {
    if (!isOffline.value) {
      isOffline.value = true;
      statusMessage.value = message;
    }
  }

  /// Called directly by ApiClient on any successful response
  void onNetworkSuccess() {
    if (isOffline.value) {
      isOffline.value = false;
      _triggerBackOnlineToast();
    }
  }

  void _triggerBackOnlineToast() {
    showBackOnline.value = true;
    _backOnlineDismissTimer?.cancel();
    _backOnlineDismissTimer = Timer(const Duration(seconds: 3), () {
      showBackOnline.value = false;
    });
  }
}
