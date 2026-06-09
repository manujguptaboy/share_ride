import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Uber-inspired light map styling shared across map screens.
class RideMapStyle {
  RideMapStyle._();

  static const Color routeColor = Color(0xFF000000);
  static const Color pinColor = Color(0xFF000000);
  static const Color accentColor = Color(0xFF000000);
  static const double routeStrokeWidth = 5;
  static const double mapBorderRadius = 16;

  static const String _tileUrl =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

  static TileLayer tileLayer() {
    return TileLayer(
      urlTemplate: _tileUrl,
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.share_ride.app',
    );
  }

  static Widget pickupPin({double size = 36}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.55,
            height: size * 0.55,
            decoration: BoxDecoration(
              color: pinColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget dropoffPin({double size = 36}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: pinColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget centerPickerPin({double size = 44}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on,
          size: size,
          color: pinColor,
          shadows: const [
            Shadow(
              color: Color(0x44000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ],
    );
  }

  static Widget myLocationButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return Material(
      elevation: 4,
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: child),
        ),
      ),
    );
  }
}
