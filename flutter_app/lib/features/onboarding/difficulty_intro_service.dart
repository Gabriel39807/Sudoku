import 'package:shared_preferences/shared_preferences.dart';

class DifficultyIntroService {
  static const _techniques = {
    'intermediate': ['Naked Pair', 'Hidden Pair', 'Triples'],
    'hard': ['Pointing Pair', 'Box Line Reduction'],
    'expert': ['XWing', 'Swordfish'],
    'evil': ['XYWing'],
    'mythic': ['Forcing Chains'],
  };

  static Future<bool> shouldShow(String difficulty) async {
    final diff = difficulty.toLowerCase();
    if (diff == 'easy') return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_seenKey(diff)) ?? false);
  }

  static Future<void> markSeen(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey(difficulty.toLowerCase()), true);
  }

  static List<String> techniquesFor(String difficulty) {
    return _techniques[difficulty.toLowerCase()] ?? const [];
  }

  static String _seenKey(String difficulty) => 'seen_difficulty_$difficulty';
}
