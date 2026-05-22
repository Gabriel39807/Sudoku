import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GameModalCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry padding;

  const GameModalCard({
    super.key,
    required this.child,
    this.onClose,
    this.padding = const EdgeInsets.fromLTRB(28, 28, 28, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetAnimationDuration: 300.ms,
      insetAnimationCurve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: padding,
              child: child.animate().fade(duration: 300.ms).scale(
                begin: const Offset(0.92, 0.92),
                duration: 350.ms,
                curve: Curves.easeOutCubic,
              ),
            ),
            if (onClose != null)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 22, color: Colors.white54),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    ).animate().fade(duration: 200.ms, curve: Curves.easeOut);
  }
}
