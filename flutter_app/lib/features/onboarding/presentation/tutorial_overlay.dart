import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TutorialOverlay extends StatelessWidget {
  final int level;
  final VoidCallback? onDismiss;

  const TutorialOverlay({super.key, required this.level, this.onDismiss});

  static const lessons = {
    1: _TutorialLesson(
      title: 'Coloca un número',
      text: 'Toca una celda vacía,\nluego el número en el teclado.',
      mentorTip: 'Bien.',
    ),
    2: _TutorialLesson(
      title: 'Filas y columnas',
      text: 'Cada número aparece\nuna vez por fila y columna.',
      mentorTip: 'Las líneas guían el camino.',
    ),
    3: _TutorialLesson(
      title: 'Bloques',
      text: 'También una vez por\ncada bloque 2×2.',
      mentorTip: 'El bloque completa la regla.',
    ),
    4: _TutorialLesson(
      title: 'Notas',
      text: 'Usa notas para marcar\nposibles candidatos.',
      mentorTip: 'Anotar es pensar.',
    ),
    5: _TutorialLesson(
      title: 'Flujo completo',
      text: 'Combina todo:\nnotas, filas, bloques.',
      mentorTip: 'Ahora entiendes el patrón.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final lesson = lessons[level];
    if (lesson == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => onDismiss?.call(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Stack(
          children: [
            // Spotlight hole
            Center(
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.95),
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            // Lesson card at bottom
            Positioned(
              left: 0, right: 0, bottom: 140,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1040).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF9C4DFF).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(lesson.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Color(0xFF9C4DFF),
                          )).animate().fade(duration: 400.ms).slideY(begin: 0.2),
                      const SizedBox(height: 10),
                      Text(lesson.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.white,
                          )).animate().fade(delay: 200.ms, duration: 400.ms),
                      const SizedBox(height: 14),
                      // Mentor phrase
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: Colors.amber.shade300),
                            const SizedBox(width: 6),
                            Text(lesson.mentorTip,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade200,
                                  fontStyle: FontStyle.italic,
                                )),
                          ],
                        ),
                      ).animate().fade(delay: 500.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialLesson {
  final String title;
  final String text;
  final String mentorTip;

  const _TutorialLesson({
    required this.title,
    required this.text,
    required this.mentorTip,
  });
}
