/// Web stub — dart:io is not available on web.
/// The ConnectivityController uses _checkViaHttp() for web,
/// so this function should never actually be called on web.
Future<bool> checkInternetIO() async {
  // Web platform: always return true (HTTP check is used instead)
  return true;
}
