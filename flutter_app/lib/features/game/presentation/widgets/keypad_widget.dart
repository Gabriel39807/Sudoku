import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../application/game_provider.dart';

class KeypadWidget extends ConsumerWidget {
  const KeypadWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockedNumber = ref.watch(
      gameProvider.select((state) => state.lockedNumber),
    );
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
              return _KeypadButton(
                    number: number,
                    isLocked: lockedNumber == number,
                    onTap: () =>
                        ref.read(gameProvider.notifier).inputNumber(number),
                    onLongHold: () => ref
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
  final VoidCallback onTap;
  final VoidCallback onLongHold;

  const _KeypadButton({
    required this.number,
    required this.isLocked,
    required this.onTap,
    required this.onLongHold,
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
    _holdTimer?.cancel();
    _didLongHold = false;
    setState(() => _isHolding = true);
    _holdTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _didLongHold = true;
      setState(() => _isHolding = false);
      widget.onLongHold();
    });
  }

  void _handleTap() {
    if (_didLongHold) {
      _didLongHold = false;
      return;
    }
    widget.onTap();
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
    final borderColor = widget.isLocked ? activeColor : const Color(0xFF2B2B2B);
    final bgColor = widget.isLocked
        ? activeColor.withValues(alpha: 0.18)
        : _isHolding
        ? activeColor.withValues(alpha: 0.10)
        : Theme.of(context).cardTheme.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: InkWell(
          onTap: _handleTap,
          onTapDown: (_) => _startHold(),
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
                    color: activeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.isLocked)
                  const Text(
                    'Modo rápido',
                    style: TextStyle(fontSize: 9, color: Colors.white70),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
