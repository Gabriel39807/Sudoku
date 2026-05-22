import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../progression/application/progression_provider.dart';
import '../progression/domain/daily_mission.dart';
import '../challenge/application/streak_provider.dart';
import '../../shared/widgets/game_modal_card.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const _TopBar(),
              const Spacer(flex: 2),
              Text(
                'SUDOKU',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
              ).animate().fade(duration: 500.ms).scale(curve: Curves.easeOutBack),
              const SizedBox(height: 8),
              Text(
                'Classic Journey',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.5),
              const Spacer(flex: 2),
              _BigButton('CONTINUAR', () {}),
              const SizedBox(height: 12),
              _BigButton('JUGAR', () => context.push('/difficulty')),
              const SizedBox(height: 12),
              _BigButton('DESAFÍO DIARIO', () => context.push('/daily')),
              const Spacer(flex: 3),
              const _BottomBar(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            _IconButton(
              icon: Icons.assignment,
              onPressed: () => _showMissionsDialog(context, ref),
              tooltip: 'Misiones',
            ),
            const SizedBox(width: 12),
            _IconButton(
              icon: Icons.emoji_events,
              onPressed: () => context.push('/achievements'),
              tooltip: 'Logros',
            ),
            const Spacer(),
            _StreakBadge(streak: streak.currentStreak),
            const SizedBox(width: 8),
            _IconButton(
              icon: Icons.settings,
              onPressed: () => context.push('/settings'),
              tooltip: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMissionsDialog(BuildContext context, WidgetRef ref) async {
    await ref.read(missionsProvider.notifier).reload();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final missions = ref.watch(missionsProvider);

          if (missions.isEmpty) {
            return GameModalCard(
              onClose: () => Navigator.pop(ctx),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 40, color: Colors.white38)
                      .animate().fade().scale(begin: Offset(0, 0)),
                  const SizedBox(height: 16),
                  const Text('No hay misiones hoy',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Vuelve mañana para nuevos desafíos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white54)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CERRAR',
                          style: TextStyle(fontSize: 13, color: Colors.white54)),
                    ),
                  ),
                ],
              ),
            );
          }

          return GameModalCard(
            onClose: () => Navigator.pop(ctx),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('MISIONES DIARIAS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2,
                        color: Theme.of(context).primaryColor))
                    .animate().fade(duration: 300.ms).slideY(begin: -0.2, duration: 300.ms),
                const SizedBox(height: 4),
                const Text('Completa desafíos para ganar XP y futuras recompensas',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.white54))
                    .animate().fade(delay: 100.ms, duration: 300.ms),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: missions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _MissionCard(mission: missions[i])
                        .animate().fade(delay: (150 + i * 100).ms, duration: 300.ms).slideX(begin: i.isEven ? -0.1 : 0.1),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final DailyMission mission;
  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final done = mission.completed;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done
            ? Colors.greenAccent.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? Colors.greenAccent.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: done ? Colors.greenAccent : Colors.white38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(mission.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14,
                        color: done ? Colors.greenAccent : Colors.white)),
              ),
              Text('+${mission.xpReward} XP',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: done ? Colors.greenAccent : Colors.greenAccent.shade200)),
            ],
          ),
          const SizedBox(height: 4),
          Text(mission.description,
              style: const TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${mission.progress} / ${mission.target}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              if (done)
                const Text('COMPLETADO',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                        color: Colors.greenAccent, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: mission.ratio),
              duration: 500.ms,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  done ? Colors.greenAccent : Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Bar ──────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _IconButton(
              icon: Icons.person,
              onPressed: () => context.push('/profile'),
              tooltip: 'Perfil',
            ),
            const SizedBox(width: 12),
            _IconButton(
              icon: Icons.store,
              onPressed: () => context.push('/shop'),
              tooltip: 'Tienda',
            ),
            const SizedBox(width: 12),
            _IconButton(
              icon: Icons.palette,
              onPressed: () => context.push('/customization'),
              tooltip: 'Personalizar',
            ),
            _IconButton(
              icon: Icons.bar_chart,
              onPressed: () => context.push('/stats'),
              tooltip: 'Estadísticas',
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ── Shared Components ───────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _IconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2B2B2B)),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  Color _glowColor() {
    if (streak >= 30) return Colors.orangeAccent;
    if (streak >= 7) return Colors.orange.withValues(alpha: 0.7);
    return Colors.orange.withValues(alpha: 0.4);
  }

  double _glowSize() {
    if (streak >= 30) return 6.0;
    if (streak >= 7) return 3.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();

    final glow = _glowSize();
    final glowColor = _glowColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        boxShadow: glow > 0
            ? [BoxShadow(color: glowColor, blurRadius: glow, spreadRadius: 1)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 16, color: glowColor),
          const SizedBox(width: 4),
          Text(streak.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: glowColor,
              )),
        ],
      ),
    ).animate().fade(duration: 400.ms).then();
  }
}

class _BigButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _BigButton(this.text, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
    );
  }
}
