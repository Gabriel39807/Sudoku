import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../domain/campaign_level.dart';
import '../domain/campaign_progress.dart';
import '../application/campaign_provider.dart';
import '../../game/application/game_provider.dart';
import '../../progression/application/progression_provider.dart';
import '../../progression/domain/player_level.dart';
import '../../../ui/currency/currency_assets.dart';
import '../../../ui/currency/currency_type.dart';

class CampaignLevelCompleteCard extends ConsumerStatefulWidget {
  final int level;
  final int elapsedSeconds;
  final int mistakes;
  final bool victory;
  final int? forcedStars;
  final bool showNext;
  final bool showPlatinum;
  final bool defeatMode;
  final VoidCallback? onContinue;
  final VoidCallback? onRepeat;
  final VoidCallback? onHome;

  const CampaignLevelCompleteCard({
    super.key,
    required this.level,
    required this.elapsedSeconds,
    required this.mistakes,
    this.victory = true,
    this.forcedStars,
    this.showNext = true,
    this.showPlatinum = true,
    this.defeatMode = false,
    this.onContinue,
    this.onRepeat,
    this.onHome,
  });

  @override
  ConsumerState<CampaignLevelCompleteCard> createState() => _CampaignLevelCompleteCardState();
}

class _CampaignLevelCompleteCardState extends ConsumerState<CampaignLevelCompleteCard>
    with TickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late AnimationController _glowCtrl;
  late List<_CardParticle> _particles;
  late List<_CardParticle> _confetti;

  static const _motivationalMessages = [
    'Cada intento mejora tu ruta',
    'Las 3 estrellas siguen disponibles',
    'Vuelve por el platino',
    'La práctica lleva a la perfección',
    'Seguí mejorando, nivel por nivel',
    'El próximo intento será el mejor',
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    final isBoss = CampaignStage.fromLevel(widget.level).isBossLevel(widget.level);
    _particles = List.generate(20, (i) => _CardParticle(
      x: math.Random().nextDouble(),
      y: math.Random().nextDouble(),
      size: isBoss ? 3 + math.Random().nextDouble() * 7 : 2 + math.Random().nextDouble() * 4,
      delay: i * (isBoss ? 50 : 80),
      type: isBoss ? _ParticleType.fire : _ParticleType.sparkle,
    ));
    _confetti = List.generate(16, (i) => _CardParticle(
      x: 0.1 + math.Random().nextDouble() * 0.8,
      y: 0.1 + math.Random().nextDouble() * 0.8,
      size: 2 + math.Random().nextDouble() * 3,
      delay: i * 60 + 300,
      type: _ParticleType.confetti,
    ));
  }

  bool get _hasParticles {
    if (widget.defeatMode) return false;
    final stage = CampaignStage.fromLevel(widget.level);
    return stage.isBossLevel(widget.level) || _computePlatinum();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  CampaignLevelResult? get _savedResult => ref.read(campaignProvider).resultFor(widget.level);

  bool _computePlatinum() => _stars >= 3;

  int get _calculatedStars {
    final stage = CampaignStage.fromLevel(widget.level);
    if (stage.isBossLevel(widget.level)) return widget.mistakes == 0 ? 3 : 1;
    final variant = stage.variant;
    final maxTime = switch (variant.boardSize) { 4 => 60, 6 => 180, 8 => 300, _ => 600 };
    final noErrors = widget.mistakes == 0;
    final timeOk = widget.elapsedSeconds <= maxTime;
    if (noErrors && timeOk) return 3;
    if (noErrors || timeOk) return 2;
    return 1;
  }

  int get _stars {
    if (widget.forcedStars != null) return widget.forcedStars!;
    final result = _savedResult;
    if (result != null) return result.stars;
    return _calculatedStars;
  }

  bool get _isPlatinum => _computePlatinum();

  @override
  Widget build(BuildContext context) {
    final stage = CampaignStage.fromLevel(widget.level);
    final isBoss = stage.isBossLevel(widget.level);
    final nextLevel = widget.level + 1;
    final isLast = nextLevel > stage.levelEnd;
    final canContinue = !isLast;
    final result = ref.watch(campaignProvider).resultFor(widget.level);
    final xpEarned = result?.xpEarned ?? 0;
    final displayTokens = result?.tokensEarned ?? 0;
    final displayGems = result?.gemsEarned ?? 0;
    final playerLevel = ref.watch(playerLevelProvider);
    final nextStage = isLast ? null : CampaignStage.fromLevel(nextLevel);
    final nextChapter = nextStage?.chapterForLevel(nextLevel);
    final stars = _stars;
    final isPlatinum = _isPlatinum;
    final currentChapter = stage.chapterForLevel(widget.level);
    final isChapterEnd = currentChapter != null && currentChapter.endLevel == widget.level && !isLast;
    final maxTime = switch (stage.variant.boardSize) { 4 => 60, 6 => 180, 8 => 300, _ => 600 };
    final gameState = ref.read(gameProvider);
    final hints = gameState.hintsUsed;
    final retries = gameState.retries;
    final continueCount = gameState.continuesUsed;
    final showParticles = _hasParticles && !widget.defeatMode;
    final showConfetti = isChapterEnd && !widget.defeatMode;
    final showChapterCompletion = isChapterEnd && !widget.defeatMode;
    final showStageCompleteNotice = isLast && !widget.defeatMode;

    // Defeat mode
    final int displayStars = widget.defeatMode ? 0 : stars;
    final bool displayIsPlatinum = widget.defeatMode ? false : isPlatinum;
    final int displayXpEarned = widget.defeatMode ? 0 : xpEarned;
    final int displayTokensEarned = widget.defeatMode ? 0 : displayTokens;
    final int displayGemsEarned = widget.defeatMode ? 0 : displayGems;

    // Random motivational message for 1★ (stable across builds)
    final motiMsg = _motivationalMessages[widget.level % _motivationalMessages.length];

    return Material(
      color: Colors.black87,
      child: Stack(
        children: [
          if (showParticles)
            ..._particles.map((p) => AnimatedBuilder(
              animation: _animCtrl,
              builder: (_, _) => Positioned(
                left: p.x * MediaQuery.of(context).size.width,
                top: p.y * MediaQuery.of(context).size.height,
                child: Opacity(
                  opacity: (_animCtrl.value - p.delay / 700).clamp(0.0, 1.0),
                  child: _particleWidget(p),
                ),
              ),
            )),
          if (showConfetti)
            ..._confetti.map((c) => AnimatedBuilder(
              animation: _animCtrl,
              builder: (_, _) => Positioned(
                left: c.x * MediaQuery.of(context).size.width,
                top: c.y * MediaQuery.of(context).size.height,
                child: Opacity(
                  opacity: (_animCtrl.value - c.delay / 700).clamp(0.0, 1.0),
                  child: Container(
                    width: c.size, height: c.size * 1.6,
                    decoration: BoxDecoration(
                      color: [Colors.amber, Colors.orange, Colors.cyan, Colors.pink, Colors.greenAccent]
                          [(_confetti.indexOf(c) % 5)],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            )),
          Center(
            child: FadeTransition(
              opacity: _animCtrl,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Container(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        maxHeight: constraints.maxHeight * 0.92,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isBoss
                              ? (widget.defeatMode
                                  ? [const Color(0xFF2A0A0A), const Color(0xFF1A0A0A)]
                                  : [const Color(0xFF2A0A0A), const Color(0xFF1A0A2E)])
                              : (widget.defeatMode
                                  ? [const Color(0xFF1A0A0A), const Color(0xFF0F0F0F)]
                                  : stars == 1
                                      ? [const Color(0xFF0D1B2A), const Color(0xFF1B2838)]
                                      : [const Color(0xFF1A1A2E), const Color(0xFF16213E)]),
                        ),
                        border: Border.all(
                          color: isBoss
                              ? Colors.amber.withValues(alpha: 0.4)
                              : widget.defeatMode
                                  ? Colors.redAccent.withValues(alpha: 0.3)
                                  : displayIsPlatinum
                                      ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.1),
                          width: isBoss ? 2 : displayIsPlatinum ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isBoss
                                ? Colors.amber.withValues(alpha: 0.25)
                                : widget.defeatMode
                                    ? Colors.redAccent.withValues(alpha: 0.15)
                                    : displayIsPlatinum
                                        ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                                        : Colors.amber.withValues(alpha: 0.08),
                            blurRadius: isBoss ? 50 : displayIsPlatinum ? 40 : 30,
                            spreadRadius: isBoss ? 8 : displayIsPlatinum ? 5 : 3,
                          ),
                          if (isBoss && !widget.defeatMode)
                            BoxShadow(color: Colors.red.withValues(alpha: 0.12), blurRadius: 30, spreadRadius: 3),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── STARS ─────────────────────────────────────
                              _StarsRow(
                                stars: displayStars,
                                isPlatinum: displayIsPlatinum,
                                starCount: stars,
                              ),
                              if (displayIsPlatinum) ...[
                                const SizedBox(height: 6),
                                _PlatinumBadge(),
                              ],
                              const SizedBox(height: 14),

                              // ── HEADER ────────────────────────────────────
                              _HeaderSection(
                                isBoss: isBoss,
                                level: widget.level,
                                stageName: stage.name,
                                bossType: isBoss ? stage.bossTypeForLevel(widget.level) : null,
                                isDefeat: widget.defeatMode,
                                stars: stars,
                              ),
                              const SizedBox(height: 18),

                              // ── REWARDS ───────────────────────────────────
                              _RewardCards(
                                gems: displayGemsEarned,
                                tokens: displayTokensEarned,
                                xp: displayXpEarned,
                              ),
                              const SizedBox(height: 14),

                              // ── XP BAR ────────────────────────────────────
                              _XpBar(playerLevel: playerLevel, xpEarned: displayXpEarned),
                              const SizedBox(height: 14),

                              // ── STAR FEEDBACK ─────────────────────────────
                              // 3★: next level premium preview
                              if (displayStars == 3 && canContinue && !widget.defeatMode && nextStage != null)
                                _NextLevelPreview(
                                  currentLevel: widget.level,
                                  nextLevel: nextLevel,
                                  nextChapterName: nextChapter?.name ?? 'Nuevo nivel',
                                  nextStage: nextStage,
                                  isBossNext: nextStage.isBossLevel(nextLevel),
                                ),
                              // 3★ but stage complete: show stage notice
                              if (displayStars == 3 && showStageCompleteNotice)
                                _StageCompleteNotice(stageName: stage.name),

                              // 2★: OBJETIVO PERDIDO card
                              if (displayStars == 2 && !widget.defeatMode)
                                _ObjectiveFeedback(
                                  stars: stars,
                                  mistakes: widget.mistakes,
                                  elapsedSeconds: widget.elapsedSeconds,
                                  maxTime: maxTime,
                                  hints: hints,
                                  retries: retries,
                                  continueCount: continueCount,
                                ),

                              // 1★: detailed feedback card
                              if (displayStars == 1 && !widget.defeatMode)
                                _OneStarFeedback(
                                  stars: stars,
                                  mistakes: widget.mistakes,
                                  elapsedSeconds: widget.elapsedSeconds,
                                  maxTime: maxTime,
                                  hints: hints,
                                  retries: retries,
                                  continueCount: continueCount,
                                  message: motiMsg,
                                ),

                              const SizedBox(height: 14),

                              // ── CHAPTER COMPLETION ────────────────────────
                              if (showChapterCompletion) _ChapterCompletionBadge(
                                chapterNumber: currentChapter.number,
                                chapterName: currentChapter.name,
                              ),
                              if (showChapterCompletion) const SizedBox(height: 16),

                              // ── BUTTONS ───────────────────────────────────
                              _ButtonSection(
                                stars: displayStars,
                                canContinue: canContinue,
                                isBoss: isBoss,
                                glowCtrl: _glowCtrl,
                                onContinue: _onContinue,
                                onHome: _onHome,
                                onRepeat: _onRepeat,
                                onPlatinum: _onRepeat,
                                isDefeatMode: widget.defeatMode,
                                showPlatinum: widget.showPlatinum && stars < 3 && !widget.defeatMode && !isBoss,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _particleWidget(_CardParticle p) {
    return switch (p.type) {
      _ParticleType.fire => Container(
        width: p.size, height: p.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.amber.withValues(alpha: 0.5),
          boxShadow: [BoxShadow(color: Colors.amber, blurRadius: p.size * 2)],
        ),
      ),
      _ParticleType.sparkle => Container(
        width: p.size, height: p.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFD700).withValues(alpha: 0.6),
          boxShadow: [BoxShadow(color: const Color(0xFFFFD700), blurRadius: p.size * 3)],
        ),
      ),
      _ParticleType.confetti => const SizedBox.shrink(),
    };
  }

  void _onContinue() {
    if (!mounted) return;
    widget.onContinue?.call();
  }

  void _onRepeat() {
    if (!mounted) return;
    widget.onRepeat?.call();
  }

  void _onHome() {
    if (!mounted) return;
    widget.onHome?.call();
  }
}

enum _ParticleType { fire, sparkle, confetti }

class _CardParticle {
  final double x;
  final double y;
  final double size;
  final int delay;
  final _ParticleType type;
  _CardParticle({required this.x, required this.y, required this.size, required this.delay, required this.type});
}

// ── STARS ────────────────────────────────────────────────────────────────────

class _StarsRow extends StatefulWidget {
  final int stars;
  final bool isPlatinum;
  final int starCount;
  const _StarsRow({required this.stars, required this.isPlatinum, this.starCount = 3});

  @override
  State<_StarsRow> createState() => _StarsRowState();
}

class _StarsRowState extends State<_StarsRow> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i < widget.stars;
        final isMissing = !filled && widget.starCount == 2 && i == 2;
        final color = filled
            ? (widget.isPlatinum ? const Color(0xFFFFD700) : Colors.amber)
            : (widget.starCount == 1 && i < 2
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.12));

        Widget star;
        if (filled && widget.stars == 3) {
          // 3★: full entrance + shimmer
          star = Icon(Icons.star, size: 44, color: color);
          star = star.animate().scale(delay: (i * 150).ms, duration: 400.ms, curve: Curves.easeOutBack)
              .then().shimmer(delay: 600.ms, duration: 2500.ms, color: Colors.white.withValues(alpha: 0.3));
        } else if (filled) {
          // 1★ or 2★: entrance
          star = Icon(Icons.star, size: 44, color: color);
          star = star.animate().scale(delay: (i * 150).ms, duration: 400.ms, curve: Curves.easeOutBack);
        } else if (isMissing && widget.stars == 2) {
          // The missing 3rd star for 2★: soft pulse
          star = AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) => Opacity(
              opacity: 0.5 + _pulseCtrl.value * 0.3,
              child: Icon(Icons.star_border, size: 44, color: Colors.white.withValues(alpha: 0.25)),
            ),
          );
        } else if (widget.stars == 1 && i < 2) {
          // Empty stars for 1★: dim glow
          star = AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) => Opacity(
              opacity: 0.3 + _pulseCtrl.value * 0.15,
              child: Icon(Icons.star_border, size: 44, color: Colors.white.withValues(alpha: 0.2)),
            ),
          );
        } else {
          star = Icon(Icons.star_border, size: 44, color: Colors.white.withValues(alpha: 0.1));
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: star,
        );
      }),
    );
  }
}

