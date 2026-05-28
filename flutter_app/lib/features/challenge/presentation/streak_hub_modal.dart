import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/streak_provider.dart';
import '../domain/streak_tier.dart';
import '../../../shared/widgets/game_modal_card.dart';
import 'streak_flame.dart';
import 'streak_timeline.dart';
import 'streak_rewards.dart';

void showStreakHub(BuildContext context) {
  final ref = ProviderScope.containerOf(context);
  final streak = ref.read(streakProvider);
  final tier = StreakTier.forStreak(streak.currentStreak);
  final nextTier = tier.next;

  showDialog(
    context: context,
    builder: (ctx) => GameModalCard(
      onClose: () => Navigator.pop(ctx),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: StreakHubModal(
        streak: streak.currentStreak,
        bestStreak: streak.bestStreak,
        completedToday: streak.completedToday,
        tier: tier,
        nextTier: nextTier,
        onClose: () => Navigator.pop(ctx),
      ),
    ),
  );
}

class StreakHubModal extends StatefulWidget {
  final int streak;
  final int bestStreak;
  final bool completedToday;
  final StreakTier tier;
  final StreakTier? nextTier;
  final VoidCallback onClose;

  const StreakHubModal({
    super.key,
    required this.streak,
    required this.bestStreak,
    required this.completedToday,
    required this.tier,
    this.nextTier,
    required this.onClose,
  });

  @override
  State<StreakHubModal> createState() => _StreakHubModalState();
}

class _StreakHubModalState extends State<StreakHubModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLife = widget.streak > 0 || widget.completedToday;
    final isLost = !hasLife;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hero flame
          _buildHeroSection(hasLife, isLost),
          const SizedBox(height: 12),

          if (hasLife) ...[
            _buildActiveBadge(),
            const SizedBox(height: 8),
          ],

          // Streak count
          _buildStreakNumber(hasLife),
          const SizedBox(height: 4),

          // Label
          Text(
            hasLife ? 'día${widget.streak == 1 ? '' : 's'} consecutivo${widget.streak == 1 ? '' : 's'}' : 'Comienza tu racha hoy',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 0.5,
            ),
          ),

          if (isLost) ...[
            const SizedBox(height: 6),
            _buildLostMessage(),
          ],

          const SizedBox(height: 16),

          // Best streak + tier info
          _buildInfoRow(),
          const SizedBox(height: 16),

          // Progress timeline
          if (hasLife || widget.nextTier != null) ...[
            StreakTimeline(
              currentStreak: widget.streak,
              currentTier: widget.tier,
              nextTier: widget.nextTier,
            ),
            const SizedBox(height: 16),
          ],

          // Rewards
          StreakRewards(
            currentStreak: widget.streak,
            currentTier: widget.tier,
          ),

          const SizedBox(height: 12),

          // Close
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: widget.onClose,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'CERRAR',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool hasLife, bool isLost) {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (context, _) {
        final entry = _entryCtrl.value;
        return Opacity(
          opacity: entry,
          child: Transform.scale(
            scale: 0.6 + entry * 0.4,
            child: isLost
                ? SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.03),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        Text('🔥', style: TextStyle(
                          fontSize: 36,
                          color: Colors.white.withValues(alpha: 0.3),
                        )),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : StreakFlameHero(
                    tier: widget.tier,
                    streak: widget.streak,
                    completedToday: widget.completedToday,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildActiveBadge() {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (context, _) {
        final delay = _entryCtrl.value > 0.3 ? (_entryCtrl.value - 0.3) / 0.7 : 0.0;
        return Opacity(
          opacity: delay,
          child: Transform.scale(
            scale: 0.7 + delay * 0.3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.tier.flameColor,
                    widget.tier.glowColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: widget.tier.glowColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                'RACHA ACTIVA',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakNumber(bool hasLife) {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (context, _) {
        final delay = _entryCtrl.value > 0.15 ? (_entryCtrl.value - 0.15) / 0.85 : 0.0;
        return Opacity(
          opacity: delay,
          child: Transform.scale(
            scale: 0.5 + delay * 0.5,
            child: Column(
              children: [
                Text(
                  '${widget.streak}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: hasLife ? widget.tier.textColor : Colors.white24,
                    letterSpacing: -2,
                    shadows: hasLife
                        ? [
                            Shadow(
                              color: widget.tier.glowColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                            ),
                            Shadow(
                              color: widget.tier.flameColor.withValues(alpha: 0.15),
                              blurRadius: 40,
                            ),
                          ]
                        : null,
                  ),
                ),
                Text(
                  widget.tier.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: hasLife
                        ? widget.tier.textColor.withValues(alpha: 0.6)
                        : Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow() {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (context, _) {
        final delay = _entryCtrl.value > 0.5 ? (_entryCtrl.value - 0.5) / 0.5 : 0.0;
        return Opacity(
          opacity: delay,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                icon: Icons.emoji_events,
                label: 'Mejor: ${widget.bestStreak}',
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.local_fire_department,
                label: widget.tier.label,
                color: widget.tier.textColor,
              ),
              if (widget.nextTier != null) ...[
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.arrow_upward,
                  label: '${widget.nextTier!.min - widget.streak} para ${widget.nextTier!.label}',
                  color: widget.nextTier!.textColor,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLostMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💨', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            'La llama se apagó...\nVuelve mañana para reavivarla.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
