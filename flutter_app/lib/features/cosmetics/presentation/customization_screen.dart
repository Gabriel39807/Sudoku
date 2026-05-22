import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../application/cosmetics_provider.dart';
import '../application/cosmetic_inventory_provider.dart';
import '../models/background_cosmetic.dart';
import '../models/background_catalog.dart';
import '../../progression/application/progression_provider.dart';

class CustomizationScreen extends ConsumerStatefulWidget {
  const CustomizationScreen({super.key});

  @override
  ConsumerState<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends ConsumerState<CustomizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cosmetics = ref.watch(cosmeticsProvider);
    final inventory = ref.watch(cosmeticInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Fondos'),
            Tab(text: 'Marcos'),
          ],
        ),
      ),
      body: Column(
        children: [
          _PreviewWidget(
            equipadaPath: inventory.equippedAssetPath,
            frame: cosmetics.selectedFrame,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FondosTab(),
                _FrameGrid(cosmetics: cosmetics),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preview ─────────────────────────────────────────────────────────────────

class _PreviewWidget extends StatelessWidget {
  final String? equipadaPath;
  final dynamic frame;

  const _PreviewWidget({required this.equipadaPath, required this.frame});

  @override
  Widget build(BuildContext context) {
    final bgPath = equipadaPath ?? BackgroundCatalog.defaultAssetPath;
    const ft = 24.0;
    const cs = 32.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 260,
        height: 260,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(bgPath, fit: BoxFit.cover),
              ),
              _FrameOverlay(frame: frame, ft: ft, cs: cs),
            ],
          ),
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
      slivers: [
        if (unlocked.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: _SectionHeader(title: 'DESBLOQUEADOS'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final bg = unlocked[index];
                  final equipped = inventory.equippedBackground == bg.id;
                  return _BackgroundCard(
                    background: bg,
                    unlocked: true,
                    equipped: equipped,
                    playerLevel: playerLevel.level,
                    onEquip: equipped
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
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
              child: _SectionHeader(title: 'POR DESBLOQUEAR'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

// ── Background Card ─────────────────────────────────────────────────────────

class _BackgroundCard extends StatelessWidget {
  final BackgroundCosmetic background;
  final bool unlocked;
  final bool equipped;
  final int playerLevel;
  final VoidCallback? onEquip;

  const _BackgroundCard({
    required this.background,
    required this.unlocked,
    required this.equipped,
    required this.playerLevel,
    this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = equipped
        ? const Color(0xFF7A5FFF)
        : unlocked
            ? _rarityColor(background.rarity).withValues(alpha: 0.4)
            : const Color(0xFF2B2B2B);
    final borderWidth = equipped ? 3.0 : unlocked ? 1.5 : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(background.assetPath, fit: BoxFit.cover),
                if (!unlocked)
                  Container(
                    color: Colors.black54,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, color: Colors.white38, size: 28),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A5FFF),
                        borderRadius: BorderRadius.circular(99),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.black26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  background.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                    const Spacer(),
                    if (unlocked && onEquip != null && !equipped)
                      GestureDetector(
                        onTap: onEquip,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7A5FFF).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'EQUIPAR',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white54),
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

// ── Frame Overlay (preview) ─────────────────────────────────────────────────

class _FrameOverlay extends StatelessWidget {
  final dynamic frame;
  final double ft;
  final double cs;

  const _FrameOverlay({
    required this.frame,
    required this.ft,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: 0, left: ft, right: ft,
              child: Image.asset(frame.edges.top, height: ft, fit: BoxFit.fill)),
          Positioned(bottom: 0, left: ft, right: ft,
              child: Image.asset(frame.edges.bottom, height: ft, fit: BoxFit.fill)),
          Positioned(left: 0, top: ft, bottom: ft,
              child: Image.asset(frame.edges.left, width: ft, fit: BoxFit.fill)),
          Positioned(right: 0, top: ft, bottom: ft,
              child: Image.asset(frame.edges.right, width: ft, fit: BoxFit.fill)),
          Positioned(top: 0, left: 0,
              child: Image.asset(frame.corners.tl, width: cs, height: cs)),
          Positioned(top: 0, right: 0,
              child: Image.asset(frame.corners.tr, width: cs, height: cs)),
          Positioned(bottom: 0, left: 0,
              child: Image.asset(frame.corners.bl, width: cs, height: cs)),
          Positioned(bottom: 0, right: 0,
              child: Image.asset(frame.corners.br, width: cs, height: cs)),
          Positioned(top: 0, left: 0, right: 0,
              child: Center(child: Image.asset(frame.decorations.topCenter, width: ft, height: ft))),
          Positioned(bottom: 0, left: 0, right: 0,
              child: Center(child: Image.asset(frame.decorations.bottomCenter, width: ft, height: ft))),
          Positioned(left: 0, top: 0, bottom: 0,
              child: Center(child: Image.asset(frame.decorations.leftCenter, width: ft, height: ft))),
          Positioned(right: 0, top: 0, bottom: 0,
              child: Center(child: Image.asset(frame.decorations.rightCenter, width: ft, height: ft))),
        ],
      ),
    );
  }
}

// ── Frame Grid (unchanged) ──────────────────────────────────────────────────

class _FrameGrid extends ConsumerWidget {
  final CosmeticsState cosmetics;
  const _FrameGrid({required this.cosmetics});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frames = cosmetics.availableFrames;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: frames.length,
      itemBuilder: (context, index) {
        final frame = frames[index];
        final isSelected = frame.id == cosmetics.selectedFrame.id;
        return _CosmeticCard(
          label: frame.name,
          rarity: frame.rarity,
          isSelected: isSelected,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(frame.corners.tl, fit: BoxFit.contain),
              Positioned(top: 0, right: 0,
                  child: Image.asset(frame.corners.tr, width: 64, height: 64)),
              Positioned(bottom: 0, left: 0,
                  child: Image.asset(frame.corners.bl, width: 64, height: 64)),
              Positioned(bottom: 0, right: 0,
                  child: Image.asset(frame.corners.br, width: 64, height: 64)),
              Positioned(top: 0, left: 64, right: 64,
                  child: Image.asset(frame.edges.top, height: 20, fit: BoxFit.fill)),
              Positioned(bottom: 0, left: 64, right: 64,
                  child: Image.asset(frame.edges.bottom, height: 20, fit: BoxFit.fill)),
              Positioned(left: 0, top: 64, bottom: 64,
                  child: Image.asset(frame.edges.left, width: 20, fit: BoxFit.fill)),
              Positioned(right: 0, top: 64, bottom: 64,
                  child: Image.asset(frame.edges.right, width: 20, fit: BoxFit.fill)),
            ],
          ),
          onTap: () => ref.read(cosmeticsProvider.notifier).selectFrame(frame.id),
        );
      },
    );
  }
}

class _CosmeticCard extends StatelessWidget {
  final String label;
  final String rarity;
  final bool isSelected;
  final Widget child;
  final VoidCallback onTap;

  const _CosmeticCard({
    required this.label,
    required this.rarity,
    required this.isSelected,
    required this.child,
    required this.onTap,
  });

  Color _rarityColor() {
    switch (rarity) {
      case 'rare': return const Color(0xFFD7B45A);
      case 'uncommon': return const Color(0xFF7A5FFF);
      default: return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF7A5FFF) : const Color(0xFF2B2B2B),
            width: isSelected ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: child),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.black26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (rarity != 'common')
                    Text(rarity.toUpperCase(), style: TextStyle(fontSize: 9, color: _rarityColor(), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