class _PlatinumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 3),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 12, color: Colors.black87),
          const SizedBox(width: 6),
          const Text('PLATINADO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.black87,
              )),
        ],
      ),
    ).animate().fade(delay: 500.ms, duration: 400.ms).scale(delay: 500.ms, begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack);
  }
}

// ── HEADER ───────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final bool isBoss;
  final int level;
  final String stageName;
  final BossType? bossType;
  final bool isDefeat;
  final int stars;

  const _HeaderSection({
    required this.isBoss,
    required this.level,
    required this.stageName,
    this.bossType,
    this.isDefeat = false,
    this.stars = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDefeat) ...[
          const Icon(Icons.sentiment_dissatisfied, size: 34, color: Colors.redAccent)
              .animate().fade().scale(begin: Offset(0, 0), curve: Curves.easeOutBack),
          const SizedBox(height: 4),
          Text('INTÉNTALO DE NUEVO',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 2,
                color: Colors.redAccent,
              )).animate().fade(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 4),
          Text('Nivel $level · Reintenta para avanzar',
              style: const TextStyle(fontSize: 13, color: Colors.white54),
          ).animate().fade(delay: 400.ms, duration: 400.ms),
        ] else if (isBoss) ...[
          Icon(Icons.whatshot, size: 34, color: Colors.orange.shade400)
              .animate().shake(duration: 600.ms),
          const SizedBox(height: 4),
          Text('JEFE DERROTADO',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 3,
                color: Colors.amber,
              )).animate().fade(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 4),
          Text('${bossType?.label ?? ''} · ${bossType?.description ?? ''}',
              style: const TextStyle(fontSize: 11, color: Colors.white54, letterSpacing: 1),
          ).animate().fade(delay: 400.ms, duration: 400.ms),
        ] else if (stars == 3) ...[
          Text('PERFECTO',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 4,
                color: Color(0xFFFFD700),
              )).animate().fade(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 4),
          Text('Nivel $level · $stageName',
              style: const TextStyle(fontSize: 13, color: Colors.white54),
          ).animate().fade(delay: 400.ms, duration: 400.ms),
        ] else if (stars == 2) ...[
          Text('NIVEL SUPERADO',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 3,
                color: Colors.white,
              )).animate().fade(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 4),
          Text('Nivel $level · $stageName',
              style: const TextStyle(fontSize: 13, color: Colors.white54),
          ).animate().fade(delay: 400.ms, duration: 400.ms),
        ] else ...[
          Text('NIVEL SUPERADO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 3,
                color: Colors.amber.shade200,
              )).animate().fade(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 4),
          Text('Todavía podés mejorar este nivel',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
          ).animate().fade(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 2),
          Text('Nivel $level · $stageName',
              style: const TextStyle(fontSize: 12, color: Colors.white38),
          ).animate().fade(delay: 450.ms, duration: 400.ms),
        ],
      ],
    );
  }
}

