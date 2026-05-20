import '../../game/domain/game_state.dart';

class XpResult {
  final String difficulty;
  final int base;
  final int perfectBonus;
  final int flawlessBonus;
  final int speedBonus;
  final int comboBonus;
  final int completionBonus;
  final int hintPenalty;
  final int failPenalty;
  final int autoCompletePenalty;
  final int total;
  final int maxCap;
  final int hintsUsed;

  const XpResult({
    required this.difficulty,
    required this.base,
    required this.perfectBonus,
    required this.flawlessBonus,
    required this.speedBonus,
    required this.comboBonus,
    required this.completionBonus,
    required this.hintPenalty,
    required this.failPenalty,
    required this.autoCompletePenalty,
    required this.total,
    required this.maxCap,
    required this.hintsUsed,
  });

  int get subtotal =>
      base + perfectBonus + flawlessBonus + speedBonus + comboBonus + completionBonus;

  int get sumPenalties => hintPenalty + failPenalty + autoCompletePenalty;

  bool get capped => total >= maxCap;

  bool get isPerfect => perfectBonus > 0;
  bool get isFlawless => flawlessBonus > 0;
}

class XpCalculator {
  XpCalculator._();

  static const baseXp = {
    'easy': 40,
    'intermediate': 70,
    'hard': 110,
    'expert': 170,
    'evil': 250,
    'mythic': 350,
  };

  static const targetSeconds = {
    'easy': 480,
    'intermediate': 720,
    'hard': 1080,
    'expert': 1500,
    'evil': 2100,
    'mythic': 3000,
  };

  static const maxXp = {
    'easy': 120,
    'intermediate': 180,
    'hard': 250,
    'expert': 350,
    'evil': 500,
    'mythic': 700,
  };

  static XpResult compute(GameState state) {
    final diff = state.difficulty;
    final base = baseXp[diff] ?? 40;
    final elapsed = state.elapsedSeconds;
    final target = targetSeconds[diff] ?? 480;
    final cap = maxXp[diff] ?? 120;
    final errors = state.errors;
    final hints = state.usedHints;
    final isAutocomplete = state.completedWithAutocomplete;
    final combo = state.maxCombo;

    final isPerfect = errors == 0 && hints == 0 && !isAutocomplete;
    final isFlawless = isPerfect && state.pauseCount == 0 && elapsed < target;

    // Bonuses
    final perfectBonus = isPerfect ? (base * 0.4).round() : 0;
    final flawlessBonus = isFlawless ? (base * 0.25).round() : 0;

    // Speed bonus
    final speedBonus = elapsed < target * 0.8
        ? 30
        : elapsed < target
            ? 15
            : 0;

    // Combo bonus
    final comboBonus = combo >= 30
        ? 35
        : combo >= 20
            ? 20
            : combo >= 10
                ? 10
                : combo >= 5
                    ? 5
                    : 0;

    // Completion bonus
    final rowsDone = state.completedRows.length.clamp(0, 9);
    final colsDone = state.completedCols.length.clamp(0, 9);
    final blocksDone = state.completedBlocks.length.clamp(0, 9);
    final completionBonus = rowsDone * 2 + colsDone * 2 + blocksDone * 4 + 15;

    // Penalties (percentage-based, applied to subtotal)
    final penaltyFactor =
        (1.0 - hints * 0.15 - (errors > 0 ? 0.20 : 0) - (isAutocomplete ? 0.35 : 0))
            .clamp(0.0, 1.0);

    final subtotal =
        base + perfectBonus + flawlessBonus + speedBonus + comboBonus + completionBonus;
    final rawTotal = (subtotal * penaltyFactor).round();
    final total = rawTotal.clamp(0, cap);

    // Compute deduction amounts for display
    final appliedHintPenalty =
        hints > 0 ? (subtotal - (subtotal * (1.0 - hints * 0.15)).round()) : 0;
    final appliedFailPenalty =
        errors > 0 ? (subtotal - (subtotal * 0.80).round()) : 0;
    final appliedAutoPenalty = isAutocomplete
        ? (subtotal - (subtotal * 0.65).round())
        : 0;

    return XpResult(
      difficulty: diff,
      base: base,
      perfectBonus: perfectBonus,
      flawlessBonus: flawlessBonus,
      speedBonus: speedBonus,
      comboBonus: comboBonus,
      completionBonus: completionBonus,
      hintPenalty: appliedHintPenalty,
      failPenalty: appliedFailPenalty,
      autoCompletePenalty: appliedAutoPenalty,
      total: total,
      maxCap: cap,
      hintsUsed: hints,
    );
  }
}
