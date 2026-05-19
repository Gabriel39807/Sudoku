import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/game_provider.dart';

class ActionsWidget extends ConsumerWidget {
  const ActionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pencilMode = ref.watch(gameProvider.select((state) => state.pencilMode));
    final canUndo = ref.watch(gameProvider.select((state) => state.undoStack.isNotEmpty));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.undo,
          label: 'DESHACER',
          onTap: canUndo ? () => ref.read(gameProvider.notifier).undo() : null,
          isDisabled: !canUndo,
        ),
        _ActionButton(
          icon: Icons.backspace_outlined,
          label: 'BORRAR',
          onTap: () => ref.read(gameProvider.notifier).erase(),
        ),
        _ActionButton(
          icon: Icons.edit,
          label: 'PENCIL',
          isActive: pencilMode,
          onTap: () => ref.read(gameProvider.notifier).togglePencil(),
        ),
        _ActionButton(
          icon: Icons.pause,
          label: 'PAUSA',
          onTap: () => ref.read(gameProvider.notifier).togglePause(),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isDisabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDisabled 
        ? Colors.white24 
        : isActive ? Theme.of(context).primaryColor : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
