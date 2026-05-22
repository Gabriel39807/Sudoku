import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/background_cosmetic.dart';
import '../models/background_catalog.dart';
import '../application/cosmetic_inventory_provider.dart';
import '../../progression/application/progression_provider.dart';

class CosmeticsScreen extends ConsumerWidget {
  const CosmeticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(cosmeticInventoryProvider);
    final playerLevel = ref.watch(playerLevelProvider);
    final catalog = BackgroundCatalog.all;

    final sorted = catalog.toList()
      ..sort((a, b) {
        final aUnlocked = inventory.isUnlocked(a.id);
        final bUnlocked = inventory.isUnlocked(b.id);
        if (aUnlocked != bUnlocked) return aUnlocked ? -1 : 1;
        return (a.unlockLevel ?? 999).compareTo(b.unlockLevel ?? 999);
      });

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('FONDOS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'FONDOS DESBLOQUEABLES',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sube de nivel para desbloquear nuevos fondos',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final bg = sorted[index];
                final unlocked = inventory.isUnlocked(bg.id);
                final equipped = inventory.equippedBackground == bg.id;

                return _BackgroundCard(
                  background: bg,
                  unlocked: unlocked,
                  equipped: equipped,
                  playerLevel: playerLevel.level,
                  onEquip: unlocked
                      ? () => ref.read(cosmeticInventoryProvider.notifier).equipBackground(bg.id)
                      : null,
                ).animate().fade(
                  delay: (50 * index).ms,
                ).slideY(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
                        Text(
                          'Desbloquea en nivel ${background.unlockLevel ?? 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                          textAlign: TextAlign.center,
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
