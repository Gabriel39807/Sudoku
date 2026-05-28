import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../economy/application/wallet_provider.dart';
import '../progression/application/progression_provider.dart';
import '../progression/domain/daily_mission.dart';
import '../challenge/application/streak_provider.dart';
import '../onboarding/application/onboarding_provider.dart';
import '../campaign/application/campaign_provider.dart';
import '../campaign/application/campaign_autosave_provider.dart';
import '../campaign/domain/campaign_level.dart';
import '../../shared/widgets/game_modal_card.dart';
import '../../ui/currency/currency_widget.dart';
import '../../ui/currency/currency_type.dart';
import '../../features/wheel/presentation/roulette_modal.dart';
import '../challenge/presentation/streak_button.dart';
import '../challenge/presentation/streak_hub_modal.dart';
import '../challenge/presentation/trophy_modal.dart';
import '../challenge/domain/trophy_collection.dart';
import '../cosmetics/application/avatar_inventory_provider.dart';
import '../cosmetics/presentation/widgets/player_profile_avatar.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final onboarding = await ref.read(onboardingProvider.notifier).waitForLoad();
    if (!mounted) return;
    if (onboarding.isFirstLaunch) {
      context.pushReplacement('/intro');
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProvider);
    final campaign = ref.watch(campaignProvider);
    final tutorialDone = onboarding.tutorialCompleted;
    final isNewUser = campaign.completedCount == 0 && !tutorialDone;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const _EconomyHeader(),
              if (tutorialDone) ...[
                const SizedBox(height: 4),
                const _CircularNav(),
              ],
              const Spacer(flex: 1),
              const _TitleSection(),
              const SizedBox(height: 16),
              _HeroContinueButton(isNewUser: isNewUser),
              if (tutorialDone) ...[
                const SizedBox(height: 14),
                _BigButton('JUGAR', () => context.push('/difficulty')),
                const SizedBox(height: 10),
                _BigButton('DESAFÍO DIARIO', () => context.push('/daily')),
                const SizedBox(height: 6),
                const _DailyTrophyCard(),
                const SizedBox(height: 10),
                _LuckyWheelButton(onTap: () => showRouletteModal(context)),
              ],
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero continue button with 3 states:
/// 1. Campaign autosave exists → Resume exact level
/// 2. Campaign progress exists → Continue next level
/// 3. New user → COMENZAR AVENTURA
class _HeroContinueButton extends ConsumerWidget {
  final bool isNewUser;
  const _HeroContinueButton({required this.isNewUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignProvider);
    final autosaveAsync = ref.watch(campaignAutosaveExistsProvider);

    if (isNewUser) {
      return _HeroButton(
        label: 'COMENZAR AVENTURA',
        subtitle: 'Campaña · Nivel 1',
        color: const Color(0xFF6C3FB5),
        glowColor: const Color(0xFF9C4DFF),
        icon: Icons.flag,
        onTap: () {
          final stage = CampaignStage.fromLevel(1);
          context.push('/campaign-game', extra: {'level': 1, 'variant': stage.variant.name});
        },
      );
    }

    // Check autosave first
    final hasAutosave = autosaveAsync.asData?.value ?? false;
    if (hasAutosave) {
      return _HeroButton(
        label: '▶  REANUDAR',
        subtitle: 'Nivel en progreso',
        color: Colors.amber.shade700,
        glowColor: Colors.amber,
        icon: Icons.play_circle_filled,
        onTap: () {
          // Will be restored by provider before navigation
          context.push('/campaign-game', extra: {'restore': true});
        },
      );
    }

    // Active run (level started but no save)
    if (campaign.hasActiveRun) {
      final stage = CampaignStage.fromLevel(campaign.activeRunLevel);
      return _HeroButton(
        label: '▶  CONTINUAR',
        subtitle: 'Nivel ${campaign.activeRunLevel}',
        color: Colors.amber.shade700,
        glowColor: Colors.amber,
        icon: Icons.play_circle_filled,
        onTap: () {
          context.push('/campaign-game',
              extra: {'level': campaign.activeRunLevel, 'variant': stage.variant.name});
        },
      );
    }

    // Regular progress — next level
    final nextLevel = campaign.currentLevel;
    final stage = CampaignStage.fromLevel(nextLevel);
    final count = campaign.completedCount;
    final total = campaign.totalCount;
    return _HeroButton(
      label: '▶  CONTINUAR',
      subtitle: 'Nivel $nextLevel  ·  $count / $total completados',
      color: Colors.amber.shade700,
      glowColor: Colors.amber,
      icon: Icons.play_circle_filled,
      onTap: () {
        context.push('/campaign-game',
            extra: {'level': nextLevel, 'variant': stage.variant.name});
      },
    );
  }
}

