import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../application/game_provider.dart';

class DefeatScreen extends ConsumerWidget {
  final String difficulty;
  const DefeatScreen({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.redAccent)
                    .animate().fade(duration: 600.ms).scale(begin: const Offset(0.5, 0.5)),
                const SizedBox(height: 24),
                const Text(
                  'DERROTA',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 4),
                ).animate().fade(delay: 200.ms),
                const SizedBox(height: 12),
                Text(
                  'Has alcanzado el máximo de errores permitidos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
                ).animate().fade(delay: 400.ms),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.replay, size: 18),
                        label: const Text('REINTENTAR', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                        ),
                        onPressed: () {
                          context.pop();
                          ref.read(gameProvider.notifier).init(difficulty);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.menu, size: 18),
                        label: const Text('MENÚ', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        onPressed: () {
                          context.pop();
                          context.pop();
                        },
                      ),
                    ),
                  ],
                ).animate().fade(delay: 600.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
