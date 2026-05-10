import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:share_ride/core/network/api_base_url.dart';

class MapApi {
  static String get _baseUrl => '$apiBaseUrl/api/maps';

  static Future<String> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/reverse-geocode').replace(
            queryParameters: {
              'lat': lat.toString(),
              'lng': lng.toString(),
            },
          ),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return '';
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return '';
    final location = decoded['location'];
    if (location is! Map<String, dynamic>) return '';
    final formattedAddress = location['formattedAddress'];
    return formattedAddress is String ? formattedAddress : '';
  }
}
