import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/game/application/game_provider.dart';
import '../../features/game/domain/game_state.dart';
import 'game_modal_card.dart';
import 'gameplay_overlay_guard.dart';

enum GameExitAction { save, abandon, cancel }

Future<GameExitAction?> showGameExitDialog(BuildContext context, WidgetRef ref, String difficulty) async {
  final state = ref.read(gameProvider);

  return showDialog<GameExitAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => GameplayOverlayGuard(
      child: GameModalCard(
        onClose: () => Navigator.pop(ctx, GameExitAction.cancel),
        child: _GameExitBody(
          state: state,
          onSave: () => Navigator.pop(ctx, GameExitAction.save),
          onAbandon: () => Navigator.pop(ctx, GameExitAction.abandon),
        ),
      ),
    ),
  );
}

class _GameExitBody extends StatelessWidget {
  final GameState state;
  final VoidCallback onSave;
  final VoidCallback onAbandon;

  const _GameExitBody({
    required this.state,
    required this.onSave,
    required this.onAbandon,
  });

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    final diff = session?.difficulty ?? '';
    final elapsed = state.elapsedSeconds;
    final errors = state.errors;
    final hintsUsed = state.usedHints;
    final empty = session == null ? 81 : session.currentBoard.where((v) => v == 0).length;
    final pct = session == null ? 0 : ((81 - empty) * 100 / 81).round();
    final h = elapsed ~/ 3600;
    final m = (elapsed % 3600) ~/ 60;
    final s = elapsed % 60;
    final timeStr = h > 0
        ? '${h}h ${m.toString().padLeft(2, '0')}m'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.exit_to_app, size: 40, color: Colors.amber.shade300)
            .animate().fade(duration: 300.ms).scale(begin: const Offset(0, 0), duration: 300.ms),
        const SizedBox(height: 16),
        Text('SALIR DE PARTIDA',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2,
                color: Colors.amber.shade200))
            .animate().fade(delay: 100.ms, duration: 300.ms).slideY(begin: -0.2, duration: 300.ms),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: diff.toUpperCase(), icon: Icons.dashboard, value: ''),
              _StatItem(label: 'Tiempo', icon: Icons.timer_outlined, value: timeStr),
              _StatItem(label: 'Progreso', icon: Icons.pie_chart, value: '$pct%'),
              _StatItem(label: 'Errores', icon: Icons.cancel_outlined, value: '$errors'),
              _StatItem(label: 'Pistas', icon: Icons.lightbulb_outline, value: '$hintsUsed'),
            ],
          ),
        ).animate().fade(delay: 200.ms, duration: 300.ms).slideY(begin: 0.15, duration: 300.ms),
        const SizedBox(height: 16),
        Text('Puedes guardar tu progreso antes de salir',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)))
            .animate().fade(delay: 300.ms, duration: 300.ms),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('GUARDAR PARTIDA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ).animate().fade(delay: 350.ms, duration: 300.ms).slideX(begin: -0.1),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAbandon,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('ABANDONAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.redAccent.shade200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ).animate().fade(delay: 400.ms, duration: 300.ms).slideX(begin: 0.1),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CONTINUAR JUGANDO',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54)),
          ),
        ).animate().fade(delay: 450.ms, duration: 300.ms),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;

  const _StatItem({required this.label, required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(height: 6),
        if (value.isNotEmpty)
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}
