class DailyMission {
  final String id;
  final String title;
  final String description;
  final int target;
  final int xpReward;
  final String dateKey;
  int progress;
  bool completed;

  DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    this.xpReward = 75,
    String? dateKey,
    this.progress = 0,
    this.completed = false,
  }) : dateKey = dateKey ?? todayKey();

  double get ratio => target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  DailyMission copyWith({int? progress, bool? completed}) =>
      DailyMission(
        id: id,
        title: title,
        description: description,
        target: target,
        xpReward: xpReward,
        dateKey: dateKey,
        progress: progress ?? this.progress,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'progress': progress,
    'completed': completed,
    'dateKey': dateKey,
  };

  factory DailyMission.fromJson(Map<String, dynamic> json) =>
      DailyMission(
        id: json['id'] as String,
        title: _titleFor(json['id'] as String),
        description: _descFor(json['id'] as String),
        target: _targetFor(json['id'] as String),
        dateKey: json['dateKey'] as String? ?? todayKey(),
        progress: json['progress'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
      );

  static String todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _titleFor(String id) {
    switch (id) {
      case 'complete_easy': return 'Easy Clear';
      case 'play_three': return 'Jugador Frecuente';
      case 'perfect_win': return 'Día Perfecto';
      case 'no_hints': return 'Sin Ayuda';
      case 'solve_50': return 'Resolvedor';
      case 'complete_expert': return 'Expert Clear';
      case 'zero_errors': return 'Impecable';
      case 'three_combos': return 'Racha';
      default: return id;
    }
  }

  static String _descFor(String id) {
    switch (id) {
      case 'complete_easy': return 'Completa una partida en Easy';
      case 'play_three': return 'Juega 3 partidas';
      case 'perfect_win': return 'Victoria perfecta (sin errores ni pistas)';
      case 'no_hints': return 'Completa una partida sin usar pistas';
      case 'solve_50': return 'Resuelve 50 celdas';
      case 'complete_expert': return 'Completa una partida en Expert';
      case 'zero_errors': return 'Completa una partida con 0 errores';
      case 'three_combos': return 'Alcanza 3 combos en una partida';
      default: return id;
    }
  }

  static int _targetFor(String id) {
    switch (id) {
      case 'complete_easy': return 1;
      case 'play_three': return 3;
      case 'perfect_win': return 1;
      case 'no_hints': return 1;
      case 'solve_50': return 50;
      case 'complete_expert': return 1;
      case 'zero_errors': return 1;
      case 'three_combos': return 3;
      default: return 1;
    }
  }
}

/// Generates daily missions for today.
List<DailyMission> generateDailyMissions() {
  final keys = [
    'complete_easy', 'play_three', 'perfect_win',
    'no_hints', 'solve_50', 'complete_expert',
    'zero_errors', 'three_combos',
  ];
  final random = DateTime.now().millisecondsSinceEpoch;
  final shuffled = List<String>.from(keys)..sort((a, b) => ((a.hashCode ^ random) % 100).compareTo((b.hashCode ^ random) % 100));
  return shuffled.take(3).map((id) => DailyMission(
    id: id,
    title: DailyMission._titleFor(id),
    description: DailyMission._descFor(id),
    target: DailyMission._targetFor(id),
  )).toList();
}
