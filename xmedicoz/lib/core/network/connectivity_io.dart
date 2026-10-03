import 'dart:io';

/// dart:io based internet check for mobile/desktop
Future<bool> checkInternetIO() async {
  try {
    final dnsResult = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 4));
    if (dnsResult.isNotEmpty && dnsResult[0].rawAddress.isNotEmpty) {
      return true;
    }
  } catch (_) {
    // DNS lookup failed, try reaching server directly
    try {
      final socket = await Socket.connect('xmedicoz.com', 443,
          timeout: const Duration(seconds: 4));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
  return false;
}
