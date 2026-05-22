import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../features/game/data/save/global_saved_game.dart';
import 'game_modal_card.dart';

Future<bool?> showSavedGameConflictDialog(
  BuildContext context,
  GlobalSavedGame savedGame,
  String newDiff,
) {
  final h = savedGame.elapsedSeconds ~/ 3600;
  final m = (savedGame.elapsedSeconds % 3600) ~/ 60;
  final timeStr = h > 0
      ? '${h}h ${m.toString().padLeft(2, '0')}m'
      : '${m.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  final now = DateTime.now();
  final dateStr = '${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')}/'
      '${now.year}';

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => GameModalCard(
      onClose: () => Navigator.pop(ctx, null),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.save_alt, size: 40, color: Colors.amber.shade300)
              .animate().fade(duration: 300.ms).scale(begin: Offset(0, 0), duration: 300.ms),
          const SizedBox(height: 16),
          const Text('PARTIDA GUARDADA DETECTADA',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 1.5))
              .animate().fade(delay: 100.ms, duration: 300.ms).slideY(begin: -0.2, duration: 300.ms),
          const SizedBox(height: 6),
          const Text('Tienes una partida guardada en curso',
              style: TextStyle(fontSize: 13, color: Colors.white60))
              .animate().fade(delay: 180.ms, duration: 300.ms),
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
                _Stat(label: savedGame.difficulty.toUpperCase(), icon: Icons.dashboard, value: ''),
                _Stat(label: 'Tiempo', icon: Icons.timer_outlined, value: timeStr),
                _Stat(label: 'Progreso', icon: Icons.pie_chart, value: '${savedGame.completionPercent}%'),
                _Stat(label: 'Errores', icon: Icons.cancel_outlined, value: '${savedGame.mistakes}'),
                _Stat(label: dateStr, icon: Icons.calendar_today, value: ''),
              ],
            ),
          ).animate().fade(delay: 250.ms, duration: 300.ms).slideY(begin: 0.15, duration: 300.ms),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('CONTINUAR PARTIDA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
              onPressed: () => Navigator.pop(ctx, false),
              icon: const Icon(Icons.refresh, size: 18, color: Colors.redAccent),
              label: const Text('EMPEZAR NUEVA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.redAccent)),
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
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('CANCELAR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54)),
            ),
          ).animate().fade(delay: 450.ms, duration: 300.ms),
        ],
      ),
    ),
  ).then((v) => v);
}

class _Stat extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  const _Stat({required this.label, required this.icon, required this.value});

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