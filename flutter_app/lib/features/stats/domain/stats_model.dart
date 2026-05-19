class GameStats {
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;

  // Best times in seconds; 0 = never completed
  final int bestEasy;
  final int bestIntermediate;
  final int bestHard;
  final int bestExpert;
  final int bestEvil;
  final int bestMythic;

  final int winStreak;
  final int bestWinStreak;

  final Map<String, int> winsByDifficulty;
  final Map<String, int> lossesByDifficulty;

  const GameStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.bestEasy = 0,
    this.bestIntermediate = 0,
    this.bestHard = 0,
    this.bestExpert = 0,
    this.bestEvil = 0,
    this.bestMythic = 0,
    this.winStreak = 0,
    this.bestWinStreak = 0,
    this.winsByDifficulty = const {},
    this.lossesByDifficulty = const {},
  });

  int bestTimeFor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':         return bestEasy;
      case 'intermediate': return bestIntermediate;
      case 'hard':         return bestHard;
      case 'expert':       return bestExpert;
      case 'evil':         return bestEvil;
      case 'mythic':       return bestMythic;
      default:             return 0;
    }
  }

  double get winRate => gamesPlayed == 0 ? 0 : gamesWon / gamesPlayed;

  GameStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? gamesLost,
    int? bestEasy,
    int? bestIntermediate,
    int? bestHard,
    int? bestExpert,
    int? bestEvil,
    int? bestMythic,
    int? winStreak,
    int? bestWinStreak,
    Map<String, int>? winsByDifficulty,
    Map<String, int>? lossesByDifficulty,
  }) {
    return GameStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesLost: gamesLost ?? this.gamesLost,
      bestEasy: bestEasy ?? this.bestEasy,
      bestIntermediate: bestIntermediate ?? this.bestIntermediate,
      bestHard: bestHard ?? this.bestHard,
      bestExpert: bestExpert ?? this.bestExpert,
      bestEvil: bestEvil ?? this.bestEvil,
      bestMythic: bestMythic ?? this.bestMythic,
      winStreak: winStreak ?? this.winStreak,
      bestWinStreak: bestWinStreak ?? this.bestWinStreak,
      winsByDifficulty: winsByDifficulty ?? Map.from(this.winsByDifficulty),
      lossesByDifficulty: lossesByDifficulty ?? Map.from(this.lossesByDifficulty),
    );
  }
}