// ── REWARDS ──────────────────────────────────────────────────────────────────

class _RewardCards extends StatelessWidget {
  final int gems;
  final int tokens;
  final int xp;
  const _RewardCards({required this.gems, required this.tokens, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _RewardCard(
          icon: CurrencyAssets.iconFor(CurrencyType.gems),
          amount: gems,
          label: 'GEMS',
          color: CurrencyAssets.colorFor(CurrencyType.gems),
          delay: 200,
        )),
        const SizedBox(width: 8),
        Expanded(child: _RewardCard(
          icon: CurrencyAssets.iconFor(CurrencyType.tokens),
          amount: tokens,
          label: 'TOKENS',
          color: CurrencyAssets.colorFor(CurrencyType.tokens),
          delay: 300,
        )),
        const SizedBox(width: 8),
        Expanded(child: _RewardCard(
          icon: Icons.auto_awesome,
          amount: xp,
          label: 'XP',
          color: Colors.amber,
          delay: 400,
        )),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  final IconData icon;
  final int amount;
  final String label;
  final Color color;
  final int delay;

  const _RewardCard({
    required this.icon,
    required this.amount,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('+$amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: color.withValues(alpha: 0.6))),
        ],
      ),
    ).animate().fade(delay: delay.ms, duration: 400.ms).slideY(begin: 0.3, delay: delay.ms, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

// ── XP BAR ───────────────────────────────────────────────────────────────────

class _XpBar extends StatelessWidget {
  final PlayerLevel playerLevel;
  final int xpEarned;
  const _XpBar({required this.playerLevel, required this.xpEarned});

  @override
  Widget build(BuildContext context) {
    if (xpEarned <= 0) return const SizedBox.shrink();
    final pct = (playerLevel.progress * 100).round();
    final remaining = playerLevel.xpForNext - playerLevel.currentXp;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('NIVEL ${playerLevel.level}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1, color: Colors.white)),
              const Spacer(),
              Text('+$xpEarned XP',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: playerLevel.progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ),
          if (remaining > 0) ...[
            const SizedBox(height: 6),
            Text('$pct% · $remaining XP para nivel ${playerLevel.level + 1}',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3))),
          ],
        ],
      ),
    ).animate().fade(delay: 500.ms, duration: 400.ms).slideY(begin: 0.2, delay: 500.ms, duration: 400.ms);
  }
}

