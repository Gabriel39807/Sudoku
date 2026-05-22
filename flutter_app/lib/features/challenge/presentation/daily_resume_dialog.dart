import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum DailyResumeAction { resume, restart, goHome }

Future<DailyResumeAction> showDailyResumeDialog(
  BuildContext context,
  Map<String, dynamic> savedData,
) {
  final elapsedMs = savedData['elapsed'] as int? ?? 0;
  final mistakes = savedData['mistakes'] as int? ?? 0;
  final currentBoard = (savedData['currentBoard'] as List?)?.cast<int>() ?? <int>[];
  final empty = currentBoard.where((v) => v == 0).length;
  final completionPercent = currentBoard.length == 81
      ? ((81 - empty) * 100 / 81).round()
      : 0;

  final h = elapsedMs ~/ 3600000;
  final m = (elapsedMs % 3600000) ~/ 60000;
  final s = (elapsedMs % 60000) ~/ 1000;
  final timeStr =
      h > 0
          ? '${h}h ${m.toString().padLeft(2, '0')}m'
          : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

  final now = DateTime.now();
  final dateStr = '${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')}/'
      '${now.year}';

  return showDialog<DailyResumeAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: Theme.of(ctx).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_outlined, size: 48,
                    color: Theme.of(ctx).primaryColor)
                    .animate().fade(duration: 400.ms).scale(duration: 400.ms),
                const SizedBox(height: 16),
                Text('DESAFÍO DIARIO EN CURSO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2,
                        color: Theme.of(ctx).primaryColor))
                    .animate().fade(delay: 150.ms, duration: 400.ms).slideY(begin: -0.2, duration: 400.ms),
                const SizedBox(height: 8),
                const Text('Continúa tu progreso o reinicia el tablero del día',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white60))
                    .animate().fade(delay: 250.ms, duration: 400.ms),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: dateStr, icon: Icons.calendar_today, value: ''),
                      _StatItem(label: 'Progreso', icon: Icons.pie_chart, value: '$completionPercent%'),
                      _StatItem(label: 'Tiempo', icon: Icons.timer_outlined, value: timeStr),
                      _StatItem(label: 'Errores', icon: Icons.cancel_outlined, value: '$mistakes'),
                    ],
                  ),
                ).animate().fade(delay: 350.ms, duration: 400.ms).slideY(begin: 0.2, duration: 400.ms),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, DailyResumeAction.resume),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('CONTINUAR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ).animate().fade(delay: 450.ms, duration: 300.ms).slideX(begin: -0.1),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, DailyResumeAction.restart),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.amber.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('REINICIAR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.amberAccent)),
                  ),
                ).animate().fade(delay: 500.ms, duration: 300.ms).slideX(begin: 0.1),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, size: 22, color: Colors.white54),
              onPressed: () => Navigator.pop(ctx, DailyResumeAction.goHome),
            ),
          ),
        ],
      ),
    ),
  ).then((v) => v ?? DailyResumeAction.goHome);
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
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}
