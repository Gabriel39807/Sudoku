import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/game_modal_card.dart';
import '../../../shared/widgets/gameplay_overlay_guard.dart';

Future<bool> showDailyExitDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => GameplayOverlayGuard(
      child: GameModalCard(
        onClose: () => Navigator.pop(ctx, false),
        child: _DailyExitBody(),
      ),
    ),
  );
  return result ?? false;
}

class _DailyExitBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.exit_to_app, size: 40, color: Colors.white70)
            .animate().fade(duration: 300.ms).scale(begin: Offset(0, 0), duration: 300.ms),
        const SizedBox(height: 16),
        Text('SALIR DEL DESAFÍO',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2,
                color: Theme.of(context).primaryColor))
            .animate().fade(delay: 100.ms, duration: 300.ms).slideY(begin: -0.2, duration: 300.ms),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: const Text('Tu progreso se guardará automáticamente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white70))
        ).animate().fade(delay: 200.ms, duration: 300.ms).slideY(begin: 0.15, duration: 300.ms),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('SALIR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.redAccent.shade200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ).animate().fade(delay: 300.ms, duration: 300.ms).slideX(begin: -0.1),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('CONTINUAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ).animate().fade(delay: 350.ms, duration: 300.ms).slideX(begin: 0.1),
      ],
    );
  }
}
