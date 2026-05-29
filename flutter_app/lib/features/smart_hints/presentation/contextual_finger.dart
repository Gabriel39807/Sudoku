import 'dart:math' as math;
import 'package:flutter/material.dart';

class ContextualFinger extends StatefulWidget {
  final Offset targetCenter;
  final String tooltip;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const ContextualFinger({
    super.key,
    required this.targetCenter,
    required this.tooltip,
    this.onTap,
    this.onComplete,
  });

  @override
  State<ContextualFinger> createState() => _ContextualFingerState();
}

class _ContextualFingerState extends State<ContextualFinger>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _floatAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _floatAnim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeInOut)),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.15, curve: Curves.easeIn)),
    );

    _ctrl.forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final progress = _ctrl.value;
        final floatY = _floatAnim.value;

        // Bounce tap en t=0.3-0.5
        final tapPhase = (progress - 0.3).clamp(0.0, 0.2) / 0.2;
        final tapScale = 1.0 - (tapPhase * 0.15 * (1 - tapPhase));

        // Ripple radius (crece en t=0.5-0.7)
        final ripplePhase = (progress - 0.5).clamp(0.0, 0.25) / 0.25;
        final rippleRadius = ripplePhase * 28;
        final rippleAlpha = (1.0 - ripplePhase).clamp(0.0, 1.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Ripple ring
            if (ripplePhase > 0 && ripplePhase < 1)
              Positioned(
                left: widget.targetCenter.dx - rippleRadius,
                top: widget.targetCenter.dy - rippleRadius - 40,
                child: Opacity(
                  opacity: rippleAlpha * _fadeAnim.value,
                  child: Container(
                    width: rippleRadius * 2,
                    height: rippleRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5 * rippleAlpha),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

            // Floating finger
            Positioned(
              left: widget.targetCenter.dx - 14,
              top: widget.targetCenter.dy - 48 + floatY,
              child: Opacity(
                opacity: _fadeAnim.value * (1.0 - (progress > 0.85 ? (progress - 0.85) / 0.15 : 0)),
                child: Transform.scale(
                  scale: tapScale,
                  child: Container(
                    width: 28,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: _FingerPainter(),
                    ),
                  ),
                ),
              ),
            ),

            // Glow at target
            Positioned(
              left: widget.targetCenter.dx - 16,
              top: widget.targetCenter.dy - 16,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(
                              alpha: 0.15 + 0.1 * math.sin(_ctrl.value * math.pi * 4),
                            ),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Tooltip
            if (progress > 0.2)
              Positioned(
                left: widget.targetCenter.dx - 100,
                top: widget.targetCenter.dy - 90 + floatY,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: ((progress - 0.2) / 0.15).clamp(0.0, 1.0) *
                        (1.0 - (progress > 0.85 ? (progress - 0.85) / 0.15 : 0)),
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - ((progress - 0.2) / 0.15).clamp(0.0, 1.0))),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.tooltip,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FingerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..style = PaintingStyle.fill;

    // Simplified finger shape
    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.1)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.15, size.width * 0.15, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.5, size.width * 0.2, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.85, size.width * 0.4, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.95, size.width * 0.7, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.65, size.width * 0.7, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.25, size.width * 0.6, size.height * 0.15)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.05, size.width * 0.45, size.height * 0.05)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}