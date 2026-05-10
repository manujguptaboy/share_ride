import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class StartLocationPickerPage extends StatefulWidget {
  const StartLocationPickerPage({super.key});

  @override
  State<StartLocationPickerPage> createState() => _StartLocationPickerPageState();
}

class _StartLocationPickerPageState extends State<StartLocationPickerPage> {
  final MapController _mapController = MapController();
  LatLng _selectedPoint = LatLng(18.5204, 73.8567);
  bool _isLocating = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _setInitialCurrentLocation();
  }

  Future<void> _setInitialCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
          _locationError = 'Location service is disabled on your device.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
          _locationError = 'Location permission denied.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final current = LatLng(position.latitude, position.longitude);
      if (!mounted) return;

      setState(() {
        _selectedPoint = current;
        _isLocating = false;
      });
      _mapController.move(current, 15);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLocating = false;
        _locationError = 'Could not fetch current location.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Starting Location')),
      body: Column(
        children: [
          if (_isLocating) const LinearProgressIndicator(),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _selectedPoint,
                zoom: 14,
                onPositionChanged: (position, hasGesture) {
                  final center = position.center;
                  if (center != null) {
                    setState(() {
                      _selectedPoint = center;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.share_ride.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 42,
                      height: 42,
                      builder: (_) => const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_locationError != null) ...[
                  Text(
                    _locationError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _setInitialCurrentLocation,
                    child: const Text('Try current location again'),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Selected: ${_selectedPoint.latitude.toStringAsFixed(5)}, '
                  '${_selectedPoint.longitude.toStringAsFixed(5)}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _selectedPoint),
                  child: const Text('Use This Starting Location'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
