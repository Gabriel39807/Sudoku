import '../stats/domain/stats_model.dart';
import '../stats/domain/unlock_progress.dart';

class UnlockService {
  static const difficulties = [
    'easy',
    'intermediate',
    'hard',
    'expert',
    'evil',
    'mythic',
  ];

  static const requirements = {
    'expert': ('hard', 10),
    'evil': ('expert', 15),
    'mythic': ('evil', 25),
  };

  static bool isUnlocked(String difficulty, GameStats stats) {
    final diff = difficulty.toLowerCase();
    if (diff == 'easy' ||
        diff == 'intermediate' ||
        diff == 'hard' ||
        diff == 'expert') {
      return true;
    }
    final requirement = requirements[diff];
    if (requirement == null) return true;
    final wins = stats.difficultyStats[requirement.$1]?.victories ?? 0;
    return wins >= requirement.$2;
  }

  static Map<String, UnlockProgressModel> buildProgress(GameStats stats) {
    return {
      for (final entry in requirements.entries)
        entry.key: UnlockProgressModel(
          difficulty: entry.key,
          sourceDifficulty: entry.value.$1,
          current: stats.difficultyStats[entry.value.$1]?.victories ?? 0,
          required: entry.value.$2,
          unlocked:
              (stats.difficultyStats[entry.value.$1]?.victories ?? 0) >=
              entry.value.$2,
        ),
    };
  }
}
