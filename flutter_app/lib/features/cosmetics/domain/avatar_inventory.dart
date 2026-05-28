import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'avatar_def.dart';
import 'avatar_frame_def.dart';

class AvatarInventory {
  static const _ownedAvatarsKey = 'avatar_owned_ids';
  static const _selectedAvatarKey = 'avatar_selected_id';
  static const _ownedFramesKey = 'avatar_frame_owned_ids';
  static const _selectedFrameKey = 'avatar_frame_selected_id';

  final List<String> ownedAvatarIds;
  final String? selectedAvatarId;
  final List<String> ownedFrameIds;
  final String? selectedFrameId;

  const AvatarInventory({
    this.ownedAvatarIds = const [],
    this.selectedAvatarId,
    this.ownedFrameIds = const [],
    this.selectedFrameId,
  });

  bool ownsAvatar(String id) => ownedAvatarIds.contains(id);
  bool ownsFrame(String id) => ownedFrameIds.contains(id);

  AvatarDef? get selectedAvatar =>
      selectedAvatarId != null ? AvatarCatalog.byId(selectedAvatarId!) : null;

  AvatarFrameDef? get selectedFrame =>
      selectedFrameId != null
          ? AvatarFrameCatalog.byId(selectedFrameId!)
          : null;

  AvatarInventory copyWith({
    List<String>? ownedAvatarIds,
    String? selectedAvatarId,
    bool clearSelectedAvatar = false,
    List<String>? ownedFrameIds,
    String? selectedFrameId,
    bool clearSelectedFrame = false,
  }) {
    return AvatarInventory(
      ownedAvatarIds: ownedAvatarIds ?? this.ownedAvatarIds,
      selectedAvatarId:
          clearSelectedAvatar
              ? null
              : selectedAvatarId ?? this.selectedAvatarId,
      ownedFrameIds: ownedFrameIds ?? this.ownedFrameIds,
      selectedFrameId:
          clearSelectedFrame
              ? null
              : selectedFrameId ?? this.selectedFrameId,
    );
  }

  // ── Persistence ─────────────────────────────────────────────────────

  static Future<AvatarInventory> load() async {
    final prefs = await SharedPreferences.getInstance();

    final avatarsRaw = prefs.getString(_ownedAvatarsKey);
    final ownedAvatars = avatarsRaw != null
        ? (jsonDecode(avatarsRaw) as List<dynamic>).cast<String>()
        : <String>[];

    final framesRaw = prefs.getString(_ownedFramesKey);
    final ownedFrames = framesRaw != null
        ? (jsonDecode(framesRaw) as List<dynamic>).cast<String>()
        : <String>[];

    final selectedAvatar = prefs.getString(_selectedAvatarKey);
    final selectedFrame = prefs.getString(_selectedFrameKey);

    var inventory = AvatarInventory(
      ownedAvatarIds: ownedAvatars,
      selectedAvatarId: selectedAvatar,
      ownedFrameIds: ownedFrames,
      selectedFrameId: selectedFrame,
    );

    inventory = await _ensureDefaults(inventory);
    return inventory;
  }

  static Future<AvatarInventory> _ensureDefaults(
    AvatarInventory inventory,
  ) async {
    var changed = false;
    var avatars = [...inventory.ownedAvatarIds];
    var frames = [...inventory.ownedFrameIds];
    var selAvatar = inventory.selectedAvatarId;
    var selFrame = inventory.selectedFrameId;

    // Only give the default avatar and 'none' frame for free
    if (!avatars.contains(AvatarCatalog.defaultId)) {
      avatars.add(AvatarCatalog.defaultId);
      changed = true;
    }
    if (!frames.contains(AvatarFrameCatalog.defaultId)) {
      frames.add(AvatarFrameCatalog.defaultId);
      changed = true;
    }

    if (selAvatar == null || !avatars.contains(selAvatar)) {
      selAvatar = AvatarCatalog.defaultId;
      changed = true;
    }

    if (selFrame == null || !frames.contains(selFrame)) {
      selFrame = AvatarFrameCatalog.defaultId;
      changed = true;
    }

    if (changed) {
      final updated = AvatarInventory(
        ownedAvatarIds: avatars,
        selectedAvatarId: selAvatar,
        ownedFrameIds: frames,
        selectedFrameId: selFrame,
      );
      await save(updated);
      return updated;
    }

    return inventory;
  }

  static Future<void> save(AvatarInventory inventory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ownedAvatarsKey,
      jsonEncode(inventory.ownedAvatarIds),
    );
    await prefs.setString(
      _ownedFramesKey,
      jsonEncode(inventory.ownedFrameIds),
    );
    if (inventory.selectedAvatarId != null) {
      await prefs.setString(
        _selectedAvatarKey,
        inventory.selectedAvatarId!,
      );
    } else {
      await prefs.remove(_selectedAvatarKey);
    }
    if (inventory.selectedFrameId != null) {
      await prefs.setString(
        _selectedFrameKey,
        inventory.selectedFrameId!,
      );
    } else {
      await prefs.remove(_selectedFrameKey);
    }
  }
}