// ── 3★: NEXT LEVEL PREVIEW ──────────────────────────────────────────────────

class _NextLevelPreview extends StatelessWidget {
  final int currentLevel;
  final int nextLevel;
  final String nextChapterName;
  final CampaignStage nextStage;
  final bool isBossNext;

  const _NextLevelPreview({
    required this.currentLevel,
    required this.nextLevel,
    required this.nextChapterName,
    required this.nextStage,
    this.isBossNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final variantName = switch (nextStage.variant.boardSize) {
      4 => 'Mini Sudoku',
      6 => 'Sudoku 6×6',
      8 => 'Sudoku 8×8',
      _ => 'Sudoku Clásico',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isBossNext
              ? [Colors.red.withValues(alpha: 0.1), Colors.orange.withValues(alpha: 0.05)]
              : [const Color(0xFFFFD700).withValues(alpha: 0.08), Colors.amber.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBossNext
              ? Colors.red.withValues(alpha: 0.2)
              : const Color(0xFFFFD700).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('PRÓXIMO',
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2,
                    color: isBossNext ? Colors.orange.shade300 : const Color(0xFFFFD700).withValues(alpha: 0.6),
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Nivel $nextLevel',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(variantName,
                    style: const TextStyle(fontSize: 10, color: Colors.white54)),
              ),
              if (isBossNext) ...[
                const SizedBox(width: 6),
                Icon(Icons.whatshot, size: 14, color: Colors.orange.shade400),
              ],
            ],
          ),
          if (nextChapterName != 'Nuevo nivel') ...[
            const SizedBox(height: 4),
            Text(nextChapterName,
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35))),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${currentLevel.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 12, color: Colors.white.withValues(alpha: 0.2)),
              ),
              Text('${nextLevel.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ],
      ),
    ).animate().fade(delay: 600.ms, duration: 400.ms).slideY(begin: 0.15, delay: 600.ms, duration: 400.ms);
  }
}

