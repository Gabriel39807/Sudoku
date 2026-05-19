import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../application/game_provider.dart';

class KeypadWidget extends ConsumerWidget {
  const KeypadWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final lockedNumber = state.lockedNumber;
    final completedDigits = state.completedDigits;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 350
            ? 350.0
            : constraints.maxWidth;
        return SizedBox(
          width: maxWidth,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: List.generate(9, (index) {
              final number = index + 1;
              final digitComplete = (completedDigits[number] ?? 0) >= 9;
              return _KeypadButton(
                    number: number,
                    isLocked: lockedNumber == number,
                    isComplete: digitComplete,
                    onTap: digitComplete
                        ? null
                        : () =>
                            ref.read(gameProvider.notifier).inputNumber(number),
                    onLongHold: digitComplete
                        ? null
                        : () => ref
                            .read(gameProvider.notifier)
                            .toggleLockedNumber(number),
                  )
                  .animate()
                  .fade(delay: (50 * index).ms)
                  .scale(begin: const Offset(0.8, 0.8));
            }),
          ),
        );
      },
    );
  }
}

class _KeypadButton extends StatefulWidget {
  final int number;
  final bool isLocked;
  final bool isComplete;
  final VoidCallback? onTap;
  final VoidCallback? onLongHold;

  const _KeypadButton({
    required this.number,
    required this.isLocked,
    required this.isComplete,
    this.onTap,
    this.onLongHold,
  });

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  bool _isHovered = false;
  bool _isHolding = false;
  bool _didLongHold = false;
  Timer? _holdTimer;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    if (widget.onLongHold == null) return;
    _holdTimer?.cancel();
    _didLongHold = false;
    setState(() => _isHolding = true);
    _holdTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _didLongHold = true;
      setState(() => _isHolding = false);
      widget.onLongHold?.call();
    });
  }

  void _handleTap() {
    if (_didLongHold) {
      _didLongHold = false;
      return;
    }
    widget.onTap?.call();
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    if (_isHolding) {
      setState(() => _isHolding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).primaryColor;
    final borderColor = widget.isLocked
        ? activeColor
        : widget.isComplete
            ? Colors.greenAccent.withValues(alpha: 0.3)
            : const Color(0xFF2B2B2B);
    final bgColor = widget.isComplete
        ? Colors.greenAccent.withValues(alpha: 0.08)
        : widget.isLocked
            ? activeColor.withValues(alpha: 0.18)
            : _isHolding
                ? activeColor.withValues(alpha: 0.10)
                : Theme.of(context).cardTheme.color;
    final textColor = widget.isComplete
        ? Colors.greenAccent.withValues(alpha: 0.5)
        : widget.isLocked
            ? activeColor
            : activeColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered && !widget.isComplete ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: InkWell(
          onTap: widget.onTap != null ? _handleTap : null,
          onTapDown: widget.onTap != null ? (_) => _startHold() : null,
          onTapCancel: _cancelHold,
          onTapUp: (_) => _cancelHold(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.isLocked ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.number.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: widget.isComplete
                        ? FontWeight.w300
                        : FontWeight.bold,
                  ),
                ),
                if (widget.isLocked)
                  const Text(
                    'Modo rápido',
                    style: TextStyle(fontSize: 9, color: Colors.white70),
                  ),
                if (widget.isComplete && !widget.isLocked)
                  Text(
                    '${widget.number} listo',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.greenAccent.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
