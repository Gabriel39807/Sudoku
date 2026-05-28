import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../domain/adventure_content.dart';

class WorldCompletionScreen extends StatefulWidget {
  final BiomeConfig biome;
  final int stageNum;
  final int tokensReward;
  final int gemsReward;
  final String? cosmeticReward;

  const WorldCompletionScreen({
    super.key,
    required this.biome,
    required this.stageNum,
    this.tokensReward = 50,
    this.gemsReward = 25,
    this.cosmeticReward,
  });

  @override
  State<WorldCompletionScreen> createState() => _WorldCompletionScreenState();
}

class _WorldCompletionScreenState extends State<WorldCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _particleCtrl;
  late ConfettiController _confettiCtrl;
  bool _showRewards = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 4));
    _ctrl.forward();
    _particleCtrl.repeat(reverse: true);
    _confettiCtrl.play();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showRewards = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _particleCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Color(widget.biome.primaryColor);
    final accent = Color(widget.biome.accentColor);

    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // Background gradient
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, child) {
              final pulse = CurvedAnimation(parent: _particleCtrl, curve: Curves.easeInOut).value;
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.5 + pulse * 0.3,
                    colors: [
                      primary.withValues(alpha: 0.3),
                      Colors.black,
                    ],
                  ),
                ),
                child: child,
              );
            },
            child: Center(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
                child: ScaleTransition(
                  scale: CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Giant chest
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            accent.withValues(alpha: 0.4),
                            accent.withValues(alpha: 0.05),
                          ]),
                          boxShadow: [
                            BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 60, spreadRadius: 10),
                          ],
                        ),
                        child: Icon(Icons.card_giftcard, size: 56, color: accent),
                      ),
                      const SizedBox(height: 24),
                      Text('${widget.biome.name}',
                          style: const TextStyle(fontSize: 14, letterSpacing: 3, color: Colors.white54)),
                      const SizedBox(height: 8),
                      const Text('WORLD CLEARED',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            letterSpacing: 6,
                            color: Colors.white,
                          )),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (_) =>
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.star, color: Colors.amber, size: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_showRewards) ...[
                        _buildRewardRow(Icons.monetization_on_outlined, '+${widget.tokensReward} tokens', Colors.amber),
                        const SizedBox(height: 8),
                        _buildRewardRow(Icons.diamond_outlined, '+${widget.gemsReward} GEMS', const Color(0xFFE91E63)),
                        if (widget.cosmeticReward != null) ...[
                          const SizedBox(height: 8),
                          _buildRewardRow(Icons.palette_outlined, 'Cosmético desbloqueado', Colors.cyan),
                        ],
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 240,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent.withValues(alpha: 0.3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('CONTINUAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 3)),
                          ),
                        ).animate().fade(duration: 500.ms).slideY(begin: 0.4),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [accent, primary, Colors.amber, Colors.white],
              numberOfParticles: 40,
              maxBlastForce: 30,
              minBlastForce: 5,
              gravity: 0.08,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRow(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideX(begin: 0.3);
  }
}
