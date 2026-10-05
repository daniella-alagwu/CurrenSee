import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:currensee/services/api_client.dart';


class NotificationService {
  NotificationService._();

  static final _controller = StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get foreground => _controller.stream;

  static StreamSubscription<RemoteMessage>? _msgSub;
  static StreamSubscription<String>? _tokenSub;
  static String? _token;

  static Future<void> start() async {
    try {
      final fm = FirebaseMessaging.instance;
      final settings = await fm.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      _token = await fm.getToken();
      if (_token != null) await _register(_token!);
      _tokenSub ??= fm.onTokenRefresh.listen((t) {
        _token = t;
        _register(t);
      });
      _msgSub ??= FirebaseMessaging.onMessage.listen(_controller.add);
    } catch (_) {
      // Push is optional; in-app notifications still work.
    }
  }

  static Future<void> _register(String token) async {
    try {
      await ApiClient.registerDeviceToken(token, Platform.isIOS ? 'ios' : 'android');
    } catch (_) {}
  }

  static Future<void> stop() async {
    final token = _token;
    _token = null;
    await _tokenSub?.cancel();
    _tokenSub = null;
    if (token == null) return;
    try {
      await ApiClient.removeDeviceToken(token);
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}