class _StageCompleteNotice extends StatelessWidget {
  final String stageName;
  const _StageCompleteNotice({required this.stageName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withValues(alpha: 0.15), Colors.green.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 20, color: Colors.greenAccent),
          const SizedBox(width: 10),
          Text('${stageName} completado',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
        ],
      ),
    ).animate().fade(delay: 700.ms, duration: 400.ms).scale(delay: 700.ms, begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}

// ── 2★: OBJETIVO PERDIDO ────────────────────────────────────────────────────

class _ObjectiveFeedback extends StatelessWidget {
  final int stars;
  final int mistakes;
  final int elapsedSeconds;
  final int maxTime;
  final int hints;
  final int retries;
  final int continueCount;

  const _ObjectiveFeedback({
    required this.stars,
    required this.mistakes,
    required this.elapsedSeconds,
    required this.maxTime,
    required this.hints,
    required this.retries,
    required this.continueCount,
  });

  @override
  Widget build(BuildContext context) {
    final timeOk = elapsedSeconds <= maxTime;
    final noErrors = mistakes == 0;
    final noHints = hints == 0;
    final noRetries = retries == 0;
    final noContinues = continueCount == 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withValues(alpha: 0.06), Colors.orange.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_border, size: 16, color: Colors.amber.shade300),
              const SizedBox(width: 6),
              Text('OBJETIVO PERDIDO',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2,
                    color: Colors.amber.shade300,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          _ObjectiveRow(icon: Icons.timer_outlined, label: 'Tiempo', ok: timeOk, detail: '$elapsedSeconds s / $maxTime s'),
          const SizedBox(height: 4),
          _ObjectiveRow(icon: Icons.block, label: 'Sin errores', ok: noErrors, detail: mistakes > 0 ? '$mistakes error${mistakes > 1 ? 'es' : ''}' : '0'),
          if (hints > 0) ...[
            const SizedBox(height: 4),
            _ObjectiveRow(icon: Icons.lightbulb_outline, label: 'Sin ayudas', ok: noHints, detail: '$hints ayuda${hints > 1 ? 's' : ''}'),
          ],
          if (retries > 0) ...[
            const SizedBox(height: 4),
            _ObjectiveRow(icon: Icons.replay, label: 'Sin reinicios', ok: noRetries, detail: '$retries reinicio${retries > 1 ? 's' : ''}'),
          ],
          if (continueCount > 0) ...[
            const SizedBox(height: 4),
            _ObjectiveRow(icon: Icons.autorenew, label: 'Sin continuar', ok: noContinues, detail: '$continueCount continuacione${continueCount > 1 ? 's' : ''}'),
          ],
          if (noErrors && noHints && noRetries && noContinues && !timeOk) ...[],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 12, color: Colors.amber.shade300),
              const SizedBox(width: 6),
              Text('Reintentá para conseguir PLATINO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade300)),
            ],
          ),
        ],
      ),
    ).animate().fade(delay: 700.ms, duration: 400.ms).slideY(begin: 0.15, delay: 700.ms, duration: 400.ms);
  }
}

