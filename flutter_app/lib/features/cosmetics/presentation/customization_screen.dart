import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../application/cosmetics_provider.dart';
import '../shared/cosmetics_board_preview.dart';

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 280,
              height: 280,
              child: CosmeticsBoardPreview(
                theme: cosmetics.selectedTheme,
                frame: cosmetics.selectedFrame,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ThemeGrid(cosmetics: cosmetics),
                _FrameGrid(cosmetics: cosmetics),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeGrid extends ConsumerWidget {
  final CosmeticsState cosmetics;
  const _ThemeGrid({required this.cosmetics});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themes = cosmetics.availableThemes;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isSelected = theme.id == cosmetics.selectedTheme.id;
        return _CosmeticCard(
          label: theme.name,
          rarity: theme.rarity,
          isSelected: isSelected,
          child: Image.asset(theme.backgroundPath, fit: BoxFit.cover),
          onTap: () => ref.read(cosmeticsProvider.notifier).selectTheme(theme.id),
        );
      },
    );
  }
}

class _FrameGrid extends ConsumerWidget {
  final CosmeticsState cosmetics;
  const _FrameGrid({required this.cosmetics});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frames = cosmetics.availableFrames;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              Positioned(
                top: 0, right: 0,
                child: Image.asset(frame.corners.tr, width: 64, height: 64),
              ),
              Positioned(
                bottom: 0, left: 0,
                child: Image.asset(frame.corners.bl, width: 64, height: 64),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Image.asset(frame.corners.br, width: 64, height: 64),
              ),
              Positioned(
                top: 0, left: 64, right: 64,
                child: Image.asset(frame.edges.top, height: 20, fit: BoxFit.fill),
              ),
              Positioned(
                bottom: 0, left: 64, right: 64,
                child: Image.asset(frame.edges.bottom, height: 20, fit: BoxFit.fill),
              ),
              Positioned(
                left: 0, top: 64, bottom: 64,
                child: Image.asset(frame.edges.left, width: 20, fit: BoxFit.fill),
              ),
              Positioned(
                right: 0, top: 64, bottom: 64,
                child: Image.asset(frame.edges.right, width: 20, fit: BoxFit.fill),
              ),
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
