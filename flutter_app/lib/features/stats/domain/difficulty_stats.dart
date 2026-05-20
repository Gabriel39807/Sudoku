class DifficultyStats {
  final int gamesStarted;
  final int victories;
  final int losses;
  final int abandons;
  final int bestTime;
  final int totalWinTime;
  final int perfectVictories;
  final int hintsUsed;
  final int completedWithAutocomplete;
  final int completedWithHints;
  final int maxCombo;
  final int totalNoteUsage;

  const DifficultyStats({
    this.gamesStarted = 0,
    this.victories = 0,
    this.losses = 0,
    this.abandons = 0,
    this.bestTime = 0,
    this.totalWinTime = 0,
    this.perfectVictories = 0,
    this.hintsUsed = 0,
    this.completedWithAutocomplete = 0,
    this.completedWithHints = 0,
    this.maxCombo = 0,
    this.totalNoteUsage = 0,
  });

  int get averageTime => victories == 0 ? 0 : totalWinTime ~/ victories;
}
