import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/wheel_reward.dart';
import '../application/wheel_provider.dart';
import '../data/wheel_storage.dart';
import '../../../core/theme/theme_palette.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/theme_tokens.dart';
import '../../economy/application/wallet_provider.dart';
import '../../economy/domain/wallet.dart';
import '../../../ui/currency/currency_type.dart';
import '../../../ui/currency/currency_assets.dart';

void showRouletteModal(BuildContext context) {
  try {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Ruleta',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim, _) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: _RouletteBody(),
      ),
    );
  } catch (_) {}
}

const _maxSpins = 20;

class _RouletteBody extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RouletteBody> createState() => _RouletteBodyState();
}

class _RouletteBodyState extends ConsumerState<_RouletteBody>
    with TickerProviderStateMixin {
  late AnimationController _wheelCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _popupCtrl;
  late AnimationController _lockBobCtrl;
  late AnimationController _purchaseAnimCtrl;

  double _wheelAngle = 0;
  bool _spinning = false;
  double _spinTarget = 0;
  double _spinStart = 0;
  WheelReward? _pendingReward;
  WheelReward? _resultReward;
  bool _claimed = false;
  bool _popping = false;

  int _purchaseAmount = 0;
  String _purchaseFeedback = '';
  bool _showingLimit = false;

  final _segAngle = 2 * math.pi / wheelSegments.length;
  final _particles = <_Particle>[];
  static const _particleCount = 20;

  @override
  void initState() {
    super.initState();
    _wheelCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
    _wheelCtrl.addListener(_onWheelTick);
    _wheelCtrl.addStatusListener(_onWheelDone);

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _pulseCtrl.repeat(reverse: true);

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _particleCtrl.addListener(_tickParticles);
    _particleCtrl.repeat();

    _popupCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _lockBobCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _lockBobCtrl.repeat(reverse: true);

    _purchaseAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _purchaseAnimCtrl.addStatusListener(_onPurchaseAnimDone);

    for (var i = 0; i < _particleCount; i++) {
      _particles.add(_Particle._random());
    }
  }

  @override
  void dispose() {
    _wheelCtrl.removeListener(_onWheelTick);
    _wheelCtrl.removeStatusListener(_onWheelDone);
    _wheelCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.removeListener(_tickParticles);
    _particleCtrl.dispose();
    _popupCtrl.dispose();
    _lockBobCtrl.dispose();
    _purchaseAnimCtrl.removeStatusListener(_onPurchaseAnimDone);
    _purchaseAnimCtrl.dispose();
    super.dispose();
  }

  void _onWheelTick() {
    if (!mounted) return;
    _wheelAngle = _spinStart + (_spinTarget - _spinStart) * _wheelCtrl.value;
    setState(() {});
  }

  void _onWheelDone(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed && _pendingReward != null) {
      _spinning = false;
      _wheelAngle = _spinTarget;
      _popping = true;
      _popupCtrl.forward();
      setState(() => _resultReward = _pendingReward);
    }
  }

  void _tickParticles() {
    if (!mounted) return;
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.02;
      p.life -= 0.005;
      if (p.life <= 0) p._reset();
    }
    setState(() {});
  }

  Future<void> _spin() async {
    if (_spinning || !mounted) return;
    try {
      final reward = await ref.read(wheelProvider.notifier).spin();
      if (!mounted) return;
      _pendingReward = reward;
      _claimed = false;
      final idx = wheelSegments.indexWhere((s) => s.reward.id == reward.id);
      if (idx < 0) return;

      final center = idx * _segAngle + _segAngle / 2;
      const pointer = 3 * math.pi / 2;
      var target = pointer - center;
      target += 5 * 2 * math.pi;
      while (target <= _wheelAngle) {
        target += 2 * math.pi;
      }

      _spinStart = _wheelAngle;
      _spinTarget = target;
      _spinning = true;
      _popping = false;
      _resultReward = null;
      _wheelCtrl.reset();
      _wheelCtrl.forward();
    } catch (_) {}
  }

  Future<void> _claim() async {
    if (_resultReward == null || _claimed || !mounted) return;
    _claimed = true;
    try {
      await ref.read(wheelProvider.notifier).claimReward(_resultReward!);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _close() {
    try {
      _pendingReward = null;
      _resultReward = null;
      _popping = false;
      _spinning = false;
      _wheelCtrl.stop();
      _popupCtrl.stop();
      ref.read(wheelProvider.notifier).clearReward();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {}
  }

  Future<void> _buyWithTokens(int cost, int spins) async {
    if (_purchaseAnimCtrl.isAnimating) return;
    final wallet = ref.read(walletProvider);
    if (wallet.tokens < cost) {
      _showInsufficientTokens();
      return;
    }
    final current = await WheelStorage.getExtraSpins();
    if (current >= _maxSpins) {
      setState(() => _showingLimit = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showingLimit = false);
      });
      return;
    }
    final space = _maxSpins - current;
    final actual = spins > space ? space : spins;
    final ok = await ref.read(walletProvider.notifier).spendTokens(cost);
    if (!ok || !mounted) return;
    await WheelStorage.addExtraSpins(actual);
    ref.read(wheelProvider.notifier).refreshExtraSpins();
    if (actual < spins) {
      setState(() => _showingLimit = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showingLimit = false);
      });
    }
    setState(() {
      _purchaseAmount = actual;
      _purchaseFeedback = '+$actual GIRO${actual > 1 ? 'S' : ''}';
    });
    _purchaseAnimCtrl.forward(from: 0);
  }

  void _onPurchaseAnimDone(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        _purchaseAmount = 0;
        _purchaseFeedback = '';
      });
    }
  }

  void _showInsufficientTokens() {
    final p = ref.palette;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Saldo insuficiente',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim, _) => FadeTransition(
        opacity: anim,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      p.surface,
                      p.surface.withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                  boxShadow: [
                    BoxShadow(color: p.glow.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 4),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.danger.withValues(alpha: 0.12),
                      ),
                      child: Icon(Icons.money_off, color: p.danger, size: 24),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sin tokens suficientes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gana más tokens resolviendo\npartidas y desafíos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          try { Navigator.maybeOf(ctx)?.pop(); } catch (_) {}
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.buttonPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('CERRAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildSafe();
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildSafe() {
    final state = ref.watch(wheelProvider);
    final wallet = ref.watch(walletProvider);
    final hasSpins = state.canSpin || state.extraSpins > 0;
    final p = ref.palette;
    final screen = MediaQuery.of(context).size;
    final wheelSize = (screen.width * 0.75).clamp(220.0, 380.0);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Particles
          ..._particles.map((pt) {
            final opacity = hasSpins
                ? pt.life.clamp(0.0, 1.0)
                : pt.life.clamp(0.0, 1.0) * 0.25;
            return Positioned(
              left: pt.x * screen.width,
              top: pt.y * screen.height,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: hasSpins ? 3 : 2,
                  height: hasSpins ? 3 : 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pt.color,
                    boxShadow: hasSpins
                        ? [BoxShadow(color: pt.color, blurRadius: 4, spreadRadius: 1)]
                        : null,
                  ),
                ),
              ),
            );
          }),

          // Close button
          Positioned(
            top: 40,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: _close,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.white54),
                ),
              ),
            ),
          ),

          // Main content — shifted up ~60px
          Transform.translate(
            offset: const Offset(0, -50),
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: topPad + 8),

                    // Header
                    AnimatedBuilder(
                      animation: _purchaseAnimCtrl,
                      builder: (context, _) {
                        final s = _purchaseAmount > 0
                            ? 1.0 + _pulseCtrl.value * 0.12
                            : 1.0;
                        return Transform.scale(
                          scale: s,
                          child: _HeaderText(state: state),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Wheel + glow + pointer
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, _) {
                        final pulse = 0.85 + _pulseCtrl.value * 0.15;
                        final glowI = hasSpins
                            ? (0.2 + _pulseCtrl.value * 0.15)
                            : (0.08 + _pulseCtrl.value * 0.06);
                        final ws = wheelSize * pulse;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: ws + 30,
                              height: ws + 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: p.wheelAccent.withValues(alpha: glowI), blurRadius: 50, spreadRadius: 10),
                                  BoxShadow(color: p.glow.withValues(alpha: glowI * 0.5), blurRadius: 70, spreadRadius: 15),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 6),
                                  CustomPaint(
                                    size: const Size(28, 16),
                                    painter: _PointerPainter(),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(0, -ws * 0.08),
                              child: SizedBox(
                                width: ws,
                                height: ws,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _WheelCircle(
                                      angle: _wheelAngle,
                                      wheelSize: ws,
                                      glowIntensity: glowI,
                                      palette: p,
                                    ),
                                    if (!hasSpins)
                                      Positioned.fill(
                                        child: ClipOval(
                                          child: Container(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            child: AnimatedBuilder(
                                              animation: _lockBobCtrl,
                                              builder: (context, _) {
                                                final bob = _lockBobCtrl.value * 6 - 3;
                                                return Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Transform.translate(
                                                      offset: Offset(0, bob),
                                                      child: Icon(
                                                        Icons.lock,
                                                        size: ws * 0.2,
                                                        color: Colors.white.withValues(alpha: 0.5),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    // Action area
                    if (hasSpins)
                      _SpinButton(
                        canSpin: state.canSpin,
                        extraSpins: state.extraSpins,
                        spinning: _spinning,
                        onSpin: _spin,
                        palette: p,
                      )
                    else ...[
                      Text(
                        'SIN TIRADAS DISPONIBLES',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nueva tirada gratuita mañana',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Token shop — ACTIVE
                    _TokenShop(
                      wallet: wallet,
                      palette: p,
                      onBuy: _buyWithTokens,
                    ),

                    const SizedBox(height: 12),

                    // Purchase feedback animation
                    AnimatedBuilder(
                      animation: _purchaseAnimCtrl,
                      builder: (context, _) {
                        if (_purchaseAmount <= 0) return const SizedBox.shrink();
                        final fade = _purchaseAnimCtrl.value < 0.1
                            ? _purchaseAnimCtrl.value / 0.1
                            : (_purchaseAnimCtrl.value > 0.8
                                ? (1.0 - _purchaseAnimCtrl.value) / 0.2
                                : 1.0);
                        final scale = 0.5 + _purchaseAnimCtrl.value * 0.5;
                        return Opacity(
                          opacity: fade.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    p.success.withValues(alpha: 0.15),
                                    p.success.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: p.success.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _purchaseFeedback,
                                    style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Limit reached feedback
                    if (_showingLimit)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Límite: $_maxSpins giros almacenados',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold,
                            color: p.warning.withValues(alpha: 0.7),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Future monetization (ad + premium packs) — PRÓXIMAMENTE
                    _FutureMonetization(palette: p),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Result popup overlay
          if (_resultReward != null && _popping)
            Positioned.fill(
              child: _ResultOverlay(
                reward: _resultReward!,
                claimed: _claimed,
                popupCtrl: _popupCtrl,
                onClaim: _claim,
                onContinue: _close,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _HeaderText extends StatelessWidget {
  final WheelState state;
  const _HeaderText({required this.state});

  @override
  Widget build(BuildContext context) {
    final (text, subtext, color) = switch ((state.canSpin, state.extraSpins)) {
      (true, _) => ('TIRADA GRATIS DISPONIBLE', '1 / 1', Colors.greenAccent),
      (false, > 0) => ('GIROS EXTRA DISPONIBLES', '${state.extraSpins} restantes', Colors.orangeAccent),
      _ => ('', '', Colors.white54),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2,
            color: color,
          ),
        ),
        if (subtext.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Spin Button ─────────────────────────────────────────────────────────────

class _SpinButton extends StatelessWidget {
  final bool canSpin;
  final int extraSpins;
  final bool spinning;
  final VoidCallback onSpin;
  final AppPalette palette;

  const _SpinButton({
    required this.canSpin,
    required this.extraSpins,
    required this.spinning,
    required this.onSpin,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = (canSpin || extraSpins > 0) && !spinning;
    final label = spinning
        ? 'GIRANDO...'
        : (canSpin ? '🎡 GIRAR' : '🎡 USAR GIRO');

    return SizedBox(
      width: 180,
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onSpin : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.buttonPrimary,
          foregroundColor: palette.textPrimary,
          disabledBackgroundColor: palette.buttonDisabled,
          disabledForegroundColor: palette.textSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeTokens.radiusMd)),
          elevation: 8,
          shadowColor: palette.glow.withValues(alpha: 0.3),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
    );
  }
}

// ── Token Shop ──────────────────────────────────────────────────────────────

class _TokenShop extends StatelessWidget {
  final Wallet wallet;
  final AppPalette palette;
  final Function(int cost, int spins) onBuy;

  const _TokenShop({
    required this.wallet,
    required this.palette,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'COMPRAR CON TOKENS',
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 3,
            color: palette.wheelAccent.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TokenCard(cost: 5, spins: 1, wallet: wallet, palette: palette, onBuy: onBuy),
            const SizedBox(width: 8),
            _TokenCard(cost: 15, spins: 4, wallet: wallet, palette: palette, onBuy: onBuy),
            const SizedBox(width: 8),
            _TokenCard(cost: 30, spins: 10, wallet: wallet, palette: palette, onBuy: onBuy),
          ],
        ),
      ],
    );
  }
}

class _TokenCard extends StatelessWidget {
  final int cost;
  final int spins;
  final Wallet wallet;
  final AppPalette palette;
  final Function(int cost, int spins) onBuy;

  const _TokenCard({
    required this.cost,
    required this.spins,
    required this.wallet,
    required this.palette,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = wallet.tokens >= cost;
    final ratio = spins / cost;

    return GestureDetector(
      onTap: canAfford ? () => onBuy(cost, spins) : null,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              palette.wheelAccent.withValues(alpha: canAfford ? 0.08 : 0.03),
              Colors.white.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: canAfford
                ? palette.wheelAccent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: canAfford
              ? [
                  BoxShadow(
                    color: palette.wheelAccent.withValues(alpha: 0.06),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Token icon + cost
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CurrencyAssets.iconFor(CurrencyType.tokens),
                  size: 14,
                  color: canAfford
                      ? CurrencyAssets.colorFor(CurrencyType.tokens)
                      : CurrencyAssets.colorFor(CurrencyType.tokens).withValues(alpha: 0.3),
                ),
                const SizedBox(width: 4),
                Text(
                  '$cost',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: canAfford ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Bonus
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: canAfford
                    ? palette.success.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+$spins Giro${spins > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: canAfford
                      ? palette.success
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
            // Efficiency tip
            if (spins > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '~${(ratio * 100).round()}% eficiencia',
                  style: TextStyle(
                    fontSize: 7,
                    color: canAfford
                        ? palette.wheelAccent.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Future monetization (PRÓXIMAMENTE) ─────────────────────────────────────

class _FutureMonetization extends StatelessWidget {
  final AppPalette palette;
  const _FutureMonetization({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MonetButton(
              icon: Icons.play_circle_outline,
              title: 'Ver anuncio',
              subtitle: '+1 giro',
              palette: palette,
            ),
            const SizedBox(width: 10),
            _MonetButton(
              icon: Icons.shopping_cart_outlined,
              title: 'Comprar giros',
              subtitle: '3 / 10 / 25',
              palette: palette,
            ),
          ],
        ),
      ],
    );
  }
}

class _MonetButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AppPalette palette;

  const _MonetButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: palette.wheelAccent.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.wheelAccent.withValues(alpha: 0.06),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: palette.wheelAccent.withValues(alpha: 0.35)),
              Positioned(
                top: -2,
                right: -6,
                child: Icon(Icons.lock, size: 10, color: Colors.white.withValues(alpha: 0.25)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: palette.wheelAccent.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: palette.wheelAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'PRÓXIMAMENTE',
              style: TextStyle(
                fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 1,
                color: palette.wheelAccent.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pure wheel circle ──────────────────────────────────────────────────────

class _WheelCircle extends StatelessWidget {
  final double angle;
  final double wheelSize;
  final double glowIntensity;
  final AppPalette palette;

  const _WheelCircle({
    required this.angle,
    required this.wheelSize,
    required this.glowIntensity,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: wheelSize + 20,
          height: wheelSize + 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [Color(0xFF8B7355), Color(0xFFD4AF37), Color(0xFF8B7355), Color(0xFFD4AF37), Color(0xFF8B7355)],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
            boxShadow: [
              BoxShadow(color: palette.wheelAccent.withValues(alpha: glowIntensity * 0.3), blurRadius: 20, spreadRadius: 4),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [Color(0xFF3A3A3A), Color(0xFF5A5A5A), Color(0xFF3A3A3A)],
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0D1117)),
            ),
          ),
        ),
        CustomPaint(
          size: Size(wheelSize - 8, wheelSize - 8),
          painter: _WheelPainter(angle: angle),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF5A5A5A), Color(0xFF1A1A1A)],
            ),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6), width: 2),
            boxShadow: [BoxShadow(color: palette.wheelAccent.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700),
                boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.5), blurRadius: 6)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Wheel Painter ──────────────────────────────────────────────────────────

class _WheelPainter extends CustomPainter {
  final double angle;
  _WheelPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    if (r <= 0) return;
    final seg = 2 * math.pi / wheelSegments.length;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);

    for (var i = 0; i < wheelSegments.length; i++) {
      final start = i * seg;
      final s = wheelSegments[i];
      final p = Paint()
        ..shader = RadialGradient(
          colors: [s.color, s.color.withValues(alpha: 0.5), s.color.withValues(alpha: 0.7)],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), start, seg, true, p);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r), start, seg, true,
        Paint()..color = Colors.white.withValues(alpha: 0.04)..style = PaintingStyle.stroke..strokeWidth = 1,
      );

      canvas.save();
      canvas.rotate(start + seg / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: s.reward.displayText,
          style: TextStyle(
            color: Colors.white, fontSize: r > 80 ? 10 : 8,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(r * 0.50 - tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter o) => o.angle != angle;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 - 12, 0)
      ..lineTo(size.width / 2 + 12, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Particle ────────────────────────────────────────────────────────────────

class _Particle {
  double x, y, vx, vy, life;
  Color color;

  _Particle(this.x, this.y, this.vx, this.vy, this.life, this.color);

  factory _Particle._random() {
    final rng = math.Random();
    const colors = [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF6347), Color(0xFFFF4500)];
    return _Particle(
      rng.nextDouble(),
      rng.nextDouble() * 0.6,
      (rng.nextDouble() - 0.5) * 0.01,
      -(rng.nextDouble() * 0.02 + 0.005),
      0.5 + rng.nextDouble() * 0.5,
      colors[rng.nextInt(colors.length)],
    );
  }

  void _reset() {
    final rng = math.Random();
    x = rng.nextDouble();
    y = 0.5 + rng.nextDouble() * 0.3;
    vx = (rng.nextDouble() - 0.5) * 0.01;
    vy = -(rng.nextDouble() * 0.02 + 0.005);
    life = 0.5 + rng.nextDouble() * 0.5;
  }
}

// ── Result overlay ─────────────────────────────────────────────────────────

class _ResultOverlay extends StatelessWidget {
  final WheelReward reward;
  final bool claimed;
  final AnimationController popupCtrl;
  final VoidCallback onClaim;
  final VoidCallback onContinue;

  const _ResultOverlay({
    required this.reward,
    required this.claimed,
    required this.popupCtrl,
    required this.onClaim,
    required this.onContinue,
  });

  Color _rarityColor() => switch (reward.rarity) {
    RewardRarity.common => Colors.greenAccent,
    RewardRarity.medium => Colors.purpleAccent,
    RewardRarity.rare => Colors.orangeAccent,
    RewardRarity.jackpot => Colors.amber,
  };

  @override
  Widget build(BuildContext context) {
    final rc = _rarityColor();
    return Material(
      color: Colors.black87,
      child: AnimatedBuilder(
        animation: popupCtrl,
        builder: (context, _) {
          final scale = 0.3 + popupCtrl.value * 0.7;
          final opacity = popupCtrl.value;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!reward.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: rc.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: rc.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            reward.rarity == RewardRarity.jackpot ? 'JACKPOT!' : 'RECOMPENSA',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: rc),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (reward.isEmpty)
                        const Icon(Icons.sentiment_neutral, size: 56, color: Colors.white38)
                      else
                        Text(reward.icon, style: const TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text('+${reward.amount}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(reward.label,
                          style: TextStyle(fontSize: 14, color: rc.withValues(alpha: 0.8))),
                      const SizedBox(height: 28),
                      if (!reward.isEmpty && !claimed)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onClaim,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: rc,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 8,
                              shadowColor: rc.withValues(alpha: 0.5),
                            ),
                            child: const Text('RECOGER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 3)),
                          ),
                        ),
                      if (claimed)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                              SizedBox(width: 8),
                              Text('RECOGIDO', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            ],
                          ),
                        ),
                      if (claimed || reward.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: onContinue,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('CONTINUAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
