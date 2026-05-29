import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../campaign/application/campaign_provider.dart';
import '../../campaign/domain/campaign_level.dart';
import '../../campaign/domain/campaign_progress.dart';
import '../../challenge/application/streak_provider.dart';
import '../../unlock/unlock_service.dart';
import '../application/stats_provider.dart';
import '../data/stats_storage.dart';
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
    'CAMPAÑA',
    'DIARIO',
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

  static const _pageCount = 10;

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
    if (_currentPage == 7) return 'CAMPANA';
    if (_currentPage == 8) return 'DIARIO';
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
    if (index == 7) return const _CampaignPage();
    if (index == 8) return const _DailyPage();
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
          _StatRow(label: 'Combo máximo', value: '${stats.maxCombo}'),
          _StatRow(label: 'Notas usadas', value: '${stats.totalNoteUsage}'),
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
              _MetricItem(label: 'Combo máximo', value: '${stats.maxCombo}'),
              _MetricItem(label: 'Notas usadas', value: '${stats.totalNoteUsage}'),
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

// ── Campaign Page ────────────────────────────────────────────────────────────

// ── DAILY PAGE ──────────────────────────────────────────────────────────────

class _DailyPage extends ConsumerStatefulWidget {
  const _DailyPage();

  @override
  ConsumerState<_DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends ConsumerState<_DailyPage> {
  Map<String, int> _dailyStore = {};

  @override
  void initState() {
    super.initState();
    _loadDailyStore();
  }

  Future<void> _loadDailyStore() async {
    final data = await StatsStorage.loadDailyStats();
    if (mounted) setState(() => _dailyStore = data);
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakProvider);

    final gamesPlayed = _dailyStore['gamesPlayed'] ?? 0;
    final wins = _dailyStore['wins'] ?? 0;
    final losses = _dailyStore['losses'] ?? 0;
    final bestTime = _dailyStore['bestTime'] ?? 0;
    final totalTime = _dailyStore['totalTime'] ?? 0;
    final totalMistakes = _dailyStore['totalMistakes'] ?? 0;
    final hintsUsed = _dailyStore['hintsUsed'] ?? 0;
    final perfect = _dailyStore['perfect'] ?? 0;
    final winRate = gamesPlayed > 0 ? (wins / gamesPlayed * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroMetric(
            label: 'Racha',
            value: '${streak.currentStreak}',
            icon: Icons.local_fire_department,
          ),
          const SizedBox(height: 12),
          _StatRow(label: 'Mejor racha', value: '${streak.bestStreak}'),
          _DividerLine(),
          _StatRow(label: 'Partidas jugadas', value: '$gamesPlayed'),
          _StatRow(label: 'Victorias', value: '$wins'),
          _StatRow(label: 'Derrotas', value: '$losses'),
          _StatRow(label: 'Win rate', value: '${winRate.toStringAsFixed(1)}%'),
          _DividerLine(),
          _StatRow(label: 'Mejor tiempo', value: _fmtTime(bestTime)),
          _StatRow(label: 'Tiempo total', value: _fmtTime(totalTime)),
          _StatRow(label: 'Errores totales', value: '$totalMistakes'),
          _StatRow(label: 'Pistas usadas', value: '$hintsUsed'),
          _StatRow(label: 'Perfectas', value: '$perfect'),
        ],
      ),
    );
  }
}

class _CampaignPage extends ConsumerStatefulWidget {
  const _CampaignPage();

  @override
  ConsumerState<_CampaignPage> createState() => _CampaignPageState();
}

class _CampaignPageState extends ConsumerState<_CampaignPage> {
  Map<String, int> _campaignStore = {};

  @override
  void initState() {
    super.initState();
    _loadCampaignStore();
  }

