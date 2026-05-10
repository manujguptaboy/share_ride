import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:share_ride/core/network/api_base_url.dart';

class DirectionsApi {
  static String get _baseUrl => '$apiBaseUrl/api/maps';

  static Future<Map<String, dynamic>> getDirections({
    required String origin,
    required String destination,
  }) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/directions').replace(
            queryParameters: {
              'origin': origin,
              'destination': destination,
            },
          ),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));

    final body = response.body;
    if (body.isEmpty) {
      throw Exception('Empty response from directions API');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response from directions API');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['success'] == true) {
      return decoded;
    }

    throw Exception((decoded['message'] as String?) ?? 'Unable to get directions');
  }
}
