import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _key = "nocta_session_step";

  static Future<int> getStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  static Future<int> incrementStep() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key) ?? 0;
    final next = current + 1;
    await prefs.setInt(_key, next);
    return next;
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
