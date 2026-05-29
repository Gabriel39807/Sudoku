import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/wallet_provider.dart';
import '../domain/wallet.dart';
import '../domain/shop_catalog.dart';
import '../../../features/cosmetics/application/cosmetic_inventory_provider.dart';
import '../../../features/cosmetics/application/avatar_inventory_provider.dart';
import '../../../features/cosmetics/presentation/widgets/player_profile_avatar.dart';
import '../../../features/cosmetics/domain/unlock_reward.dart';
import '../../../shared/widgets/game_modal_card.dart';
import '../../../ui/currency/currency_assets.dart';
import '../../../ui/currency/currency_type.dart';
import '../../../ui/currency/currency_widget.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                _ShopHeader(wallet: wallet),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      _SectionTitle(title: 'FONDOS PREMIUM'),
                      const SizedBox(height: 8),
                      ...ShopCatalog.premiumBackgrounds.map(
                        (item) => _CosmeticCard(
                          item: item,
                          owned: wallet.ownedPremiumCosmetics.contains(item.id),
                          wallet: wallet,
                          onBuy: () => _buyCosmetic(context, ref, item),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(title: 'MARCOS PREMIUM'),
                      const SizedBox(height: 8),
                      ...ShopCatalog.premiumFrames.map(
                        (item) => _CosmeticCard(
                          item: item,
                          owned: wallet.ownedPremiumCosmetics.contains(item.id),
                          wallet: wallet,
                          onBuy: () => _buyCosmetic(context, ref, item),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(title: 'AVATARES'),
                      const SizedBox(height: 8),
                      ...ShopCatalog.premiumAvatars.map(
                        (item) => _AvatarShopCard(
                          item: item,
                          onBuy: () => _buyAvatar(context, ref, item),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(title: 'MARCOS DE AVATAR'),
                      const SizedBox(height: 8),
                      ...ShopCatalog.premiumAvatarFrames.map(
                        (item) => _AvatarFrameShopCard(
                          item: item,
                          onBuy: () => _buyAvatarFrame(context, ref, item),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(title: 'CONSUMIBLES'),
                      const SizedBox(height: 8),
                      ...ShopCatalog.consumables.map(
                        (item) => _ConsumableCard(
                          item: item,
                          wallet: wallet,
                          onBuy: () => _buyConsumable(context, ref, item),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _InventorySection(wallet: wallet),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _buyCosmetic(BuildContext context, WidgetRef ref, ShopCosmetic item) async {
    final notifier = ref.read(walletProvider.notifier);
    final ok = await notifier.buyPremiumCosmetic(item.id, item.gemCost);
    if (!ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes suficientes GEMS')),
      );
      return;
    }
    final inv = ref.read(cosmeticInventoryProvider.notifier);
    if (item.type == 'background') {
      await inv.unlockBackground(item.id);
    }
    if (!context.mounted) return;
    final reward = UnlockReward.fromRarityString(
      id: 'shop_${item.id}',
      type: RewardType.background,
      rarityName: item.rarity,
      title: item.name,
      cosmeticId: item.id,
    );
    final result = await RewardQueue.show(context, reward);
    if (result == 'equip') {
      ref.read(cosmeticInventoryProvider.notifier).equipBackground(item.id);
    } else if (result == 'view') {
      if (!context.mounted) return;
      context.push('/customization', extra: {'initialTab': 2});
    }
  }

  Future<void> _buyAvatar(BuildContext context, WidgetRef ref, ShopAvatar item) async {
    final notifier = ref.read(walletProvider.notifier);
    final ok = await notifier.buyPremiumCosmetic(item.id, item.gemCost);
    if (!ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes suficientes GEMS')),
      );
      return;
    }
    final inv = ref.read(avatarInventoryProvider.notifier);
    await inv.unlockAvatar(item.id);
    await inv.selectAvatar(item.id);
    if (!context.mounted) return;
    final reward = UnlockReward.fromRarityString(
      id: 'shop_${item.id}',
      type: RewardType.avatar,
      rarityName: item.rarity,
      title: item.name,
      cosmeticId: item.id,
    );
    final result = await RewardQueue.show(context, reward);
    if (result == 'view') {
      if (!context.mounted) return;
      context.push('/customization', extra: {'initialTab': 0});
    }
  }

  Future<void> _buyAvatarFrame(BuildContext context, WidgetRef ref, ShopAvatar item) async {
    final notifier = ref.read(walletProvider.notifier);
    final ok = await notifier.buyPremiumCosmetic(item.id, item.gemCost);
    if (!ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes suficientes GEMS')),
      );
      return;
    }
    final inv = ref.read(avatarInventoryProvider.notifier);
    await inv.unlockFrame(item.id);
    await inv.selectFrame(item.id);
    if (!context.mounted) return;
    final reward = UnlockReward.fromRarityString(
      id: 'shop_${item.id}',
      type: RewardType.frame,
      rarityName: item.rarity,
      title: item.name,
      cosmeticId: item.id,
    );
    final result = await RewardQueue.show(context, reward);
    if (result == 'view') {
      if (!context.mounted) return;
      context.push('/customization', extra: {'initialTab': 1});
    }
  }

  Future<void> _buyConsumable(BuildContext context, WidgetRef ref, ShopConsumable item) async {
    final wallet = ref.read(walletProvider);
    if (item.id.startsWith('hint') && wallet.hintConsumables >= Wallet.maxHints) {
      _showInventoryFullDialog(context, 'Pistas', wallet.hintConsumables, Wallet.maxHints);
      return;
    }
    if (item.id.startsWith('adv_note') && wallet.advancedNoteConsumables >= Wallet.maxAdvancedNotes) {
      _showInventoryFullDialog(context, 'Notas Avanzadas', wallet.advancedNoteConsumables, Wallet.maxAdvancedNotes);
      return;
    }

    final notifier = ref.read(walletProvider.notifier);
    final ok = await notifier.spendTokens(item.tokenCost);
    if (!ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes suficientes TOKENS')),
      );
      return;
    }
    if (item.id.startsWith('hint')) {
      await notifier.addHints(item.quantity);
    } else if (item.id.startsWith('adv_note')) {
      await notifier.addAdvancedNotes(item.quantity);
    }
  }

  void _showInventoryFullDialog(BuildContext context, String name, int current, int max) {
    showDialog(
      context: context,
      builder: (ctx) => GameModalCard(
        onClose: () => Navigator.pop(ctx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(current >= max ? 'INVENTARIO LLENO' : 'USOS COMPLETOS',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Ya tienes el máximo de $name',
                style: const TextStyle(fontSize: 13, color: Colors.white54)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$current / $max',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ACEPTAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  final Wallet wallet;
  const _ShopHeader({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 4),
              Text('TIENDA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Theme.of(context).primaryColor,
                  )),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CurrencyWidget(type: CurrencyType.gems, amount: wallet.gems, size: 18, showLabel: true),
              const SizedBox(width: 24),
              CurrencyWidget(type: CurrencyType.tokens, amount: wallet.tokens, size: 18, showLabel: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white54,
          letterSpacing: 2,
        )).animate().fade(duration: 300.ms);
  }
}

class _CosmeticCard extends StatelessWidget {
  final ShopCosmetic item;
  final bool owned;
  final Wallet wallet;
  final VoidCallback onBuy;

  const _CosmeticCard({
    required this.item,
    required this.owned,
    required this.wallet,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = wallet.gems >= item.gemCost;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: owned ? 0.03 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: owned
              ? Colors.greenAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.image_outlined, size: 24, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _rarityChip(item.rarity),
                    const SizedBox(width: 8),
                    Text(item.type == 'background' ? 'Fondo' : 'Marco',
                        style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),
          if (owned)
            const Text('PROPIEDAD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ))
          else
            _PriceButton(
              icon: CurrencyAssets.iconFor(CurrencyType.gems),
              iconColor: CurrencyAssets.colorFor(CurrencyType.gems),
              price: item.gemCost,
              canAfford: canAfford,
              onTap: onBuy,
            ),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: 0.05);
  }

  Widget _rarityChip(String rarity) {
    final color = switch (rarity) {
      'rare' => Colors.blueAccent,
      'epic' => const Color(0xFF9B59B6),
      'legendary' => Colors.orangeAccent,
      _ => Colors.white54,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(rarity.toUpperCase(),
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _ConsumableCard extends StatelessWidget {
  final ShopConsumable item;
  final Wallet wallet;
  final VoidCallback onBuy;

  const _ConsumableCard({
    required this.item,
    required this.wallet,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = wallet.tokens >= item.tokenCost;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3498DB).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 24, color: Color(0xFF3498DB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(item.description,
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
          _PriceButton(
            icon: CurrencyAssets.iconFor(CurrencyType.tokens),
            iconColor: CurrencyAssets.colorFor(CurrencyType.tokens),
            price: item.tokenCost,
            canAfford: canAfford,
            onTap: onBuy,
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: 0.05);
  }
}

class _InventorySection extends StatelessWidget {
  final Wallet wallet;
  const _InventorySection({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'INVENTARIO'),
        const SizedBox(height: 8),
        _InventoryRow(
          label: 'Pistas',
          current: wallet.hintConsumables,
          max: Wallet.maxHints,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 12),
        _InventoryRow(
          label: 'Notas Avanzadas',
          current: wallet.advancedNoteConsumables,
          max: Wallet.maxAdvancedNotes,
          color: const Color(0xFF3498DB),
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }
}

class _InventoryRow extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;

  const _InventoryRow({
    required this.label,
    required this.current,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? current / max : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Text('$current / $max',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: 500.ms,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarShopCard extends ConsumerWidget {
  final ShopAvatar item;
  final VoidCallback onBuy;
  const _AvatarShopCard({required this.item, required this.onBuy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final owned = wallet.ownedPremiumCosmetics.contains(item.id);
    final canAfford = wallet.gems >= item.gemCost;
    final rarityColor = _avatarRarityColor(item.rarity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: owned ? 0.03 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: owned
              ? Colors.greenAccent.withValues(alpha: 0.2)
              : rarityColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          PlayerProfileAvatar(
            avatarId: item.id,
            frameId: null,
            size: 48,
            showBreathing: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _avatarRarityChip(item.rarity, rarityColor),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
          if (owned)
            const Text('PROPIEDAD',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent))
          else
            _PriceButton(
              icon: CurrencyAssets.iconFor(CurrencyType.gems),
              iconColor: CurrencyAssets.colorFor(CurrencyType.gems),
              price: item.gemCost,
              canAfford: canAfford,
              onTap: onBuy,
            ),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: 0.05);
  }

  Color _avatarRarityColor(String rarity) {
    switch (rarity) {
      case 'rare': return const Color(0xFF3498DB);
      case 'epic': return const Color(0xFF9B59B6);
      case 'legendary': return const Color(0xFFFF6B35);
      case 'mythic': return const Color(0xFFE91E63);
      default: return Colors.white54;
    }
  }

  Widget _avatarRarityChip(String rarity, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(rarity.toUpperCase(),
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _AvatarFrameShopCard extends ConsumerWidget {
  final ShopAvatar item;
  final VoidCallback onBuy;
  const _AvatarFrameShopCard({required this.item, required this.onBuy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final owned = wallet.ownedPremiumCosmetics.contains(item.id);
    final canAfford = wallet.gems >= item.gemCost;
    final rarityColor = _avatarRarityColor(item.rarity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: owned ? 0.03 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: owned
              ? Colors.greenAccent.withValues(alpha: 0.2)
              : rarityColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          PlayerProfileAvatar(
            avatarId: null,
            frameId: item.id,
            size: 48,
            showBreathing: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                _avatarRarityChip(item.rarity, rarityColor),
              ],
            ),
          ),
          if (owned)
            const Text('PROPIEDAD',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent))
          else
            _PriceButton(
              icon: CurrencyAssets.iconFor(CurrencyType.gems),
              iconColor: CurrencyAssets.colorFor(CurrencyType.gems),
              price: item.gemCost,
              canAfford: canAfford,
              onTap: onBuy,
            ),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: 0.05);
  }

  Color _avatarRarityColor(String rarity) {
    switch (rarity) {
      case 'rare': return const Color(0xFF3498DB);
      case 'epic': return const Color(0xFF9B59B6);
      case 'legendary': return const Color(0xFFFF6B35);
      case 'mythic': return const Color(0xFFE91E63);
      default: return Colors.white54;
    }
  }

  Widget _avatarRarityChip(String rarity, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(rarity.toUpperCase(),
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _PriceButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int price;
  final bool canAfford;
  final VoidCallback onTap;

  const _PriceButton({
    required this.icon,
    required this.iconColor,
    required this.price,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: canAfford ? iconColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: canAfford
                ? iconColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: canAfford ? iconColor : Colors.white24),
            const SizedBox(width: 4),
            Text(price.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: canAfford ? iconColor : Colors.white24,
                )),
          ],
        ),
      ),
    );
  }
}
