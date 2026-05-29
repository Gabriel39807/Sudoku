import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/cosmetics_provider.dart';
import '../application/cosmetic_inventory_provider.dart';
import '../application/avatar_inventory_provider.dart';
import '../domain/avatar_def.dart';
import '../domain/avatar_frame_def.dart';
import '../domain/avatar_inventory.dart';
import '../models/background_cosmetic.dart';
import '../models/background_catalog.dart';
import '../../progression/application/progression_provider.dart';
import '../../../core/theme/theme_palette.dart';
import '../../customization/application/customization_provider.dart';
import '../../customization/domain/game_background_theme.dart';
import 'widgets/player_profile_avatar.dart';

class CustomizationScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const CustomizationScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<CustomizationScreen> createState() =>
      _CustomizationScreenState();
}

class _CustomizationScreenState extends ConsumerState<CustomizationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarInv = ref.watch(avatarInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('PERSONALIZAR',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Avatares'),
            Tab(text: 'Marcos'),
            Tab(text: 'Fondos'),
            Tab(text: 'Temas'),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                SizedBox(
                  height: 140,
                  child: _AvatarPreviewWidget(
                    avatarId: avatarInv.selectedAvatarId,
                    frameId: avatarInv.selectedFrameId,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _AvatarsTab(),
                      _AvatarFramesTab(),
                      _FondosTab(),
                      _TemasTab(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Avatar Preview ──────────────────────────────────────────────────────────

class _AvatarPreviewWidget extends StatelessWidget {
  final String? avatarId;
  final String? frameId;

  const _AvatarPreviewWidget({
    required this.avatarId,
    required this.frameId,
  });

  @override
  Widget build(BuildContext context) {
    final avatar =
        avatarId != null ? AvatarCatalog.byId(avatarId!) : null;
    final frame =
        frameId != null ? AvatarFrameCatalog.byId(frameId!) : null;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 24),
          PlayerProfileAvatar(
            avatarId: avatarId,
            frameId: frameId,
            size: 80,
            showBreathing: true,
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (avatar != null)
                Text(
                  avatar.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              if (avatar != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: avatar.rarity.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: avatar.rarity.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    avatar.rarity.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: avatar.rarity.color,
                    ),
                  ),
                ),
              if (frame != null && frame.id != 'none')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: frame.rarity.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        frame.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: frame.rarity.color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

// ── Avatars Tab ─────────────────────────────────────────────────────────────

class _AvatarsTab extends ConsumerWidget {
  const _AvatarsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(avatarInventoryProvider);
    final notifier = ref.read(avatarInventoryProvider.notifier);
    final catalog = AvatarCatalog.all;

    final common =
        catalog.where((a) => a.rarity == AvatarRarity.common).toList();
    final rare = catalog.where((a) => a.rarity == AvatarRarity.rare).toList();
    final epic = catalog.where((a) => a.rarity == AvatarRarity.epic).toList();
    final legendary =
        catalog.where((a) => a.rarity == AvatarRarity.legendary).toList();
    final mythic =
        catalog.where((a) => a.rarity == AvatarRarity.mythic).toList();

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        _AvatarSection(
          title: 'COMUNES',
          avatars: common,
          inv: inv,
          notifier: notifier,
        ),
        _AvatarSection(
          title: 'RAROS',
          avatars: rare,
          inv: inv,
          notifier: notifier,
        ),
        _AvatarSection(
          title: 'ÉPICOS',
          avatars: epic,
          inv: inv,
          notifier: notifier,
        ),
        _AvatarSection(
          title: 'LEGENDARIOS',
          avatars: legendary,
          inv: inv,
          notifier: notifier,
        ),
        _AvatarSection(
          title: 'MÍTICOS',
          avatars: mythic,
          inv: inv,
          notifier: notifier,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final String title;
  final List<AvatarDef> avatars;
  final AvatarInventory inv;
  final AvatarInventoryNotifier notifier;

  const _AvatarSection({
    required this.title,
    required this.avatars,
    required this.inv,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: _SectionHeader(title: title),
          ),
          SizedBox(
            height: 88,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final avatar = avatars[index];
                final owned = inv.ownsAvatar(avatar.id);
                final selected = inv.selectedAvatarId == avatar.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _AvatarItem(
                    avatar: avatar,
                    owned: owned,
                    selected: selected,
                    onTap: owned
                        ? () => notifier.selectAvatar(avatar.id)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarItem extends StatelessWidget {
  final AvatarDef avatar;
  final bool owned;
  final bool selected;
  final VoidCallback? onTap;

  const _AvatarItem({
    required this.avatar,
    required this.owned,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = avatar.rarity.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        width: 76,
        decoration: BoxDecoration(
          color: selected
              ? rarityColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? rarityColor
                : owned
                    ? rarityColor.withValues(alpha: 0.3)
                    : Colors.white12,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: avatar.rarity.glowColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: PlayerProfileAvatar(
                avatarId: avatar.id,
                frameId: null,
                size: 32,
                showGlow: false,
                showBreathing: false,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              avatar.name,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: selected
                    ? rarityColor
                    : owned
                        ? Colors.white70
                        : Colors.white38,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            if (selected)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '✓',
                  style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: rarityColor),
                ),
              )
            else if (!owned)
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child:
                    Icon(Icons.lock, size: 8, color: Colors.white24),
              )
            else
              const SizedBox(height: 11),
          ],
        ),
      ),
    );
  }
}

// ── Avatar Frames Tab ──────────────────────────────────────────────────────

class _AvatarFramesTab extends ConsumerWidget {
  const _AvatarFramesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(avatarInventoryProvider);
    final notifier = ref.read(avatarInventoryProvider.notifier);
    final frames = AvatarFrameCatalog.all
        .where((f) => f.id != 'none')
        .toList();

    final common =
        frames.where((f) => f.rarity == AvatarRarity.common).toList();
    final rare =
        frames.where((f) => f.rarity == AvatarRarity.rare).toList();
    final epic =
        frames.where((f) => f.rarity == AvatarRarity.epic).toList();
    final legendary =
        frames.where((f) => f.rarity == AvatarRarity.legendary).toList();
    final mythic =
        frames.where((f) => f.rarity == AvatarRarity.mythic).toList();

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        _FrameSection(
          title: 'COMUNES',
          frames: common,
          inv: inv,
          notifier: notifier,
        ),
        _FrameSection(
          title: 'RAROS',
          frames: rare,
          inv: inv,
          notifier: notifier,
        ),
        _FrameSection(
          title: 'ÉPICOS',
          frames: epic,
          inv: inv,
          notifier: notifier,
        ),
        _FrameSection(
          title: 'LEGENDARIOS',
          frames: legendary,
          inv: inv,
          notifier: notifier,
        ),
        _FrameSection(
          title: 'MÍTICOS',
          frames: mythic,
          inv: inv,
          notifier: notifier,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _FrameSection extends StatelessWidget {
  final String title;
  final List<AvatarFrameDef> frames;
  final AvatarInventory inv;
  final AvatarInventoryNotifier notifier;

  const _FrameSection({
    required this.title,
    required this.frames,
    required this.inv,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    if (frames.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: _SectionHeader(title: title),
          ),
          SizedBox(
            height: 88,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: frames.length,
              itemBuilder: (context, index) {
                final frame = frames[index];
                final owned = inv.ownsFrame(frame.id);
                final selected = inv.selectedFrameId == frame.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _FrameItem(
                    frame: frame,
                    owned: owned,
                    selected: selected,
                    onTap: owned
                        ? () => notifier.selectFrame(frame.id)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FrameItem extends StatelessWidget {
  final AvatarFrameDef frame;
  final bool owned;
  final bool selected;
  final VoidCallback? onTap;

  const _FrameItem({
    required this.frame,
    required this.owned,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = frame.rarity.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        width: 76,
        decoration: BoxDecoration(
          color: selected
              ? rarityColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? rarityColor
                : owned
                    ? rarityColor.withValues(alpha: 0.3)
                    : Colors.white12,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: frame.rarity.glowColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: PlayerProfileAvatar(
                avatarId: null,
                frameId: frame.id,
                size: 32,
                showGlow: false,
                showBreathing: false,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              frame.name,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: selected
                    ? rarityColor
                    : owned
                        ? Colors.white70
                        : Colors.white38,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            if (selected)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '✓',
                  style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: rarityColor),
                ),
              )
            else if (!owned)
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child:
                    Icon(Icons.lock, size: 8, color: Colors.white24),
              )
            else
              const SizedBox(height: 11),
          ],
        ),
      ),
    );
  }
}

// ── Fondos Tab ──────────────────────────────────────────────────────────────

class _FondosTab extends ConsumerWidget {
  const _FondosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(cosmeticInventoryProvider);
    final playerLevel = ref.watch(playerLevelProvider);
    final catalog = BackgroundCatalog.all;

    final unlocked = catalog
        .where((bg) => inventory.isUnlocked(bg.id))
        .toList()
      ..sort((a, b) {
        if (inventory.equippedBackground == a.id) return -1;
        if (inventory.equippedBackground == b.id) return 1;
        return 0;
      });

    final locked = catalog
        .where((bg) => !inventory.isUnlocked(bg.id))
        .toList()
      ..sort((a, b) =>
          (a.unlockLevel ?? 999).compareTo(b.unlockLevel ?? 999));

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        if (unlocked.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _SectionHeader(title: 'DESBLOQUEADOS'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final bg = unlocked[index];
                  final equipped =
                      inventory.equippedBackground == bg.id;
                  return _BackgroundCard(
                    background: bg,
                    unlocked: true,
                    equipped: equipped,
                    playerLevel: playerLevel.level,
                    onTap: equipped
                        ? null
                        : () => ref
                            .read(cosmeticInventoryProvider.notifier)
                            .equipBackground(bg.id),
                  );
                },
                childCount: unlocked.length,
              ),
            ),
          ),
        ],
        if (locked.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: _SectionHeader(title: 'POR DESBLOQUEAR'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(
                left: 16, right: 16, bottom: 24),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final bg = locked[index];
                  return _BackgroundCard(
                    background: bg,
                    unlocked: false,
                    equipped: false,
                    playerLevel: playerLevel.level,
                    onTap: () {
                      final msg = bg.unlockLevel != null
                          ? 'Se desbloquea en nivel ${bg.unlockLevel}'
                          : 'Próximamente disponible';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg,
                              textAlign: TextAlign.center),
                          behavior: SnackBarBehavior.floating,
                          duration: 2.seconds,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 80),
                        ),
                      );
                    },
                  );
                },
                childCount: locked.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

class _BackgroundCard extends StatelessWidget {
  final BackgroundCosmetic background;
  final bool unlocked;
  final bool equipped;
  final int playerLevel;
  final VoidCallback? onTap;

  const _BackgroundCard({
    required this.background,
    required this.unlocked,
    required this.equipped,
    required this.playerLevel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = equipped
        ? const Color(0xFF7A5FFF)
        : unlocked
            ? _rarityColor(background.rarity).withValues(alpha: 0.4)
            : const Color(0xFF2B2B2B);
    final borderWidth = equipped ? 3.0 : unlocked ? 1.5 : 1.0;
    final tapEnabled = !equipped && onTap != null;
    final isLocked = !unlocked;

    return GestureDetector(
      onTap: tapEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ??
              const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: borderColor, width: borderWidth),
          boxShadow: equipped
              ? [
                  BoxShadow(
                      color: const Color(0xFF7A5FFF)
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1)
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(background.assetPath,
                      fit: BoxFit.cover),
                  if (isLocked)
                    Container(
                      color: Colors.black54,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock,
                              color: Colors.white38, size: 28),
                          const SizedBox(height: 6),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Nivel ${background.unlockLevel ?? 1}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          if (_showProgress) ...[
                            const SizedBox(height: 6),
                            _progressBar(),
                          ],
                        ],
                      ),
                    ),
                  if (equipped)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A5FFF),
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7A5FFF)
                                  .withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Text(
                          'ACTIVO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8),
              color: Colors.black26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    background.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        background.rarity.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: _rarityColor(background.rarity),
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 6),
                        Text(
                          'TOCA PARA MÁS INFO',
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.white.withValues(alpha: 0.3),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _showProgress {
    if (unlocked) return false;
    final level = background.unlockLevel;
    if (level == null) return false;
    if (playerLevel >= level) return false;
    return playerLevel >= level - 3;
  }

  Widget _progressBar() {
    final level = background.unlockLevel!;
    final progress = playerLevel / level;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$playerLevel / $level',
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Color _rarityColor(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return Colors.white54;
      case Rarity.rare:
        return const Color(0xFF3498DB);
      case Rarity.epic:
        return const Color(0xFF9B59B6);
      case Rarity.legendary:
        return const Color(0xFFFF6B35);
    }
  }
}

// ── Temas Tab ────────────────────────────────────────────────────────────

class _TemasTab extends ConsumerWidget {
  const _TemasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(customizationProvider);
    final cosmetics = ref.watch(cosmeticsProvider);

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _SectionHeader(title: 'PALETAS DE COLOR'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final palette = AppPalette.all[index];
                final selected = customization.palette == palette;
                return _PaletteCard(
                    palette: palette, selected: selected);
              },
              childCount: AppPalette.all.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: _SectionHeader(title: 'FONDOS GLOBALES'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final bg = GameBackgroundTheme.values[index];
                final selected = customization.background == bg;
                return _GlobalBgCard(
                    background: bg, selected: selected);
              },
              childCount: GameBackgroundTheme.values.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: _SectionHeader(title: 'MARCOS DE TABLERO'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final frame = cosmetics.availableFrames[index];
                final isSelected =
                    frame.id == cosmetics.selectedFrame.id;
                return _FrameCard(
                  frame: frame,
                  isSelected: isSelected,
                  onTap: () => ref
                      .read(cosmeticsProvider.notifier)
                      .selectFrame(frame.id),
                );
              },
              childCount: cosmetics.availableFrames.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _FrameCard extends StatelessWidget {
  final dynamic frame;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrameCard({
    required this.frame,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ??
              const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7A5FFF)
                : const Color(0xFF2B2B2B),
            width: isSelected ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.asset(frame.corners.tl,
                      fit: BoxFit.contain),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              color: Colors.black26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(frame.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  if (frame.rarity != 'common')
                    Text(
                      frame.rarity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: _frameRarityColor(frame.rarity),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _frameRarityColor(String rarity) {
    switch (rarity) {
      case 'rare':
        return const Color(0xFFD7B45A);
      case 'uncommon':
        return const Color(0xFF7A5FFF);
      default:
        return Colors.white54;
    }
  }
}

class _PaletteCard extends ConsumerWidget {
  final AppPalette palette;
  final bool selected;

  const _PaletteCard({required this.palette, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () =>
          ref.read(customizationProvider.notifier).setPalette(palette),
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? palette.accent
                : palette.primary.withValues(alpha: 0.2),
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: palette.glow.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2)
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Swatch(color: palette.primary),
                const SizedBox(width: 6),
                _Swatch(color: palette.secondary),
                const SizedBox(width: 6),
                _Swatch(color: palette.accent),
              ],
            ),
            const SizedBox(height: 12),
            Text(palette.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: selected ? palette.accent : Colors.white70,
                )),
            if (selected) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                      color: palette.accent.withValues(alpha: 0.3)),
                ),
                child: Text('ACTIVA',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: palette.accent)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  const _Swatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
    );
  }
}

class _GlobalBgCard extends ConsumerWidget {
  final GameBackgroundTheme background;
  final bool selected;

  const _GlobalBgCard(
      {required this.background, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref
          .read(customizationProvider.notifier)
          .setBackground(background),
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 2)
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: background.gradientColors,
                  ),
                ),
                child: selected
                    ? const Center(
                        child: Icon(Icons.check,
                            color: Colors.white, size: 32))
                    : null,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              color: Colors.black26,
              child: Text(
                background.label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
