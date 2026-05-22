import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../application/game_provider.dart';
import '../../domain/game_state.dart';
import '../../../settings/application/settings_provider.dart';
import '../../../settings/domain/settings_model.dart';
import '../../../../shared/widgets/game_modal_card.dart';

class ActionsWidget extends ConsumerWidget {
  const ActionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pencilMode = ref.watch(
      gameProvider.select((state) => state.pencilMode),
    );
    final advancedNotes = ref.watch(
      gameProvider.select((state) => state.advancedNotesEnabled),
    );
    final canUndo = ref.watch(
      gameProvider.select((state) => state.undoStack.isNotEmpty),
    );
    final remainingHints = ref.watch(
      gameProvider.select((state) => state.remainingHints),
    );
    final assistMode = ref.watch(
      settingsProvider.select((s) => s.assistMode),
    );
    final isExtreme = assistMode == AssistMode.extreme;
    final isExpert = assistMode == AssistMode.expert;
    final showHints = remainingHints != 0 && !isExpert && !isExtreme;
    final hintLabel = remainingHints < 0
        ? 'PISTA ILIM'
        : 'PISTA $remainingHints';

    final buttons = <Widget>[
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
        icon: Icons.auto_awesome,
        label: 'ADV',
        isActive: advancedNotes,
        onTap: () async {
          final ok = await ref.read(gameProvider.notifier).toggleAdvancedNotes();
          if (!ok && context.mounted) {
            _showNoAvancedNotesDialog(context);
          }
        },
      ),
      if (showHints)
        _ActionButton(
          icon: Icons.lightbulb_outline,
          label: hintLabel,
          onTap: () async {
            final result = await ref.read(gameProvider.notifier).useHint();
            if (result == HintResult.noSelection) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selecciona una casilla')),
              );
            } else if (result == HintResult.noHints && context.mounted) {
              _showNoHintsDialog(context);
            }
          },
        ),
      if (!isExtreme)
        _ActionButton(
          icon: Icons.pause,
          label: 'PAUSA',
          onTap: () => ref.read(gameProvider.notifier).togglePause(),
        ),
    ];

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: buttons,
        ),
      ),
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
        : isActive
        ? Theme.of(context).primaryColor
        : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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

void _showNoHintsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => GameModalCard(
      onClose: () => Navigator.pop(ctx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline, size: 40, color: Theme.of(context).primaryColor)
              .animate().fade().scale(begin: Offset(0, 0)),
          const SizedBox(height: 16),
          const Text('SIN PISTAS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('No te quedan pistas disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/shop');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('COMPRAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('CANCELAR', style: TextStyle(fontSize: 13, color: Colors.white54)),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showNoAvancedNotesDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => GameModalCard(
      onClose: () => Navigator.pop(ctx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 40, color: Theme.of(context).primaryColor)
              .animate().fade().scale(begin: Offset(0, 0)),
          const SizedBox(height: 16),
          const Text('SIN NOTAS AVANZADAS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('No te quedan notas avanzadas.\nCompra más en la tienda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white54)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/shop');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('COMPRAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('CANCELAR', style: TextStyle(fontSize: 13, color: Colors.white54)),
            ),
          ),
        ],
      ),
    ),
  );
}