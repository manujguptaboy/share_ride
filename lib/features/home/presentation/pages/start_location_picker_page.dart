import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_ride/core/location/device_location.dart';
import 'package:share_ride/core/theme/ride_map_style.dart';
import 'package:share_ride/features/home/data/map_api.dart';

class StartLocationPickerPage extends StatefulWidget {
  const StartLocationPickerPage({super.key});

  @override
  State<StartLocationPickerPage> createState() => _StartLocationPickerPageState();
}

class _StartLocationPickerPageState extends State<StartLocationPickerPage> {
  final MapController _mapController = MapController();
  LatLng _selectedPoint = LatLng(20, 0);
  double _mapZoom = 3;
  bool _isLocating = true;
  bool _isResolvingName = false;
  String? _locationError;
  String _locationName = '';
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialCurrentLocation();
    });
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  String _shortPlaceName(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return 'Unknown location';

    final parts = trimmed
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0]}, ${parts[1]}';
    }
    return parts.first;
  }

  Future<void> _updateLocationName(LatLng point) async {
    setState(() => _isResolvingName = true);

    final address = await MapApi.reverseGeocode(
      lat: point.latitude,
      lng: point.longitude,
    );

    if (!mounted) return;
    setState(() {
      _isResolvingName = false;
      _locationName = _shortPlaceName(address);
    });
  }

  void _scheduleLocationNameUpdate(LatLng point) {
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 400), () {
      _updateLocationName(point);
    });
  }

  Future<void> _setInitialCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    final result = await DeviceLocation.getCurrent();
    if (!mounted) return;

    if (result.isSuccess) {
      final position = result.position!;
      final current = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPoint = current;
        _mapZoom = 15;
        _isLocating = false;
        _locationError = null;
      });
      _mapController.move(current, 15);
      await _updateLocationName(current);
      return;
    }

    setState(() {
      _isLocating = false;
      _locationError = result.errorMessage;
    });
  }

  void _onMapCenterChanged(LatLng center) {
    setState(() => _selectedPoint = center);
    _scheduleLocationNameUpdate(center);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _selectedPoint,
                zoom: _mapZoom,
                onPositionChanged: (position, hasGesture) {
                  final center = position.center;
                  if (center != null) {
                    _onMapCenterChanged(center);
                  }
                },
              ),
              children: [RideMapStyle.tileLayer()],
            ),
          ),
          if (_isLocating)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: IgnorePointer(
                child: _CenterMapPin(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _MapIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 168 + bottomInset,
            child: RideMapStyle.myLocationButton(
              onPressed: _isLocating ? null : _setInitialCurrentLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: RideMapStyle.accentColor,
                      ),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      size: 22,
                      color: RideMapStyle.accentColor,
                    ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_locationError != null) ...[
                    Text(
                      _locationError!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 22,
                        color: RideMapStyle.accentColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isResolvingName
                            ? const Text(
                                'Finding nearby place...',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              )
                            : Text(
                                _locationName.isEmpty
                                    ? 'Move the map to select a location'
                                    : _locationName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: (_isLocating || _isResolvingName)
                          ? null
                          : () => Navigator.pop(context, _selectedPoint),
                      style: FilledButton.styleFrom(
                        backgroundColor: RideMapStyle.accentColor,
                        disabledBackgroundColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm pickup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterMapPin extends StatelessWidget {
  const _CenterMapPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: RideMapStyle.pinColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Container(
          width: 2,
          height: 10,
          color: RideMapStyle.pinColor,
        ),
      ],
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: RideMapStyle.accentColor),
        ),
      ),
    );
  }
}
