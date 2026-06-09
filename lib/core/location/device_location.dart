import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_ride/core/network/platform/platform_io.dart'
    if (dart.library.html) 'package:share_ride/core/network/platform/platform_stub.dart';

class DeviceLocationResult {
  const DeviceLocationResult.success(this.position)
      : errorMessage = null;

  const DeviceLocationResult.failure(this.errorMessage) : position = null;

  final Position? position;
  final String? errorMessage;

  bool get isSuccess => position != null;
}

class DeviceLocation {
  static bool get _isDesktop => isMacOS || isWindows || isLinux;

  static Duration get _primaryTimeout =>
      _isDesktop ? const Duration(seconds: 45) : const Duration(seconds: 20);

  static Duration get _fallbackTimeout =>
      _isDesktop ? const Duration(seconds: 30) : const Duration(seconds: 15);

  static Future<DeviceLocationResult> getCurrent() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return DeviceLocationResult.failure(_serviceDisabledMessage());
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return DeviceLocationResult.failure(_permissionDeniedMessage());
      }

      if (permission == LocationPermission.deniedForever) {
        return DeviceLocationResult.failure(_permissionDeniedForeverMessage());
      }

      final position = await _resolvePosition();
      if (position != null) {
        return DeviceLocationResult.success(position);
      }

      return DeviceLocationResult.failure(_unavailableMessage());
    } catch (error, stackTrace) {
      debugPrint('DeviceLocation error: $error');
      debugPrint('$stackTrace');
      return DeviceLocationResult.failure(_mapErrorToMessage(error));
    }
  }

  static Future<Position?> _resolvePosition() async {
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null && _isFreshEnough(lastKnown)) {
      return lastKnown;
    }

    final attempts = _isDesktop
        ? [
            (LocationAccuracy.medium, _primaryTimeout),
            (LocationAccuracy.low, _fallbackTimeout),
            (LocationAccuracy.lowest, _fallbackTimeout),
          ]
        : [
            (LocationAccuracy.high, _primaryTimeout),
            (LocationAccuracy.medium, _fallbackTimeout),
          ];

    for (final (accuracy, timeout) in attempts) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
          timeLimit: timeout,
        );
        return position;
      } catch (error) {
        debugPrint(
          'DeviceLocation attempt failed ($accuracy): $error',
        );
      }
    }

    if (lastKnown != null) {
      return lastKnown;
    }

    return null;
  }

  static bool _isFreshEnough(Position position) {
    final age = DateTime.now().difference(position.timestamp);
    return age < const Duration(minutes: 30);
  }

  static String _serviceDisabledMessage() {
    if (isMacOS) {
      return 'Turn on Location Services in System Settings → Privacy & Security → Location Services.';
    }
    return 'Location services are off. Enable them in device settings or pick a point on the map.';
  }

  static String _permissionDeniedMessage() {
    if (isMacOS) {
      return 'Allow location for share_ride in System Settings → Privacy & Security → Location Services.';
    }
    return 'Location permission denied. Allow location access in settings or pick a point on the map.';
  }

  static String _permissionDeniedForeverMessage() {
    if (isMacOS) {
      return 'Location access is blocked. Enable share_ride under System Settings → Privacy & Security → Location Services.';
    }
    return 'Location permission permanently denied. Enable it in app settings or pick a point on the map.';
  }

  static String _unavailableMessage() {
    if (isMacOS) {
      return 'Mac could not determine your location (Wi‑Fi positioning). Pan the map to your start point, or enable Precise Location for share_ride in System Settings.';
    }
    return 'Could not detect your location. Pan the map to select your starting point.';
  }

  static String _mapErrorToMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('timeout') || message.contains('timed out')) {
      if (isMacOS) {
        return 'Location timed out on Mac. Ensure Wi‑Fi is on, allow share_ride in Location Services, then tap the location button again.';
      }
      return 'Location request timed out. Try again or pick a point on the map.';
    }
    return _unavailableMessage();
  }
}