class _HeroButton extends StatefulWidget {
  final String label;
  final String subtitle;
  final Color color;
  final Color glowColor;
  final IconData icon;
  final VoidCallback onTap;

  const _HeroButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.glowColor,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineCtrl;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(min: 0.3, max: 1.0);
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 72,
      child: AnimatedBuilder(
        animation: _shineCtrl,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.5 * _shineCtrl.value),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Shine sweep
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.15 * _shineCtrl.value),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            begin: Alignment(-1.5 + 3 * _shineCtrl.value, 0),
                            end: Alignment(1.5 - 3 * _shineCtrl.value, 0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(widget.icon, size: 28, color: Colors.white),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.label,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                  )),
                              const SizedBox(height: 2),
                              Text(widget.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  )),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white54),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      duration: 4000.ms,
      color: Colors.white12,
      delay: 1000.ms,
    );
  }
}

class _EconomyHeader extends ConsumerWidget {
  const _EconomyHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final streak = ref.watch(streakProvider);
    final avatarInv = ref.watch(avatarInventoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            CurrencyWidget(type: CurrencyType.gems, amount: wallet.gems, size: 16, animated: false),
            const SizedBox(width: 8),
            CurrencyWidget(type: CurrencyType.tokens, amount: wallet.tokens, size: 16, animated: false),
            const Spacer(),
            PlayerProfileAvatar(
              avatarId: avatarInv.selectedAvatarId,
              frameId: avatarInv.selectedFrameId,
              size: 36,
              onTap: () => context.push('/profile'),
              showBreathing: true,
            ),
            const SizedBox(width: 8),
            StreakButton(
              streak: streak.currentStreak,
              completedToday: streak.completedToday,
              onTap: () => showStreakHub(context),
            ),
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

// ── Daily Trophy Card ───────────────────────────────────────────────────────

class _DailyTrophyCard extends ConsumerWidget {
  const _DailyTrophyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<TrophyCollection>(
      future: TrophyCollection.load(),
      builder: (ctx, snapshot) {
        final collection = snapshot.data;
        if (collection == null) return const SizedBox.shrink();
        final now = DateTime.now();
        final total = collection.daysInMonth(now.year, now.month);
        final done = collection.countForMonth(now.year, now.month);
        final ratio = total > 0 ? done / total : 0.0;

        return InkWell(
          onTap: () => showTrophyModal(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 240,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TROFEOS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.amber.shade200,
                          )),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('$done / $total',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  static const _rarityColors = {
    MissionDifficulty.easy: Color(0xFF66BB6A),
    MissionDifficulty.medium: Color(0xFF42A5F5),
    MissionDifficulty.hard: Color(0xFFAB47BC),
    MissionDifficulty.elite: Color(0xFFFF7043),
  };

  static const _rarityLabels = {
    MissionDifficulty.easy: 'FÁCIL',
    MissionDifficulty.medium: 'MEDIO',
    MissionDifficulty.hard: 'DIFÍCIL',
    MissionDifficulty.elite: 'ÉLITE',
  };

  @override
  Widget build(BuildContext context) {
    final done = mission.completed;
    final color = _rarityColors[mission.difficulty] ?? Colors.white;
    final label = _rarityLabels[mission.difficulty] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done ? Colors.greenAccent.withValues(alpha: 0.06) : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? Colors.greenAccent.withValues(alpha: 0.25) : color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16, color: done ? Colors.greenAccent : color),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(label,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900,
                        letterSpacing: 1, color: color)),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(mission.title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                      color: done ? Colors.greenAccent : Colors.white))),
              if (!done) ...[
                Text('+${mission.xpReward} XP',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: Colors.greenAccent.shade200)),
                const SizedBox(width: 4),
                Text('+${mission.gemsReward}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: Colors.amber.shade200)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(mission.description,
              style: TextStyle(fontSize: 11, color: done ? Colors.greenAccent.withValues(alpha: 0.7) : Colors.white54)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${mission.progress} / ${mission.target}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: done ? Colors.greenAccent : Colors.white)),
              if (done)
                _RewardPopup(xp: mission.xpReward, gems: mission.gemsReward)
              else
                const SizedBox.shrink(),
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
                    done ? Colors.greenAccent : color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardPopup extends StatelessWidget {
  final int xp;
  final int gems;
  const _RewardPopup({required this.xp, required this.gems});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
            ),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('+$xp XP',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(width: 4),
              Text('+$gems',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                      color: Colors.amberAccent)),
            ],
          ),
        ),
      ],
    ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms)
        .then().shake(duration: 300.ms);
  }
}
