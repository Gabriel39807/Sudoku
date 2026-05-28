import 'package:flutter/material.dart';
import '../domain/streak_tier.dart';

class StreakRewards extends StatelessWidget {
  final int currentStreak;
  final StreakTier currentTier;

  const StreakRewards({
    super.key,
    required this.currentStreak,
    required this.currentTier,
  });

  static const _rewards = [
    _StreakReward(days: 3, icon: '🔥', label: 'Racha activa', desc: 'Desbloquea bonus de GEMS'),
    _StreakReward(days: 7, icon: '⭐', label: '+5% GEMS', desc: 'Multiplicador de recompensas'),
    _StreakReward(days: 14, icon: '💎', label: '+10% XP', desc: 'Ganas más experiencia'),
    _StreakReward(days: 30, icon: '🎡', label: 'Giro extra', desc: 'Un giro de ruleta adicional'),
    _StreakReward(days: 60, icon: '🏆', label: 'Racha élite', desc: 'Cofre especial de recompensas'),
    _StreakReward(days: 100, icon: '👑', label: 'Leyenda', desc: '¡Marco legendario exclusivo!'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMPENSAS',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 8),
        ...(_rewards.asMap().entries.map((entry) {
          return _RewardCard(
            reward: entry.value,
            unlocked: currentStreak >= entry.value.days,
            isCurrent: currentStreak >= entry.value.days &&
                (entry.key == _rewards.length - 1 || currentStreak < _rewards[entry.key + 1].days),
            tier: currentTier,
          );
        })),
      ],
    );
  }
}

class _StreakReward {
  final int days;
  final String icon;
  final String label;
  final String desc;
  const _StreakReward({
    required this.days,
    required this.icon,
    required this.label,
    required this.desc,
  });
}

class _RewardCard extends StatelessWidget {
  final _StreakReward reward;
  final bool unlocked;
  final bool isCurrent;
  final StreakTier tier;

  const _RewardCard({
    required this.reward,
    required this.unlocked,
    required this.isCurrent,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked
            ? tier.flameColor.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? tier.accentColor.withValues(alpha: isCurrent ? 0.35 : 0.15)
              : Colors.white.withValues(alpha: 0.04),
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: isCurrent && unlocked
            ? [
                BoxShadow(
                  color: tier.glowColor.withValues(alpha: 0.12),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? tier.flameColor.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: unlocked
                    ? tier.accentColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Center(
              child: Text(
                unlocked ? reward.icon : '🔒',
                style: TextStyle(fontSize: 14, color: unlocked ? null : Colors.white24),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.white : Colors.white38,
                  ),
                ),
                Text(
                  reward.desc,
                  style: TextStyle(
                    fontSize: 10,
                    color: unlocked ? Colors.white54 : Colors.white24,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: unlocked
                  ? tier.flameColor.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${reward.days}d',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: unlocked ? tier.textColor : Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
