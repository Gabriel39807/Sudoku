import 'campaign_level.dart';

class CampaignLevelResult {
  final bool completed;
  final int bestTimeSeconds;
  final int bestMistakes;
  final int stars;
  final int attempts;

  const CampaignLevelResult({
    this.completed = false,
    this.bestTimeSeconds = 0,
    this.bestMistakes = 0,
    this.stars = 0,
    this.attempts = 0,
  });

  CampaignLevelResult copyWith({
    bool? completed,
    int? bestTimeSeconds,
    int? bestMistakes,
    int? stars,
    int? attempts,
  }) {
    return CampaignLevelResult(
      completed: completed ?? this.completed,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      bestMistakes: bestMistakes ?? this.bestMistakes,
      stars: stars ?? this.stars,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() => {
    'completed': completed,
    'bestTimeSeconds': bestTimeSeconds,
    'bestMistakes': bestMistakes,
    'stars': stars,
    'attempts': attempts,
  };

  factory CampaignLevelResult.fromJson(Map<String, dynamic> json) => CampaignLevelResult(
    completed: json['completed'] as bool? ?? false,
    bestTimeSeconds: json['bestTimeSeconds'] as int? ?? 0,
    bestMistakes: json['bestMistakes'] as int? ?? 0,
    stars: json['stars'] as int? ?? 0,
    attempts: json['attempts'] as int? ?? 0,
  );
}

class CampaignProgress {
  final int currentLevel;
  final int activeRunLevel;
  final Map<int, CampaignLevelResult> results;

  const CampaignProgress({
    this.currentLevel = 1,
    this.activeRunLevel = 0,
    this.results = const {},
  });

  bool get hasActiveRun => activeRunLevel > 0;

  bool isUnlocked(int level) => level <= currentLevel;
  bool isCompleted(int level) => results[level]?.completed ?? false;

  CampaignLevelResult? resultFor(int level) => results[level];

  int get completedCount => results.values.where((r) => r.completed).length;
  int get totalCount => CampaignStage.values.fold(0, (s, st) => s + st.levelEnd - st.levelStart + 1);

  CampaignStage? get currentStage => CampaignStage.fromLevel(currentLevel);

  CampaignProgress copyWith({int? currentLevel, int? activeRunLevel, Map<int, CampaignLevelResult>? results}) {
    return CampaignProgress(
      currentLevel: currentLevel ?? this.currentLevel,
      activeRunLevel: activeRunLevel ?? this.activeRunLevel,
      results: results ?? this.results,
    );
  }

  CampaignProgress completeLevel(int level, int timeSeconds, int mistakes) {
    final existing = results[level] ?? CampaignLevelResult();
    final stars = _computeStars(timeSeconds, mistakes, level);
    final better = !existing.completed ||
        timeSeconds < existing.bestTimeSeconds ||
        (timeSeconds == existing.bestTimeSeconds && mistakes < existing.bestMistakes);

    return copyWith(
      currentLevel: currentLevel + 1,
      activeRunLevel: 0,
      results: {
        ...results,
        level: existing.copyWith(
          completed: true,
          bestTimeSeconds: better ? timeSeconds : existing.bestTimeSeconds,
          bestMistakes: better ? mistakes : existing.bestMistakes,
          stars: better ? stars : existing.stars,
          attempts: existing.attempts + 1,
        ),
      },
    );
  }

  int _computeStars(int timeSeconds, int mistakes, int level) {
    final variant = CampaigStageRef.fromLevel(level).variant;
    final maxTime = switch (variant.boardSize) { 4 => 60, 6 => 180, 8 => 300, _ => 600 };
    var stars = 3;
    if (mistakes > 0) stars--;
    if (timeSeconds > maxTime) stars--;
    return stars.clamp(1, 3);
  }

  Map<String, dynamic> toJson() => {
    'currentLevel': currentLevel,
    'activeRunLevel': activeRunLevel,
    'results': results.map((k, v) => MapEntry(k.toString(), v.toJson())),
  };

  factory CampaignProgress.fromJson(Map<String, dynamic> json) {
    final resultsRaw = json['results'] as Map<String, dynamic>? ?? {};
    return CampaignProgress(
      currentLevel: json['currentLevel'] as int? ?? 1,
      activeRunLevel: json['activeRunLevel'] as int? ?? 0,
      results: resultsRaw.map(
        (k, v) => MapEntry(int.parse(k), CampaignLevelResult.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}

class CampaigStageRef {
  static CampaignStage fromLevel(int level) => CampaignStage.fromLevel(level);
}
