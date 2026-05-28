import 'campaign_level.dart';

class CampaignLevelResult {
  final bool completed;
  final int bestTimeSeconds;
  final int bestMistakes;
  final int stars;
  final int attempts;
  final int xpEarned;
  final int tokensEarned;
  final int gemsEarned;
  final bool isBoss;
  final bool isPlatinum;
  // ── Future hooks ──────────────────────────────────────────────────────
  final int perfectRuns;     // future: count of 0-error completions
  final int chapterStars;    // future: cumulative stars in current chapter
  final bool worldPlatinum;  // future: all levels in world platinumed
  final int speedMedals;     // future: completions under par time

  const CampaignLevelResult({
    this.completed = false,
    this.bestTimeSeconds = 0,
    this.bestMistakes = 0,
    this.stars = 0,
    this.attempts = 0,
    this.xpEarned = 0,
    this.tokensEarned = 0,
    this.gemsEarned = 0,
    this.isBoss = false,
    this.isPlatinum = false,
    this.perfectRuns = 0,
    this.chapterStars = 0,
    this.worldPlatinum = false,
    this.speedMedals = 0,
  });

  double get starXpMultiplier {
    return switch (stars) { 1 => 1.10, 2 => 1.20, 3 => 1.40, _ => 1.0 };
  }

  CampaignLevelResult copyWith({
    bool? completed,
    int? bestTimeSeconds,
    int? bestMistakes,
    int? stars,
    int? attempts,
    int? xpEarned,
    int? tokensEarned,
    int? gemsEarned,
    bool? isBoss,
    bool? isPlatinum,
    int? perfectRuns,
    int? chapterStars,
    bool? worldPlatinum,
    int? speedMedals,
  }) {
    return CampaignLevelResult(
      completed: completed ?? this.completed,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      bestMistakes: bestMistakes ?? this.bestMistakes,
      stars: stars ?? this.stars,
      attempts: attempts ?? this.attempts,
      xpEarned: xpEarned ?? this.xpEarned,
      tokensEarned: tokensEarned ?? this.tokensEarned,
      gemsEarned: gemsEarned ?? this.gemsEarned,
      isBoss: isBoss ?? this.isBoss,
      isPlatinum: isPlatinum ?? this.isPlatinum,
      perfectRuns: perfectRuns ?? this.perfectRuns,
      chapterStars: chapterStars ?? this.chapterStars,
      worldPlatinum: worldPlatinum ?? this.worldPlatinum,
      speedMedals: speedMedals ?? this.speedMedals,
    );
  }

  Map<String, dynamic> toJson() => {
    'completed': completed,
    'bestTimeSeconds': bestTimeSeconds,
    'bestMistakes': bestMistakes,
    'stars': stars,
    'attempts': attempts,
    'xpEarned': xpEarned,
    'tokensEarned': tokensEarned,
    'gemsEarned': gemsEarned,
    'isBoss': isBoss,
    'isPlatinum': isPlatinum,
    'perfectRuns': perfectRuns,
    'chapterStars': chapterStars,
    'worldPlatinum': worldPlatinum,
    'speedMedals': speedMedals,
  };

  factory CampaignLevelResult.fromJson(Map<String, dynamic> json) => CampaignLevelResult(
    completed: json['completed'] as bool? ?? false,
    bestTimeSeconds: json['bestTimeSeconds'] as int? ?? 0,
    bestMistakes: json['bestMistakes'] as int? ?? 0,
    stars: json['stars'] as int? ?? 0,
    attempts: json['attempts'] as int? ?? 0,
    xpEarned: json['xpEarned'] as int? ?? 0,
    tokensEarned: json['tokensEarned'] as int? ?? 0,
    gemsEarned: json['gemsEarned'] as int? ?? 0,
    isBoss: json['isBoss'] as bool? ?? false,
    isPlatinum: json['isPlatinum'] as bool? ?? false,
    perfectRuns: json['perfectRuns'] as int? ?? 0,
    chapterStars: json['chapterStars'] as int? ?? 0,
    worldPlatinum: json['worldPlatinum'] as bool? ?? false,
    speedMedals: json['speedMedals'] as int? ?? 0,
  );
}

class CampaignProgress {
  final int currentLevel;
  final int activeRunLevel;
  final Map<int, CampaignLevelResult> results;
  final int campaignXp;
  final int campaignRank;

