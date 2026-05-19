import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('ESTADÍSTICAS',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _Section(
              title: 'GENERAL',
              children: [
                _StatRow('Partidas jugadas', '${stats.gamesPlayed}'),
                _StatRow('Victorias', '${stats.gamesWon}'),
                _StatRow('Derrotas', '${stats.gamesLost}'),
                _StatRow('Win Rate',
                    '${(stats.winRate * 100).toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'RACHA',
              children: [
                _StatRow('Racha actual', '${stats.winStreak}'),
                _StatRow('Mejor racha', '${stats.bestWinStreak}'),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'MEJORES TIEMPOS',
              children: [
                for (final diff in [
                  'easy', 'intermediate', 'hard', 'expert', 'evil', 'mythic'
                ])
                  _StatRow(
                    diff.toUpperCase(),
                    _fmtTime(stats.bestTimeFor(diff)),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
              label: const Text('RESET ESTADÍSTICAS',
                  style: TextStyle(color: Colors.orangeAccent)),
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

  String _fmtTime(int seconds) {
    if (seconds == 0) return '—';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resetear estadísticas'),
        content: const Text('Se borrarán todas las estadísticas. Los tableros no se verán afectados.'),
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
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
