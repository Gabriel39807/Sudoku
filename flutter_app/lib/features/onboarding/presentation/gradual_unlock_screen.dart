import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/onboarding_provider.dart';
import '../../economy/application/wallet_provider.dart';
import '../../cosmetics/application/cosmetic_inventory_provider.dart';

class GradualUnlockScreen extends ConsumerStatefulWidget {
  const GradualUnlockScreen({super.key});

  @override
  ConsumerState<GradualUnlockScreen> createState() => _GradualUnlockScreenState();
}

class _GradualUnlockScreenState extends ConsumerState<GradualUnlockScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _step = 0;

  final _steps = [
    _UnlockItem(
      icon: Icons.star,
      label: 'Nuevos desafíos desbloqueados',
      desc: 'Has completado el tutorial.\nNuevos modos te esperan.',
    ),
    _UnlockItem(
      icon: Icons.calendar_today,
      label: 'Desafío Diario',
      desc: 'Un reto nuevo cada día.\nCompleta todos los días del mes.',
    ),
    _UnlockItem(
      icon: Icons.store,
      label: 'Tienda',
      desc: 'Consigue cosméticos y ventajas\njugando.',
    ),
    _UnlockItem(
      icon: Icons.palette,
      label: 'Personalización',
      desc: 'Haz el juego tuyo.\nFondos, colores y más.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _startUnlocks();
  }

  Future<void> _startUnlocks() async {
    await Future.delayed(800.ms);
    for (var i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() => _step = i + 1);
      if (i == 0) {
        // Unlock daily
        ref.read(onboardingProvider.notifier).unlockDaily();
      } else if (i == 1) {
        ref.read(onboardingProvider.notifier).unlockShop();
      } else if (i == 2) {
        ref.read(onboardingProvider.notifier).unlockCustomization();
      }
      await Future.delayed(1200.ms);
    }
    // Grant rewards
    await ref.read(walletProvider.notifier).addSouls(100);
    await ref.read(walletProvider.notifier).addTokens(25);
    await ref.read(cosmeticInventoryProvider.notifier).unlockBackground('celestial_horizon');
    if (!mounted) return;
    await ref.read(onboardingProvider.notifier).completeTutorial();
    await ref.read(onboardingProvider.notifier).claimRewards();
    setState(() => _step = _steps.length + 1);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A0A2E), Color(0xFF0D0D1A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(flex: 2),
                  if (_step <= _steps.length) ...[
                    // Sequential unlock animation
                    ...List.generate(_step, (i) => _buildItem(i)),
                  ] else ...[
                    // Final celebration
                    _buildFinalRewards(),
                  ],
                  const Spacer(flex: 2),
                  if (_step > _steps.length)
                    _FinishButton(onTap: () => context.go('/')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final item = _steps[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C3FB5).withValues(alpha: 0.25),
              border: Border.all(color: const Color(0xFF9C4DFF).withValues(alpha: 0.5)),
            ),
            child: Icon(item.icon, color: const Color(0xFF9C4DFF), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    )),
                const SizedBox(height: 2),
                Text(item.desc,
                    style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideX(begin: 0.1);
  }

  Widget _buildFinalRewards() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.celebration, size: 56, color: Colors.amber)
            .animate().scale(curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        const Text('¡TUTORIAL COMPLETADO!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white,
            )),
        const SizedBox(height: 8),
        const Text('Has ganado:',
            style: TextStyle(fontSize: 14, color: Colors.white54)),
        const SizedBox(height: 16),
        _RewardRow(icon: Icons.stars, label: '100 Almas', color: Colors.amber),
        const SizedBox(height: 6),
        _RewardRow(icon: Icons.token, label: '25 Fichas', color: Colors.cyan),
        const SizedBox(height: 6),
        _RewardRow(icon: Icons.wallpaper, label: 'Fondo: Horizonte Celestial', color: Colors.purple.shade200),
        const SizedBox(height: 6),
        _RewardRow(icon: Icons.emoji_events, label: 'Insignia: Iniciado', color: Colors.greenAccent),
      ],
    ).animate().fade(duration: 600.ms);
  }
}

class _UnlockItem {
  final IconData icon;
  final String label;
  final String desc;
  const _UnlockItem({
    required this.icon,
    required this.label,
    required this.desc,
  });
}

class _RewardRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RewardRow({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}

class _FinishButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FinishButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C3FB5), Color(0xFF9C4DFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C4DFF).withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(27),
            child: const Center(
              child: Text(
                'IR AL INICIO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
