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

  static Future<Map<String, dynamic>> _authedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw ApiException('Not signed in.');
    final token = await user.getIdToken();
    if (token == null) throw ApiException('Could not refresh your sign-in token.');

    late final http.Response response;
    try {
      var uri = Uri.parse('$baseUrl$path');
      if (queryParameters != null) {
        uri = uri.replace(queryParameters: queryParameters);
      }
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final requestBody = jsonEncode(body ?? {});
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 15),
          );
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: requestBody)
              .timeout(const Duration(seconds: 15));
          break;
        case 'PATCH':
          response = await http
              .patch(uri, headers: headers, body: requestBody)
              .timeout(const Duration(seconds: 15));
          break;
        default:
          throw ApiException('Unsupported API request method: $method');
      }
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

  static Future<Map<String, dynamic>> _authedPost(
    String path,
    Map<String, dynamic> body,
  ) =>
      _authedRequest('POST', path, body: body);

  static Future<Map<String, dynamic>> _authedGet(String path) =>
      _authedRequest('GET', path);

  static Future<Map<String, dynamic>> _authedPatch(
    String path,
    Map<String, dynamic> body,
  ) =>
      _authedRequest('PATCH', path, body: body);

  static Future<Map<String, dynamic>> getCurrentUser() =>
      _authedGet('/users/me');

  static Future<Map<String, dynamic>> getPreferences() =>
      _authedGet('/users/preferences');

  static Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> changes,
  ) =>
      _authedPatch('/users/preferences', changes);

  static Future<Map<String, dynamic>> saveConversion({
    required String fromCode,
    required String toCode,
    required String amount,
    required String rateUsed,
  }) =>
      _authedPost('/users/conversions', {
        'fromCode': fromCode,
        'toCode': toCode,
        'amount': amount,
        'rateUsed': rateUsed,
      });

  static Future<Map<String, dynamic>> getConversionHistory({
    int limit = 50,
    int offset = 0,
  }) =>
      _authedRequest(
        'GET',
        '/users/conversions',
        queryParameters: {
          'limit': '$limit',
          'offset': '$offset',
        },
      );

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

  static Future<Map<String, dynamic>> getAdminIdentity() =>
      _authedGet('/admin/me');
}
