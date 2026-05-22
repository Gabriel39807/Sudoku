enum Rarity {
  common,
  rare,
  epic,
  legendary;

  String get label {
    switch (this) {
      case Rarity.common:
        return 'COMUN';
      case Rarity.rare:
        return 'RARO';
      case Rarity.epic:
        return 'EPICO';
      case Rarity.legendary:
        return 'LEGENDARIO';
    }
  }
}

class BackgroundCosmetic {
  final String id;
  final String name;
  final String assetPath;
  final int? unlockLevel;
  final Rarity rarity;

  const BackgroundCosmetic({
    required this.id,
    required this.name,
    required this.assetPath,
    this.unlockLevel,
    this.rarity = Rarity.common,
  });

  bool get isAlwaysUnlocked => unlockLevel == null || unlockLevel! <= 1;
}
