import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../domain/trophy_collection.dart';
import '../../../shared/widgets/game_modal_card.dart';

Future<void> showTrophyModal(BuildContext context) async {
  final collection = await TrophyCollection.load();
  final now = DateTime.now();
  final totalDays = collection.daysInMonth(now.year, now.month);
  final completed = collection.countForMonth(now.year, now.month);

  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (ctx) => GameModalCard(
      onClose: () => Navigator.pop(ctx),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: _TrophyContent(
        year: now.year,
        month: now.month,
        totalDays: totalDays,
        completed: completed,
        collection: collection,
        onClose: () => Navigator.pop(ctx),
      ),
    ),
  );
}

class _TrophyContent extends StatelessWidget {
  final int year;
  final int month;
  final int totalDays;
  final int completed;
  final TrophyCollection collection;
  final VoidCallback onClose;

  const _TrophyContent({
    required this.year,
    required this.month,
    required this.totalDays,
    required this.completed,
    required this.collection,
    required this.onClose,
  });

  static const _monthNames = [
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE',
  ];

  static const _dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final monthName = _monthNames[month - 1];
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon ... 7=Sun
    final today = DateTime.now().day;
    final ratio = totalDays > 0 ? completed / totalDays : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.emoji_events, size: 36, color: Colors.amber)
            .animate().fade(duration: 400.ms).scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack),
        const SizedBox(height: 8),
        Text('TROFEOS',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 3, color: Colors.amber))
            .animate().fade(delay: 100.ms, duration: 400.ms),
        const SizedBox(height: 4),
        Text('$monthName $year',
            style: const TextStyle(fontSize: 13, color: Colors.white54))
            .animate().fade(delay: 150.ms, duration: 400.ms),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: ratio),
            duration: 600.ms,
            curve: Curves.easeOutCubic,
            builder: (ctx, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ).animate().fade(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 4),
        Text('$completed / $totalDays',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54))
            .animate().fade(delay: 250.ms, duration: 400.ms),
        const SizedBox(height: 16),
        // Day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _dayNames.map((d) => SizedBox(
            width: 32,
            child: Text(d, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.3))),
          )).toList(),
        ),
        const SizedBox(height: 4),
        // Calendar grid — up to 6 rows
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(42, (i) {
              final day = i - firstWeekday + 2;
              if (day < 1 || day > totalDays) return const SizedBox.shrink();
              final date = DateTime(year, month, day);
              final isToday = day == today;
              final done = collection.isCompleted(date);
              return _DayCell(day: day, isToday: isToday, completed: done);
            }),
          ),
        ).animate().fade(delay: 300.ms, duration: 400.ms),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onClose,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('CERRAR',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool completed;

  const _DayCell({required this.day, required this.isToday, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed
            ? Colors.amber.withValues(alpha: 0.15)
            : isToday
                ? Colors.white.withValues(alpha: 0.05)
                : null,
        border: isToday && !completed
            ? Border.all(color: Colors.white.withValues(alpha: 0.15))
            : null,
      ),
      child: Center(
        child: completed
            ? const Icon(Icons.emoji_events, size: 18, color: Colors.amber)
                .animate().scale(begin: const Offset(0.5, 0.5), duration: 300.ms, curve: Curves.easeOutBack)
            : Text('$day',
                style: TextStyle(
                  fontSize: 11,
                  color: isToday ? Colors.white54 : Colors.white24,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                )),
      ),
    );
  }
}
