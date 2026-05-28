import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/adventure_content.dart';

class AdventureStorage {
  static const _missionKey = 'adventure_missions';
  static const _chestKey = 'adventure_chests';
  static const _fragmentKey = 'adventure_fragments';
  static const _streakKey = 'adventure_streak';
  static const _codexKey = 'adventure_codex';
  static const _mentorKey = 'adventure_mentor';
  static const _tutorialKey = 'adventure_tutorials_seen';
  static const _worldCompletionKey = 'adventure_world_completion';

  // ── Missions ───────────────────────────────────────────────────────────

  static Future<WorldMissionProgress> loadMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_missionKey);
    if (raw == null) return const WorldMissionProgress();
    try {
      return WorldMissionProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const WorldMissionProgress();
    }
  }

  static Future<void> saveMissions(WorldMissionProgress p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_missionKey, jsonEncode(p.toJson()));
  }

  // ── Chests ─────────────────────────────────────────────────────────────

  static Future<Map<String, WorldChest>> loadChests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chestKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, WorldChest.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveChests(Map<String, WorldChest> chests) async {
    final prefs = await SharedPreferences.getInstance();
    final map = chests.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_chestKey, jsonEncode(map));
  }

  // ── Fragments ──────────────────────────────────────────────────────────

  static Future<FragmentProgress> loadFragments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_fragmentKey);
    if (raw == null) return const FragmentProgress();
    try {
      return FragmentProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const FragmentProgress();
    }
  }

  static Future<void> saveFragments(FragmentProgress p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fragmentKey, jsonEncode(p.toJson()));
  }

  // ── Streak ─────────────────────────────────────────────────────────────

  static Future<PerfectStreak> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_streakKey);
    if (raw == null) return const PerfectStreak();
    try {
      return PerfectStreak.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const PerfectStreak();
    }
  }

  static Future<void> saveStreak(PerfectStreak s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_streakKey, jsonEncode(s.toJson()));
  }

  // ── Codex ──────────────────────────────────────────────────────────────

  static Future<CodexProgress> loadCodex() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_codexKey);
    if (raw == null) return const CodexProgress();
    try {
      return CodexProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const CodexProgress();
    }
  }

  static Future<void> saveCodex(CodexProgress c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codexKey, jsonEncode(c.toJson()));
  }

  // ── Mentor ────────────────────────────────────────────────────────────

  static Future<Set<String>> loadMentorSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_mentorKey);
    return raw?.toSet() ?? {};
  }

  static Future<void> saveMentorSeen(Set<String> seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_mentorKey, seen.toList());
  }

  // ── Tutorials ──────────────────────────────────────────────────────────

  static Future<Set<String>> loadTutorialsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_tutorialKey);
    return raw?.toSet() ?? {};
  }

  static Future<void> saveTutorialsSeen(Set<String> seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_tutorialKey, seen.toList());
  }

  // ── World Completion ───────────────────────────────────────────────────

  static Future<WorldCompletionProgress> loadWorldCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_worldCompletionKey);
    if (raw == null) return const WorldCompletionProgress();
    try {
      return WorldCompletionProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const WorldCompletionProgress();
    }
  }

  static Future<void> saveWorldCompletion(WorldCompletionProgress p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_worldCompletionKey, jsonEncode(p.toJson()));
  }
}
