import 'background_cosmetic.dart';

class BackgroundCatalog {
  BackgroundCatalog._();

  static final List<BackgroundCosmetic> all = _buildCatalog();

  static BackgroundCosmetic? byId(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  static String get defaultAssetPath => 'assets/cosmetics/backgrounds/default_board.webp';

  static bool hasAssetPath(String path) {
    return all.any((b) => b.assetPath == path);
  }

  /// Map of old IDs (bg_01…bg_11) to new IDs for migration.
  static String migrateId(String oldId) {
    const map = {
      'bg_01': 'ember_forge',
      'bg_02': 'lava_core',
      'bg_03': 'obsidian_flare',
      'bg_04': 'crimson_rift',
      'bg_05': 'shadow_glass',
      'bg_06': 'void_ember',
      'bg_07': 'infernal_crystal',
      'bg_08': 'molten_depths',
      'bg_09': 'abyss_core',
      'bg_10': 'shadow_veil',
      'bg_11': 'pagoda',
    };
    return map[oldId] ?? oldId;
  }

  static const List<_BackgroundEntry> _entries = [
    _BackgroundEntry('ember_forge', 'Ember Forge', 'Bridge.webp', null, Rarity.common),
    _BackgroundEntry('lava_core', 'Lava Core', 'crystal_board.webp', null, Rarity.common),
    _BackgroundEntry('obsidian_flare', 'Obsidian Flare', 'default_board.webp', 2, Rarity.rare),
    _BackgroundEntry('crimson_rift', 'Crimson Rift', 'descarga (1).webp', 4, Rarity.rare),
    _BackgroundEntry('shadow_glass', 'Shadow Glass', 'descarga (2).webp', 6, Rarity.epic),
    _BackgroundEntry('void_ember', 'Void Ember', 'descarga (3).webp', 8, Rarity.epic),
    _BackgroundEntry('infernal_crystal', 'Infernal Crystal', 'Fresh iPad Wallpapers.webp', 10, Rarity.epic),
    _BackgroundEntry('molten_depths', 'Molten Depths', 'Gerhard Richter, 1024 Colours, 1974,Catalogue Raisonn\u00e9_ 353-5,  Enamel on canvas, 299 cm x 299 cm.webp', 15, Rarity.legendary),
    _BackgroundEntry('abyss_core', 'Abyss Core', 'Let it snow.webp', 20, Rarity.legendary),
    _BackgroundEntry('shadow_veil', 'Shadow Veil', 'night_board.webp', 25, Rarity.legendary),
    _BackgroundEntry('pagoda', 'Pagoda', 'Pagoda.webp', 30, Rarity.legendary),
  ];

  static List<BackgroundCosmetic> _buildCatalog() {
    return [
      for (final e in _entries)
        BackgroundCosmetic(
          id: e.id,
          name: e.name,
          assetPath: 'assets/cosmetics/backgrounds/${e.file}',
          unlockLevel: e.unlockLevel,
          rarity: e.rarity,
        ),
    ];
  }
}

class _BackgroundEntry {
  final String id;
  final String name;
  final String file;
  final int? unlockLevel;
  final Rarity rarity;

  const _BackgroundEntry(this.id, this.name, this.file, this.unlockLevel, this.rarity);
}
