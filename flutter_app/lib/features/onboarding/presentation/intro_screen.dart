import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../campaign/domain/campaign_level.dart';
import '../application/onboarding_provider.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen>
    with SingleTickerProviderStateMixin {
  final _phrases = [
    'SUDOKU no es solo números.',
    'Es concentración.',
    'Patrones.',
    'Velocidad.',
    'Dominio.',
    'Aquí comienza tu viaje.',
  ];

  late final AnimationController _bgCtrl;
  late final Animation<double> _bgAnim;
  int _currentIndex = 0;
  bool _showButton = false;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _bgAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut),
    );
    _bgCtrl.forward();
    _startSequence();
  }

  void _startSequence() {
    _scheduleNext(1500);
  }

  void _scheduleNext(int delayMs) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_currentIndex < _phrases.length - 1) {
        setState(() => _currentIndex++);
        _scheduleNext(2800);
      } else {
        setState(() => _showButton = true);
      }
    });
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _onStart() {
    ref.read(onboardingProvider.notifier).completeIntro();
    final stage = CampaignStage.fromLevel(1);
    context.pushReplacement('/campaign-game',
        extra: {'level': 1, 'variant': stage.variant.name});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A0A2E), Color(0xFF0D0D1A)],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles (simple dots)
            ...List.generate(30, (i) => _Particle(i: i, anim: _bgAnim)),
            // Central content
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Spacer(flex: 2),
                      AnimatedSwitcher(
                        duration: 600.ms,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween(begin: 1.1, end: 1.0).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _phrases[_currentIndex],
                          key: ValueKey(_currentIndex),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 1.3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _showButton ? 1.0 : 0.0,
                        duration: 800.ms,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60, height: 2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1),
                                gradient: const LinearGradient(
                                  colors: [Colors.amber, Colors.amberAccent],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _StartButton(onTap: _onStart),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C3FB5), Color(0xFF9C4DFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C4DFF).withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(27),
            child: const Center(
              child: Text(
                'COMENZAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().shimmer(duration: 2000.ms, delay: 1600.ms, color: Colors.white24);
  }
}

class _Particle extends StatelessWidget {
  final int i;
  final Animation<double> anim;
  const _Particle({required this.i, required this.anim});

  @override
  Widget build(BuildContext context) {
    final seed = i * 137.5;
    final x = ((seed * 1.7) % 100) / 100;
    final y = ((seed * 2.3 + 50) % 100) / 100;
    final size = 1.5 + (i % 3) * 1.0;
    final delay = (i % 8) * 800;
    return Positioned(
      left: (MediaQuery.of(context).size.width * x).clamp(0, MediaQuery.of(context).size.width - 10),
      top: (MediaQuery.of(context).size.height * y).clamp(0, MediaQuery.of(context).size.height - 10),
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) => Transform.scale(
          scale: anim.value,
          child: Opacity(
            opacity: 0.3 + (i % 3) * 0.2,
            child: Container(
              width: size, height: size,
              decoration: BoxDecoration(
                color: Colors.amber.shade200,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat()).then(delay: delay.ms).fadeIn(duration: 600.ms).then()
          .shimmer(duration: 3000.ms, color: Colors.white54),
      ),
    );
  }
}
