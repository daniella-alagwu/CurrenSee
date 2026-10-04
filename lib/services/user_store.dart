import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:currensee/services/api_client.dart';
import 'package:currensee/services/notification_service.dart';
import 'package:currensee/services/notification_store.dart';

/// Single source of truth for the signed-in user's profile + preferences.
class UserStore extends ChangeNotifier {
  UserStore._();
  static final UserStore instance = UserStore._();

  Map<String, dynamic> _user = const {};
  bool loaded = false;
  bool loading = false;
  String? error;
  Future<void>? _inflight;

  Map<String, dynamic> get _prefs =>
      (_user['preferences'] as Map<String, dynamic>?) ?? const {};

  String? get name => (_user['name'] as String?)?.trim();
  String get email =>
      (_user['email'] as String?) ?? FirebaseAuth.instance.currentUser?.email ?? '';
  String? get countryCode => _user['countryCode'] as String?;
  String? get countryName => _user['countryName'] as String?;
  String? get avatar => _user['avatar'] as String?;
  String? get baseCurrency => (_prefs['defaultBaseCurrency'] as String?)?.toUpperCase();
  String? get targetCurrency => (_prefs['defaultTargetCurrency'] as String?)?.toUpperCase();
  bool get pushEnabled => _asBool(_prefs['pushEnabled'], true);
  bool get alertsEnabled => _asBool(_prefs['alertNotificationsEnabled'], true);

  String get displayName {
    final n = name;
    if (n != null && n.isNotEmpty) return n;
    final local = email.split('@').first;
    if (local.isEmpty) return 'there';
    return local[0].toUpperCase() + local.substring(1);
  }

  static bool _asBool(Object? v, bool fallback) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    return fallback;
  }

  Future<void> load({bool force = false}) {
    if (loaded && !force) return Future.value();
    return _inflight ??= _fetch().whenComplete(() => _inflight = null);
  }

  Future<void> _fetch() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiClient.getCurrentUser();
      _user = (data['user'] as Map<String, dynamic>?) ?? const {};
      loaded = true;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Optimistic local update for a notification switch.
  void setPref(String key, bool value) {
    final p = Map<String, dynamic>.from(_prefs)..[key] = value;
    _user = {..._user, 'preferences': p};
    notifyListeners();
  }

  Future<void> signOut() async {
    await NotificationService.stop(); // needs the signed-in session, so before signOut
    NotificationStore.instance.stop();
    _user = const {};
    loaded = false;
    error = null;
    notifyListeners();
    await FirebaseAuth.instance.signOut();
  }
}