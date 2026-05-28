import 'dart:math';
import 'package:flutter/material.dart';
import '../domain/streak_tier.dart';

class StreakFlame extends StatefulWidget {
  final StreakTier tier;
  final double size;
  final bool showCount;
  final int count;
  final bool completedToday;

  const StreakFlame({
    super.key,
    required this.tier,
    this.size = 24,
    this.showCount = false,
    this.count = 0,
    this.completedToday = false,
  });

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame> with TickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late AnimationController _flickerCtrl;
  late AnimationController _popCtrl;
  late StreakTier _tier;

  @override
  void initState() {
    super.initState();
    _tier = widget.tier;

    _breathCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _flickerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _popCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void didUpdateWidget(StreakFlame old) {
    super.didUpdateWidget(old);
    _tier = widget.tier;
    if (old.count < widget.count && widget.count > 0) {
      _popCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _flickerCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showGlow = _tier.min > 0 || widget.completedToday;

    return AnimatedBuilder(
      animation: Listenable.merge([_breathCtrl, _flickerCtrl, _popCtrl]),
      builder: (context, _) {
        final breath = _breathCtrl.value;
        final flicker = _flickerCtrl.value;
        final pop = _popCtrl.value;

        final scale = 1.0 + breath * _tier.pulseSpeed * 0.03;
        final popScale = pop > 0
            ? (pop > 0.5 ? 1.0 + (1.0 - pop) * 0.15 : 1.0 + pop * 0.3)
            : 1.0;
        final glowOpacity = showGlow
            ? _tier.glowIntensity * (0.7 + breath * 0.3)
            : 0.0;

        final children = <Widget>[];

        if (showGlow) {
          children.addAll(_buildGlowLayers(glowOpacity, breath, flicker));
        }

        children.add(
          Center(
            child: Transform.scale(
              scale: scale * popScale * _tier.flameScale,
              child: widget.showCount
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔥', style: TextStyle(fontSize: widget.size * 0.55)),
                        Text(
                          '${widget.count}',
                          style: TextStyle(
                            fontSize: widget.size * 0.28,
                            fontWeight: FontWeight.w900,
                            color: _tier.textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    )
                  : Text('🔥', style: TextStyle(fontSize: widget.size * _tier.flameScale)),
            ),
          ),
        );

        if (_tier.hasSparkles && showGlow) {
          children.addAll(_buildSparkles(breath));
        }

        return SizedBox(
          width: widget.size * 2.2,
          height: widget.size * 2.2,
          child: Stack(
            clipBehavior: Clip.none,
            children: children,
          ),
        );
      },
    );
  }

  List<Widget> _buildGlowLayers(double opacity, double breath, double flicker) {
    final blur1 = 8.0 + breath * 4.0 + flicker * 2.0;
    final blur2 = 16.0 + breath * 6.0;
    final blur3 = 28.0 + breath * 8.0;

    return [
      if (opacity > 0.1)
        Positioned.fill(
          child: Center(
            child: Container(
              width: widget.size * 2.0,
              height: widget.size * 2.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _tier.glowColor.withValues(alpha: opacity * 0.15),
                    blurRadius: blur3,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: _tier.flameColor.withValues(alpha: opacity * 0.2),
                    blurRadius: blur2,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: _tier.glowColor.withValues(alpha: opacity * 0.3),
                    blurRadius: blur1,
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildSparkles(double breath) {
    final rng = Random(widget.count);
    return List.generate(4, (i) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = widget.size * (0.8 + rng.nextDouble() * 0.5 + breath * 0.15);
      final dx = cos(angle) * dist;
      final dy = sin(angle) * dist;
      final sparkleOpacity = (0.3 + rng.nextDouble() * 0.5) * (0.6 + breath * 0.4);
      final sparkleSize = 2.0 + rng.nextDouble() * 2.0;

      return Positioned(
        left: widget.size * 1.1 + dx,
        top: widget.size * 1.1 + dy,
        child: Opacity(
          opacity: sparkleOpacity.clamp(0.0, 1.0),
          child: Container(
            width: sparkleSize,
            height: sparkleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _tier.accentColor,
              boxShadow: [
                BoxShadow(
                  color: _tier.accentColor.withValues(alpha: 0.6),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class StreakFlameHero extends StatefulWidget {
  final StreakTier tier;
  final int streak;
  final bool completedToday;

  const StreakFlameHero({
    super.key,
    required this.tier,
    required this.streak,
    this.completedToday = false,
  });

  @override
  State<StreakFlameHero> createState() => _StreakFlameHeroState();
}

class _StreakFlameHeroState extends State<StreakFlameHero>
    with TickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late AnimationController _flickerCtrl;
  late AnimationController _auraCtrl;
  late StreakTier _tier;

  @override
  void initState() {
    super.initState();
    _tier = widget.tier;
    _breathCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
    _flickerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _auraCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
  }

  @override
  void didUpdateWidget(StreakFlameHero old) {
    super.didUpdateWidget(old);
    _tier = widget.tier;
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _flickerCtrl.dispose();
    _auraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showGlow = _tier.min > 0 || widget.completedToday;

    return AnimatedBuilder(
      animation: Listenable.merge([_breathCtrl, _flickerCtrl, _auraCtrl]),
      builder: (context, _) {
        final breath = _breathCtrl.value;
        final flicker = _flickerCtrl.value;
        final aura = _auraCtrl.value;
        final glowOpacity = showGlow
            ? _tier.glowIntensity * (0.65 + breath * 0.35)
            : 0.0;

        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_tier.hasAura && showGlow)
                Positioned.fill(
                  child: Center(
                    child: Transform.rotate(
                      angle: aura * 2 * pi,
                      child: Container(
                        width: 120 + breath * 10,
                        height: 120 + breath * 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _tier.accentColor.withValues(
                              alpha: 0.15 + 0.1 * sin(aura * 2 * pi),
                            ),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _tier.glowColor.withValues(alpha: 0.1 * (0.5 + breath * 0.5)),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (showGlow)
                ..._buildHeroGlow(glowOpacity, breath, flicker),
              Transform.scale(
                scale: 1.0 + breath * _tier.pulseSpeed * 0.025,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 52 * _tier.flameScale)),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.streak}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: _tier.textColor,
                        letterSpacing: -2,
                        shadows: [
                          Shadow(
                            color: _tier.glowColor.withValues(alpha: glowOpacity * 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_tier.hasSparkles && showGlow)
                ..._buildHeroSparkles(breath, flicker),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildHeroGlow(double opacity, double breath, double flicker) {
    return [
      Positioned.fill(
        child: Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _tier.glowColor.withValues(alpha: opacity * 0.12),
                  blurRadius: 50 + breath * 10,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: _tier.flameColor.withValues(alpha: opacity * 0.18),
                  blurRadius: 30 + breath * 8 + flicker * 4,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: _tier.glowColor.withValues(alpha: opacity * 0.25),
                  blurRadius: 16 + breath * 5,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildHeroSparkles(double breath, double flicker) {
    final rng = Random(widget.streak);
    return List.generate(6, (i) {
      final angle = rng.nextDouble() * 2 * pi + flicker * 0.3;
      final dist = 50 + rng.nextDouble() * 25 + breath * 8;
      final dx = cos(angle) * dist;
      final dy = sin(angle) * dist;
      final opacity = (0.25 + rng.nextDouble() * 0.45) * (0.5 + breath * 0.5);
      final size = 2.5 + rng.nextDouble() * 2.5;

      return Positioned(
        left: 70 + dx,
        top: 70 + dy,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: size,
            height: size * 1.4,
            decoration: BoxDecoration(
              color: _tier.accentColor,
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                  color: _tier.accentColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
