import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/daily_streak.dart';

class StreakStorage {
  static const _key = 'daily_streak';

  static Future<DailyStreak> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const DailyStreak();
    try {
      return DailyStreak.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const DailyStreak();
    }
  }

  static Future<void> save(DailyStreak streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(streak.toJson()));
  }
}
