import 'package:shared_preferences/shared_preferences.dart';


class SessionInfo {
  const SessionInfo({required this.isAdmin});
  final bool isAdmin;
}

class SessionStore {
  SessionStore._();

  static const _kUid = 'session_uid';
  static const _kAdmin = 'session_is_admin';

  //the saved session, or null if there isn't one for this user.
  static Future<SessionInfo?> load(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_kUid) != uid) return null;
      return SessionInfo(isAdmin: prefs.getBool(_kAdmin) ?? false);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String uid, {required bool isAdmin}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUid, uid);
      await prefs.setBool(_kAdmin, isAdmin);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUid);
      await prefs.remove(_kAdmin);
    } catch (_) {}
  }
}