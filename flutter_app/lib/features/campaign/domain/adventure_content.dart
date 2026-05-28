import '../domain/campaign_level.dart';

// ═══════════════════════════════════════════════════════════════════════════
// F12 — World Music Profile (adaptive music architecture)
// ═══════════════════════════════════════════════════════════════════════════

class WorldMusicProfile {
  final String themeName;
  final int bpm;
  final String scale;
  final double intensity; // 0.0–1.0
  final int layers;
  final double bossIntensity;
  final String victoryTheme;
  final String description;

  const WorldMusicProfile({
    required this.themeName,
    required this.bpm,
    required this.scale,
    this.intensity = 0.5,
    this.layers = 2,
    this.bossIntensity = 0.8,
    this.victoryTheme = 'triumph',
    this.description = '',
  });

  static final Map<int, WorldMusicProfile> forStage = {
    1: const WorldMusicProfile(
      themeName: 'forest_calm', bpm: 80, scale: 'pentatonic_major',
      intensity: 0.3, layers: 2, description: 'Bosque — calma, hojas, naturaleza',
    ),
    2: const WorldMusicProfile(
      themeName: 'academy_focus', bpm: 90, scale: 'lydian',
      intensity: 0.4, layers: 2, description: 'Academia — concentración, estudio',
    ),
    3: const WorldMusicProfile(
      themeName: 'temple_serenity', bpm: 70, scale: 'dorian',
      intensity: 0.4, layers: 3, victoryTheme: 'reverence',
      description: 'Templo — campanas, eco, serenidad',
    ),
    4: const WorldMusicProfile(
      themeName: 'meadows_gentle', bpm: 85, scale: 'major',
      intensity: 0.35, layers: 2, description: 'Praderas — suave, abierto',
    ),
    5: const WorldMusicProfile(
      themeName: 'kingdom_rising', bpm: 95, scale: 'mixolydian',
      intensity: 0.5, layers: 3, description: 'Reino — determinación',
    ),
    6: const WorldMusicProfile(
      themeName: 'mountains_majestic', bpm: 88, scale: 'aeolian',
      intensity: 0.55, layers: 3, victoryTheme: 'soar',
      description: 'Montañas — niebla, grandeza',
    ),
    7: const WorldMusicProfile(
      themeName: 'city_advanced', bpm: 100, scale: 'phrygian',
      intensity: 0.6, layers: 3, description: 'Ciudad — ritmo, complejidad',
    ),
    8: const WorldMusicProfile(
      themeName: 'fortress_war', bpm: 110, scale: 'phrygian_dominant',
      intensity: 0.7, layers: 4, bossIntensity: 0.9, victoryTheme: 'battle_hymn',
      description: 'Fortaleza — brasas, batalla',
    ),
    9: const WorldMusicProfile(
      themeName: 'evil_shadow', bpm: 75, scale: 'diminished',
      intensity: 0.8, layers: 4, bossIntensity: 0.95, victoryTheme: 'dark_triumph',
      description: 'Evil — sombras, tensión',
    ),
    10: const WorldMusicProfile(
      themeName: 'mythic_stars', bpm: 65, scale: 'chromatic',
      intensity: 0.9, layers: 5, bossIntensity: 1.0, victoryTheme: 'apotheosis',
      description: 'Mythic — estrellas, infinito',
    ),
  };

  static WorldMusicProfile forStageNum(int stage) => forStage[stage] ?? forStage.values.first;
}

// ═══════════════════════════════════════════════════════════════════════════
// F11 — Variant Architecture (future-proof, NOT implemented in gameplay)
// ═══════════════════════════════════════════════════════════════════════════

enum SudokuVariantType {
  classic,
  jigsaw,
  hyper,
  windoku,
  xSudoku;

  String get label => switch (this) {
    SudokuVariantType.classic => 'Clásico',
    SudokuVariantType.jigsaw => 'Jigsaw',
    SudokuVariantType.hyper => 'Hyper',
    SudokuVariantType.windoku => 'Windoku',
    SudokuVariantType.xSudoku => 'X Sudoku',
  };

  String get iconAsset => 'assets/cosmetics/variants/${name}.png';
}