  Future<void> _loadCampaignStore() async {
    final data = await StatsStorage.loadCampaignStats();
    if (mounted) setState(() => _campaignStore = data);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(campaignProvider);
    final results = progress.results;

    final completed = results.values.where((r) => r.completed).length;
    final totalLevels = CampaignStage.totalLevels;
    final totalStars = results.values.fold<int>(0, (s, r) => s + (r.completed ? r.stars : 0));
    final maxStars = completed * 3;
    final perfectCount = results.values.where((r) => r.completed && r.stars >= 3).length;
    final twoStarCount = results.values.where((r) => r.completed && r.stars == 2).length;
    final oneStarCount = results.values.where((r) => r.completed && r.stars == 1).length;
    final bossesDefeated = results.values.where((r) => r.completed && r.isBoss).length;
    final bossPerfects = results.values.where((r) => r.completed && r.isBoss && r.stars >= 3).length;
    final completionPercent = totalLevels > 0 ? (completed / totalLevels * 100).round() : 0;

    final storedWins = _campaignStore['wins'] ?? 0;
    final storedLosses = _campaignStore['losses'] ?? 0;
    final storedStreak = _campaignStore['streak'] ?? 0;
    final storedBestStreak = _campaignStore['bestStreak'] ?? 0;
    final storedMistakes = _campaignStore['totalMistakes'] ?? 0;
    final storedBosses = _campaignStore['bossesDefeated'] ?? 0;
    final storedBossPerfect = _campaignStore['bossPerfectWins'] ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        _CampaignHeroCard(
          completed: completed,
          totalLevels: totalLevels,
          completionPercent: completionPercent,
          totalStars: totalStars,
          maxStars: maxStars,
        ),
        const SizedBox(height: 16),
        _CampaignSectionTitle(title: 'PROGRESO'),
        const SizedBox(height: 8),
        _CampaignStatRow(icon: Icons.auto_awesome, label: 'Completados', value: '$completed / $totalLevels'),
        _CampaignStatRow(icon: Icons.star, label: 'Estrellas', value: '$totalStars / $maxStars'),
        _CampaignStatRow(icon: Icons.military_tech, label: 'Platinados (★★★)', value: '$perfectCount'),
        _CampaignStatRow(icon: Icons.star_half, label: '★★', value: '$twoStarCount'),
        _CampaignStatRow(icon: Icons.star_border, label: '★', value: '$oneStarCount'),
        _CampaignStatRow(icon: Icons.flag, label: '% Completado', value: '$completionPercent%'),
        const SizedBox(height: 16),
        _CampaignSectionTitle(title: 'BATALLA'),
        const SizedBox(height: 8),
        _CampaignStatRow(icon: Icons.shield, label: 'Jefes Derrotados', value: '$bossesDefeated'),
        _CampaignStatRow(icon: Icons.workspace_premium, label: 'Jefes Perfectos', value: '$bossPerfects'),
        _CampaignStatRow(icon: Icons.emoji_events, label: 'Victorias', value: '$storedWins'),
        _CampaignStatRow(
          icon: Icons.cancel_outlined,
          label: 'Derrotas',
          value: '$storedLosses',
          color: Colors.redAccent,
        ),
        _CampaignStatRow(icon: Icons.local_fire_department, label: 'Racha Actual', value: '$storedStreak'),
        _CampaignStatRow(icon: Icons.whatshot, label: 'Mejor Racha', value: '$storedBestStreak'),
        _CampaignStatRow(icon: Icons.error_outline, label: 'Errores Totales', value: '$storedMistakes'),
        if (storedBosses > 0)
          _CampaignStatRow(
            icon: Icons.auto_awesome,
            label: 'Stats Boss (guardadas)',
            value: '$storedBosses derrotados / $storedBossPerfect perfectos',
          ),
        const SizedBox(height: 16),
        _CampaignSectionTitle(title: 'RECOMPENSAS'),
        const SizedBox(height: 8),
        _CampaignRewardSummary(results: results),
      ],
    );
  }
}

class _CampaignHeroCard extends StatelessWidget {
  final int completed, totalLevels, completionPercent, totalStars, maxStars;

  const _CampaignHeroCard({
    required this.completed,
    required this.totalLevels,
    required this.completionPercent,
    required this.totalStars,
    required this.maxStars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A3E).withValues(alpha: 0.8),
            const Color(0xFF2D1B4E).withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, color: Colors.amber.shade300, size: 28),
              const SizedBox(width: 10),
              const Text(
                'CAMPAÑA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _CampaignProgressBar(value: completionPercent / 100),
          const SizedBox(height: 12),
          Text(
            '$completionPercent%',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.amber.shade300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$completed / $totalLevels niveles completados',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (i) {
                final starVal = (totalStars / (completed > 0 ? completed : 1) / 3 * 5).clamp(0, 5);
                final filled = i < starVal.round();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: filled ? Colors.amber : Colors.white24,
                    size: 24,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampaignProgressBar extends StatelessWidget {
  final double value;
  const _CampaignProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange.shade400],
              ),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampaignSectionTitle extends StatelessWidget {
  final String title;
  const _CampaignSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: Colors.amber.shade300.withValues(alpha: 0.8),
      ),
    );
  }
}

class _CampaignStatRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? color;

  const _CampaignStatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color ?? Colors.amber.shade300),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignRewardSummary extends StatelessWidget {
  final Map<int, CampaignLevelResult> results;
  const _CampaignRewardSummary({required this.results});

  @override
  Widget build(BuildContext context) {
    final totalXp = results.values.fold<int>(0, (s, r) => s + r.xpEarned);
    final totalTokens = results.values.fold<int>(0, (s, r) => s + r.tokensEarned);
    final totalGems = results.values.fold<int>(0, (s, r) => s + r.gemsEarned);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A2A1A).withValues(alpha: 0.6),
            const Color(0xFF1A1A2E).withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _RewardBadge(icon: Icons.stars, label: 'XP', value: '$totalXp'),
              const SizedBox(width: 8),
              _RewardBadge(icon: Icons.monetization_on, label: 'Tokens', value: '$totalTokens'),
              const SizedBox(width: 8),
              _RewardBadge(icon: Icons.diamond, label: 'Gemas', value: '$totalGems'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _RewardBadge({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.amber.shade300),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
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
