import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../economy/application/wallet_provider.dart';
import '../progression/application/progression_provider.dart';
import '../progression/domain/daily_mission.dart';
import '../challenge/application/streak_provider.dart';
import '../../shared/widgets/game_modal_card.dart';
import '../../ui/currency/currency_widget.dart';
import '../../ui/currency/currency_type.dart';
import '../../features/wheel/presentation/roulette_modal.dart';
import '../campaign/application/campaign_provider.dart';
import '../campaign/domain/campaign_level.dart';

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
              const _EconomyHeader(),
              const SizedBox(height: 4),
              const _CircularNav(),
              const Spacer(flex: 1),
              const _TitleSection(),
              const Spacer(flex: 1),
              _BigButton('CONTINUAR', () {}),
              const SizedBox(height: 10),
              _BigButton('JUGAR', () => context.push('/difficulty')),
              const SizedBox(height: 10),
              Consumer(
                builder: (context, ref, _) {
                  final progress = ref.watch(campaignProvider);
                  if (progress.hasActiveRun) {
                    return _CampaignContinueButton(
                      level: progress.activeRunLevel,
                      stage: CampaignStage.fromLevel(progress.activeRunLevel),
                      onTap: () {
                        final stage = CampaignStage.fromLevel(progress.activeRunLevel);
                        context.push('/campaign-game', extra: {'level': progress.activeRunLevel, 'variant': stage.variant.name});
                      },
                    );
                  }
                  return _CampaignButton(onTap: () => context.push('/campaign'));
                },
              ),
              const SizedBox(height: 10),
              _BigButton('DESAFÍO DIARIO', () => context.push('/daily')),
              const SizedBox(height: 12),
              _LuckyWheelButton(onTap: () => showRouletteModal(context)),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignButton extends ConsumerWidget {
  final VoidCallback onTap;
  const _CampaignButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(campaignProvider);
    return SizedBox(
      width: 240,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.flag, size: 16),
        label: Text('CAMPAÑA  ·  ${progress.completedCount}/${progress.totalCount}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

class _CampaignContinueButton extends ConsumerWidget {
  final int level;
  final CampaignStage stage;
  final VoidCallback onTap;
  const _CampaignContinueButton({
    required this.level,
    required this.stage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 240,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.play_arrow, size: 20),
        label: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('CONTINUAR  ·  NIVEL $level',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.black87,
                )),
            Text('${stage.variant.boardSize}x${stage.variant.boardSize}',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.black87.withValues(alpha: 0.6),
                )),
          ],
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.amber.shade400,
          foregroundColor: Colors.black87,
          elevation: 6,
          shadowColor: Colors.amber.withValues(alpha: 0.4),
        ),
      ),
    ).animate().shimmer(duration: 2000.ms, color: Colors.white24);
  }
}

class _EconomyHeader extends ConsumerWidget {
  const _EconomyHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final streak = ref.watch(streakProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            CurrencyWidget(type: CurrencyType.souls, amount: wallet.souls, size: 16, animated: false),
            const SizedBox(width: 8),
            CurrencyWidget(type: CurrencyType.tokens, amount: wallet.tokens, size: 16, animated: false),
            const Spacer(),
            _StreakBadge(streak: streak.currentStreak),
            const SizedBox(width: 8),
            _CircleBtn(
              icon: Icons.settings,
              tooltip: 'Ajustes',
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Circular Navigation ─────────────────────────────────────────────────────

class _CircularNav extends StatelessWidget {
  const _CircularNav();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CircleBtn(icon: Icons.assignment, tooltip: 'Misiones', onTap: () => _showMissions(context)),
          const SizedBox(width: 12),
          _CircleBtn(icon: Icons.emoji_events, tooltip: 'Logros', onTap: () => context.push('/achievements')),
          const SizedBox(width: 12),
          _CircleBtn(icon: Icons.person, tooltip: 'Perfil', onTap: () => context.push('/profile')),
          const SizedBox(width: 12),
          _CircleBtn(icon: Icons.store, tooltip: 'Tienda', onTap: () => context.push('/shop')),
          const SizedBox(width: 12),
          _CircleBtn(icon: Icons.palette, tooltip: 'Personalizar', onTap: () => context.push('/customization')),
          const SizedBox(width: 12),
          _CircleBtn(icon: Icons.bar_chart, tooltip: 'Estadísticas', onTap: () => context.push('/stats')),
        ],
      ),
    );
  }

  static Future<void> _showMissions(BuildContext context) async {
    final ref = ProviderScope.containerOf(context);
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
                  const Icon(Icons.info_outline, size: 40, color: Colors.white38).animate().fade().scale(begin: Offset(0, 0)),
                  const SizedBox(height: 16),
                  const Text('No hay misiones hoy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Vuelve mañana para nuevos desafíos.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white54)),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CERRAR', style: TextStyle(fontSize: 13, color: Colors.white54)))),
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
                Text('MISIONES DIARIAS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2, color: Theme.of(context).primaryColor)).animate().fade(duration: 300.ms).slideY(begin: -0.2, duration: 300.ms),
                const SizedBox(height: 4),
                const Text('Completa desafíos para ganar XP y futuras recompensas', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white54)).animate().fade(delay: 100.ms, duration: 300.ms),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: missions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _MissionCard(mission: missions[i]).animate().fade(delay: (150 + i * 100).ms, duration: 300.ms).slideX(begin: i.isEven ? -0.1 : 0.1),
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

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
            border: Border.all(color: const Color(0xFF2B2B2B)),
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

// ── Title Section ───────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  const _TitleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('SUDOKU',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ))
            .animate().fade(duration: 500.ms).scale(curve: Curves.easeOutBack),
        const SizedBox(height: 4),
        Text('Classic Journey',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ))
            .animate().fade(delay: 200.ms).slideY(begin: 0.5),
      ],
    );
  }
}

// ── Lucky Wheel ─────────────────────────────────────────────────────────────

class _LuckyWheelButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LuckyWheelButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('LUCKY WHEEL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.amber.shade200,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Streak Badge ─────────────────────────────────────────────────────────────

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
        boxShadow: glow > 0 ? [BoxShadow(color: glowColor, blurRadius: glow, spreadRadius: 1)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 16, color: glowColor),
          const SizedBox(width: 4),
          Text(streak.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: glowColor)),
        ],
      ),
    ).animate().fade(duration: 400.ms).then();
  }
}

// ── Big Buttons ──────────────────────────────────────────────────────────────

class _BigButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _BigButton(this.text, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }
}

// ── Mission Card ─────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final DailyMission mission;
  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final done = mission.completed;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done ? Colors.greenAccent.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: done ? Colors.greenAccent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: done ? Colors.greenAccent : Colors.white38),
              const SizedBox(width: 10),
              Expanded(child: Text(mission.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: done ? Colors.greenAccent : Colors.white))),
              Text('+${mission.xpReward} XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: done ? Colors.greenAccent : Colors.greenAccent.shade200)),
            ],
          ),
          const SizedBox(height: 4),
          Text(mission.description, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${mission.progress} / ${mission.target}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              if (done) const Text('COMPLETADO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.greenAccent, letterSpacing: 1)),
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
                valueColor: AlwaysStoppedAnimation<Color>(done ? Colors.greenAccent : Theme.of(context).primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
