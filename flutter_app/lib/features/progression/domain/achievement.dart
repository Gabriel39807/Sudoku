class Achievement {
  final String id;
  final String title;
  final String description;
  final int target;
  final int xpReward;
  final String iconName;
  final bool hidden;
  int progress;
  bool unlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    this.xpReward = 50,
    this.iconName = 'emoji_events',
    this.hidden = false,
    this.progress = 0,
    this.unlocked = false,
    this.unlockedAt,
  });

  double get ratio => target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
  bool get isNew => unlockedAt != null;

  /// Rarity tier based on target value (heuristic for display).
  String get rarity {
    if (target >= 500) return 'legendario';
    if (target >= 250) return 'épico';
    if (target >= 100) return 'raro';
    if (target >= 25) return 'poco común';
    return 'común';
  }

  Map<String, dynamic> toJson() => {
    'progress': progress,
    'unlocked': unlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory Achievement.fromJson(String id, Map<String, dynamic> json) =>
      Achievement(
        id: id,
        title: '',
        description: '',
        target: 0,
        progress: json['progress'] as int? ?? 0,
        unlocked: json['unlocked'] as bool? ?? false,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.parse(json['unlockedAt'] as String)
            : null,
      );

  Achievement copyWith({int? progress, bool? unlocked, DateTime? unlockedAt}) =>
      Achievement(
        id: id,
        title: title,
        description: description,
        target: target,
        xpReward: xpReward,
        iconName: iconName,
        hidden: hidden,
        progress: progress ?? this.progress,
        unlocked: unlocked ?? this.unlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );
}

