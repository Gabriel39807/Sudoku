enum RewardType { background, frame, roulette, palette }

class LevelReward {
  final int level;
  final RewardType type;
  final String id;
  final String name;
  final String description;

  const LevelReward({
    required this.level,
    required this.type,
    required this.id,
    required this.name,
    required this.description,
  });

  String get typeLabel {
    return switch (type) {
      RewardType.background => 'Fondo',
      RewardType.frame => 'Marco',
      RewardType.roulette => 'Ruleta',
      RewardType.palette => 'Paleta',
    };
  }
}

class LevelRewardRegistry {
  LevelRewardRegistry._();

  static final List<LevelReward> _rewards = [
    const LevelReward(
      level: 3, type: RewardType.background,
      id: 'reward_lvl3_bg', name: 'Fondo Secreto',
      description: 'Desbloqueaste un fondo misterioso',
    ),
    const LevelReward(
      level: 5, type: RewardType.frame,
      id: 'reward_lvl5_frame', name: 'Marco Básico',
      description: 'Marco decorativo para tu perfil',
    ),
    const LevelReward(
      level: 8, type: RewardType.roulette,
      id: 'reward_lvl8_wheel', name: 'Ruleta Arcana',
      description: 'Nuevo diseño para la ruleta',
    ),
    const LevelReward(
      level: 10, type: RewardType.palette,
      id: 'reward_lvl10_palette', name: 'Paleta Nocturna',
      description: 'Esquema de colores alternativo',
    ),
    const LevelReward(
      level: 15, type: RewardType.background,
      id: 'reward_lvl15_bg', name: 'Fundo Abisal',
      description: 'Un fondo de rareza legendaria',
    ),
    const LevelReward(
      level: 20, type: RewardType.frame,
      id: 'reward_lvl20_frame', name: 'Marco Legendario',
      description: 'Un marco de rareza legendaria',
    ),
    const LevelReward(
      level: 25, type: RewardType.palette,
      id: 'reward_lvl25_palette', name: 'Paleta Premium',
      description: 'Esquema de colores premium',
    ),
    const LevelReward(
      level: 30, type: RewardType.background,
      id: 'reward_lvl30_bg', name: 'Fondo Épico Supremo',
      description: 'El fondo más exclusivo del juego',
    ),
    const LevelReward(
      level: 35, type: RewardType.roulette,
      id: 'reward_lvl35_wheel', name: 'Ruleta Épica',
      description: 'Diseño épico para la ruleta',
    ),
    const LevelReward(
      level: 40, type: RewardType.frame,
      id: 'reward_lvl40_frame', name: 'Marco Épico',
      description: 'Marco de rareza épica',
    ),
    const LevelReward(
      level: 50, type: RewardType.palette,
      id: 'reward_lvl50_palette', name: 'Paleta Mítica',
      description: 'Esquema de colores mítico',
    ),
  ];

  static List<LevelReward> unlockedAt(int level) {
    return _rewards.where((r) => r.level == level).toList();
  }

  static List<LevelReward> checkNewUnlocks(int newLevel, Set<String> alreadyUnlocked) {
    return _rewards.where((r) => r.level <= newLevel && !alreadyUnlocked.contains(r.id)).toList();
  }

  static List<LevelReward> get all => List.unmodifiable(_rewards);
}
