import 'dart:math';
import 'package:flutter/material.dart';
import '../domain/streak_tier.dart';

class StreakButton extends StatefulWidget {
  final int streak;
  final bool completedToday;
  final VoidCallback onTap;

  const StreakButton({
    super.key,
    required this.streak,
    required this.completedToday,
    required this.onTap,
  });

  @override
  State<StreakButton> createState() => _StreakButtonState();
}

class _StreakButtonState extends State<StreakButton> with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _breathCtrl;
  late StreakTier _tier;

  @override
  void initState() {
    super.initState();
    _tier = StreakTier.forStreak(widget.streak);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _breathCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StreakButton old) {
    super.didUpdateWidget(old);
    _tier = StreakTier.forStreak(widget.streak);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _breathCtrl.dispose();
    super.dispose();
  }

  bool get _hasLife => widget.streak > 0 || widget.completedToday;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowCtrl, _breathCtrl]),
      builder: (context, _) {
        final glow = _glowCtrl.value;
        final breath = _breathCtrl.value;

        final glowOpacity = _hasLife
            ? _tier.glowIntensity * (0.4 + glow * 0.4)
            : 0.05 + glow * 0.05;

        return Tooltip(
          message: _hasLife
              ? 'Racha activa: ${widget.streak} día${widget.streak == 1 ? '' : 's'}'
              : 'Sin racha activa',
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasLife
                    ? const Color(0xFF1A1A2E).withValues(alpha: 0.85)
                    : const Color(0xFF121212).withValues(alpha: 0.85),
                border: Border.all(
                  color: _hasLife
                      ? _tier.accentColor.withValues(alpha: 0.3 + glow * 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _tier.glowColor.withValues(alpha: glowOpacity * 0.6),
                    blurRadius: 8 + breath * 4,
                    spreadRadius: 1 + glow * 1.5,
                  ),
                  BoxShadow(
                    color: _tier.flameColor.withValues(alpha: glowOpacity * 0.3),
                    blurRadius: 16 + breath * 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: _buildButtonContent(breath),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent(double breath) {
    if (!_hasLife) {
      return const Center(
        child: Text('🔥', style: TextStyle(fontSize: 18, color: Colors.white24)),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 20,
          child: Center(
            child: Text('🔥', style: TextStyle(
              fontSize: 14 * _tier.flameScale,
            )),
          ),
        ),
        Text(
          '${widget.streak}',
          style: TextStyle(
            fontSize: _tier.label == 'Mítico' ? 12 : 11,
            fontWeight: FontWeight.w900,
            color: _tier.textColor,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: _tier.glowColor.withValues(alpha: 0.3 + breath * 0.2),
                blurRadius: 4 + breath * 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StreakGlowRing extends StatefulWidget {
  final StreakTier tier;
  final double radius;
  final bool active;

  const StreakGlowRing({
    super.key,
    required this.tier,
    this.radius = 30,
    this.active = true,
  });

  @override
  State<StreakGlowRing> createState() => _StreakGlowRingState();
}

class _StreakGlowRingState extends State<StreakGlowRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || widget.tier.glowIntensity < 0.3) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final rot = _ctrl.value * 2 * pi;
        final opacity = 0.12 + 0.08 * sin(_ctrl.value * 2 * pi);

        return Transform.rotate(
          angle: rot,
          child: CustomPaint(
            size: Size(widget.radius * 2, widget.radius * 2),
            painter: _GlowRingPainter(
              color: widget.tier.accentColor,
              opacity: opacity,
            ),
          ),
        );
      },
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _GlowRingPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: size.center(Offset.zero), width: size.width - 4, height: size.height - 4),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, paint);

    final dashPaint = Paint()
      ..color = color.withValues(alpha: opacity * 1.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 4, dashPaint);
  }

  @override
  bool shouldRepaint(_GlowRingPainter old) => old.opacity != opacity || old.color != color;
}
