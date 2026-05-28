import 'sudoku_variant.dart';

/// Future variant types — only [classic] is active now.
enum VariantBossType { classic, jigsaw, hyper, windoku, xSudoku }

/// Boss mechanics for special levels.
enum BossType {
  perfect,    // 0 errors or lose perfect star
  timeAttack, // reduced time limit
  noHelp,     // no hints, no advanced notes
  fog,        // reduced visibility (stages 6+)
  mixed;      // combination of multiple types

  String get label {
    return switch (this) {
      BossType.perfect => 'PERFECTO',
      BossType.timeAttack => 'CONTRARRELOJ',
      BossType.noHelp => 'SIN AYUDA',
      BossType.fog => 'NIEBLA',
      BossType.mixed => 'MIXTO',
    };
  }

  String get description {
    return switch (this) {
      BossType.perfect => 'Completá sin errores',
      BossType.timeAttack => 'Tiempo reducido',
      BossType.noHelp => 'Sin pistas ni notas',
      BossType.fog => 'Visibilidad reducida',
      BossType.mixed => 'Desafío combinado',
    };
  }
}

/// A chapter within a campaign stage (20 levels each).
class CampaignChapter {
  final int number;
  final int startLevel;
  final int endLevel;
  final String name;
  final String description;

  const CampaignChapter({
    required this.number,
    required this.startLevel,
    required this.endLevel,
    required this.name,
    required this.description,
  });

  int get levelCount => endLevel - startLevel + 1;
  bool contains(int level) => level >= startLevel && level <= endLevel;
  int indexInChapter(int level) => level - startLevel;

  bool get isBossLevel => false; // handled per-stage in CampaignStage
}

/// Level ranges per boss type in a stage.
class StageBossConfig {
  final int miniBossLevel;
  final int bossLevel;
  final int eliteBossLevel;
  final int worldBossLevel;
  final BossType miniBossType;
  final BossType bossType;
  final BossType eliteBossType;
  final BossType worldBossType;

  const StageBossConfig({
    required this.miniBossLevel,
    required this.bossLevel,
    required this.eliteBossLevel,
    required this.worldBossLevel,
    required this.miniBossType,
    required this.bossType,
    required this.eliteBossType,
    required this.worldBossType,
  });

  BossType? typeForLevel(int level) {
    if (level == miniBossLevel) return miniBossType;
    if (level == bossLevel) return bossType;
    if (level == eliteBossLevel) return eliteBossType;
    if (level == worldBossLevel) return worldBossType;
    return null;
  }

  bool isBossLevel(int level) => typeForLevel(level) != null;
  double get rewardMultiplier {
    // Mini: x1.5, Boss: x2, Elite: x3, World: x5
    return 1.0; // computed per-level
  }

  double multiplierForLevel(int level) {
    if (level == miniBossLevel) return 1.5;
    if (level == bossLevel) return 2.0;
    if (level == eliteBossLevel) return 3.0;
    if (level == worldBossLevel) return 5.0;
    return 1.0;
  }
}

