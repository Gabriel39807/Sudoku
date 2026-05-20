class PlayerLevel {
  final int level;
  final int currentXp;
  final int totalXp;

  const PlayerLevel({
    this.level = 1,
    this.currentXp = 0,
    this.totalXp = 0,
  });

  int get xpForNext => _xpForLevel(level);
  double get progress => xpForNext > 0 ? currentXp / xpForNext : 0.0;
  String get title => _titleForLevel(level);

  PlayerLevel copyWith({int? level, int? currentXp, int? totalXp}) =>
      PlayerLevel(
        level: level ?? this.level,
        currentXp: currentXp ?? this.currentXp,
        totalXp: totalXp ?? this.totalXp,
      );

  // Tiered XP requirements
  static int _xpForLevel(int lvl) {
    if (lvl >= 76) return 600;
    if (lvl >= 51) return 400;
    if (lvl >= 26) return 250;
    if (lvl >= 11) return 150;
    return 100;
  }

  static String _titleForLevel(int lvl) {
    if (lvl >= 96) return 'Eternal Solver';
    if (lvl >= 86) return 'Mythic';
    if (lvl >= 71) return 'Legend';
    if (lvl >= 56) return 'Grand Master';
    if (lvl >= 41) return 'Master';
    if (lvl >= 31) return 'Strategist';
    if (lvl >= 21) return 'Expert';
    if (lvl >= 11) return 'Solver';
    return 'Beginner';
  }

  static PlayerLevel addXp(PlayerLevel current, int xp) {
    var lvl = current.level;
    var curXp = current.currentXp + xp;
    var total = current.totalXp + xp;
    var needed = _xpForLevel(lvl);

    while (curXp >= needed) {
      curXp -= needed;
      lvl++;
      needed = _xpForLevel(lvl);
    }

    return PlayerLevel(level: lvl, currentXp: curXp, totalXp: total);
  }
}
