enum GameMode { normal, campaign, daily, savedGame }

class GameSessionContext {
  final GameMode mode;
  final String difficulty;
  final String boardId;
  final String dataset;
  final String origin;
  final String? saveSlot;
  final int? seed;
  final int? progress;

  const GameSessionContext({
    required this.mode,
    required this.difficulty,
    required this.boardId,
    required this.dataset,
    required this.origin,
    this.saveSlot,
    this.seed,
    this.progress,
  });

  GameSessionContext copyWith({
    GameMode? mode,
    String? difficulty,
    String? boardId,
    String? dataset,
    String? origin,
    String? saveSlot,
    int? seed,
    int? progress,
    bool clearSaveSlot = false,
    bool clearSeed = false,
    bool clearProgress = false,
  }) {
    return GameSessionContext(
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      boardId: boardId ?? this.boardId,
      dataset: dataset ?? this.dataset,
      origin: origin ?? this.origin,
      saveSlot: clearSaveSlot ? null : (saveSlot ?? this.saveSlot),
      seed: clearSeed ? null : (seed ?? this.seed),
      progress: clearProgress ? null : (progress ?? this.progress),
    );
  }

  @override
  String toString() => 'GameSessionContext($mode, $difficulty, $boardId, $dataset, $origin)';
}
