import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../progression/application/progression_provider.dart';
import '../../progression/domain/achievement.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final all = AchievementRegistry.all();
    final list = achievements.values.toList()
      ..sort((a, b) {
        if (a.unlocked != b.unlocked) return a.unlocked ? 1 : -1;
        return a.id.compareTo(b.id);
      });

    final unlockedCount = list.where((a) => a.unlocked).length;
    final totalCount = all.length;
    final completionPct = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('LOGROS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2B2B2B)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$unlockedCount / $totalCount',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: completionPct,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              completionPct >= 1.0
                                  ? const Color(0xFFD7B45A)
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('${(completionPct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: completionPct >= 1.0
                            ? const Color(0xFFD7B45A)
                            : Colors.white70,
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFF2B2B2B)),
              itemBuilder: (context, index) {
                final a = list[index];
                return _AchievementTile(achievement: a, totalCount: totalCount);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final int totalCount;

  const _AchievementTile({required this.achievement, required this.totalCount});

  Color _rarityColor() {
    switch (achievement.rarity) {
      case 'legendario': return const Color(0xFFFF6B35);
      case 'épico': return const Color(0xFF9B59B6);
      case 'raro': return const Color(0xFF3498DB);
      case 'poco común': return const Color(0xFF2ECC71);
      default: return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHidden = achievement.hidden && !achievement.unlocked;
    final opacity = achievement.unlocked ? 1.0 : 0.4;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            isHidden ? Icons.help_outline : Icons.emoji_events,
            size: 28,
            color: achievement.unlocked
                ? const Color(0xFFD7B45A)
                : Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isHidden ? '???' : achievement.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: opacity),
                        ),
                      ),
                    ),
                    Text(achievement.rarity,
                        style: TextStyle(
                          fontSize: 9,
                          color: _rarityColor(),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isHidden
                      ? 'Sigue jugando para descubrir este logro...'
                      : achievement.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: opacity * 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (achievement.unlocked)
            const Icon(Icons.check_circle, size: 20, color: Color(0xFFD7B45A))
          else
            Text('${(achievement.ratio * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}
