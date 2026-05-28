import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../domain/player_level.dart';
import '../domain/achievement.dart';
import '../domain/daily_mission.dart';

class ProgressionStorage {
  // ── XP / Level ──────────────────────────────────────────────────────────

  static const _xpKey = 'progression_xp';
  static const _levelKey = 'progression_level';
  static const _totalXpKey = 'progression_total_xp';

  static Future<PlayerLevel> loadPlayerLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return PlayerLevel(
      level: prefs.getInt(_levelKey) ?? 1,
      currentXp: prefs.getInt(_xpKey) ?? 0,
      totalXp: prefs.getInt(_totalXpKey) ?? 0,
    );
  }

  static Future<void> savePlayerLevel(PlayerLevel level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_levelKey, level.level);
    await prefs.setInt(_xpKey, level.currentXp);
    await prefs.setInt(_totalXpKey, level.totalXp);
  }

  // ── Achievements ────────────────────────────────────────────────────────

  static const _achievementsKey = 'progression_achievements';

  static Future<Map<String, Achievement>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_achievementsKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final result = <String, Achievement>{};
    for (final e in map.entries) {
      result[e.key] = Achievement.fromJson(e.key, e.value as Map<String, dynamic>);
    }
    // Merge with registry to get titles/descriptions/targets
    for (final a in AchievementRegistry.all()) {
      if (result.containsKey(a.id)) {
        result[a.id] = a.copyWith(
          progress: result[a.id]!.progress,
          unlocked: result[a.id]!.unlocked,
          unlockedAt: result[a.id]!.unlockedAt,
        );
      } else {
        result[a.id] = a;
      }
    }
    return result;
  }

  static Future<void> saveAchievements(Map<String, Achievement> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, Map<String, dynamic>>{};
    for (final e in achievements.entries) {
      map[e.key] = e.value.toJson();
    }
    await prefs.setString(_achievementsKey, jsonEncode(map));
  }

  // ── Daily Missions ──────────────────────────────────────────────────────

  static const _missionsKey = 'progression_missions';
  static const _missionsDateKey = 'progression_missions_date';
  static const _totalMissionsKey = 'progression_total_missions';

  static Future<int> loadTotalMissionsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalMissionsKey) ?? 0;
  }

  static Future<void> saveTotalMissionsCompleted(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalMissionsKey, count);
  }

  static Future<List<DailyMission>> loadMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = prefs.getString(_missionsDateKey);
    final today = DailyMission.todayKey();

    // Reset if different day
    if (dateKey != today) {
      final newMissions = generateDailyMissions();
      await saveMissions(newMissions, today);
      return newMissions;
    }

    final raw = prefs.getString(_missionsKey);
    if (raw == null) {
      final newMissions = generateDailyMissions();
      await saveMissions(newMissions, today);
      return newMissions;
    }

    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => DailyMission.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveMissions(List<DailyMission> missions, [String? dateKey]) async {
    final prefs = await SharedPreferences.getInstance();
    final list = missions.map((m) => m.toJson()).toList();
    await prefs.setString(_missionsKey, jsonEncode(list));
    await prefs.setString(_missionsDateKey, dateKey ?? DailyMission.todayKey());
  }

  // ── First Win of Day ─────────────────────────────────────────────────────

  static const _firstWinDateKey = 'progression_first_win_date';

  static Future<bool> hasClaimedFirstWinToday() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_firstWinDateKey);
    final today = DailyMission.todayKey();
    return saved == today;
  }

  static Future<void> markFirstWinClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_firstWinDateKey, DailyMission.todayKey());
  }
}
