import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DailyChallengeStorage {
  static const _completedKey = 'daily_challenge_completed';
  static const _boardIdKey = 'daily_challenge_board_id';
  static const _dateKey = 'daily_challenge_date';
  static const _gameStateKey = 'daily_challenge_game_state';

  static String _todayKey() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<bool> _isToday() async {
    final prefs = await SharedPreferences.getInstance();
    final date = prefs.getString(_dateKey);
    return date == _todayKey();
  }

  static Future<bool> isCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final date = prefs.getString(_dateKey);
    if (date != _todayKey()) return false;
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<String?> getStoredBoardId() async {
    final prefs = await SharedPreferences.getInstance();
    final date = prefs.getString(_dateKey);
    if (date != _todayKey()) return null;
    return prefs.getString(_boardIdKey);
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, _todayKey());
    await prefs.setBool(_completedKey, true);
    await prefs.remove(_gameStateKey);
  }

  static Future<void> saveBoardId(String boardId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, _todayKey());
    await prefs.setString(_boardIdKey, boardId);
  }

  static Future<void> saveGameState(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, _todayKey());
    await prefs.setString(_gameStateKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadGameState() async {
    if (!await _isToday()) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_gameStateKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameStateKey);
  }
}
