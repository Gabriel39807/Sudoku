import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../unlock/unlock_service.dart';
import '../application/stats_provider.dart';
import '../domain/difficulty_stats.dart';
import '../domain/stats_model.dart';
import '../domain/unlock_progress.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  static const _tabLabels = [
    'General',
    'Easy',
    'Intermediate',
    'Hard',
    'Expert',
    'Evil',
    '???',
    'Progreso',
  ];

  static const _difficulties = [
    'easy',
    'intermediate',
    'hard',
    'expert',
    'evil',
    'mythic',
  ];

  static const _pageCount = 8;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(
          _titleForPage(statsAsync.asData?.value),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => Column(
          children: [
            _TabBar(
              current: _currentPage,
              stats: stats,
              onTap: (i) {
                _pageController.jumpToPage(i);
                setState(() => _currentPage = i);
              },
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pageCount,
                itemBuilder: (context, index) => _buildPage(index, stats),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForPage(GameStats? stats) {
    if (_currentPage == 0) return 'ESTADISTICAS';
    if (_currentPage >= 1 && _currentPage <= 6) {
      if (_currentPage == 6 && stats != null && !UnlockService.isUnlocked('mythic', stats)) {
        return '???';
      }
      return _tabLabels[_currentPage].toUpperCase();
    }
    return 'PROGRESO';
  }

  Widget _buildPage(int index, GameStats stats) {
    if (index == 0) return _GeneralPage(stats: stats);
    if (index >= 1 && index <= 6) {
      final diff = _difficulties[index - 1];
      final hidden = diff == 'mythic' && !UnlockService.isUnlocked('mythic', stats);
      return _DifficultyPage(
        difficulty: diff,
        stats: stats.difficultyStats[diff] ?? const DifficultyStats(),
        hidden: hidden,
        isUnlocked: UnlockService.isUnlocked(diff, stats),
        unlockProgress: stats.unlockProgress[diff],
      );
    }
    return _ProgressPage(stats: stats);
  }
}

// ── TAB BAR ─────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final int current;
  final GameStats stats;
  final ValueChanged<int> onTap;

  const _TabBar({required this.current, required this.stats, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final mythicUnlocked = UnlockService.isUnlocked('mythic', stats);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(_StatsScreenState._pageCount, (i) {
            final isActive = i == current;
            String label;
            if (i == 6) {
              label = mythicUnlocked ? 'MYTHIC' : '???';
            } else {
              label = _StatsScreenState._tabLabels[i];
            }
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(99),
                    border: isActive
                        ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      letterSpacing: 1,
                      color: isActive
                          ? Theme.of(context).primaryColor
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── GENERAL PAGE ────────────────────────────────────────────────────────────

class _GeneralPage extends StatelessWidget {
  final GameStats stats;

  const _GeneralPage({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroMetric(
            label: 'Partidas jugadas',
            value: '${stats.gamesPlayed}',
            icon: Icons.play_circle_outline,
          ),
          const SizedBox(height: 12),
          _StatRow(label: 'Partidas iniciadas', value: '${stats.gamesPlayed}'),
          _StatRow(label: 'Victorias', value: '${stats.gamesWon}'),
          _StatRow(label: 'Derrotas', value: '${stats.gamesLost}'),
          _StatRow(label: 'Abandonadas', value: '${stats.gamesAbandoned}'),
          _DividerLine(),
          _StatRow(
            label: 'Win rate',
            value: '${(stats.winRate * 100).toStringAsFixed(1)}%',
          ),
          _StatRow(label: 'Tiempo total jugado', value: _fmtTime(stats.totalPlayTime)),
          _StatRow(label: 'Mejor tiempo global', value: _fmtTime(_bestGlobalTime(stats))),
          _DividerLine(),
          _StatRow(label: 'Racha actual', value: '${stats.winStreak}'),
          _StatRow(label: 'Racha maxima', value: '${stats.bestWinStreak}'),
          _DividerLine(),
          _StatRow(label: 'Victorias con pistas', value: '${stats.victoriesWithHints}'),
          _StatRow(label: 'Victorias perfectas', value: '${stats.perfectVictories}'),
          _StatRow(label: 'Completadas con autocomplete', value: '${stats.completedWithAutocomplete}'),
          _StatRow(label: 'Completadas con pistas', value: '${stats.completedWithHints}'),
          _StatRow(label: 'Total pistas usadas', value: '${stats.hintsUsed}'),
          const SizedBox(height: 24),
          _ResetButton(stats: stats),
        ],
      ),
    );
  }

  int _bestGlobalTime(GameStats stats) {
    final times = [
      stats.bestEasy,
      stats.bestIntermediate,
      stats.bestHard,
      stats.bestExpert,
      stats.bestEvil,
      stats.bestMythic,
    ]..removeWhere((t) => t == 0);
    if (times.isEmpty) return 0;
    return times.reduce((a, b) => a < b ? a : b);
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroMetric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.25),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).primaryColor),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: Colors.white60)),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
    );
  }
}

class _ResetButton extends ConsumerWidget {
  final GameStats stats;

  const _ResetButton({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
        label: const Text('RESET ESTADISTICAS', style: TextStyle(color: Colors.orangeAccent)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.orangeAccent),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Resetear estadisticas'),
              content: const Text('Se borraran todas las estadisticas.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Resetear', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(statsProvider.notifier).resetStats();
          }
        },
      ),
    );
  }
}

