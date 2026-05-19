import 'package:flutter/material.dart';
import '../../domain/difficulty_model.dart';

class DifficultyCard extends StatefulWidget {
  final DifficultyModel model;
  final VoidCallback onTap;

  const DifficultyCard({
    super.key,
    required this.model,
    required this.onTap,
  });

  @override
  State<DifficultyCard> createState() => _DifficultyCardState();
}

class _DifficultyCardState extends State<DifficultyCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.model.state == DifficultyState.locked;
    final isHidden = widget.model.state == DifficultyState.hidden;

    Widget content = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isLocked || isHidden) ? null : widget.onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForDifficulty(widget.model.id),
                  size: 64,
                  color: _getColorForDifficulty(widget.model.id, context),
                ),
                const SizedBox(height: 16),
                Text(
                  isHidden ? '?????' : widget.model.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getColorForDifficulty(widget.model.id, context),
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isHidden ? '?????' : widget.model.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isHidden) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.help_outline, size: 80, color: Colors.white24),
            ),
          ),
        ],
      );
    } else if (isLocked) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 48, color: Colors.white54),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    widget.model.unlockRequirement ?? 'Locked',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered && !isLocked && !isHidden ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: content,
      ),
    );
  }

  IconData _getIconForDifficulty(String id) {
    switch (id) {
      case 'EASY':
        return Icons.sentiment_satisfied;
      case 'INTERMEDIATE':
        return Icons.psychology;
      case 'HARD':
        return Icons.local_fire_department;
      case 'EXPERT':
        return Icons.diamond;
      case 'EVIL':
        return Icons.warning;
      case 'MYTHIC':
        return Icons.star;
      default:
        return Icons.extension;
    }
  }

  Color _getColorForDifficulty(String id, BuildContext context) {
    if (id == 'MYTHIC') return Theme.of(context).colorScheme.secondary;
    return Theme.of(context).primaryColor;
  }
}
