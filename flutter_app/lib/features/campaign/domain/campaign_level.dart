import 'sudoku_variant.dart';

enum CampaignStage {
  miniSudoku(
    name: 'Mini Sudoku',
    subtitle: 'Aprendé las bases',
    levelStart: 1,
    levelEnd: 50,
    variant: SudokuVariant.mini4,
    description: 'Tablero 4×4 · subgrid 2×2',
    datasetStage: 1,
  ),
  intermediate(
    name: 'Intermedio',
    subtitle: 'Crece el desafío',
    levelStart: 51,
    levelEnd: 125,
    variant: SudokuVariant.mini6,
    description: 'Tablero 6×6 · subgrid 2×3',
    datasetStage: 2,
  ),
  advanced(
    name: 'Avanzado',
    subtitle: 'Menos ayuda, más reto',
    levelStart: 126,
    levelEnd: 225,
    variant: SudokuVariant.mini8,
    description: 'Tablero 8×8 · subgrid 2×4',
    datasetStage: 3,
  );

  final String name;
  final String subtitle;
  final int levelStart;
  final int levelEnd;
  final SudokuVariant variant;
  final String description;
  final int datasetStage;

  const CampaignStage({
    required this.name,
    required this.subtitle,
    required this.levelStart,
    required this.levelEnd,
    required this.variant,
    required this.description,
    required this.datasetStage,
  });

  bool contains(int level) => level >= levelStart && level <= levelEnd;

  static CampaignStage fromLevel(int level) {
    for (final stage in values) {
      if (stage.contains(level)) return stage;
    }
    return CampaignStage.miniSudoku;
  }
}

class CampaignLevel {
  final int level;
  final String boardId;
  final CampaignStage stage;
  final bool completed;
  final int? bestTimeSeconds;
  final int? bestMistakes;
  final int stars;

  CampaignLevel({
    required this.level,
    required this.boardId,
    required this.stage,
    this.completed = false,
    this.bestTimeSeconds,
    this.bestMistakes,
    this.stars = 0,
  });

  SudokuVariant get variant => stage.variant;

  CampaignLevel copyWith({
    bool? completed,
    int? bestTimeSeconds,
    int? bestMistakes,
    int? stars,
  }) {
    return CampaignLevel(
      level: level,
      boardId: boardId,
      stage: stage,
      completed: completed ?? this.completed,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      bestMistakes: bestMistakes ?? this.bestMistakes,
      stars: stars ?? this.stars,
    );
  }

  bool get isUnlocked {
    if (level == 1) return true;
    return false; // Will be determined by CampaignProgress
  }
}