// ═══════════════════════════════════════════════════════════════════════════
// F10 — Boss Identity
// ═══════════════════════════════════════════════════════════════════════════

class BossIdentity {
  final String name;
  final String title;
  final String introQuote;
  final String entryAnimation;
  final String victoryQuote;

  const BossIdentity({
    required this.name,
    required this.title,
    required this.introQuote,
    required this.entryAnimation,
    required this.victoryQuote,
  });

  static final Map<String, BossIdentity> registry = {
    'guardian_of_logic': BossIdentity(
      name: 'Guardian of Logic',
      title: 'El Guardián',
      introQuote: 'Demostrame que entendés las reglas básicas.',
      entryAnimation: 'guardian',
      victoryQuote: 'Bien. Tenés fundamentos sólidos.',
    ),
    'master_of_time': BossIdentity(
      name: 'Master of Time',
      title: 'El Maestro del Tiempo',
      introQuote: 'El tiempo no espera. Mostrame tu velocidad.',
      entryAnimation: 'time',
      victoryQuote: 'Impresionante. Tu velocidad es notable.',
    ),
    'silent_solver': BossIdentity(
      name: 'Silent Solver',
      title: 'El Solitario',
      introQuote: 'Sin pistas. Sin ayuda. Solo vos.',
      entryAnimation: 'silent',
      victoryQuote: 'Resolviste en silencio. Respeto.',
    ),
    'perfect_judge': BossIdentity(
      name: 'Perfect Judge',
      title: 'El Juez Perfecto',
      introQuote: 'Un solo error y caerás.',
      entryAnimation: 'judge',
      victoryQuote: 'Perfecto. No esperaba menos.',
    ),
    'logic_colossus': BossIdentity(
      name: 'Logic Colossus',
      title: 'El Coloso',
      introQuote: 'Mis técnicas son superiores.',
      entryAnimation: 'colossus',
      victoryQuote: 'Imposible... caí ante un mortal.',
    ),
    'time_weaver': BossIdentity(
      name: 'Time Weaver',
      title: 'El Tejedor',
      introQuote: 'El reloj corre. ¿Podrás seguir mi ritmo?',
      entryAnimation: 'time',
      victoryQuote: 'Tejedor del tiempo... derrotado.',
    ),
    'void_anchorite': BossIdentity(
      name: 'Void Anchorite',
      title: 'El Anacoreta',
      introQuote: 'En el vacío, solo tu mente importa.',
      entryAnimation: 'void',
      victoryQuote: 'Has visto el vacío y regresaste.',
    ),
    'quantum_sage': BossIdentity(
      name: 'Quantum Sage',
      title: 'El Sabio Cuántico',
      introQuote: 'Las variables se multiplican.',
      entryAnimation: 'quantum',
      victoryQuote: 'Tu lógica trasciende dimensiones.',
    ),
    'abyss_sentinel': BossIdentity(
      name: 'Abyss Sentinel',
      title: 'El Centinela',
      introQuote: 'El abismo te observa.',
      entryAnimation: 'abyss',
      victoryQuote: 'El abismo parpadeó primero.',
    ),
    'mythic_phoenix': BossIdentity(
      name: 'Mythic Phoenix',
      title: 'El Fénix',
      introQuote: 'Renacido de las cenizas del caos.',
      entryAnimation: 'phoenix',
      victoryQuote: 'El Fénix se inclina ante su maestro.',
    ),
  };

  static BossIdentity forId(String id) => registry[id] ?? registry.values.first;
}

// ═══════════════════════════════════════════════════════════════════════════
// F4 — World Missions
// ═══════════════════════════════════════════════════════════════════════════

enum MissionType {
  completeLevels,
  perfectLevels,
  bossNoHelp,
  totalStars,
  noMistakesStreak,
  speedLevels,
}

class WorldMission {
  final String id;
  final MissionType type;
  final String title;
  final String description;
  final int target;
  final int soulsReward;
  final int tokensReward;
  final String? cosmeticRewardId;

  const WorldMission({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.target,
    this.soulsReward = 0,
    this.tokensReward = 0,
    this.cosmeticRewardId,
  });
}

