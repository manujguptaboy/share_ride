import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:share_ride/core/network/api_base_url.dart';

class AuthApi {
  static String get _baseUrl => '$apiBaseUrl/api/auth';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    debugPrint('login baseUrl: $_baseUrl');
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));

    debugPrint('login response: $response');
    final data = _decodeResponse(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message'] ?? 'Login failed');
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required bool agreeToTerms,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'confirmPassword': confirmPassword,
        'agreeToTerms': agreeToTerms,
      }),
    );

    final data = _decodeResponse(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message'] ?? 'Signup failed');
  }

  static Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {};
  }
}
