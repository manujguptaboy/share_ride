import 'package:flutter/foundation.dart' show kIsWeb;

import 'platform/platform_stub.dart'
    if (dart.library.io) 'platform/platform_io.dart';

/// Override at runtime with:
/// `--dart-define=API_BASE_URL=http://<host>:3008`
const String _overrideBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: '');

String get apiBaseUrl {
  if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;

  if (kIsWeb) {
    return 'http://localhost:3008';
  }
    // debugPrint('apiBaseUrl: $_overrideBaseUrl');
    // debugPrint('kIsWeb: $kIsWeb');
    // debugPrint('isAndroid: $isAndroid');
    // debugPrint('isIOS: $isIOS');
    // debugPrint('isMacOS: $isMacOS');
    // debugPrint('isWindows: $isWindows');
    // debugPrint('isLinux: $isLinux');

  if (isMacOS) {
    // Desktop app running on the same machine as backend.
    return 'http://localhost:3008';
  }

  // macOS/Windows/Linux desktop and iOS simulator usually work with localhost.
  // For physical devices, pass API_BASE_URL with your laptop LAN IP.
  return 'http://localhost:3008';
} 

