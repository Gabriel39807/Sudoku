enum ProgressionTier { onboarding, midgame, longGame, endgame }

class ProgressionCurve {
  ProgressionCurve._();

  static const _midgameBase = 830 + 1 * 120; // level 11→12
  static const _longGameBase = 830 + 15 * 120; // = 2630, level 26→27
  static const _endgameBase = 2630 + 25 * 180; // = 7130, level 51→52

  /// XP needed to go from [level] to [level+1].
  /// Values build on previous tiers:
  ///   onboarding: specific table
  ///   midgame (11-25): 830 + (level-10) * 120
  ///   long game (26-50): 2630 + (level-25) * 180
  ///   endgame (50+): 7130 + (level-50) * 250
  static int xpForLevel(int level) {
    if (level >= 50) return _endgameBase + (level - 50) * 250;
    if (level >= 26) return _longGameBase + (level - 25) * 180;
    if (level >= 11) return _midgameBase + (level - 11) * 120;
    return _onboardingXp(level);
  }

  /// Total cumulative XP required to reach level [level] (level 1 = 0).
  static int cumulativeXp(int level) {
    if (level <= 1) return 0;
    var total = 0;
    for (var i = 1; i < level; i++) {
      total += xpForLevel(i);
    }
    return total;
  }

  static ProgressionTier tier(int level) {
    if (level >= 50) return ProgressionTier.endgame;
    if (level >= 26) return ProgressionTier.longGame;
    if (level >= 11) return ProgressionTier.midgame;
    return ProgressionTier.onboarding;
  }

  static String titleForLevel(int level) {
    if (level >= 96) return 'Eternal Solver';
    if (level >= 86) return 'Mythic';
    if (level >= 71) return 'Legend';
    if (level >= 56) return 'Grand Master';
    if (level >= 41) return 'Master';
    if (level >= 31) return 'Strategist';
    if (level >= 21) return 'Expert';
    if (level >= 11) return 'Solver';
    return 'Beginner';
  }

  static int _onboardingXp(int level) {
    const table = {
      1: 100,
      2: 150,
      3: 200,
      4: 260,
      5: 330,
      6: 410,
      7: 500,
      8: 600,
      9: 710,
      10: 830,
    };
    return table[level] ?? 100;
  }
}
