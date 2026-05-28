import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/avatar_inventory.dart';

class AvatarInventoryNotifier extends Notifier<AvatarInventory> {
  @override
  AvatarInventory build() {
    _load();
    return const AvatarInventory();
  }

  Future<void> _load() async {
    state = await AvatarInventory.load();
  }

  Future<void> reload() async {
    state = await AvatarInventory.load();
  }

  Future<void> unlockAvatar(String id) async {
    if (state.ownsAvatar(id)) return;
    final updated = state.copyWith(
      ownedAvatarIds: [...state.ownedAvatarIds, id],
    );
    state = updated;
    await AvatarInventory.save(updated);
  }

  Future<void> selectAvatar(String id) async {
    if (!state.ownsAvatar(id)) return;
    final updated = state.copyWith(selectedAvatarId: id);
    state = updated;
    await AvatarInventory.save(updated);
  }

  Future<void> unlockFrame(String id) async {
    if (state.ownsFrame(id)) return;
    final updated = state.copyWith(
      ownedFrameIds: [...state.ownedFrameIds, id],
    );
    state = updated;
    await AvatarInventory.save(updated);
  }

  Future<void> selectFrame(String id) async {
    if (!state.ownsFrame(id)) return;
    final updated = state.copyWith(selectedFrameId: id);
    state = updated;
    await AvatarInventory.save(updated);
  }
}

final avatarInventoryProvider =
    NotifierProvider<AvatarInventoryNotifier, AvatarInventory>(
  AvatarInventoryNotifier.new,
);
