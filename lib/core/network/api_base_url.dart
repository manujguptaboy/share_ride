import 'package:flutter/foundation.dart' show kDebugMode;

/// Deployed backend (Render).
const String productionApiBaseUrl = 'https://share-ride-backend.onrender.com';

/// Local backend when developing on the same machine.
const String localApiBaseUrl = 'http://localhost:3008';

/// Override at runtime with:
/// `--dart-define=API_BASE_URL=http://<host>:3008`
const String _overrideBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: '');

String get apiBaseUrl {
  if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
  if (kDebugMode) return localApiBaseUrl;
  return productionApiBaseUrl;
} 

