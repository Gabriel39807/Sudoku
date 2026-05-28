import 'progression_curve.dart';

class PlayerLevel {
  final int level;
  final int currentXp;
  final int totalXp;

  const PlayerLevel({
    this.level = 1,
    this.currentXp = 0,
    this.totalXp = 0,
  });

  int get xpForNext => ProgressionCurve.xpForLevel(level);
  double get progress => xpForNext > 0 ? currentXp / xpForNext : 0.0;
  String get title => ProgressionCurve.titleForLevel(level);
  ProgressionTier get tier => ProgressionCurve.tier(level);

  PlayerLevel copyWith({int? level, int? currentXp, int? totalXp}) =>
      PlayerLevel(
        level: level ?? this.level,
        currentXp: currentXp ?? this.currentXp,
        totalXp: totalXp ?? this.totalXp,
      );

  static PlayerLevel addXp(PlayerLevel current, int xp) {
    var lvl = current.level;
    var curXp = current.currentXp + xp;
    var total = current.totalXp + xp;
    var needed = ProgressionCurve.xpForLevel(lvl);

    while (curXp >= needed) {
      curXp -= needed;
      lvl++;
      needed = ProgressionCurve.xpForLevel(lvl);
    }

    return PlayerLevel(level: lvl, currentXp: curXp, totalXp: total);
  }
}
