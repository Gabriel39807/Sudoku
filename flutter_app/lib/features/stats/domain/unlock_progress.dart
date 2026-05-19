class UnlockProgressModel {
  final String difficulty;
  final String sourceDifficulty;
  final int current;
  final int required;
  final bool unlocked;

  const UnlockProgressModel({
    required this.difficulty,
    required this.sourceDifficulty,
    required this.current,
    required this.required,
    required this.unlocked,
  });

  double get ratio {
    if (required <= 0) return unlocked ? 1 : 0;
    return (current / required).clamp(0, 1).toDouble();
  }
}