class _ObjectiveRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ok;
  final String detail;
  const _ObjectiveRow({required this.icon, required this.label, required this.ok, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel, size: 14,
            color: ok ? Colors.greenAccent : Colors.redAccent),
        const SizedBox(width: 6),
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
        const Spacer(),
        Text(detail,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: ok ? Colors.greenAccent : Colors.redAccent.shade200)),
      ],
    );
  }
}

// ── 1★: DETAILED FEEDBACK ────────────────────────────────────────────────────

class _OneStarFeedback extends StatelessWidget {
  final int stars;
  final int mistakes;
  final int elapsedSeconds;
  final int maxTime;
  final int hints;
  final int retries;
  final int continueCount;
  final String message;

  const _OneStarFeedback({
    required this.stars,
    required this.mistakes,
    required this.elapsedSeconds,
    required this.maxTime,
    required this.hints,
    required this.retries,
    required this.continueCount,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.withValues(alpha: 0.08), Colors.blueGrey.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FeedbackRow(icon: Icons.block, label: 'Errores', value: mistakes.toString()),
          const SizedBox(height: 4),
          _FeedbackRow(icon: Icons.lightbulb_outline, label: 'Ayudas', value: hints.toString()),
          const SizedBox(height: 4),
          _FeedbackRow(icon: Icons.timer_outlined, label: 'Tiempo', value: '$elapsedSeconds s'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology_outlined, size: 14, color: Colors.amber.shade200),
              const SizedBox(width: 6),
              Flexible(
                child: Text(message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade200, fontStyle: FontStyle.italic)),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(delay: 700.ms, duration: 400.ms).slideY(begin: 0.15, delay: 700.ms, duration: 400.ms);
  }
}

class _FeedbackRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _FeedbackRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}

