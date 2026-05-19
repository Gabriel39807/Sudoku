import 'difficulty_stats.dart';
import 'unlock_progress.dart';

class GameStats {
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final int gamesAbandoned;
  final int totalPlayTime;
  final int hintsUsed;
  final int perfectVictories;
  final int victoriesWithHints;
  final int completedWithAutocomplete;
  final int completedWithHints;

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
  final Map<String, int> playedBoardsByDifficulty;
  final Map<String, DifficultyStats> difficultyStats;
  final Map<String, UnlockProgressModel> unlockProgress;

  const GameStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.gamesAbandoned = 0,
    this.totalPlayTime = 0,
    this.hintsUsed = 0,
    this.perfectVictories = 0,
    this.victoriesWithHints = 0,
    this.completedWithAutocomplete = 0,
    this.completedWithHints = 0,
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
    this.playedBoardsByDifficulty = const {},
    this.difficultyStats = const {},
    this.unlockProgress = const {},
  });

  int bestTimeFor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return bestEasy;
      case 'intermediate':
        return bestIntermediate;
      case 'hard':
        return bestHard;
      case 'expert':
        return bestExpert;
      case 'evil':
        return bestEvil;
      case 'mythic':
        return bestMythic;
      default:
        return 0;
    }
  }

  double get winRate => gamesPlayed == 0 ? 0 : gamesWon / gamesPlayed;

  double completionRateFor(String difficulty, int totalBoards) {
    if (totalBoards <= 0) return 0;
    return (playedBoardsByDifficulty[difficulty.toLowerCase()] ?? 0) /
        totalBoards;
  }

  GameStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? gamesLost,
    int? gamesAbandoned,
    int? totalPlayTime,
    int? hintsUsed,
    int? perfectVictories,
    int? victoriesWithHints,
    int? completedWithAutocomplete,
    int? completedWithHints,
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
    Map<String, int>? playedBoardsByDifficulty,
    Map<String, DifficultyStats>? difficultyStats,
    Map<String, UnlockProgressModel>? unlockProgress,
  }) {
    return GameStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesLost: gamesLost ?? this.gamesLost,
      gamesAbandoned: gamesAbandoned ?? this.gamesAbandoned,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      perfectVictories: perfectVictories ?? this.perfectVictories,
      victoriesWithHints: victoriesWithHints ?? this.victoriesWithHints,
      completedWithAutocomplete:
          completedWithAutocomplete ?? this.completedWithAutocomplete,
      completedWithHints: completedWithHints ?? this.completedWithHints,
      bestEasy: bestEasy ?? this.bestEasy,
      bestIntermediate: bestIntermediate ?? this.bestIntermediate,
      bestHard: bestHard ?? this.bestHard,
      bestExpert: bestExpert ?? this.bestExpert,
      bestEvil: bestEvil ?? this.bestEvil,
      bestMythic: bestMythic ?? this.bestMythic,
      winStreak: winStreak ?? this.winStreak,
      bestWinStreak: bestWinStreak ?? this.bestWinStreak,
      winsByDifficulty: winsByDifficulty ?? Map.from(this.winsByDifficulty),
      lossesByDifficulty:
          lossesByDifficulty ?? Map.from(this.lossesByDifficulty),
      playedBoardsByDifficulty:
          playedBoardsByDifficulty ?? Map.from(this.playedBoardsByDifficulty),
      difficultyStats: difficultyStats ?? Map.from(this.difficultyStats),
      unlockProgress: unlockProgress ?? Map.from(this.unlockProgress),
    );
  }
}
