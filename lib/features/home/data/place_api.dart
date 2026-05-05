import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:share_ride/core/network/api_base_url.dart';

class PlaceApi {
  static String get _baseUrl => '$apiBaseUrl/api/places';

  static Future<List<String>> autocomplete(String input) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/autocomplete').replace(
        queryParameters: {'input': input},
      ),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return [];
    }

    final suggestions = decoded['suggestions'];
    if (suggestions is! List) {
      return [];
    }

    return suggestions
        .map(
          (item) =>
              item is Map<String, dynamic> ? item['description'] as String? : null,
        )
        .whereType<String>()
        .toList();
  }
}
