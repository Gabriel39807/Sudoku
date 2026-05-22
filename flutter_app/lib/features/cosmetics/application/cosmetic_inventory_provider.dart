import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cosmetic_inventory.dart';
import '../../progression/application/progression_provider.dart';

class CosmeticInventoryNotifier extends Notifier<CosmeticInventory> {
  @override
  CosmeticInventory build() {
    _loadAndInit();
    return const CosmeticInventory();
  }

  Future<void> _loadAndInit() async {
    state = await CosmeticInventory.load();
    await _ensureDefaults();
  }

  Future<void> _ensureDefaults() async {
    var changed = false;
    final unlocked = [...state.unlockedBackgrounds];
    final equippedId = state.equippedBackground;

    for (final id in CosmeticInventory.defaultUnlockedIds) {
      if (!unlocked.contains(id)) {
        unlocked.add(id);
        changed = true;
      }
    }

    final level = ref.read(playerLevelProvider).level;
    final tempInventory = CosmeticInventory(
      unlockedBackgrounds: unlocked,
      equippedBackground: equippedId,
    );
    final newUnlocks = CosmeticInventory.checkNewUnlocks(tempInventory, level);
    for (final bg in newUnlocks) {
      unlocked.add(bg.id);
      changed = true;
    }

    if (equippedId != null && !unlocked.contains(equippedId)) {
      unlocked.add(equippedId);
      changed = true;
    }

    if (changed) {
      state = state.copyWith(
        unlockedBackgrounds: unlocked,
        equippedBackground: equippedId,
      );
      await CosmeticInventory.save(state);
    }
  }

  Future<void> reload() async {
    state = await CosmeticInventory.load();
    await _ensureDefaults();
  }

  Future<void> unlockBackground(String id) async {
    if (state.isUnlocked(id)) return;
    final updated = state.copyWith(
      unlockedBackgrounds: [...state.unlockedBackgrounds, id],
    );
    state = updated;
    await CosmeticInventory.save(updated);
  }

  Future<void> equipBackground(String id) async {
    if (!state.isUnlocked(id)) return;
    final updated = state.copyWith(equippedBackground: id);
    state = updated;
    await CosmeticInventory.save(updated);
  }

  Future<void> unequipBackground() async {
    final updated = state.copyWith(clearEquipped: true);
    state = updated;
    await CosmeticInventory.save(updated);
  }

  List<String> checkNewUnlocksAtLevel(int level) {
    final newOnes = CosmeticInventory.checkNewUnlocks(state, level);
    for (final bg in newOnes) {
      state = state.copyWith(
        unlockedBackgrounds: [...state.unlockedBackgrounds, bg.id],
      );
    }
    if (newOnes.isNotEmpty) {
      CosmeticInventory.save(state);
    }
    return newOnes.map((bg) => bg.id).toList();
  }
}

final cosmeticInventoryProvider = NotifierProvider<CosmeticInventoryNotifier, CosmeticInventory>(
  CosmeticInventoryNotifier.new,
);
