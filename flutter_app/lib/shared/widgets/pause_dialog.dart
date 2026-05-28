import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/game/application/game_provider.dart';
import '../../features/game/domain/session_stats.dart';

class PauseOverlayWidget extends ConsumerWidget {
  final String difficulty;
  final VoidCallback? onRestart;
  final VoidCallback? onExit;

  const PauseOverlayWidget({super.key, required this.difficulty, this.onRestart, this.onExit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final stats = state.sessionStats;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pause_circle_outline, size: 44, color: Colors.white70)
                              .animate().fade(duration: 300.ms).scale(begin: Offset(0, 0), duration: 300.ms),
                          const SizedBox(height: 14),
                          const Text('PAUSA',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4))
                              .animate().fade(delay: 100.ms, duration: 300.ms).slideY(begin: -0.2, duration: 300.ms),
                          const SizedBox(height: 24),
                          _PauseStats(stats: stats)
                              .animate().fade(delay: 200.ms, duration: 300.ms).slideY(begin: 0.15, duration: 300.ms),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => ref.read(gameProvider.notifier).togglePause(),
                              icon: const Icon(Icons.play_arrow, size: 20),
                              label: const Text('CONTINUAR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ).animate().fade(delay: 300.ms, duration: 300.ms).slideX(begin: -0.1),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onRestart ?? (() => ref.read(gameProvider.notifier).restartCurrentBoard()),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('REINICIAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.amber.shade400),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ).animate().fade(delay: 350.ms, duration: 300.ms).slideX(begin: 0.1),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child:                           TextButton.icon(
                              onPressed: onExit,
                              icon: const Icon(Icons.exit_to_app, size: 18, color: Colors.redAccent),
                              label: const Text('SALIR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.redAccent)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ).animate().fade(delay: 400.ms, duration: 300.ms),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 22, color: Colors.white54),
                        onPressed: () => ref.read(gameProvider.notifier).togglePause(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseStats extends StatelessWidget {
  final SessionStats stats;
  const _PauseStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final h = stats.elapsedSeconds ~/ 3600;
    final m = (stats.elapsedSeconds % 3600) ~/ 60;
    final s = stats.elapsedSeconds % 60;
    final timeStr = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceAround,
        children: [
          _SmallStat(label: 'Tiempo', value: timeStr),
          _SmallStat(label: 'Errores', value: '${stats.errors}'),
          _SmallStat(label: 'Pistas', value: '${stats.remainingHints}'),
          _SmallStat(label: 'Completado', value: '${stats.completionPercent.toStringAsFixed(0)}%'),
          _SmallStat(label: 'Racha', value: 'x${stats.currentCombo}'),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  const _SmallStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}
