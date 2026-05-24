import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/wheel_reward.dart';
import '../application/wheel_provider.dart';

class LuckyWheelScreen extends ConsumerStatefulWidget {
  const LuckyWheelScreen({super.key});

  @override
  ConsumerState<LuckyWheelScreen> createState() => _LuckyWheelScreenState();
}

class _LuckyWheelScreenState extends ConsumerState<LuckyWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnim;
  double _currentAngle = 0;
  bool _spinning = false;
  WheelReward? _pendingReward;
  final _segAngle = 2 * math.pi / wheelSegments.length;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _spinAnim = CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic);
    _spinController.addListener(_onSpinTick);
    _spinController.addStatusListener(_onSpinDone);
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _onSpinTick() => setState(() {});

  void _onSpinDone(AnimationStatus status) async {
    if (status == AnimationStatus.completed && _pendingReward != null) {
      _spinning = false;
      await ref.read(wheelProvider.notifier).claimReward(_pendingReward!);
      if (!mounted) return;
      _showResult(_pendingReward!);
    }
  }

  Future<void> _spin() async {
    if (_spinning) return;
    final notifier = ref.read(wheelProvider.notifier);
    try {
      final reward = await notifier.spin();
      _pendingReward = reward;
      final targetIdx = wheelSegments.indexWhere((s) => s.reward.id == reward.id);
      if (targetIdx < 0) return;

      final targetSegmentCenter = targetIdx * _segAngle + _segAngle / 2;
      final pointerAngle = 3 * math.pi / 2;
      var targetAngle = pointerAngle - targetSegmentCenter;
      final fullRotations = 5 * 2 * math.pi;
      targetAngle = targetAngle + fullRotations;
      while (targetAngle <= _currentAngle) {
        targetAngle += 2 * math.pi;
      }

      _spinning = true;
      _spinController.reset();
      final fixedTarget = targetAngle;
      _spinAnim = CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic);
      _spinController.addListener(() {
        _currentAngle = _spinAnim.value * fixedTarget;
      });
      _spinController.addStatusListener(_onSpinDone);
      _spinController.forward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya giraste hoy. Volvé mañana.')),
        );
      }
    }
  }

  void _showResult(WheelReward reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _WheelResultDialog(reward: reward, onClaim: () {
        Navigator.of(ctx).pop();
        ref.read(wheelProvider.notifier).clearReward();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wheelProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('LUCKY WHEEL', style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3)),
      ),
      body: Center(
        child: Column(
          children: [
            const Spacer(flex: 1),
            Text(
              state.canSpin ? '¡Girar para ganar!' : 'Ya giraste hoy',
              style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 1),
            ).animate().fade().slideY(begin: -0.3),
            const SizedBox(height: 24),
            _WheelWidget(currentAngle: _currentAngle, spinning: _spinning),
            const SizedBox(height: 32),
            SizedBox(
              width: 200, height: 56,
              child: ElevatedButton(
                onPressed: state.canSpin && !_spinning ? _spin : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade800,
                  disabledForegroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: Colors.amber.withValues(alpha: 0.4),
                ),
                child: Text(
                  _spinning ? 'GIRANDO...' : (state.canSpin ? '🎡 GIRAR' : '✅ LISTO'),
                  style: GoogleFonts.exo2(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

// ── Wheel Widget ────────────────────────────────────────────────────────────

class _WheelWidget extends StatelessWidget {
  final double currentAngle;
  final bool spinning;
  const _WheelWidget({required this.currentAngle, required this.spinning});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 360.0);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size + 20, height: size + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: spinning ? 0.2 : 0.1), blurRadius: 40, spreadRadius: 5)],
                ),
              ),
              CustomPaint(size: Size(size, size), painter: _WheelPainter(currentAngle: currentAngle)),
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1A1A2E)),
                child: Center(
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber,
                      boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 8)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -8, left: 0, right: 0,
                child: IgnorePointer(
                  child: CustomPaint(size: const Size(40, 24), painter: _PointerPainter()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  final double currentAngle;
  _WheelPainter({required this.currentAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final segAngle = 2 * math.pi / wheelSegments.length;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(currentAngle);

    for (var i = 0; i < wheelSegments.length; i++) {
      final startAngle = i * segAngle;
      final segment = wheelSegments[i];

      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle, segAngle, true,
        Paint()..color = segment.color..style = PaintingStyle.fill,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle, segAngle, true,
        Paint()
          ..color = const Color(0xFF0D1117)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      canvas.save();
      canvas.rotate(startAngle + segAngle / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: segment.reward.displayText,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius > 100 ? 14 : 11,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(radius * 0.58 - tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    canvas.drawCircle(
      Offset.zero, radius,
      Paint()
        ..color = const Color(0xFF2B2B2B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) => oldDelegate.currentAngle != currentAngle;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 - 12, 0)
      ..lineTo(size.width / 2 + 12, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.amber..style = PaintingStyle.fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Result Dialog ───────────────────────────────────────────────────────────

class _WheelResultDialog extends StatefulWidget {
  final WheelReward reward;
  final VoidCallback onClaim;
  const _WheelResultDialog({required this.reward, required this.onClaim});

  @override
  State<_WheelResultDialog> createState() => _WheelResultDialogState();
}

class _WheelResultDialogState extends State<_WheelResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 500.ms);
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _rarityColor() => switch (widget.reward.rarity) {
    RewardRarity.common => Colors.green,
    RewardRarity.medium => Colors.purple,
    RewardRarity.rare => Colors.orange,
    RewardRarity.jackpot => Colors.amber,
  };

  String _rarityLabel() => switch (widget.reward.rarity) {
    RewardRarity.common => 'COMÚN',
    RewardRarity.medium => 'MEDIO',
    RewardRarity.rare => 'RARO',
    RewardRarity.jackpot => '¡JACKPOT!',
  };

  String _rewardName() {
    if (widget.reward.id.contains('hint')) return 'Pista';
    if (widget.reward.id.contains('token')) return 'Token';
    return 'Souls';
  }

  @override
  Widget build(BuildContext context) {
    final rc = _rarityColor();
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: FadeTransition(
            opacity: _ctrl,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    ),
                    border: Border.all(color: rc.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [BoxShadow(color: rc.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 2)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: rc.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: rc.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _rarityLabel(),
                          style: GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: rc),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(widget.reward.icon, style: const TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text(
                        '+${widget.reward.amount}',
                        style: GoogleFonts.orbitron(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _rewardName(),
                        style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white54),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onClaim,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rc,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 8,
                            shadowColor: rc.withValues(alpha: 0.5),
                          ),
                          child: Text('RECOGER', style: GoogleFonts.exo2(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 3)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
