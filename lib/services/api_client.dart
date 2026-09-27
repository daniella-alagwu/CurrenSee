import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static Map<String, dynamic>? _pendingSignupProfile;
  static String? _pendingSignupUid;

  
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static void keepPendingSignupProfile({
    required String firebaseUid,
    required String countryCode,
    required String countryName,
    required String currencyCode,
    String? currencyName,
    String? currencySymbol,
  }) {
    _pendingSignupUid = firebaseUid;
    _pendingSignupProfile = {
      'countryCode': countryCode,
      'countryName': countryName,
      'currencyCode': currencyCode,
      if (currencyName != null) 'currencyName': currencyName,
      if (currencySymbol != null) 'currencySymbol': currencySymbol,
    };
  }

  static Future<Map<String, dynamic>> _authedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw ApiException('Not signed in.');
    final token = await user.getIdToken();

    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw ApiException(
        'Could not reach CurrenSee backend at $baseUrl. Check that it is running and the address is correct. ($error)',
      );
    }

    dynamic payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'The backend returned an unreadable response (${response.statusCode}).',
      );
    }
    final decoded = payload is Map<String, dynamic>
        ? payload
        : <String, dynamic>{};
    if (response.statusCode >= 400) {
      final error = decoded['error'];
      final message = error is Map<String, dynamic>
          ? error['message'] ?? 'Something went wrong.'
          : 'Something went wrong.';
      throw ApiException(message);
    }
    return decoded;
  }

  static Future<void> registerProfile({
    String? name,
    String? countryCode,
    String? countryName,
    String? currencyCode,
    String? currencyName,
    String? currencySymbol,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final pending = currentUid == _pendingSignupUid
        ? _pendingSignupProfile
        : null;
    final body = <String, dynamic>{...?pending};
    if (name != null) body['name'] = name;
    if (countryCode != null) body['countryCode'] = countryCode;
    if (countryName != null) body['countryName'] = countryName;
    if (currencyCode != null) body['currencyCode'] = currencyCode;
    if (currencyName != null) body['currencyName'] = currencyName;
    if (currencySymbol != null) body['currencySymbol'] = currencySymbol;
    await _authedPost('/users/create', body);
    if (currentUid == _pendingSignupUid) {
      _pendingSignupProfile = null;
      _pendingSignupUid = null;
    }
  }

  static Future<void> sendOtp() async {
    await _authedPost('/users/otp/send', {});
  }

  static Future<void> verifyOtp(String code) async {
    await _authedPost('/users/otp/verify', {'code': code});
  }
}