enum CampaignStage {
  miniSudoku(
    name: 'Mini Sudoku',
    subtitle: 'Aprendé las bases',
    levelStart: 1,
    levelEnd: 50,
    variant: SudokuVariant.mini4,
    description: 'Tablero 4×4 · subgrid 2×2',
    datasetStage: 1,
    bossConfig: null,
  ),
  intermediate(
    name: 'Intermedio',
    subtitle: 'Crece el desafío',
    levelStart: 51,
    levelEnd: 125,
    variant: SudokuVariant.mini6,
    description: 'Tablero 6×6 · subgrid 2×3',
    datasetStage: 2,
    bossConfig: null,
  ),
  advanced(
    name: 'Avanzado',
    subtitle: 'Menos ayuda, más reto',
    levelStart: 126,
    levelEnd: 225,
    variant: SudokuVariant.mini8,
    description: 'Tablero 8×8 · subgrid 2×4',
    datasetStage: 3,
    bossConfig: null,
  ),
  assisted(
    name: 'Asistido',
    subtitle: 'Primeros pasos en 9×9',
    levelStart: 226,
    levelEnd: 325,
    variant: SudokuVariant.normal9,
    description: '9×9 · 60–62 clues · Tier 1',
    datasetStage: 4,
    bossConfig: StageBossConfig(
      miniBossLevel: 250,  // stage offset + 25
      bossLevel: 275,
      eliteBossLevel: 300,
      worldBossLevel: 325,
      miniBossType: BossType.perfect,
      bossType: BossType.timeAttack,
      eliteBossType: BossType.noHelp,
      worldBossType: BossType.mixed,
    ),
  ),
  beginner(
    name: 'Beginner Journey',
    subtitle: 'Sudokus reales',
    levelStart: 326,
    levelEnd: 425,
    variant: SudokuVariant.normal9,
    description: '9×9 · 60→55 clues · Tier 1–2',
    datasetStage: 5,
    bossConfig: StageBossConfig(
      miniBossLevel: 350,
      bossLevel: 375,
      eliteBossLevel: 400,
      worldBossLevel: 425,
      miniBossType: BossType.perfect,
      bossType: BossType.timeAttack,
      eliteBossType: BossType.noHelp,
      worldBossType: BossType.mixed,
    ),
  ),
  intermediate9(
    name: 'Intermedio 9×9',
    subtitle: 'Técnicas intermedias',
    levelStart: 426,
    levelEnd: 525,
    variant: SudokuVariant.normal9,
    description: '9×9 · 54–48 clues · Pairs',
    datasetStage: 6,
    bossConfig: StageBossConfig(
      miniBossLevel: 450,
      bossLevel: 475,
      eliteBossLevel: 500,
      worldBossLevel: 525,
      miniBossType: BossType.perfect,
      bossType: BossType.timeAttack,
      eliteBossType: BossType.noHelp,
      worldBossType: BossType.mixed,
    ),
  ),
  advanced9(
    name: 'Avanzado 9×9',
    subtitle: 'Técnicas avanzadas',
    levelStart: 526,
    levelEnd: 625,
    variant: SudokuVariant.normal9,
    description: '9×9 · 48–42 clues · X-Wing',
    datasetStage: 7,
    bossConfig: StageBossConfig(
      miniBossLevel: 550,
      bossLevel: 575,
      eliteBossLevel: 600,
      worldBossLevel: 625,
      miniBossType: BossType.perfect,
      bossType: BossType.timeAttack,
      eliteBossType: BossType.noHelp,
      worldBossType: BossType.mixed,
    ),
  ),
  expert9(
    name: 'Experto',
    subtitle: 'Técnicas de experto',
    levelStart: 626,
    levelEnd: 725,
    variant: SudokuVariant.normal9,
    description: '9×9 · 42–36 clues · Swordfish',
    datasetStage: 8,
    bossConfig: StageBossConfig(
      miniBossLevel: 650,
      bossLevel: 675,
      eliteBossLevel: 700,
      worldBossLevel: 725,
      miniBossType: BossType.perfect,
      bossType: BossType.timeAttack,
      eliteBossType: BossType.noHelp,
      worldBossType: BossType.mixed,
    ),
  ),
  evil9(
    name: 'Malvado',
    subtitle: 'Solo para valientes',
    levelStart: 726,
    levelEnd: 825,
    variant: SudokuVariant.normal9,
    description: '9×9 · 36–30 clues · BUG',
    datasetStage: 9,
    bossConfig: StageBossConfig(
      miniBossLevel: 750,
      bossLevel: 775,
      eliteBossLevel: 800,
      worldBossLevel: 825,
      miniBossType: BossType.perfect,
      bossType: BossType.timeAttack,
      eliteBossType: BossType.noHelp,
      worldBossType: BossType.mixed,
    ),
  ),
  mythic9(
    name: 'Mítico',
    subtitle: 'El desafío final',
    levelStart: 826,
    levelEnd: 875,
    variant: SudokuVariant.normal9,
    description: '9×9 · 30–24 clues · Técnicas altas',
    datasetStage: 10,
    bossConfig: StageBossConfig(
      miniBossLevel: 850,
      bossLevel: 875,
      eliteBossLevel: 0,  // no elite in 50-level stage
      worldBossLevel: 0,  // no world boss in 50-level stage
      miniBossType: BossType.fog,
      bossType: BossType.mixed,
      eliteBossType: BossType.mixed,
      worldBossType: BossType.mixed,
    ),
  );

  final String name;
  final String subtitle;
  final int levelStart;
  final int levelEnd;
  final SudokuVariant variant;
  final String description;
  final int datasetStage;
  final StageBossConfig? bossConfig;

  const CampaignStage({
    required this.name,
    required this.subtitle,
    required this.levelStart,
    required this.levelEnd,
    required this.variant,
    required this.description,
    required this.datasetStage,
    required this.bossConfig,
  });

  bool contains(int level) => level >= levelStart && level <= levelEnd;
  int get levelCount => levelEnd - levelStart + 1;
  bool get hasBosses => bossConfig != null;

  BossType? bossTypeForLevel(int level) => bossConfig?.typeForLevel(level);
  double bossMultiplierForLevel(int level) => bossConfig?.multiplierForLevel(level) ?? 1.0;
  bool isBossLevel(int level) => bossConfig?.isBossLevel(level) ?? false;

  /// 5 chapters per stage for 100-level stages, fewer for smaller stages.
  List<CampaignChapter> get chapters {
    final total = levelCount;
    final chapterSize = total >= 100 ? 20 : (total >= 50 ? 10 : total >= 25 ? 5 : total);
    final count = (total / chapterSize).ceil();
    return List.generate(count, (i) {
      final start = levelStart + i * chapterSize;
      final end = (start + chapterSize - 1).clamp(levelStart, levelEnd);
      return CampaignChapter(
        number: i + 1,
        startLevel: start,
        endLevel: end,
        name: 'Capítulo ${i + 1}',
        description: 'Niveles $start–$end',
      );
    });
  }

  CampaignChapter? chapterForLevel(int level) {
    for (final ch in chapters) {
      if (ch.contains(level)) return ch;
    }
    return null;
  }

  static CampaignStage fromLevel(int level) {
    for (final stage in values) {
      if (stage.contains(level)) return stage;
    }
    return CampaignStage.miniSudoku;
  }

  /// Total levels across all stages.
  static int get totalLevels => values.fold(0, (s, st) => s + st.levelCount);
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
    return false;
  }
}
