import 'package:shared_preferences/shared_preferences.dart';

class HintService {
  static const unlimited = -1;

  static int maxHintsFor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return unlimited;
      case 'intermediate':
        return 3;
      case 'hard':
        return 2;
      case 'expert':
        return 1;
      case 'evil':
      case 'mythic':
        return 0;
      default:
        return 0;
    }
  }

  static bool hasHints(String difficulty) => maxHintsFor(difficulty) != 0;

  static Future<void> resetCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_game_hints_used', 0);
  }

  static Future<void> persistCurrentGameHintUsed(int usedHints) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_game_hints_used', usedHints);
  }
}