// ── BUTTONS ─────────────────────────────────────────────────────────────────

class _ButtonSection extends StatelessWidget {
  final int stars;
  final bool canContinue;
  final bool isBoss;
  final Animation<double> glowCtrl;
  final VoidCallback onContinue;
  final VoidCallback onHome;
  final VoidCallback onRepeat;
  final VoidCallback onPlatinum;
  final bool isDefeatMode;
  final bool showPlatinum;

  const _ButtonSection({
    required this.stars,
    required this.canContinue,
    required this.isBoss,
    required this.glowCtrl,
    required this.onContinue,
    required this.onHome,
    required this.onRepeat,
    required this.onPlatinum,
    required this.isDefeatMode,
    required this.showPlatinum,
  });

  @override
  Widget build(BuildContext context) {
    if (isDefeatMode) return _defeatButtons();
    if (stars == 3) return _threeStarButtons();
    if (stars == 2) return _twoStarButtons();
    return _oneStarButtons();
  }

  // ── DEFEAT (0★): REINTENTAR + MAPA ──────────────────────────────────────
  Widget _defeatButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PrimaryButton(
          label: 'REINTENTAR',
          glowCtrl: glowCtrl,
          color: Colors.redAccent,
          onPressed: onRepeat,
          delay: 1000,
        ),
        const SizedBox(height: 10),
        _SecondaryRow(buttons: [
          _SecondaryButton(label: 'MAPA', onPressed: onHome, delay: 1100),
          const SizedBox(width: 10),
          _SecondaryButton(label: '', onPressed: null, delay: 0, invisible: true),
        ]),
      ],
    );
  }

  // ── 3★: CONTINUAR + REINTENTAR + MAPA ────────────────────────────────────
  Widget _threeStarButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PrimaryButton(
          label: canContinue ? 'CONTINUAR' : 'VOLVER AL MAPA',
          glowCtrl: glowCtrl,
          color: isBoss ? Colors.amber.shade700 : null,
          onPressed: canContinue ? onContinue : onHome,
          delay: 1000,
        ),
        if (canContinue) ...[
          const SizedBox(height: 4),
          Text('Abrir siguiente nivel',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
        ],
        const SizedBox(height: 10),
        _SecondaryRow(buttons: [
          _SecondaryButton(label: 'REINTENTAR', onPressed: onRepeat, delay: 1100),
          const SizedBox(width: 10),
          _SecondaryButton(label: 'MAPA', onPressed: onHome, delay: 1100),
        ]),
      ],
    );
  }

  // ── 2★: SIGUIENTE NIVEL + PLATINAR + MAPA ───────────────────────────────
  Widget _twoStarButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PrimaryButton(
          label: canContinue ? 'SIGUIENTE NIVEL' : 'VOLVER AL MAPA',
          glowCtrl: glowCtrl,
          color: null,
          onPressed: canContinue ? onContinue : onHome,
          delay: 1000,
        ),
        const SizedBox(height: 10),
        _SecondaryRow(buttons: [
          if (showPlatinum)
            _SecondaryButton(label: 'PLATINAR', onPressed: onPlatinum, delay: 1100, strong: true),
          const SizedBox(width: 10),
          _SecondaryButton(label: 'MAPA', onPressed: onHome, delay: 1100),
        ]),
      ],
    );
  }

  // ── 1★: SIGUIENTE NIVEL + REINTENTAR + MAPA ─────────────────────────────
  Widget _oneStarButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PrimaryButton(
          label: canContinue ? 'SIGUIENTE NIVEL' : 'VOLVER AL MAPA',
          glowCtrl: glowCtrl,
          color: null,
          onPressed: canContinue ? onContinue : onHome,
          delay: 1000,
        ),
        const SizedBox(height: 10),
        _SecondaryRow(buttons: [
          _SecondaryButton(label: 'REINTENTAR', onPressed: onRepeat, delay: 1100),
          const SizedBox(width: 10),
          _SecondaryButton(label: 'MAPA', onPressed: onHome, delay: 1100),
        ]),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Animation<double> glowCtrl;
  final Color? color;
  final VoidCallback onPressed;
  final int delay;

  const _PrimaryButton({
    required this.label,
    required this.glowCtrl,
    this.color,
    required this.onPressed,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: AnimatedBuilder(
        animation: glowCtrl,
        builder: (context, _) => ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 8 + glowCtrl.value * 4,
            shadowColor: (color ?? Theme.of(context).primaryColor)
                .withValues(alpha: 0.3 + glowCtrl.value * 0.2),
          ),
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
        ),
      ),
    ).animate().fade(delay: delay.ms, duration: 400.ms).slideY(begin: 0.2, delay: delay.ms, duration: 400.ms);
  }
}

