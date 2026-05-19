import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../unlock/unlock_service.dart';
import '../application/stats_provider.dart';
import '../domain/difficulty_stats.dart';
import '../domain/stats_model.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text(
          'ESTADISTICAS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _GeneralDashboard(stats: stats),
            const SizedBox(height: 24),
            _UnlockProgress(stats: stats),
            const SizedBox(height: 24),
            _DifficultyDashboard(stats: stats),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
              label: const Text(
                'RESET ESTADISTICAS',
                style: TextStyle(color: Colors.orangeAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orangeAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _confirmReset(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resetear estadisticas'),
        content: const Text(
          'Se borraran todas las estadisticas. Los tableros no se veran afectados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Resetear',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(statsProvider.notifier).resetStats();
    }
  }
}

class _GeneralDashboard extends StatelessWidget {
  final GameStats stats;

  const _GeneralDashboard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'GENERAL',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _MetricCard('Tiempo total', _fmtTime(stats.totalPlayTime)),
          _MetricCard('Partidas iniciadas', '${stats.gamesPlayed}'),
          _MetricCard('Victorias', '${stats.gamesWon}'),
          _MetricCard('Derrotas', '${stats.gamesLost}'),
          _MetricCard('Abandonadas', '${stats.gamesAbandoned}'),
          _MetricCard(
            'Winrate',
            '${(stats.winRate * 100).toStringAsFixed(1)}%',
          ),
          _MetricCard('Hints usadas', '${stats.hintsUsed}'),
          _MetricCard('Perfect victories', '${stats.perfectVictories}'),
          _MetricCard('Victories with hints', '${stats.victoriesWithHints}'),
          _MetricCard('Best streak', '${stats.bestWinStreak}'),
          _MetricCard('Current streak', '${stats.winStreak}'),
        ],
      ),
    );
  }
}

class _UnlockProgress extends StatelessWidget {
  final GameStats stats;

  const _UnlockProgress({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'PROGRESO DESBLOQUEO',
      child: Column(
        children: [
          for (final progress in stats.unlockProgress.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(progress.difficulty.toUpperCase()),
                      Text('${progress.current} / ${progress.required}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.ratio),
                    duration: const Duration(milliseconds: 450),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DifficultyDashboard extends StatelessWidget {
  final GameStats stats;

  const _DifficultyDashboard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'POR DIFICULTAD',
      child: Column(
        children: [
          for (final difficulty in UnlockService.difficulties)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DifficultyCard(
                difficulty: difficulty,
                stats:
                    stats.difficultyStats[difficulty] ??
                    const DifficultyStats(),
                hidden:
                    difficulty == 'mythic' &&
                    !UnlockService.isUnlocked('mythic', stats),
              ),
            ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final String difficulty;
  final DifficultyStats stats;
  final bool hidden;

  const _DifficultyCard({
    required this.difficulty,
    required this.stats,
    required this.hidden,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: hidden
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '?????',
                  style: TextStyle(fontSize: 24, letterSpacing: 4),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  difficulty.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      'Partidas',
                      '${stats.gamesStarted}',
                      compact: true,
                    ),
                    _MetricCard(
                      'Victorias',
                      '${stats.victories}',
                      compact: true,
                    ),
                    _MetricCard(
                      'Mejor tiempo',
                      _fmtTime(stats.bestTime),
                      compact: true,
                    ),
                    _MetricCard(
                      'Promedio',
                      _fmtTime(stats.averageTime),
                      compact: true,
                    ),
                    _MetricCard('Abandons', '${stats.abandons}', compact: true),
                    _MetricCard(
                      'Perfect clears',
                      '${stats.perfectVictories}',
                      compact: true,
                    ),
                    _MetricCard(
                      'Hints usadas',
                      '${stats.hintsUsed}',
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _MetricCard(this.label, this.value, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 145 : 180,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

String _fmtTime(int seconds) {
  if (seconds <= 0) return '-';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
