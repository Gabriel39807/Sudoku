class DailyStreak {
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastDailyDate;

  const DailyStreak({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastDailyDate,
  });

  DailyStreak copyWith({
    int? currentStreak,
    int? bestStreak,
    DateTime? lastDailyDate,
  }) =>
      DailyStreak(
        currentStreak: currentStreak ?? this.currentStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastDailyDate: lastDailyDate ?? this.lastDailyDate,
      );

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastDailyDate': lastDailyDate?.toIso8601String(),
      };

  factory DailyStreak.fromJson(Map<String, dynamic> json) => DailyStreak(
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        lastDailyDate: json['lastDailyDate'] != null
            ? DateTime.parse(json['lastDailyDate'] as String)
            : null,
      );
}
