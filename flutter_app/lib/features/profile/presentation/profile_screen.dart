import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../stats/application/stats_provider.dart';
import '../../stats/domain/stats_model.dart';
import '../../progression/application/progression_provider.dart';
import '../../progression/domain/player_level.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final playerLevel = ref.watch(playerLevelProvider);

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
                _ProgressSection(stats: stats, playerLevel: playerLevel).animate().fade(delay: 300.ms),
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
  final PlayerLevel playerLevel;
  const _ProgressSection({required this.stats, required this.playerLevel});

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
            if (diffs[i] == 'mythic')
              _mythicLocked()
            else
              _diffRow(labels[i], stats.winsByDifficulty[diffs[i]] ?? 0, colors[i]),
          ],
        ],
      ),
    );
  }

  Widget _mythicLocked() {
    return Row(
      children: [
        SizedBox(width: 80, child: Text('???',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white24))),
        const SizedBox(width: 8),
        const Text('???', style: TextStyle(fontSize: 12, color: Colors.white24)),
        const Spacer(),
        const Icon(Icons.lock, size: 14, color: Colors.white12),
      ],
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


