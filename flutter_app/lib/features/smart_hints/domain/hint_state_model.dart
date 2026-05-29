import 'hint_type.dart';

class HintState {
  final Set<HintType> seen;
  final Set<HintType> learned;
  final Map<String, int> lastShownTimestamps;

  const HintState({
    this.seen = const {},
    this.learned = const {},
    this.lastShownTimestamps = const {},
  });

  bool hasSeen(HintType type) => seen.contains(type);
  bool hasLearned(HintType type) => learned.contains(type);

  HintState markSeen(HintType type) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return copyWith(
      seen: {...seen, type},
      lastShownTimestamps: {...lastShownTimestamps, type.name: now},
    );
  }

  HintState markLearned(HintType type) {
    return copyWith(
      seen: {...seen, type},
      learned: {...learned, type},
    );
  }

  HintState copyWith({
    Set<HintType>? seen,
    Set<HintType>? learned,
    Map<String, int>? lastShownTimestamps,
  }) {
    return HintState(
      seen: seen ?? this.seen,
      learned: learned ?? this.learned,
      lastShownTimestamps: lastShownTimestamps ?? this.lastShownTimestamps,
    );
  }

  Map<String, dynamic> toJson() => {
    'seen': seen.map((e) => e.name).toList(),
    'learned': learned.map((e) => e.name).toList(),
    'lastShown': lastShownTimestamps,
  };

  factory HintState.fromJson(Map<String, dynamic> json) {
    final seenList = (json['seen'] as List<dynamic>?)
        ?.map((e) => HintType.values.firstWhere(
          (h) => h.name == e,
          orElse: () => HintType.erase,
        ))
        .toSet() ?? {};
    final learnedList = (json['learned'] as List<dynamic>?)
        ?.map((e) => HintType.values.firstWhere(
          (h) => h.name == e,
          orElse: () => HintType.erase,
        ))
        .toSet() ?? {};
    final timestamps = (json['lastShown'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v as int)) ?? {};
    return HintState(
      seen: seenList,
      learned: learnedList,
      lastShownTimestamps: timestamps,
    );
  }
}