  const CampaignProgress({
    this.currentLevel = 1,
    this.activeRunLevel = 0,
    this.results = const {},
    this.campaignXp = 0,
    this.campaignRank = 1,
  });

  bool get hasActiveRun => activeRunLevel > 0;

  bool isUnlocked(int level) => level <= currentLevel;
  bool isCompleted(int level) => results[level]?.completed ?? false;

  CampaignLevelResult? resultFor(int level) => results[level];

  int get completedCount => results.values.where((r) => r.completed).length;
  int get totalCount => CampaignStage.totalLevels;

  CampaignStage? get currentStage => CampaignStage.fromLevel(currentLevel);

  CampaignProgress copyWith({
    int? currentLevel,
    int? activeRunLevel,
    Map<int, CampaignLevelResult>? results,
    int? campaignXp,
    int? campaignRank,
  }) {
    return CampaignProgress(
      currentLevel: currentLevel ?? this.currentLevel,
      activeRunLevel: activeRunLevel ?? this.activeRunLevel,
      results: results ?? this.results,
      campaignXp: campaignXp ?? this.campaignXp,
      campaignRank: campaignRank ?? this.campaignRank,
    );
  }

  CampaignProgress completeLevel(
    int level,
    int timeSeconds,
    int mistakes,
    int xpEarned,
    int tokensEarned,
    int gemsEarned,
    {int? overrideStars})
  {
    final existing = results[level] ?? CampaignLevelResult();
    final stage = CampaignStage.fromLevel(level);
    final stars = overrideStars ?? _computeStars(timeSeconds, mistakes, level, stage);
    final better = !existing.completed ||
        stars > existing.stars ||
        (stars == existing.stars && timeSeconds < existing.bestTimeSeconds) ||
        (stars == existing.stars && timeSeconds == existing.bestTimeSeconds && mistakes < existing.bestMistakes);

    final newXpEarned = better ? xpEarned : existing.xpEarned;

    return copyWith(
      currentLevel: currentLevel + 1,
      activeRunLevel: 0,
      campaignXp: campaignXp + newXpEarned,
      results: {
        ...results,
        level: existing.copyWith(
          completed: true,
          bestTimeSeconds: better ? timeSeconds : existing.bestTimeSeconds,
          bestMistakes: better ? mistakes : existing.bestMistakes,
          stars: better ? stars : existing.stars,
          isPlatinum: better ? stars >= 3 : existing.isPlatinum,
          attempts: existing.attempts + 1,
          xpEarned: better ? xpEarned : existing.xpEarned,
          tokensEarned: better ? tokensEarned : existing.tokensEarned,
          gemsEarned: better ? gemsEarned : existing.gemsEarned,
          isBoss: stage.isBossLevel(level),
        ),
      },
    );
  }

  /// Calculate stars based on actual gameplay metrics
  /// 0★ = defeat
  /// 1★ = completed with errors AND overtime
  /// 2★ = exactly one of: no errors OR within time
  /// 3★ = no errors AND within time
  int _computeStars(int timeSeconds, int mistakes, int level, CampaignStage stage) {
    final variant = stage.variant;
    final maxTime = switch (variant.boardSize) { 4 => 60, 6 => 180, 8 => 300, _ => 600 };
    
    if (stage.isBossLevel(level)) {
      return mistakes == 0 ? 3 : 1;
    }
    
    final noErrors = mistakes == 0;
    final timeOk = timeSeconds <= maxTime;
    if (noErrors && timeOk) return 3;
    if (noErrors || timeOk) return 2;
    return 1;
  }

  Map<String, dynamic> toJson() => {
    'currentLevel': currentLevel,
    'activeRunLevel': activeRunLevel,
    'results': results.map((k, v) => MapEntry(k.toString(), v.toJson())),
    'campaignXp': campaignXp,
    'campaignRank': campaignRank,
  };

  factory CampaignProgress.fromJson(Map<String, dynamic> json) {
    final resultsRaw = json['results'] as Map<String, dynamic>? ?? {};
    return CampaignProgress(
      currentLevel: json['currentLevel'] as int? ?? 1,
      activeRunLevel: json['activeRunLevel'] as int? ?? 0,
      results: resultsRaw.map(
        (k, v) => MapEntry(int.parse(k), CampaignLevelResult.fromJson(v as Map<String, dynamic>)),
      ),
      campaignXp: json['campaignXp'] as int? ?? 0,
      campaignRank: json['campaignRank'] as int? ?? 1,
    );
  }
}
