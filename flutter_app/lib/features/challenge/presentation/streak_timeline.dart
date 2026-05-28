import 'package:flutter/material.dart';
import '../domain/streak_tier.dart';

class StreakTimeline extends StatelessWidget {
  final int currentStreak;
  final StreakTier currentTier;
  final StreakTier? nextTier;

  const StreakTimeline({
    super.key,
    required this.currentStreak,
    required this.currentTier,
    this.nextTier,
  });

  static const _milestones = [1, 3, 7, 14, 30, 60, 100];

  @override
  Widget build(BuildContext context) {
    final milestones = _milestones.where((m) => m > currentStreak).take(5).toList();
    if (milestones.isEmpty && currentStreak < 100) {
      milestones.add(100);
    }
    if (milestones.isEmpty) return const SizedBox.shrink();

    final nextMilestone = milestones.first;
    final prevMilestone = _lastMilestoneBefore(currentStreak);
    final progress = _milestoneProgress(currentStreak, prevMilestone, nextMilestone);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProgressBar(progress, nextMilestone, prevMilestone, milestones),
        const SizedBox(height: 16),
        _buildMilestoneRow(milestones, nextMilestone),
      ],
    );
  }

  Widget _buildProgressBar(double progress, int next, int prev, List<int> milestones) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: Colors.white.withValues(alpha: 0.06),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: LinearGradient(
                    colors: [
                      currentTier.flameColor.withValues(alpha: 0.6),
                      currentTier.glowColor,
                    ],
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (_, constraints) => AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(
                      colors: [
                        currentTier.flameColor,
                        currentTier.glowColor,
                        currentTier.accentColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentTier.glowColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              prev > 0 ? '$prev días' : 'Inicio',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            Text(
              '$next días',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: nextTier?.textColor ?? Colors.white54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMilestoneRow(List<int> milestones, int next) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: milestones.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final m = milestones[i];
          final unlocked = currentStreak >= m;
          final isNext = m == next;
          final tier = StreakTier.forStreak(m);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: unlocked
                  ? tier.flameColor.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: unlocked
                    ? tier.accentColor.withValues(alpha: 0.3)
                    : isNext
                        ? tier.accentColor.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                width: isNext ? 1.5 : 1,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: tier.glowColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tier.icon,
                  style: TextStyle(
                    fontSize: 14,
                    color: unlocked ? null : Colors.white24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$m',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: unlocked
                        ? tier.textColor
                        : isNext
                            ? tier.textColor.withValues(alpha: 0.5)
                            : Colors.white24,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _lastMilestoneBefore(int streak) {
    int last = 0;
    for (final m in _milestones) {
      if (m <= streak) last = m;
    }
    return last;
  }

  double _milestoneProgress(int streak, int prev, int next) {
    if (next <= prev) return 1.0;
    final range = next - prev;
    final progress = streak - prev;
    return (progress / range).clamp(0.0, 1.0);
  }
}
