import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../domain/adventure_content.dart';
import '../../../ui/currency/currency_assets.dart';
import '../../../ui/currency/currency_type.dart';

class ChestOpenModal extends StatefulWidget {
  final WorldChest chest;
  final ChestReward reward;

  const ChestOpenModal({super.key, required this.chest, required this.reward});

  @override
  State<ChestOpenModal> createState() => _ChestOpenModalState();
}

class _ChestOpenModalState extends State<ChestOpenModal>
    with TickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late AnimationController _scaleCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _rayCtrl;
  late AnimationController _particleBurstCtrl;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _rayCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _particleBurstCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shakeCtrl.repeat(reverse: true);
    _scaleCtrl.forward();
    _glowCtrl.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _shakeCtrl.stop();
        _rayCtrl.forward();
        _particleBurstCtrl.forward();
        setState(() => _opened = true);
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _scaleCtrl.dispose();
    _glowCtrl.dispose();
    _rayCtrl.dispose();
    _particleBurstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chestLabel = switch (widget.chest.type) {
      ChestType.mini => 'Cofre Mini',
      ChestType.world => 'Cofre del Mundo',
      ChestType.boss => 'Cofre de Boss',
      ChestType.completion => '¡Cofre de la Corona!',
    };
    final chestColor = switch (widget.chest.type) {
      ChestType.mini => Colors.cyan,
      ChestType.world => Colors.amber,
      ChestType.boss => Colors.deepOrange,
      ChestType.completion => Colors.purple,
    };

    return Material(
      color: Colors.black87,
      child: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: _scaleCtrl,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, child) {
                final glow = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut).value;
                return Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        chestColor.withValues(alpha: 0.15 + glow * 0.1),
                        const Color(0xFF1A1A2E),
                      ],
                    ),
                    border: Border.all(
                      color: chestColor.withValues(alpha: 0.3 + glow * 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: chestColor.withValues(alpha: 0.2 + glow * 0.3),
                        blurRadius: 40 + glow * 20,
                        spreadRadius: 3 + glow * 5,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _opened
                      ? _buildOpenedContent(chestLabel, chestColor)
                      : _buildClosedContent(chestColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClosedContent(Color chestColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ray effect behind chest
        AnimatedBuilder(
          animation: _glowCtrl,
          builder: (_, child) {
            final glow = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut).value;
            return CustomPaint(
              size: const Size(120, 120),
              painter: _RayPainter(color: chestColor, progress: glow),
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: _shakeCtrl,
            builder: (_, child) {
              final shakeValue = math.sin(_shakeCtrl.value * math.pi * 4) * 4.0;
              return Transform.translate(offset: Offset(shakeValue, 0), child: child);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  chestColor.withValues(alpha: 0.3),
                  chestColor.withValues(alpha: 0.05),
                ]),
                boxShadow: [
                  BoxShadow(color: chestColor.withValues(alpha: 0.2), blurRadius: 30),
                ],
              ),
              child: Icon(Icons.inventory_2_outlined, size: 48, color: chestColor),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('ABRIENDO...',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 3,
              color: chestColor.withValues(alpha: 0.7),
            )).animate().fade().shake(duration: 800.ms),
      ],
    );
  }

  Widget _buildOpenedContent(String chestLabel, Color chestColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.reward.isJackpot)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFD32F2F)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 24)],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('¡JACKPOT!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 3, color: Colors.white)),
              ],
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
        if (!widget.reward.isJackpot)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                chestColor,
                chestColor.withValues(alpha: 0.1),
              ]),
            ),
            child: const Icon(Icons.inventory, size: 36, color: Colors.white),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 12),
        Text(chestLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 2,
              color: chestColor,
            )).animate().fade(duration: 400.ms),
        const SizedBox(height: 20),
        ..._buildRewards(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: chestColor.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('RECOGER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
          ),
        ).animate().fade(duration: 400.ms, delay: 800.ms).slideY(begin: 0.3),
      ],
    );
  }

  List<Widget> _buildRewards() {
    final r = widget.reward;
    final items = <Widget>[];
    void addItem(IconData icon, String text, Color color) {
      final i = items.length;
      items.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            ],
          ),
        ).animate().fade(delay: (i * 120).ms, duration: 400.ms).slideX(begin: 0.2),
      );
    }

    if (r.tokens > 0) addItem(CurrencyAssets.iconFor(CurrencyType.tokens), '+${r.tokens} tokens', CurrencyAssets.colorFor(CurrencyType.tokens));
    if (r.souls > 0) addItem(CurrencyAssets.iconFor(CurrencyType.souls), '+${r.souls} almas', CurrencyAssets.colorFor(CurrencyType.souls));
    if (r.hints > 0) addItem(Icons.lightbulb_outline, '+${r.hints} pistas', Colors.amber);
    if (r.advancedNotes > 0) addItem(Icons.auto_awesome, '+${r.advancedNotes} notas avanzadas', Colors.cyan);
    if (r.spins > 0) addItem(Icons.casino_outlined, '+${r.spins} giros', Colors.pinkAccent);
    if (r.cosmeticId != null) addItem(Icons.palette_outlined, 'Cosmético desbloqueado', Colors.purpleAccent);

    return items;
  }
}

class _RayPainter extends CustomPainter {
  final Color color;
  final double progress;
  _RayPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2;
      final len = 20 + progress * 30;
      final alpha = ((1.0 - progress) * 0.4).clamp(0.0, 0.4);
      paint.color = color.withValues(alpha: alpha);
      canvas.drawLine(
        center + Offset(math.cos(angle) * 35, math.sin(angle) * 35),
        center + Offset(math.cos(angle) * (35 + len), math.sin(angle) * (35 + len)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RayPainter old) => old.progress != progress;
}
