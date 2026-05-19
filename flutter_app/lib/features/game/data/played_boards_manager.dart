import 'package:shared_preferences/shared_preferences.dart';

class PlayedBoardsManager {
  static const String _keyPrefix = 'played_boards_';

  static Future<Set<String>> getPlayedBoards(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('$_keyPrefix${difficulty.toLowerCase()}') ?? [];
    return list.toSet();
  }

  static Future<void> markBoardAsPlayed(String difficulty, String boardId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${difficulty.toLowerCase()}';
    final list = prefs.getStringList(key) ?? [];
    if (!list.contains(boardId)) {
      list.add(boardId);
      await prefs.setStringList(key, list);
    }
  }

  static Future<void> clearPlayedBoards(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix${difficulty.toLowerCase()}');
  }
}