class _SecondaryRow extends StatelessWidget {
  final List<Widget> buttons;
  const _SecondaryRow({required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons,
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final int delay;
  final bool strong;
  final bool invisible;

  const _SecondaryButton({
    required this.label,
    this.onPressed,
    required this.delay,
    this.strong = false,
    this.invisible = false,
  });

  @override
  Widget build(BuildContext context) {
    if (invisible) {
      return const Expanded(child: SizedBox.shrink());
    }
    if (strong) {
      return Expanded(
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.withValues(alpha: 0.12),
            foregroundColor: Colors.amber.shade200,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: Colors.amber.withValues(alpha: 0.25)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 11, color: Colors.amber.shade200),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1,
                    color: Colors.amber.shade200,
                  )),
            ],
          ),
        ),
      ).animate().fade(delay: delay.ms, duration: 400.ms);
    }
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45), fontWeight: FontWeight.bold)),
      ),
    ).animate().fade(delay: delay.ms, duration: 400.ms);
  }
}

// ── CHAPTER COMPLETION ──────────────────────────────────────────────────────

class _ChapterCompletionBadge extends StatelessWidget {
  final int chapterNumber;
  final String chapterName;
  const _ChapterCompletionBadge({required this.chapterNumber, required this.chapterName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withValues(alpha: 0.15), Colors.orange.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard, size: 20, color: Colors.amber),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CAPÍTULO $chapterNumber COMPLETADO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2,
                      color: Colors.amber.withValues(alpha: 0.7))),
              Text(chapterName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ],
      ),
    ).animate().fade(delay: 800.ms, duration: 500.ms).scale(delay: 800.ms, begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack);
  }
}