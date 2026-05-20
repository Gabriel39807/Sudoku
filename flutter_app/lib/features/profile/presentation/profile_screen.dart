import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../stats/application/stats_provider.dart';
import '../../stats/domain/stats_model.dart';
import '../../progression/application/progression_provider.dart';
import '../../progression/domain/player_level.dart';
import '../../progression/domain/achievement.dart';
import '../../progression/domain/daily_mission.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final playerLevel = ref.watch(playerLevelProvider);
    final achievements = ref.watch(achievementsProvider);
    final missions = ref.watch(missionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('PERFIL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PlayerHeader(playerLevel: playerLevel, stats: stats).animate().fade().slideY(begin: -0.1),
                const SizedBox(height: 20),
                _StatsSection(stats: stats).animate().fade(delay: 200.ms),
                const SizedBox(height: 20),
                _ProgressSection(stats: stats).animate().fade(delay: 300.ms),
                const SizedBox(height: 20),
                _MissionsSection(missions: missions).animate().fade(delay: 400.ms),
                const SizedBox(height: 20),
                _AchievementsSection(
                  achievements: achievements,
                  totalCount: AchievementRegistry.all().length,
                ).animate().fade(delay: 600.ms),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Player Header ──────────────────────────────────────────────────────────

class _PlayerHeader extends StatelessWidget {
  final PlayerLevel playerLevel;
  final GameStats stats;

  const _PlayerHeader({required this.playerLevel, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.2),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            child: Icon(Icons.person, size: 32, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(playerLevel.title,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 2),
                Text('NIVEL ${playerLevel.level}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('${playerLevel.totalXp} XP total',
                    style: const TextStyle(fontSize: 13, color: Colors.white60)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: playerLevel.progress),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${playerLevel.currentXp} / ${playerLevel.xpForNext} XP',
                    style: const TextStyle(fontSize: 11, color: Colors.white38)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Section ──────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final GameStats stats;
  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ESTADÍSTICAS',
              style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white54)),
          const SizedBox(height: 12),
          _profileStat('Victorias', '${stats.gamesWon}'),
          _profileStat('Derrotas', '${stats.gamesLost}'),
          _profileStat('Winrate', '${(stats.winRate * 100).toStringAsFixed(1)}%'),
          _profileStat('Racha máxima', '${stats.bestWinStreak}'),
          _profileStat('Victorias perfectas', '${stats.perfectVictories}'),
          _profileStat('Pistas usadas', '${stats.hintsUsed}'),
          _profileStat('Combo máximo', '${stats.maxCombo}'),
          _profileStat('Notas usadas', '${stats.totalNoteUsage}'),
        ],
      ),
    );
  }

  Widget _profileStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Progress Section (per-difficulty completion) ──────────────────────────

class _ProgressSection extends StatelessWidget {
  final GameStats stats;
  const _ProgressSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final diffs = ['easy', 'intermediate', 'hard', 'expert', 'evil', 'mythic'];
    final labels = ['Easy', 'Inter', 'Hard', 'Expert', 'Evil', 'Mythic'];
    final colors = [
      Colors.greenAccent, Colors.lightBlueAccent, Colors.amberAccent,
      Colors.orangeAccent, Colors.redAccent, Colors.purpleAccent,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROGRESIÓN',
              style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white54)),
          const SizedBox(height: 12),
          for (var i = 0; i < diffs.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _diffRow(labels[i], stats.winsByDifficulty[diffs[i]] ?? 0, colors[i]),
          ],
        ],
      ),
    );
  }

  Widget _diffRow(String label, int wins, Color color) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))),
        const SizedBox(width: 8),
        Text('$wins', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const Spacer(),
        Icon(Icons.check_circle, size: 14,
            color: wins > 0 ? color : Colors.white12),
      ],
    );
  }
}

// ── Missions Section ───────────────────────────────────────────────────────

class _MissionsSection extends StatelessWidget {
  final List<DailyMission> missions;
  const _MissionsSection({required this.missions});

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MISIONES DIARIAS',
              style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white54)),
          const SizedBox(height: 12),
          for (final mission in missions) ...[
            _MissionRow(mission: mission),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final DailyMission mission;
  const _MissionRow({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mission.completed
            ? Colors.greenAccent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mission.completed
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : const Color(0xFF2B2B2B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(mission.title, style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: mission.completed ? Colors.greenAccent : Colors.white,
                )),
              ),
              if (mission.completed)
                const Icon(Icons.check_circle, size: 18, color: Colors.greenAccent),
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
              Text('+${mission.xpReward} XP',
                  style: const TextStyle(fontSize: 11, color: Colors.greenAccent)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: mission.ratio,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                mission.completed
                    ? Colors.greenAccent
                    : Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Achievements Section ───────────────────────────────────────────────────

class _AchievementsSection extends StatelessWidget {
  final Map<String, Achievement> achievements;
  final int totalCount;

  const _AchievementsSection({
    required this.achievements,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final list = achievements.values.toList()
      ..sort((a, b) {
        if (a.unlocked != b.unlocked) return a.unlocked ? 1 : -1;
        return a.id.compareTo(b.id);
      });

    if (list.isEmpty) return const SizedBox.shrink();

    final unlockedCount = list.where((a) => a.unlocked).length;
    final completionPct = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('LOGROS ($unlockedCount/$totalCount)',
                  style: const TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white54)),
              const Spacer(),
              Text('${(completionPct * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                      color: completionPct >= 1.0
                          ? const Color(0xFFD7B45A)
                          : Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: completionPct,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                completionPct >= 1.0
                    ? const Color(0xFFD7B45A)
                    : Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...list.map((a) => _AchievementRow(
            achievement: a,
            totalCount: totalCount,
          )),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final Achievement achievement;
  final int totalCount;

  const _AchievementRow({
    required this.achievement,
    required this.totalCount,
  });

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isHidden ? Icons.help_outline : Icons.emoji_events,
            size: 24,
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
                const SizedBox(height: 2),
                Text(
                  isHidden ? 'Sigue jugando para descubrir este logro...'
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
            const Icon(Icons.check_circle, size: 18, color: Color(0xFFD7B45A))
          else
            Text('${(achievement.ratio * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}
