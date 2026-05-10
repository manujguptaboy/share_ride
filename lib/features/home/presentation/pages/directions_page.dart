import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_ride/features/home/data/directions_api.dart';

class DirectionsPage extends StatefulWidget {
  const DirectionsPage({
    super.key,
    required this.origin,
    required this.destination,
  });

  final String origin;
  final String destination;

  @override
  State<DirectionsPage> createState() => _DirectionsPageState();
}

class _DirectionsPageState extends State<DirectionsPage> {
  final MapController _mapController = MapController();
  bool _isLoading = true;
  String? _error;
  String? _staticMapUrl;
  String _distance = '';
  String _duration = '';
  String _originAddress = '';
  String _destinationAddress = '';
  LatLng? _startPoint;
  LatLng? _endPoint;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _loadDirections();
  }

  Future<void> _loadDirections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await DirectionsApi.getDirections(
        origin: widget.origin,
        destination: widget.destination,
      );
      if (!mounted) return;
      final route = data['route'];
      if (route is! Map<String, dynamic>) {
        throw Exception('Invalid route data');
      }

      setState(() {
        _staticMapUrl = route['staticMapUrl'] as String?;
        _distance = (route['distanceText'] as String?) ?? '';
        _duration = (route['durationText'] as String?) ?? '';
        _originAddress = (route['origin'] as String?) ?? widget.origin;
        _destinationAddress =
            (route['destination'] as String?) ?? widget.destination;
        _startPoint = _latLngFromJson(route['startLocation']);
        _endPoint = _latLngFromJson(route['endLocation']);
        _routePoints = _decodePolylineSafe((route['polyline'] as String?) ?? '');
        if (_routePoints.length < 2 && _startPoint != null && _endPoint != null) {
          _routePoints = [_startPoint!, _endPoint!];
        }
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitRouteInView();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _startPoint ?? _endPoint ?? LatLng(20.5937, 78.9629);

    return Scaffold(
      appBar: AppBar(title: const Text('Ride Direction')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _loadDirections,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 320,
                          child: _buildMapPanel(center),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F3F7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.route_rounded),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _distance.isEmpty && _duration.isEmpty
                                            ? 'Route details unavailable'
                                            : '$_distance • $_duration',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(
                                  Icons.trip_origin,
                                  color: Colors.green,
                                ),
                                title: const Text('Start'),
                                subtitle: Text(_originAddress),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.place_outlined,
                                  color: Colors.red,
                                ),
                                title: const Text('Destination'),
                                subtitle: Text(_destinationAddress),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  /// Map is outside the scrolling [ListView] so pan/zoom gestures work on web & mobile.
  Widget _buildMapPanel(LatLng center) {
    final canUseTiles = _routePoints.isNotEmpty ||
        _startPoint != null ||
        _endPoint != null;

    if (canUseTiles) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: center,
                zoom: 13.5,
                minZoom: 3,
                maxZoom: 19,
                keepAlive: true,
                enableScrollWheel: true,
                interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.share_ride.app',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: const Color(0xFF4A35F3),
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_startPoint != null)
                      Marker(
                        point: _startPoint!,
                        width: 34,
                        height: 34,
                        builder: (_) => const Icon(
                          Icons.trip_origin,
                          color: Colors.green,
                          size: 30,
                        ),
                      ),
                    if (_endPoint != null)
                      Marker(
                        point: _endPoint!,
                        width: 34,
                        height: 34,
                        builder: (_) => const Icon(
                          Icons.place,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Column(
                children: [
                  _ZoomButton(
                    icon: Icons.add,
                    onTap: () => _nudgeZoom(1),
                  ),
                  const SizedBox(height: 8),
                  _ZoomButton(
                    icon: Icons.remove,
                    onTap: () => _nudgeZoom(-1),
                  ),
                  const SizedBox(height: 8),
                  _ZoomButton(
                    icon: Icons.fit_screen,
                    onTap: _fitRouteInView,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_staticMapUrl != null && _staticMapUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          _staticMapUrl!,
          height: 320,
          fit: BoxFit.cover,
        ),
      );
    }

    return const Center(child: Text('No map data'));
  }

  void _nudgeZoom(double delta) {
    final c = _mapController.center;
    final z = (_mapController.zoom + delta).clamp(3.0, 19.0);
    _mapController.move(c, z);
  }

  LatLng? _latLngFromJson(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    final lat = value['lat'];
    final lng = value['lng'];
    if (lat is! num || lng is! num) return null;
    return LatLng(lat.toDouble(), lng.toDouble());
  }

  List<LatLng> _decodePolylineSafe(String encoded) {
    if (encoded.isEmpty) return const [];

    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    int? nextValue() {
      int shift = 0;
      int result = 0;

      while (index < encoded.length) {
        final int byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) {
          return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
        }
      }
      return null;
    }

    while (index < encoded.length) {
      final dLat = nextValue();
      if (dLat == null) break;
      lat += dLat;

      final dLng = nextValue();
      if (dLng == null) break;
      lng += dLng;

      final latitude = lat / 1e5;
      final longitude = lng / 1e5;
      if (latitude >= -90 &&
          latitude <= 90 &&
          longitude >= -180 &&
          longitude <= 180) {
        points.add(LatLng(latitude, longitude));
      }
    }

    return points;
  }

  void _fitRouteInView() {
    final points = <LatLng>[
      ..._routePoints,
      if (_startPoint != null) _startPoint!,
      if (_endPoint != null) _endPoint!,
    ];
    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(
        padding: EdgeInsets.all(32),
        maxZoom: 16,
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
