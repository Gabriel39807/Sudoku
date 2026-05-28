import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/adventure_content.dart';

class WorldBackground extends StatelessWidget {
  final int stageNum;
  final ScrollController scrollCtrl;

  const WorldBackground({super.key, required this.stageNum, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _BiomeBackground(key: ValueKey(stageNum), stageNum: stageNum, scrollCtrl: scrollCtrl),
    );
  }
}

class _BiomeBackground extends StatelessWidget {
  final int stageNum;
  final ScrollController scrollCtrl;

  const _BiomeBackground({super.key, required this.stageNum, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    final biome = BiomeConfig.forStageNum(stageNum);
    return AnimatedBuilder(
      animation: scrollCtrl,
      builder: (_, child) {
        final offset = scrollCtrl.hasClients ? scrollCtrl.offset : 0.0;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(biome.primaryColor).withValues(alpha: 0.7),
                Color(biome.backgroundColor).withValues(alpha: 0.9),
                Color(biome.secondaryColor).withValues(alpha: 0.7),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _AmbientPainter(
                  biome: biome,
                  offset: offset * 0.1,
                  seed: stageNum * 137,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final BiomeConfig biome;
  final double offset;
  final int seed;

  _AmbientPainter({required this.biome, required this.offset, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rng = math.Random(seed);

    switch (biome.particleType) {
      case 'leaf': _drawForest(canvas, size, rng);
      case 'book': _drawAcademy(canvas, size, rng);
      case 'ember': _drawEmbers(canvas, size, rng);
      case 'snow': _drawSnow(canvas, size, rng);
      case 'sparkle': _drawSparkle(canvas, size, rng);
      case 'skull': _drawShadow(canvas, size, rng);
      case 'phoenix': _drawMythic(canvas, size, rng);
      case 'dust': _drawDust(canvas, size, rng);
      default: _drawDust(canvas, size, rng);
    }
  }

  // ── Stage 1: Bosque — hojas verdes, polen, tree silhouettes ─────────
  void _drawForest(Canvas canvas, Size size, math.Random rng) {
    for (var i = 0; i < 28; i++) {
      final float = math.sin(offset * 0.015 + i * 0.73) * 0.5 + 0.5;
      final x = (rng.nextDouble() * size.width + offset * 0.08) % size.width;
      final y = (rng.nextDouble() * size.height + float * 20) % size.height;
      final paint = Paint()..color = Color.lerp(
        const Color(0xFF2E7D32), const Color(0xFF81C784), float,
      )!.withValues(alpha: 0.2 + float * 0.3);
      final angle = offset * 0.008 + i * 1.3;
      canvas.save();
      canvas.translate(x + math.sin(angle) * 12, y);
      canvas.rotate(angle);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-4, -2, 8, 4), const Radius.circular(2)), paint);
      canvas.restore();
    }
    // Polen (tiny yellow dots)
    final polen = Paint()..color = const Color(0xFFFDD835).withValues(alpha: 0.15);
    for (var i = 0; i < 15; i++) {
      final float = math.sin(offset * 0.02 + i * 1.1) * 0.5 + 0.5;
      final x = (rng.nextDouble() * size.width + offset * 0.05) % size.width;
      final y = (rng.nextDouble() * size.height + float * 10) % size.height;
      canvas.drawCircle(Offset(x, y), 0.8 + float, polen);
    }
  }

  // ── Stage 2: Academia — partículas azules, símbolos de libro ─────────
  void _drawAcademy(Canvas canvas, Size size, math.Random rng) {
    final bluePaint = Paint()..color = const Color(0xFF42A5F5).withValues(alpha: 0.25);
    for (var i = 0; i < 22; i++) {
      final float = math.sin(offset * 0.02 + i * 0.9) * 0.5 + 0.5;
      final x = (rng.nextDouble() * size.width + offset * 0.06) % size.width;
      final y = (rng.nextDouble() * size.height + float * 12) % size.height;
      canvas.drawCircle(Offset(x, y), 1.0 + float * 2.0, bluePaint);
    }
    // Brillo estrellas
    for (var i = 0; i < 10; i++) {
      final float = math.sin(offset * 0.025 + i * 2.0) * 0.5 + 0.5;
      final x = (rng.nextDouble() * size.width + offset * 0.03) % size.width;
      final y = (rng.nextDouble() * size.height * 0.4) % size.height;
      if (float > 0.5) {
        final paint = Paint()..color = Colors.white.withValues(alpha: (float - 0.5) * 0.6);
        canvas.drawCircle(Offset(x, y), 0.5 + float, paint);
      }
    }
  }

  // ── Stage 3: Templo — polvo dorado, campanas ────────────────────────
  void _drawDust(Canvas canvas, Size size, math.Random rng) {
    for (var i = 0; i < 20; i++) {
      final float = math.sin(offset * 0.01 + i * 0.83) * 0.5 + 0.5;
      final x = (rng.nextDouble() * size.width + offset * 0.05) % size.width;
      final y = (rng.nextDouble() * size.height + float * 8) % size.height;
      final paint = Paint()
        ..color = Color.lerp(const Color(0xFFD4A574), const Color(0xFFFFD54F), float)!
            .withValues(alpha: 0.08 + float * 0.12);
      canvas.drawCircle(Offset(x + math.sin(offset * 0.015 + i) * 3, y), 1.0 + float * 2.5, paint);
    }
  }

  // ── Stage 6: Montañas — niebla, copos ───────────────────────────────
  void _drawSnow(Canvas canvas, Size size, math.Random rng) {
    final large = Paint()..color = Colors.white.withValues(alpha: 0.08);
    final small = Paint()..color = Colors.white.withValues(alpha: 0.15);
    for (var i = 0; i < 30; i++) {
      final float = math.sin(offset * 0.02 + i * 0.6) * 0.5 + 0.5;
      final x = (rng.nextDouble() * size.width + offset * 0.12) % size.width;
      final y = (rng.nextDouble() * size.height + float * 15) % size.height;
      final p = i % 3 == 0 ? large : small;
      canvas.drawCircle(Offset(x, y + float * 5), 0.5 + float * 1.5, p);
    }
  }

  // ── Stage 7: Ciudad/Advanced — sparkle, circuitos ──────────────────
  void _drawSparkle(Canvas canvas, Size size, math.Random rng) {
    for (var i = 0; i < 25; i++) {
      final float = math.sin(offset * 0.018 + i * 1.1) * 0.5 + 0.5;
      final alpha = 0.15 + float * 0.5;
      final paint = Paint()..color = const Color(0xFFB388FF).withValues(alpha: alpha);
      final x = (rng.nextDouble() * size.width + offset * 0.07) % size.width;
      final y = (rng.nextDouble() * size.height) % size.height;
      canvas.drawCircle(Offset(x + math.sin(offset * 0.02 + i) * 5, y), 0.5 + float * 1.5, paint);
      if (float > 0.65) {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 0.3;
        canvas.drawCircle(Offset(x, y), 2.0 + float * 2.0, paint);
        paint.style = PaintingStyle.fill;
      }
    }
  }

  // ── Stage 8: Fortaleza — brasas, llamas ─────────────────────────────
  void _drawEmbers(Canvas canvas, Size size, math.Random rng) {
    for (var i = 0; i < 22; i++) {
      final float = math.sin(offset * 0.025 + i * 0.9) * 0.5 + 0.5;
      final x = (rng.nextDouble() * size.width + offset * 0.06) % size.width;
      final y = (rng.nextDouble() * size.height * 0.7 + size.height * 0.3) % size.height;
      final paint = Paint()
        ..color = Color.lerp(const Color(0xFFFF6E40), const Color(0xFFFFD54F), float)!
            .withValues(alpha: 0.15 + float * 0.45);
      canvas.drawCircle(Offset(x + rng.nextDouble() * 4 - 2, y - float * 25), 1.0 + float * 2.5, paint);
    }
    // Glow inferior
    final glow = Paint()..shader = RadialGradient(
      center: Alignment.bottomCenter,
      colors: [const Color(0xFFFF6E40).withValues(alpha: 0.1), Colors.transparent],
    ).createShader(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4), glow);
  }

  // ── Stage 9: Evil — sombras, púrpura ──────────────────────────────
  void _drawShadow(Canvas canvas, Size size, math.Random rng) {
    for (var i = 0; i < 20; i++) {
      final float = math.sin(offset * 0.015 + i * 0.8) * 0.5 + 0.5;
      final x = (rng.nextDouble() * size.width + offset * 0.04) % size.width;
      final y = (rng.nextDouble() * size.height + float * 10) % size.height;
      final paint = Paint()..color = const Color(0xFF7B1FA2).withValues(alpha: 0.1 + float * 0.2);
      canvas.drawCircle(Offset(x + math.sin(offset * 0.012 + i) * 6, y), 1.5 + float * 3.0, paint);
    }
    // Neblina púrpura inferior
    final mist = Paint()..shader = RadialGradient(
      center: const Alignment(0.5, 1.0),
      colors: [const Color(0xFF4A148C).withValues(alpha: 0.15), Colors.transparent],
    ).createShader(Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.7));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.7), mist);
  }

  // ── Stage 10: Mythic — estrellas, fénix, brillos ───────────────────
  void _drawMythic(Canvas canvas, Size size, math.Random rng) {
    for (var i = 0; i < 25; i++) {
      final float = math.sin(offset * 0.016 + i * 1.3) * 0.5 + 0.5;
      final x = (rng.nextDouble() * size.width + offset * 0.05) % size.width;
      final y = (rng.nextDouble() * size.height) % size.height;
      final paint = Paint()
        ..color = Color.lerp(const Color(0xFFFF6F00), const Color(0xFFFFD54F), float)!
            .withValues(alpha: 0.1 + float * 0.35);
      canvas.drawCircle(Offset(x + math.sin(offset * 0.02 + i) * 7, y), 0.8 + float * 2.5, paint);
      if (float > 0.7) {
        paint.strokeWidth = 0.5;
        paint.style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(x, y), 3.0 + float * 3.0, paint);
        paint.style = PaintingStyle.fill;
      }
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
    old.biome.particleType != biome.particleType || (old.offset - offset).abs() > 0.5;
}
