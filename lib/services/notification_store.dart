import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:currensee/services/api_client.dart';

/// In-app notification inbox + unread badge count.
class NotificationStore extends ChangeNotifier {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  List<Map<String, dynamic>> items = const [];
  int unread = 0;
  bool loaded = false;
  String? error;
  Timer? _timer;

  void start() {
    refresh();
    _timer ??= Timer.periodic(const Duration(seconds: 60), (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    items = const [];
    unread = 0;
    loaded = false;
    error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final data = await ApiClient.getNotifications();
      items = (data['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      unread = (data['unread'] as num?)?.toInt() ?? 0;
      loaded = true;
      error = null;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (unread == 0) return;
    try {
      await ApiClient.markNotificationsRead();
      items = [for (final i in items) {...i, 'isRead': true}];
      unread = 0;
      notifyListeners();
    } catch (_) {}
  }
}