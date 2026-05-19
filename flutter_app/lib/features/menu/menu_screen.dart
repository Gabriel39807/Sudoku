import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SUDOKU',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
            ).animate().fade(duration: 500.ms).scale(curve: Curves.easeOutBack),
            const SizedBox(height: 8),
            Text(
              'Classic Journey',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.5),
            const SizedBox(height: 64),
            _MenuButton('JUGAR', () => context.push('/difficulty')),
            _MenuButton('ESTADÍSTICAS', () => context.push('/stats')),
            _MenuButton('EVENTOS', () {}),
            _MenuButton('PERSONALIZAR', () {}),
            _MenuButton('CONFIGURACIÓN', () => context.push('/settings')),
          ].animate(interval: 100.ms).fade(duration: 300.ms).slideY(begin: 0.2),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _MenuButton(this.text, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: 250,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(text),
        ),
      ),
    );
  }
}