/// Registry of all achievements in the game.
class AchievementRegistry {
  static List<Achievement> all() => [
    // ── General ─────────────────────────────────────────────────────────────
    Achievement(id: 'wins_1', title: 'Primera Victoria', description: 'Gana tu primera partida', target: 1, xpReward: 50),
    Achievement(id: 'wins_10', title: '10 Victorias', description: 'Gana 10 partidas', target: 10, xpReward: 100),
    Achievement(id: 'wins_50', title: '50 Victorias', description: 'Gana 50 partidas', target: 50, xpReward: 200),
    Achievement(id: 'wins_100', title: 'Centenario', description: 'Gana 100 partidas', target: 100, xpReward: 300),
    Achievement(id: 'wins_250', title: 'Dedicación', description: 'Gana 250 partidas', target: 250, xpReward: 500),
    Achievement(id: 'wins_500', title: 'Obsesión', description: 'Gana 500 partidas', target: 500, xpReward: 750),
    Achievement(id: 'wins_1000', title: 'Leyenda Viviente', description: 'Gana 1000 partidas', target: 1000, xpReward: 1000),

    // ── Perfect ─────────────────────────────────────────────────────────────
    Achievement(id: 'perfect_1', title: 'Impecable', description: 'Consigue tu primera Victoria Perfecta', target: 1, xpReward: 150),
    Achievement(id: 'perfect_10', title: '10 Perfectas', description: 'Consigue 10 Victorias Perfectas', target: 10, xpReward: 300),
    Achievement(id: 'perfect_25', title: '25 Perfectas', description: 'Consigue 25 Victorias Perfectas', target: 25, xpReward: 500),
    Achievement(id: 'perfect_50', title: '50 Perfectas', description: 'Consigue 50 Victorias Perfectas', target: 50, xpReward: 750),
    Achievement(id: 'perfect_100', title: '100 Perfectas', description: 'Consigue 100 Victorias Perfectas', target: 100, xpReward: 1000),

    // ── Difficulty: Easy ────────────────────────────────────────────────────
    Achievement(id: 'easy_10', title: 'Easy 10', description: 'Completa 10 partidas en Easy', target: 10, xpReward: 50),
    Achievement(id: 'easy_50', title: 'Easy 50', description: 'Completa 50 partidas en Easy', target: 50, xpReward: 150),
    Achievement(id: 'easy_100', title: 'Easy 100', description: 'Completa 100 partidas en Easy', target: 100, xpReward: 300),

    // ── Difficulty: Intermediate ────────────────────────────────────────────
    Achievement(id: 'intermediate_10', title: 'Intermedio 10', description: 'Completa 10 partidas en Intermediate', target: 10, xpReward: 75),
    Achievement(id: 'intermediate_50', title: 'Intermedio 50', description: 'Completa 50 partidas en Intermediate', target: 50, xpReward: 200),

    // ── Difficulty: Hard ────────────────────────────────────────────────────
    Achievement(id: 'hard_5', title: 'Hard 5', description: 'Completa 5 partidas en Hard', target: 5, xpReward: 100),
    Achievement(id: 'hard_25', title: 'Hard 25', description: 'Completa 25 partidas en Hard', target: 25, xpReward: 250),
    Achievement(id: 'hard_75', title: 'Hard 75', description: 'Completa 75 partidas en Hard', target: 75, xpReward: 500),

    // ── Difficulty: Expert ──────────────────────────────────────────────────
    Achievement(id: 'expert_1', title: 'Expert Clear', description: 'Completa tu primera partida en Expert', target: 1, xpReward: 150),
    Achievement(id: 'expert_10', title: 'Expert 10', description: 'Completa 10 partidas en Expert', target: 10, xpReward: 300),
    Achievement(id: 'expert_50', title: 'Expert 50', description: 'Completa 50 partidas en Expert', target: 50, xpReward: 600),

    // ── Difficulty: Evil ───────────────────────────────────────────────────
    Achievement(id: 'evil_1', title: 'Sin Miedo', description: 'Completa tu primera partida en Evil', target: 1, xpReward: 200),
    Achievement(id: 'evil_10', title: 'Evil 10', description: 'Completa 10 partidas en Evil', target: 10, xpReward: 400),
    Achievement(id: 'evil_25', title: 'Evil 25', description: 'Completa 25 partidas en Evil', target: 25, xpReward: 700),

    // ── Difficulty: Mythic (hidden) ─────────────────────────────────────────
    Achievement(id: 'mythic_1', title: '???', description: '???', target: 1, xpReward: 500, hidden: true),
    Achievement(id: 'mythic_10', title: '???', description: '???', target: 10, xpReward: 1000, hidden: true),
    Achievement(id: 'mythic_25', title: '???', description: '???', target: 25, xpReward: 1500, hidden: true),

    // ── Time ────────────────────────────────────────────────────────────────
    Achievement(id: 'time_easy_5m', title: 'Rápido Easy', description: 'Completa Easy en menos de 5 minutos', target: 1, xpReward: 100),
    Achievement(id: 'time_intermediate_8m', title: 'Rápido Intermedio', description: 'Completa Intermediate en menos de 8 minutos', target: 1, xpReward: 150),
    Achievement(id: 'time_hard_10m', title: 'Rápido Hard', description: 'Completa Hard en menos de 10 minutos', target: 1, xpReward: 200),
    Achievement(id: 'time_expert_12m', title: 'Rápido Expert', description: 'Completa Expert en menos de 12 minutos', target: 1, xpReward: 300),

    // ── Combos ──────────────────────────────────────────────────────────────
    Achievement(id: 'combo_5', title: 'Combo 5', description: 'Alcanza un combo de 5 aciertos consecutivos', target: 5, xpReward: 50),
    Achievement(id: 'combo_10', title: 'Combo 10', description: 'Alcanza un combo de 10 aciertos consecutivos', target: 10, xpReward: 100),
    Achievement(id: 'combo_20', title: 'Combo 20', description: 'Alcanza un combo de 20 aciertos consecutivos', target: 20, xpReward: 200),
    Achievement(id: 'combo_50', title: 'Combo 50', description: 'Alcanza un combo de 50 aciertos consecutivos', target: 50, xpReward: 500),

    // ── Winstreaks ──────────────────────────────────────────────────────────
    Achievement(id: 'perfect_streak_5', title: 'Racha Perfecta 5', description: 'Consigue 5 Victorias Perfectas consecutivas', target: 5, xpReward: 200),
    Achievement(id: 'win_streak_10', title: 'Racha 10', description: 'Consigue 10 victorias consecutivas', target: 10, xpReward: 300),

    // ── Hints ───────────────────────────────────────────────────────────────
    Achievement(id: 'hints_10', title: '10 Pistas', description: 'Usa 10 pistas en total', target: 10, xpReward: 50),
    Achievement(id: 'hints_50', title: '50 Pistas', description: 'Usa 50 pistas en total', target: 50, xpReward: 150),
    Achievement(id: 'hints_100', title: '100 Pistas', description: 'Usa 100 pistas en total', target: 100, xpReward: 300),
    Achievement(id: 'no_hints_10', title: 'Sin Pistas 10', description: 'Completa 10 partidas sin usar pistas', target: 10, xpReward: 200),
    Achievement(id: 'no_hints_50', title: 'Sin Pistas 50', description: 'Completa 50 partidas sin usar pistas', target: 50, xpReward: 500),

    // ── Errors ──────────────────────────────────────────────────────────────
    Achievement(id: 'lost_10', title: '10 Derrotas', description: 'Pierde 10 partidas', target: 10, xpReward: 50),
    Achievement(id: 'expert_no_errors', title: 'Expert sin Errores', description: 'Completa Expert sin cometer errores', target: 1, xpReward: 200),
    Achievement(id: 'mythic_no_errors', title: '???', description: '???', target: 1, xpReward: 500, hidden: true),

    // ── Missions ────────────────────────────────────────────────────────────
    Achievement(id: 'missions_1', title: 'Primera Misión', description: 'Completa tu primera misión diaria', target: 1, xpReward: 50),
    Achievement(id: 'missions_25', title: '25 Misiones', description: 'Completa 25 misiones diarias', target: 25, xpReward: 200),
    Achievement(id: 'missions_100', title: '100 Misiones', description: 'Completa 100 misiones diarias', target: 100, xpReward: 500),

    // ── Completion ──────────────────────────────────────────────────────────
    Achievement(id: 'all_modes', title: 'Versátil', description: 'Completa al menos una partida en cada dificultad', target: 6, xpReward: 500),
    Achievement(id: 'all_achievements', title: 'Completista', description: 'Consigue todos los logros', target: 1, xpReward: 2000),
  ];

  static Achievement? byId(String id) {
    try {
      return all().firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
