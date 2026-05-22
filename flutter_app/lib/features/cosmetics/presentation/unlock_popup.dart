import 'package:flutter/material.dart';
import '../models/background_cosmetic.dart';

class UnlockPopup extends StatefulWidget {
  final BackgroundCosmetic background;

  const UnlockPopup({super.key, required this.background});

  @override
  State<UnlockPopup> createState() => _UnlockPopupState();
}

class _UnlockPopupState extends State<UnlockPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.background;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _controller,
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: _controller,
            curve: Curves.elasticOut,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _rarityColor(bg.rarity).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: _rarityColor(bg.rarity),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'NUEVO FONDO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: _rarityColor(bg.rarity),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DESBLOQUEADO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: _rarityColor(bg.rarity),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Image.asset(bg.assetPath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  bg.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _rarityColor(bg.rarity).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    bg.rarity.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: _rarityColor(bg.rarity),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('GENIAL'),
                  ),
                ),
              ],
            ),
          ),
        ),
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