class WorldMissionProgress {
  final Map<String, int> progress; // missionId -> current count
  final Set<String> completed;

  const WorldMissionProgress({
    this.progress = const {},
    this.completed = const {},
  });

  int get(String missionId) => progress[missionId] ?? 0;
  bool isCompleted(String missionId) => completed.contains(missionId);
  bool get allCompleted => completed.length >= 4; // 3-5 per world

  WorldMissionProgress copyWith({
    Map<String, int>? progress,
    Set<String>? completed,
  }) => WorldMissionProgress(
    progress: progress ?? this.progress,
    completed: completed ?? this.completed,
  );

  Map<String, dynamic> toJson() => {
    'progress': progress,
    'completed': completed.toList(),
  };

  factory WorldMissionProgress.fromJson(Map<String, dynamic> json) => WorldMissionProgress(
    progress: (json['progress'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {},
    completed: (json['completed'] as List?)?.map((e) => e.toString()).toSet() ?? {},
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// World mission definitions per stage
// ═══════════════════════════════════════════════════════════════════════════

List<WorldMission> worldMissionsForStage(CampaignStage stage) {
  final baseId = 'stage_${stage.datasetStage}';
  return [
    WorldMission(
      id: '${baseId}_complete',
      type: MissionType.completeLevels,
      title: 'Completador',
      description: 'Completá ${stage.levelCount} niveles',
      target: stage.levelCount,
      soulsReward: stage.datasetStage * 2,
      tokensReward: stage.datasetStage * 5,
    ),
    WorldMission(
      id: '${baseId}_perfect',
      type: MissionType.perfectLevels,
      title: 'Perfecto',
      description: 'Conseguí 5 niveles sin errores',
      target: 5,
      soulsReward: stage.datasetStage * 3,
      tokensReward: stage.datasetStage * 3,
    ),
    WorldMission(
      id: '${baseId}_stars',
      type: MissionType.totalStars,
      title: 'Coleccionista de Estrellas',
      description: 'Acumulá 60 estrellas en este mundo',
      target: 60,
      soulsReward: stage.datasetStage * 5,
      tokensReward: stage.datasetStage * 8,
    ),
    WorldMission(
      id: '${baseId}_speed',
      type: MissionType.speedLevels,
      title: 'Rayo',
      description: 'Completá 3 niveles en tiempo récord',
      target: 3,
      soulsReward: stage.datasetStage * 2,
      tokensReward: stage.datasetStage * 4,
    ),
    if (stage.hasBosses)
      WorldMission(
        id: '${baseId}_boss',
        type: MissionType.bossNoHelp,
        title: 'Sin Miedo',
        description: 'Derrotá al boss sin pistas',
        target: 1,
        soulsReward: stage.datasetStage * 10,
        tokensReward: stage.datasetStage * 10,
        cosmeticRewardId: 'boss_${stage.datasetStage}',
      ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// F5 — Chests
// ═══════════════════════════════════════════════════════════════════════════

enum ChestType { mini, world, boss, completion }

class ChestReward {
  final int tokens;
  final int souls;
  final int hints;
  final int advancedNotes;
  final int spins;
  final String? cosmeticId;
  final bool isJackpot;

  const ChestReward({
    this.tokens = 0,
    this.souls = 0,
    this.hints = 0,
    this.advancedNotes = 0,
    this.spins = 0,
    this.cosmeticId,
    this.isJackpot = false,
  });
}

class WorldChest {
  final String id;
  final int level;
  final ChestType type;
  final bool claimed;

  const WorldChest({
    required this.id,
    required this.level,
    required this.type,
    this.claimed = false,
  });

  WorldChest claim() => copyWith(claimed: true);
  WorldChest copyWith({bool? claimed}) => WorldChest(
    id: id, level: level, type: type, claimed: claimed ?? this.claimed,
  );

  ChestReward generateReward(int stage) {
    final rng = _SimpleRng(level * 7 + stage * 13);
    return switch (type) {
      ChestType.mini => ChestReward(
        tokens: 1 + rng.nextInt(3),
        souls: 1 + rng.nextInt(2),
        hints: rng.nextInt(2),
      ),
      ChestType.world => ChestReward(
        tokens: 5 + rng.nextInt(6),
        souls: 3 + rng.nextInt(4),
        hints: 1 + rng.nextInt(2),
        advancedNotes: rng.nextInt(2),
        spins: rng.nextInt(2),
      ),
      ChestType.boss => ChestReward(
        tokens: 1 + rng.nextInt(2),
        souls: 10 + rng.nextInt(51),
        hints: 2 + rng.nextInt(2),
        advancedNotes: 1 + rng.nextInt(2),
        spins: 1 + rng.nextInt(2),
        cosmeticId: rng.nextInt(100) < 35 ? 'chest_cosmetic_$stage' : null,
      ),
      ChestType.completion => ChestReward(
        tokens: 25 + rng.nextInt(26),
        souls: 25 + rng.nextInt(26),
        hints: 5,
        advancedNotes: 3,
        spins: 3,
        cosmeticId: 'completion_$stage',
        isJackpot: true,
      ),
    };
  }

  Map<String, dynamic> toJson() => {'id': id, 'level': level, 'type': type.name, 'claimed': claimed};

  factory WorldChest.fromJson(Map<String, dynamic> json) => WorldChest(
    id: json['id'] as String? ?? '',
    level: (json['level'] as num?)?.toInt() ?? 0,
    type: ChestType.values.firstWhere((e) => e.name == json['type'], orElse: () => ChestType.mini),
    claimed: json['claimed'] as bool? ?? false,
  );
}

class _SimpleRng {
  int _state;
  _SimpleRng(this._state);
  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }
}

List<WorldChest> chestsForStage(CampaignStage stage) {
  final s = stage.datasetStage;
  final start = stage.levelStart;
  final chests = <WorldChest>[];
  if (stage.levelCount >= 25) {
    chests.add(WorldChest(id: 's${s}_mini', level: start + 9, type: ChestType.mini));
    chests.add(WorldChest(id: 's${s}_world', level: start + 19, type: ChestType.world));
  }
  if (stage.bossConfig != null) {
    chests.add(WorldChest(id: 's${s}_boss_mini', level: stage.bossConfig!.miniBossLevel, type: ChestType.boss));
    chests.add(WorldChest(id: 's${s}_boss_main', level: stage.bossConfig!.bossLevel, type: ChestType.boss));
  }
  chests.add(WorldChest(id: 's${s}_complete', level: stage.levelEnd, type: ChestType.completion));
  return chests;
}

// ═══════════════════════════════════════════════════════════════════════════
// F6 — Collectibles (Astral Fragments)
// ═══════════════════════════════════════════════════════════════════════════

class AstralFragment {
  final int fragmentIndex;
  final int level;
  final bool collected;

  const AstralFragment({required this.fragmentIndex, required this.level, this.collected = false});
}

class WorldCompletionProgress {
  final Set<int> clearedStages;

  const WorldCompletionProgress({this.clearedStages = const {}});

  bool isCleared(int stage) => clearedStages.contains(stage);
  WorldCompletionProgress markCleared(int stage) =>
    WorldCompletionProgress(clearedStages: {...clearedStages, stage});

  Map<String, dynamic> toJson() => {'clearedStages': clearedStages.toList()};

  factory WorldCompletionProgress.fromJson(Map<String, dynamic> json) => WorldCompletionProgress(
    clearedStages: (json['clearedStages'] as List?)?.map((e) => (e as num).toInt()).toSet() ?? {},
  );
}

class FragmentProgress {
  final Map<String, Set<int>> collected; // stageKey -> fragment indices (0-7)

  const FragmentProgress({this.collected = const {}});

  int collectedIn(String stageKey) => collected[stageKey]?.length ?? 0;
  bool hasCollected(String stageKey, int index) => collected[stageKey]?.contains(index) ?? false;
  static const int totalPerStage = 8;

  FragmentProgress collect(String stageKey, int index) {
    final current = collected[stageKey] ?? {};
    final updated = Set<int>.from(current)..add(index);
    return FragmentProgress(collected: {...collected, stageKey: updated});
  }

  int totalCollected() => collected.values.fold(0, (s, set) => s + set.length);

  Map<String, dynamic> toJson() => {'collected': collected.map((k, v) => MapEntry(k, v.toList()))};

  factory FragmentProgress.fromJson(Map<String, dynamic> json) => FragmentProgress(
    collected: (json['collected'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, (v as List).map((e) => (e as num).toInt()).toSet())) ?? {},
  );
}

List<AstralFragment> fragmentsForStage(CampaignStage stage) {
  final start = stage.levelStart;
  final total = stage.levelCount;
  final step = total ~/ 8;
  return List.generate(8, (i) => AstralFragment(
    fragmentIndex: i,
    level: start + (step * i).clamp(0, total - 1),
  ));
}

// ═══════════════════════════════════════════════════════════════════════════
// F7 — Perfect Streak
// ═══════════════════════════════════════════════════════════════════════════

class PerfectStreak {
  final int currentStreak;
  final int bestStreak;
  final Set<int> streakRewardLevels;

  const PerfectStreak({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.streakRewardLevels = const {},
  });

  bool get hasActiveStreak => currentStreak >= 2;
  bool rewardClaimedAt(int level) => streakRewardLevels.contains(level);

  PerfectStreak recordWin(bool wasPerfect) {
    if (!wasPerfect) return PerfectStreak(bestStreak: currentStreak > bestStreak ? currentStreak : bestStreak);
    final newStreak = currentStreak + 1;
    final newBest = newStreak > bestStreak ? newStreak : bestStreak;
    return PerfectStreak(currentStreak: newStreak, bestStreak: newBest, streakRewardLevels: streakRewardLevels);
  }

  PerfectStreak claimReward(int level) => PerfectStreak(
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    streakRewardLevels: {...streakRewardLevels, level},
  );

  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'streakRewardLevels': streakRewardLevels.toList(),
  };

  factory PerfectStreak.fromJson(Map<String, dynamic> json) => PerfectStreak(
    currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
    bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
    streakRewardLevels: (json['streakRewardLevels'] as List?)?.map((e) => (e as num).toInt()).toSet() ?? {},
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// F8 — Technique Codex
// ═══════════════════════════════════════════════════════════════════════════

class CodexEntry {
  final String techniqueId;
  final String name;
  final String description;
  final String icon;
  final int unlockLevel;
  final int tier;

  const CodexEntry({
    required this.techniqueId,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlockLevel,
    required this.tier,
  });

  static final List<CodexEntry> registry = [
    CodexEntry(techniqueId: 'last_blank_cell', name: 'Última Celda', description: 'Si solo queda una celda vacía en una unidad, esa celda debe contener el número faltante.', icon: '🔲', unlockLevel: 1, tier: 1),
    CodexEntry(techniqueId: 'full_house', name: 'Casa Llena', description: 'Cuando solo falta un número en una fila, columna o bloque.', icon: '🏠', unlockLevel: 2, tier: 1),
    CodexEntry(techniqueId: 'naked_single', name: 'Single Desnudo', description: 'Una celda con una sola opción posible.', icon: '1️⃣', unlockLevel: 3, tier: 1),
    CodexEntry(techniqueId: 'hidden_single', name: 'Single Oculto', description: 'Un número que solo puede ir en una celda dentro de una unidad.', icon: '🔍', unlockLevel: 5, tier: 1),
    CodexEntry(techniqueId: 'pointing_pair', name: 'Par Apuntador', description: 'Un par de celdas en un bloque que apuntan a una fila o columna.', icon: '👉', unlockLevel: 25, tier: 2),
    CodexEntry(techniqueId: 'box_line_reduction', name: 'Reducción Caja-Línea', description: 'Un número restringido a una línea dentro de un bloque.', icon: '📦', unlockLevel: 50, tier: 2),
    CodexEntry(techniqueId: 'naked_pair', name: 'Par Desnudo', description: 'Dos celdas en la misma unidad con las mismas dos opciones.', icon: '2️⃣', unlockLevel: 75, tier: 2),
    CodexEntry(techniqueId: 'hidden_pair', name: 'Par Oculto', description: 'Dos números que solo pueden ir en dos celdas dentro de una unidad.', icon: '🙈', unlockLevel: 100, tier: 3),
    CodexEntry(techniqueId: 'naked_triple', name: 'Triple Desnudo', description: 'Tres celdas con tres opciones totales.', icon: '3️⃣', unlockLevel: 150, tier: 3),
    CodexEntry(techniqueId: 'xwing', name: 'X-Wing', description: 'Dos filas donde un número solo aparece en las mismas dos columnas.', icon: '✈️', unlockLevel: 250, tier: 4),
    CodexEntry(techniqueId: 'swordfish', name: 'Swordfish', description: 'Tres filas donde un número aparece en solo tres columnas.', icon: '🐟', unlockLevel: 400, tier: 5),
    CodexEntry(techniqueId: 'xywing', name: 'XY-Wing', description: 'Tres celdas con valores AB, AC, BC que eliminan BC.', icon: '🪽', unlockLevel: 500, tier: 5),
    CodexEntry(techniqueId: 'unique_rectangle', name: 'Rectángulo Único', description: 'Evita soluciones múltiples usando una forma de 4 celdas.', icon: '⬛', unlockLevel: 600, tier: 6),
    CodexEntry(techniqueId: 'bug', name: 'BUG', description: 'Bivalue Universal Grave — patrón que indica solución única.', icon: '🐛', unlockLevel: 700, tier: 7),
    CodexEntry(techniqueId: 'empty_rectangle', name: 'Rectángulo Vacío', description: 'Un bloque casi lleno donde un número solo falta en una línea.', icon: '▫️', unlockLevel: 800, tier: 8),
  ];
}

class CodexProgress {
  final Set<String> seenTechniques;

  const CodexProgress({this.seenTechniques = const {}});

  bool hasSeen(String techniqueId) => seenTechniques.contains(techniqueId);
  bool get allSeen => seenTechniques.length >= CodexEntry.registry.length;

  CodexProgress markSeen(String techniqueId) => CodexProgress(
    seenTechniques: {...seenTechniques, techniqueId},
  );

  Map<String, dynamic> toJson() => {'seenTechniques': seenTechniques.toList()};

  factory CodexProgress.fromJson(Map<String, dynamic> json) => CodexProgress(
    seenTechniques: (json['seenTechniques'] as List?)?.map((e) => e.toString()).toSet() ?? {},
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// F9 — Mentor Messages
// ═══════════════════════════════════════════════════════════════════════════

class MentorMessage {
  final String id;
  final int triggerLevel;
  final String message;
  final String? techniqueId;

  const MentorMessage({
    required this.id,
    required this.triggerLevel,
    required this.message,
    this.techniqueId,
  });
}

final List<MentorMessage> mentorMessages = [
  MentorMessage(id: 'welcome', triggerLevel: 1, message: 'Bienvenido al Sudoku. Colocá números sin repetir en filas, columnas y bloques.', techniqueId: null),
  MentorMessage(id: 'naked_single_intro', triggerLevel: 5, message: 'Buscá celdas con UNA sola opción posible — es la técnica más básica.', techniqueId: 'naked_single'),
  MentorMessage(id: 'hidden_single_intro', triggerLevel: 10, message: 'Si un número solo puede ir en una celda de una unidad, es un Single Oculto.', techniqueId: 'hidden_single'),
  MentorMessage(id: 'pointing_intro', triggerLevel: 25, message: 'Hoy aprenderás Pointing Pair. Un par en un bloque apunta a toda una línea.', techniqueId: 'pointing_pair'),
  MentorMessage(id: 'pairs_intro', triggerLevel: 75, message: 'Pares Desnudos: dos celdas, dos opciones. Eliminalos del resto de la unidad.', techniqueId: 'naked_pair'),
  MentorMessage(id: 'xwing_intro', triggerLevel: 250, message: 'X-Wing — buscá dos filas donde un número solo aparezca en las mismas dos columnas.', techniqueId: 'xwing'),
  MentorMessage(id: 'swordfish_intro', triggerLevel: 400, message: 'Swordfish: como X-Wing pero con tres filas y tres columnas.', techniqueId: 'swordfish'),
  MentorMessage(id: 'mythic_hint', triggerLevel: 826, message: 'Estás en territorio mítico. Cada movimiento cuenta.', techniqueId: null),
];

// ═══════════════════════════════════════════════════════════════════════════
// F1 — Biome Configs (map visual identity per stage)
// ═══════════════════════════════════════════════════════════════════════════

class BiomeConfig {
  final String name;
  final String subtitle;
  final int primaryColor;
  final int secondaryColor;
  final int accentColor;
  final int backgroundColor;
  final String particleType;
  final String icon;

  const BiomeConfig({
    required this.name,
    required this.subtitle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    this.particleType = 'sparkle',
    this.icon = '🌍',
  });

  static final Map<int, BiomeConfig> forStage = {
    1: const BiomeConfig(name: 'Bosque Inicial', subtitle: '4×4 — Aprendé las bases', primaryColor: 0xFF2D5016, secondaryColor: 0xFF1A3A0A, accentColor: 0xFF7CB342, backgroundColor: 0xFF0D1F08, particleType: 'leaf', icon: '🌳'),
    2: const BiomeConfig(name: 'Academia', subtitle: '6×6 — Crece el desafío', primaryColor: 0xFF1A237E, secondaryColor: 0xFF0D1442, accentColor: 0xFF5C6BC0, backgroundColor: 0xFF0A0D2E, particleType: 'book', icon: '📚'),
    3: const BiomeConfig(name: 'Templo', subtitle: '8×8 — Concentración', primaryColor: 0xFF8D6E63, secondaryColor: 0xFF4E342E, accentColor: 0xFFD4A574, backgroundColor: 0xFF2C1B0E, particleType: 'ember', icon: '🏛️'),
    4: const BiomeConfig(name: 'Praderas del Saber', subtitle: '9×9 — Primeros pasos', primaryColor: 0xFF4A7C59, secondaryColor: 0xFF2E5C3E, accentColor: 0xFF81C784, backgroundColor: 0xFF1B2E1A, particleType: 'leaf', icon: '🌾'),
    5: const BiomeConfig(name: 'Reino Beginner', subtitle: 'Tier 1–2', primaryColor: 0xFF5D4037, secondaryColor: 0xFF3E2723, accentColor: 0xFFA1887F, backgroundColor: 0xFF1D110A, particleType: 'dust', icon: '🏰'),
    6: const BiomeConfig(name: 'Montañas Logic', subtitle: 'Tier 2–3', primaryColor: 0xFF37474F, secondaryColor: 0xFF263238, accentColor: 0xFF78909C, backgroundColor: 0xFF111B1E, particleType: 'snow', icon: '⛰️'),
    7: const BiomeConfig(name: 'Ciudad Advanced', subtitle: 'Tier 3–4', primaryColor: 0xFF4527A0, secondaryColor: 0xFF2A0E6B, accentColor: 0xFFB388FF, backgroundColor: 0xFF130733, particleType: 'sparkle', icon: '🏙️'),
    8: const BiomeConfig(name: 'Fortaleza Expert', subtitle: 'Tier 4–6', primaryColor: 0xFFBF360C, secondaryColor: 0xFF871F00, accentColor: 0xFFFF6E40, backgroundColor: 0xFF1A0500, particleType: 'ember', icon: '🏯'),
    9: const BiomeConfig(name: 'Tierras Evil', subtitle: 'Tier 5–7', primaryColor: 0xFF4A148C, secondaryColor: 0xFF2C0052, accentColor: 0xFFCE93D8, backgroundColor: 0xFF0E001A, particleType: 'skull', icon: '💀'),
    10: const BiomeConfig(name: 'Dominio Mythic', subtitle: 'Tier 6–8', primaryColor: 0xFFFF6F00, secondaryColor: 0xFFBF360C, accentColor: 0xFFFFD54F, backgroundColor: 0xFF1A0A00, particleType: 'phoenix', icon: '🔥'),
  };

  static BiomeConfig forStageNum(int stage) => forStage[stage] ?? forStage.values.first;
}
