import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:share_ride/core/network/api_base_url.dart';

class AadhaarGenerateResult {
  const AadhaarGenerateResult({
    required this.referenceId,
    required this.message,
    this.testMode = false,
    this.testOtp,
  });

  final String referenceId;
  final String message;
  final bool testMode;
  final String? testOtp;
}

class AadhaarVerifyResult {
  const AadhaarVerifyResult({
    required this.message,
    required this.data,
  });

  final String message;
  final Map<String, dynamic> data;

  String? get name => data['name'] as String?;
  String? get dateOfBirth => data['date_of_birth'] as String?;
  String? get gender => data['gender'] as String?;
  String? get fullAddress => data['full_address'] as String?;
}

class AadhaarApi {
  static String get _baseUrl => '$apiBaseUrl/api/aadhaar';

  static Future<AadhaarGenerateResult> generateOtp({
    required String aadhaarNumber,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/otp/generate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'aadhaar_number': aadhaarNumber,
            'consent': 'y',
          }),
        )
        .timeout(const Duration(seconds: 30));

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return AadhaarGenerateResult(
        referenceId: '${data['referenceId'] ?? ''}',
        message: (data['message'] as String?) ?? 'OTP sent successfully',
        testMode: data['testMode'] == true,
        testOtp: data['testOtp'] as String?,
      );
    }

    throw Exception(
      (data['message'] as String?)?.trim().isNotEmpty == true
          ? data['message'] as String
          : 'Could not send Aadhaar OTP',
    );
  }

  static Future<AadhaarVerifyResult> verifyOtp({
    required int userId,
    required String referenceId,
    required String otp,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/otp/verify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'reference_id': referenceId,
            'otp': otp,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final data = _decodeJson(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      final kyc = data['data'];
      return AadhaarVerifyResult(
        message: (data['message'] as String?) ?? 'Aadhaar verified successfully',
        data: kyc is Map<String, dynamic> ? kyc : {},
      );
    }

    throw Exception(
      (data['message'] as String?)?.trim().isNotEmpty == true
          ? data['message'] as String
          : 'Aadhaar verification failed',
    );
  }

  static Map<String, dynamic> _decodeJson(String body) {
    if (body.isEmpty) return {};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }
}
