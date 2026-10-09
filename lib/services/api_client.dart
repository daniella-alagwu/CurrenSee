import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;

  bool get isSuspended => code == 'ACCOUNT_SUSPENDED';
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  /// Holds the Firebase uid of a user the backend reported as suspended
  /// (HTTP 403 ACCOUNT_SUSPENDED). AuthGate listens to this and shows the
  /// suspended page instead of the app. Set back to null when reactivated.
  static final ValueNotifier<String?> suspendedUid = ValueNotifier<String?>(null);

  static Map<String, dynamic>? _pendingSignupProfile;
  static String? _pendingSignupUid;

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://currensee-f0sf.onrender.com/api',
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
      'currencyName': currencyName,
      'currencySymbol': currencySymbol,
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
      final code = error is Map<String, dynamic> ? error['code'] as String? : null;
      if (code == 'ACCOUNT_SUSPENDED') {
        suspendedUid.value = user.uid;
      }
      throw ApiException('$message', code: code, statusCode: response.statusCode);
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

  static List<Map<String, dynamic>> _items(Map<String, dynamic> d) =>
      (d['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();

  // User Base Info
  static Future<Map<String, dynamic>> getCurrentUser() =>
      _authedGet('/users/me');

  static Future<Map<String, dynamic>> getPreferences() =>
      _authedGet('/users/preferences');

  static Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> changes,
  ) =>
      _authedPatch('/users/preferences', changes);

  static Future<void> updateProfile(Map<String, dynamic> changes) async {
    await _authedPatch('/users/profile', changes);
  }

  // Support chat (user side)
  static Future<List<Map<String, dynamic>>> getMessages() async =>
      _items(await _authedGet('/users/messages'));

  static Future<void> sendMessage(String body) async {
    await _authedPost('/users/messages', {'body': body});
  }

  /// Suspended users: sends an appeal. The server tags it ACCOUNT_SUSPENSION_APPEAL
  /// so it shows up in the admin's support inbox as an appeal.
  static Future<void> submitSuspensionAppeal(String body) async {
    await _authedPost('/users/suspension-appeal', {'body': body});
  }

  /// 'ACTIVE' or 'SUSPENDED'. /users/me is not blocked for suspended accounts.
  static Future<String> getMyStatus() async {
    final data = await getCurrentUser();
    final user = data['user'];
    final status = user is Map<String, dynamic> ? user['status'] : null;
    return '${status ?? 'ACTIVE'}'.toUpperCase();
  }

  // Support chat (admin side)
  static Future<List<Map<String, dynamic>>> getAdminThreads() async =>
      _items(await _authedGet('/admin/messages/threads'));

  static Future<List<Map<String, dynamic>>> getAdminThread(int userId) async =>
      _items(await _authedGet('/admin/messages/threads/$userId'));

  static Future<void> adminReply(int userId, String body) async {
    await _authedPost('/admin/messages/threads/$userId', {'body': body});
  }

  // Admin: dashboard + user management
  static Future<Map<String, dynamic>> getAdminStats() =>
      _authedGet('/admin/stats');

  /// { items: [...], total, limit, offset }
  static Future<Map<String, dynamic>> getAdminUsers({
    String query = '',
    int limit = 30,
    int offset = 0,
  }) =>
      _authedRequest(
        'GET',
        '/admin/users',
        queryParameters: {'q': query, 'limit': '$limit', 'offset': '$offset'},
      );

  /// { user: {...} }
  static Future<Map<String, dynamic>> getAdminUser(int id) =>
      _authedGet('/admin/users/$id');

  /// action: suspend | unsuspend | promote | demote | delete
  static Future<void> adminUserAction(int id, String action) async {
    await _authedPost('/admin/users/$id/$action', {});
  }

  // Push notifications & alerts
  static Future<void> registerDeviceToken(String token, String platform) async {
    await _authedPost('/users/device-token', {'token': token, 'platform': platform});
  }

  static Future<void> removeDeviceToken(String token) async {
    await _authedPost('/users/device-token/remove', {'token': token});
  }

  static Future<Map<String, dynamic>> getNotifications() =>
      _authedGet('/users/notifications');

  static Future<void> markNotificationsRead() async {
    await _authedPost('/users/notifications/read', {});
  }

  static Future<List<Map<String, dynamic>>> getAlerts() async =>
      _items(await _authedGet('/users/alerts'));

  static Future<void> createAlert({
    required String baseCode,
    required String targetCode,
    required String threshold,
    required String direction, // 'ABOVE' | 'BELOW'
  }) async {
    await _authedPost('/users/alerts', {
      'baseCode': baseCode,
      'targetCode': targetCode,
      'threshold': threshold,
      'direction': direction,
    });
  }

  static Future<void> deleteAlert(int id) async {
    await _authedPost('/users/alerts/$id/delete', {});
  }

  // Conversions
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


// Market news

static Future<List<Map<String, dynamic>>> getNews({
  int limit = 20,
}) async =>
    _items(
      await _authedRequest(
        'GET',
        '/users/news',
        queryParameters: {
          'limit': '$limit',
        },
      ),
    );


  // Verification & Admin Identity Endpoints
  static Future<void> sendOtp() async {
    await _authedPost('/users/otp/send', {});
  }

  static Future<void> verifyOtp(String code) async {
    await _authedPost('/users/otp/verify', {'code': code});
  }

  static Future<Map<String, dynamic>> getAdminIdentity() =>
      _authedGet('/admin/me');

  // Authentication Signup Profile
  static Future<void> registerProfile({
    String? name,
    String? countryCode,
    String? countryName,
    String? currencyCode,
    String? currencyName,
    String? currencySymbol,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final pending = currentUid == _pendingSignupUid ? _pendingSignupProfile : null;

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
}