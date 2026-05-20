class SessionStats {
  final int elapsedSeconds;
  final int errors;
  final int remainingCells;
  final double completionPercent;
  final int remainingHints;
  final int currentStreak;
  final int currentCombo;
  final double accuracy;
  final int totalMoves;
  final int correctMoves;

  const SessionStats({
    this.elapsedSeconds = 0,
    this.errors = 0,
    this.remainingCells = 81,
    this.completionPercent = 0.0,
    this.remainingHints = 0,
    this.currentStreak = 0,
    this.currentCombo = 0,
    this.accuracy = 1.0,
    this.totalMoves = 0,
    this.correctMoves = 0,
  });

  SessionStats copyWith({
    int? elapsedSeconds,
    int? errors,
    int? remainingCells,
    double? completionPercent,
    int? remainingHints,
    int? currentStreak,
    int? currentCombo,
    double? accuracy,
    int? totalMoves,
    int? correctMoves,
  }) =>
      SessionStats(
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        errors: errors ?? this.errors,
        remainingCells: remainingCells ?? this.remainingCells,
        completionPercent: completionPercent ?? this.completionPercent,
        remainingHints: remainingHints ?? this.remainingHints,
        currentStreak: currentStreak ?? this.currentStreak,
        currentCombo: currentCombo ?? this.currentCombo,
        accuracy: accuracy ?? this.accuracy,
        totalMoves: totalMoves ?? this.totalMoves,
        correctMoves: correctMoves ?? this.correctMoves,
      );
}
