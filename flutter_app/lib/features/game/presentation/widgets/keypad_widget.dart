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
        final h = constraints.maxHeight;
        final keyHeight = (h * 0.24).clamp(48.0, 72.0);
        final fontSize = (keyHeight * 0.35).clamp(16.0, 26.0);
        const spacing = 8.0;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (row) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: spacing / 2),
                child: Row(
                  children: List.generate(3, (col) {
                    final number = row * 3 + col + 1;
                    final digitComplete = (completedDigits[number] ?? 0) >= 9;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                        child: SizedBox(
                          height: keyHeight,
                          child: _KeypadButton(
                            number: number,
                            fontSize: fontSize,
                            isLocked: lockedNumber == number,
                            lockModeActive: lockedNumber != null,
                            isComplete: digitComplete,
                            onTap: digitComplete
                                ? null
                                : () {
                                    if (lockedNumber != null && lockedNumber != number) {
                                      ref.read(gameProvider.notifier).toggleLockedNumber(number);
                                    } else if (lockedNumber == null) {
                                      ref.read(gameProvider.notifier).inputNumber(number);
                                    }
                                  },
                            onLongHold: digitComplete
                                ? null
                                : () => ref
                                    .read(gameProvider.notifier)
                                    .toggleLockedNumber(number),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _KeypadButton extends StatefulWidget {
  final int number;
  final double fontSize;
  final bool isLocked;
  final bool lockModeActive;
  final bool isComplete;
  final VoidCallback? onTap;
  final VoidCallback? onLongHold;

  const _KeypadButton({
    required this.number,
    required this.fontSize,
    required this.isLocked,
    required this.lockModeActive,
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
    _holdTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _didLongHold = true;
      setState(() => _isHolding = false);
      widget.onLongHold?.call();
    });
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

    final lockFontSize = widget.fontSize * 1.15;
    final usedFontSize = widget.isLocked ? lockFontSize : widget.fontSize;
    final subFontSize = widget.fontSize * 0.38;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _startHold() : null,
        onTapUp: widget.onTap != null
            ? (_) {
                _cancelHold();
                if (!_didLongHold) {
                  widget.onTap?.call();
                }
                _didLongHold = false;
              }
            : null,
        onTapCancel: widget.onTap != null
            ? () {
                _cancelHold();
                _didLongHold = false;
              }
            : null,
        child: AnimatedScale(
          scale: _isHovered && !widget.isComplete ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: 300.ms,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.isLocked ? 2 : 1,
              ),
              boxShadow: widget.isLocked
                  ? [BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)]
                  : null,
            ),
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: 200.ms,
                    style: TextStyle(
                      fontSize: usedFontSize,
                      color: textColor,
                      fontWeight: widget.isComplete
                          ? FontWeight.w300
                          : widget.isLocked
                              ? FontWeight.w900
                              : FontWeight.bold,
                    ),
                    child: Text(widget.number.toString())
                        .animate(target: widget.isLocked ? 1 : 0)
                        .scaleXY(begin: 0.85, end: 1, duration: 300.ms, curve: Curves.easeOutBack),
                  ),
                  if (widget.isLocked)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'FIJADO',
                        style: TextStyle(fontSize: subFontSize * 0.85, color: activeColor, fontWeight: FontWeight.bold),
                      ),
                    ).animate().fade(duration: 300.ms).scale(begin: Offset(0, 0)),
                  if (widget.isComplete && !widget.isLocked)
                    Text(
                      '${widget.number} listo',
                      style: TextStyle(
                        fontSize: subFontSize,
                        color: Colors.greenAccent.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}