// ── DIFFICULTY PAGE ─────────────────────────────────────────────────────────

class _DifficultyPage extends StatelessWidget {
  final String difficulty;
  final DifficultyStats stats;
  final bool hidden;
  final bool isUnlocked;
  final UnlockProgressModel? unlockProgress;

  const _DifficultyPage({
    required this.difficulty,
    required this.stats,
    required this.hidden,
    required this.isUnlocked,
    this.unlockProgress,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: hidden ? _buildHidden(context) : _buildContent(context),
    );
  }

  Widget _buildHidden(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline, size: 80, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 24),
          const Text(
            '???',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8),
          ),
          const SizedBox(height: 12),
          Text(
            'Completa los requisitos para desbloquear',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4)),
          ),
          if (unlockProgress != null) ...[
            const SizedBox(height: 24),
            _ProgressBar(
              current: unlockProgress!.current,
              required: unlockProgress!.required,
              label: '${unlockProgress!.sourceDifficulty.toUpperCase()} victories',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final winRate = stats.gamesStarted == 0
        ? 0.0
        : (stats.victories / stats.gamesStarted * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _iconFor(difficulty),
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              difficulty.toUpperCase(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Card(
          child: Column(
            children: [
              _MetricItem(label: 'Partidas jugadas', value: '${stats.gamesStarted}'),
              _MetricItem(label: 'Victorias', value: '${stats.victories}'),
              _MetricItem(label: 'Derrotas', value: '${stats.losses}'),
              _MetricItem(label: 'Abandonadas', value: '${stats.abandons}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              _MetricItem(label: 'Win rate', value: '${winRate.toStringAsFixed(1)}%'),
              _MetricItem(label: 'Mejor tiempo', value: _fmtTime(stats.bestTime)),
              _MetricItem(label: 'Tiempo total', value: _fmtTime(stats.totalWinTime)),
              _MetricItem(label: 'Tiempo promedio', value: _fmtTime(stats.averageTime)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              _MetricItem(label: 'Pistas usadas', value: '${stats.hintsUsed}'),
              _MetricItem(label: 'Victorias perfectas', value: '${stats.perfectVictories}'),
              _MetricItem(label: 'Autocomplete', value: '${stats.completedWithAutocomplete}'),
              _MetricItem(label: 'Con pistas', value: '${stats.completedWithHints}'),
            ],
          ),
        ),
        if (unlockProgress != null && !unlockProgress!.unlocked) ...[
          const SizedBox(height: 20),
          _ProgressBar(
            current: unlockProgress!.current,
            required: unlockProgress!.required,
            label: 'Progreso desbloqueo siguiente',
          ),
        ],
        const SizedBox(height: 16),
        if (!isUnlocked)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, size: 18, color: Colors.orangeAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    unlockProgress?.sourceDifficulty != null
                        ? 'Gana ${unlockProgress!.required - unlockProgress!.current} mas en ${unlockProgress!.sourceDifficulty.toUpperCase()}'
                        : 'Bloqueado',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _iconFor(String diff) {
    switch (diff) {
      case 'easy': return Icons.sentiment_satisfied;
      case 'intermediate': return Icons.psychology;
      case 'hard': return Icons.local_fire_department;
      case 'expert': return Icons.diamond;
      case 'evil': return Icons.warning;
      case 'mythic': return Icons.star;
      default: return Icons.extension;
    }
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: child,
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int required;
  final String label;

  const _ProgressBar({required this.current, required this.required, required this.label});

  @override
  Widget build(BuildContext context) {
    final ratio = required > 0 ? ((current / required).clamp(0, 1) as double) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
            Text('$current / $required', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: ratio),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
      ],
    );
  }
}

// ── PROGRESS PAGE ───────────────────────────────────────────────────────────

class _ProgressPage extends StatelessWidget {
  final GameStats stats;
  const _ProgressPage({required this.stats});

  @override
  Widget build(BuildContext context) {
    final progressList = stats.unlockProgress.values.toList()
      ..sort((a, b) => UnlockService.difficulties.indexOf(a.difficulty)
          .compareTo(UnlockService.difficulties.indexOf(b.difficulty)));

    final mythicLocked = !UnlockService.isUnlocked('mythic', stats);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROGRESO DE DESBLOQUEO',
            style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          for (final progress in progressList) ...[
            _ProgressCard(progress: progress, stats: stats, mythicLocked: mythicLocked),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final UnlockProgressModel progress;
  final GameStats stats;
  final bool mythicLocked;

  const _ProgressCard({required this.progress, required this.stats, required this.mythicLocked});

  @override
  Widget build(BuildContext context) {
    final isMythic = progress.difficulty == 'mythic';
    final hidden = isMythic && mythicLocked;
    final label = hidden ? '???' : progress.difficulty.toUpperCase();
    final icon = hidden ? Icons.help_outline : Icons.lock_open;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: progress.unlocked
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : const Color(0xFF2B2B2B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: progress.unlocked ? Colors.greenAccent : Colors.white54),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const Spacer(),
              if (progress.unlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'DESBLOQUEADO',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.sourceDifficulty.toUpperCase()} victories',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
              Text(
                '${progress.current} / ${progress.required}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.ratio),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
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
