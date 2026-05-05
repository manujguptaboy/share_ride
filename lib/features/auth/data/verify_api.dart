import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:share_ride/core/network/api_base_url.dart';

class VerifyApi {
  static String get _baseUrl => '$apiBaseUrl/api/otp';

  static Future<void> sendOtp(String phone) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/send'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 25));

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return;
    }
    throw Exception(
      (data['message'] as String?)?.trim().isNotEmpty == true
          ? data['message'] as String
          : 'Could not send OTP',
    );
  }

  static Future<void> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/verify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            'code': code,
          }),
        )
        .timeout(const Duration(seconds: 25));

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return;
    }
    throw Exception(
      (data['message'] as String?)?.trim().isNotEmpty == true
          ? data['message'] as String
          : 'Verification failed',
    );
  }

  static Map<String, dynamic> _decodeJson(String body) {
    if (body.isEmpty) return {};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }
}
