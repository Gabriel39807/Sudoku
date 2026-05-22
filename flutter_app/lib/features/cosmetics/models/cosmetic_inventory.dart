import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'background_cosmetic.dart';
import 'background_catalog.dart';

class CosmeticInventory {
  static const _unlockedKey = 'cosmetic_unlocked_backgrounds';
  static const _equippedKey = 'cosmetic_equipped_background';

  final List<String> unlockedBackgrounds;
  final String? equippedBackground;

  const CosmeticInventory({
    this.unlockedBackgrounds = const [],
    this.equippedBackground,
  });

  bool isUnlocked(String id) => unlockedBackgrounds.contains(id);

  bool get hasEquipped =>
      equippedBackground != null &&
      unlockedBackgrounds.contains(equippedBackground);

  String? get equippedAssetPath {
    if (!hasEquipped || equippedBackground == null) return null;
    return BackgroundCatalog.byId(equippedBackground!)?.assetPath;
  }

  CosmeticInventory copyWith({
    List<String>? unlockedBackgrounds,
    String? equippedBackground,
    bool clearEquipped = false,
  }) {
    return CosmeticInventory(
      unlockedBackgrounds: unlockedBackgrounds ?? this.unlockedBackgrounds,
      equippedBackground:
          clearEquipped ? null : equippedBackground ?? this.equippedBackground,
    );
  }

  // ── Persistence ─────────────────────────────────────────────────────────

  static Future<CosmeticInventory> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_unlockedKey);
    var unlocked = raw != null
        ? (jsonDecode(raw) as List<dynamic>).cast<String>()
        : <String>[];

    // Migrate old IDs (bg_01…) to new IDs
    bool migrated = false;
    unlocked = unlocked.map((id) {
      final migratedId = BackgroundCatalog.migrateId(id);
      if (migratedId != id) migrated = true;
      return migratedId;
    }).toList();

    var equippedId = prefs.getString(_equippedKey);
    if (equippedId != null) {
      final migratedEquipped = BackgroundCatalog.migrateId(equippedId);
      if (migratedEquipped != equippedId) {
        equippedId = migratedEquipped;
        migrated = true;
      }
    }

    if (migrated) {
      final migratedInventory = CosmeticInventory(
        unlockedBackgrounds: unlocked,
        equippedBackground: equippedId,
      );
      await save(migratedInventory);
    }

    return CosmeticInventory(
      unlockedBackgrounds: unlocked,
      equippedBackground: equippedId,
    );
  }

  static Future<void> save(CosmeticInventory inventory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unlockedKey, jsonEncode(inventory.unlockedBackgrounds));
    if (inventory.equippedBackground != null) {
      await prefs.setString(_equippedKey, inventory.equippedBackground!);
    } else {
      await prefs.remove(_equippedKey);
    }
  }

  // ── Queries ──────────────────────────────────────────────────────────────

  static List<BackgroundCosmetic> getUnlockedBackgrounds(
      CosmeticInventory inventory) {
    final unlocked = inventory.unlockedBackgrounds;
    return BackgroundCatalog.all
        .where((b) => unlocked.contains(b.id))
        .toList();
  }

  static bool canUnlock(CosmeticInventory inventory, int playerLevel) {
    return BackgroundCatalog.all.any(
      (b) =>
          b.unlockLevel != null &&
          b.unlockLevel! <= playerLevel &&
          !inventory.unlockedBackgrounds.contains(b.id),
    );
  }

  static List<BackgroundCosmetic> checkNewUnlocks(
    CosmeticInventory inventory,
    int playerLevel,
  ) {
    return BackgroundCatalog.all.where((b) {
      if (inventory.unlockedBackgrounds.contains(b.id)) return false;
      return b.unlockLevel != null && b.unlockLevel! <= playerLevel;
    }).toList();
  }

  /// IDs that should always be unlocked from the start.
  static const List<String> defaultUnlockedIds = ['ember_forge', 'lava_core'];
}
