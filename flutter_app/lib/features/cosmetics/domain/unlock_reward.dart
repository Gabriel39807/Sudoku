import 'dart:async';
import 'package:flutter/material.dart';
import 'avatar_def.dart';
import '../models/background_cosmetic.dart';

// ── Reward Model ──────────────────────────────────────────────────────────

enum RewardType {
  background,
  avatar,
  frame,
  boardFrame,
  achievement,
  levelUp,
}

class UnlockReward {
  final String id;
  final RewardType type;
  final AvatarRarity rarity;
  final String title;
  final String description;
  final String cosmeticId;
  final Map<String, dynamic>? metadata;

  const UnlockReward({
    required this.id,
    required this.type,
    required this.rarity,
    required this.title,
    this.description = '',
    required this.cosmeticId,
    this.metadata,
  });

  static UnlockReward fromBackground(BackgroundCosmetic bg) {
    final rarity = bg.rarity.toAvatarRarity();
    return UnlockReward(
      id: 'bg_reward_${bg.id}',
      type: RewardType.background,
      rarity: rarity,
      title: bg.name,
      cosmeticId: bg.id,
      metadata: {'assetPath': bg.assetPath},
    );
  }

  static UnlockReward fromRarityString({
    required String id,
    required RewardType type,
    required String rarityName,
    required String title,
    required String cosmeticId,
    String description = '',
    Map<String, dynamic>? metadata,
  }) {
    final rarity = _parseRarity(rarityName);
    return UnlockReward(
      id: id,
      type: type,
      rarity: rarity,
      title: title,
      description: description,
      cosmeticId: cosmeticId,
      metadata: metadata,
    );
  }

  static AvatarRarity _parseRarity(String name) {
    switch (name.toLowerCase()) {
      case 'common':
        return AvatarRarity.common;
      case 'rare':
      case 'raro':
        return AvatarRarity.rare;
      case 'epic':
      case 'épico':
      case 'epico':
        return AvatarRarity.epic;
      case 'legendary':
      case 'legendario':
        return AvatarRarity.legendary;
      case 'mythic':
      case 'mítico':
      case 'mitico':
        return AvatarRarity.mythic;
      default:
        return AvatarRarity.common;
    }
  }
}

extension RarityConversion on Rarity {
  AvatarRarity toAvatarRarity() {
    switch (this) {
      case Rarity.common:
        return AvatarRarity.common;
      case Rarity.rare:
        return AvatarRarity.rare;
      case Rarity.epic:
        return AvatarRarity.epic;
      case Rarity.legendary:
        return AvatarRarity.legendary;
    }
  }
}

// ── Rarity Theme Helpers ──────────────────────────────────────────────────

class RarityTheme {
  static Color glowColor(AvatarRarity rarity) {
    switch (rarity) {
      case AvatarRarity.common:
        return Colors.white38;
      case AvatarRarity.rare:
        return const Color(0xFF2196F3);
      case AvatarRarity.epic:
        return const Color(0xFF9C27B0);
      case AvatarRarity.legendary:
        return const Color(0xFFFF9800);
      case AvatarRarity.mythic:
        return const Color(0xFFE91E63);
    }
  }

  static List<Color> gradient(AvatarRarity rarity) {
    switch (rarity) {
      case AvatarRarity.common:
        return [const Color(0xFF616161), const Color(0xFF424242)];
      case AvatarRarity.rare:
        return [const Color(0xFF1565C0), const Color(0xFF0D47A1)];
      case AvatarRarity.epic:
        return [const Color(0xFF7B1FA2), const Color(0xFF4A148C)];
      case AvatarRarity.legendary:
        return [const Color(0xFFFF6F00), const Color(0xFFE65100)];
      case AvatarRarity.mythic:
        return [const Color(0xFFC2185B), const Color(0xFF880E4F)];
    }
  }

  static Color particleColor(AvatarRarity rarity) {
    switch (rarity) {
      case AvatarRarity.common:
        return Colors.white24;
      case AvatarRarity.rare:
        return const Color(0xFF64B5F6);
      case AvatarRarity.epic:
        return const Color(0xFFCE93D8);
      case AvatarRarity.legendary:
        return const Color(0xFFFFB74D);
      case AvatarRarity.mythic:
        return const Color(0xFFF48FB1);
    }
  }

  static double glowRadius(AvatarRarity rarity) {
    switch (rarity) {
      case AvatarRarity.common:
        return 8;
      case AvatarRarity.rare:
        return 12;
      case AvatarRarity.epic:
        return 18;
      case AvatarRarity.legendary:
        return 28;
      case AvatarRarity.mythic:
        return 36;
    }
  }
}

// ── Queue System ──────────────────────────────────────────────────────────

class _QueuedReward {
  final UnlockReward reward;
  final Completer<String?> completer;
  _QueuedReward({required this.reward, required this.completer});
}

class RewardQueue {
  static final List<_QueuedReward> _queue = [];
  static bool _isShowing = false;

  static Future<String?> show(BuildContext context, UnlockReward reward) {
    final completer = Completer<String?>();
    _queue.add(_QueuedReward(reward: reward, completer: completer));
    if (!_isShowing) _processQueue(context);
    return completer.future;
  }

  static Future<void> _processQueue(BuildContext context) async {
    while (_queue.isNotEmpty) {
      _isShowing = true;
      final entry = _queue.removeAt(0);
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (_) => _CosmeticUnlockModalContent(reward: entry.reward),
      );
      entry.completer.complete(result);
    }
    _isShowing = false;
  }
}

// ── Modal Content ─────────────────────────────────────────────────────────

class _CosmeticUnlockModalContent extends StatefulWidget {
  final UnlockReward reward;
  const _CosmeticUnlockModalContent({required this.reward});

  @override
  State<_CosmeticUnlockModalContent> createState() =>
      _CosmeticUnlockModalContentState();
}

class _CosmeticUnlockModalContentState
    extends State<_CosmeticUnlockModalContent>
    with TickerProviderStateMixin {
  late AnimationController _backdropCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _textCtrl;
  late AnimationController _shineCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _glowCtrl;

  late final List<_Particle> _particles;
  late final List<_OrbitingParticle> _orbiting;
  final _particleRng = math.Random(42);
  final _orbitalRng = math.Random(84);

  @override
  void initState() {
    super.initState();
    _backdropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _particles = List.generate(
      30,
      (i) => _Particle(
        x: _particleRng.nextDouble(),
        y: _particleRng.nextDouble(),
        size: 1.5 + _particleRng.nextDouble() * 3,
        speed: 0.02 + _particleRng.nextDouble() * 0.04,
        opacity: 0.2 + _particleRng.nextDouble() * 0.5,
      ),
    );

    _orbiting = List.generate(
      widget.reward.rarity == AvatarRarity.mythic ? 6 : 0,
      (i) => _OrbitingParticle(
        angle: (i / 6) * 2 * math.pi,
        radius: 70 + i * 8,
        size: 2 + _orbitalRng.nextDouble() * 2,
        speed: 0.3 + _orbitalRng.nextDouble() * 0.2,
        direction: i.isEven ? 1 : -1,
      ),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    _backdropCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _particleCtrl.repeat();
    _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    _textCtrl.forward();
    _shineCtrl.repeat();
    if (widget.reward.rarity.index >= AvatarRarity.legendary.index) {
      await Future.delayed(const Duration(milliseconds: 100));
      _glowCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _backdropCtrl.dispose();
    _cardCtrl.dispose();
    _textCtrl.dispose();
    _shineCtrl.dispose();
    _particleCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rarity = widget.reward.rarity;
    final isPremium = rarity.index >= AvatarRarity.legendary.index;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _backdropCtrl,
          _cardCtrl,
          _textCtrl,
          _shineCtrl,
          _particleCtrl,
          _glowCtrl,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              _buildBackdrop(rarity),
              _buildParticleLayer(),
              if (isPremium) _buildOrbitalLayer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildRewardCard(rarity),
                    const SizedBox(height: 20),
                    _buildButtonRow(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Backdrop ────────────────────────────────────────────────────────────

  Widget _buildBackdrop(AvatarRarity rarity) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              RarityTheme.glowColor(rarity).withValues(alpha: 0.15 * _backdropCtrl.value),
              Colors.black.withValues(alpha: 0.85 * _backdropCtrl.value),
              Colors.black,
            ],
            radius: 0.8,
            focal: const Alignment(0, -0.3),
          ),
        ),
        child: BackdropFilter(
          filter: _backdropCtrl.value > 0.5
              ? ImageFilter.blur(sigmaX: 4 * (_backdropCtrl.value - 0.5) * 2, sigmaY: 4 * (_backdropCtrl.value - 0.5) * 2)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  // ── Particles ───────────────────────────────────────────────────────────

  Widget _buildParticleLayer() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            controller: _particleCtrl,
            color: RarityTheme.particleColor(widget.reward.rarity),
            opacity: _backdropCtrl.value,
          ),
        ),
      ),
    );
  }

  Widget _buildOrbitalLayer() {
    if (_orbiting.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _OrbitalPainter(
            particles: _orbiting,
            controller: _particleCtrl,
            color: RarityTheme.particleColor(widget.reward.rarity),
            visibility: _textCtrl.value,
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Opacity(
      opacity: _textCtrl.value,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - _textCtrl.value)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¡NUEVO DESBLOQUEO!',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: RarityTheme.glowColor(widget.reward.rarity).withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.reward.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reward Card ─────────────────────────────────────────────────────────

  Widget _buildRewardCard(AvatarRarity rarity) {
    final cardScale = Curves.easeOutBack.transform(_cardCtrl.value);
    final cardOpacity = _cardCtrl.value;
    final isPremium = rarity.index >= AvatarRarity.legendary.index;

    return Opacity(
      opacity: cardOpacity,
      child: Transform.scale(
        scale: 0.6 + cardScale * 0.4,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: RarityTheme.gradient(rarity),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: RarityTheme.glowColor(rarity).withValues(alpha: 0.3 + _glowCtrl.value * 0.3),
                blurRadius: RarityTheme.glowRadius(rarity),
                spreadRadius: 2 + _glowCtrl.value * 4,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.08 * _shineCtrl.value),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment(-1.5 + 3 * _shineCtrl.value, 0),
                          end: Alignment(1.5 - 3 * _shineCtrl.value, 0),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    _buildPreview(),
                    const SizedBox(height: 16),
                    _buildItemName(),
                    const SizedBox(height: 6),
                    _buildRarityBadge(rarity),
                    const SizedBox(height: 24),
                  ],
                ),
                if (isPremium)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: RarityTheme.glowColor(rarity)
                                .withValues(alpha: 0.15 + _glowCtrl.value * 0.15),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Preview ─────────────────────────────────────────────────────────────

  Widget _buildPreview() {
    final reward = widget.reward;

    switch (reward.type) {
      case RewardType.avatar:
        return PlayerProfileAvatar(
          avatarId: reward.cosmeticId,
          frameId: reward.metadata?['frameId'] as String?,
          size: 100,
          showBreathing: false,
        );

      case RewardType.frame:
        return SizedBox(
          width: 120,
          height: 120,
          child: PlayerProfileAvatar(
            avatarId: reward.metadata?['avatarId'] as String?,
            frameId: reward.cosmeticId,
            size: 80,
            showBreathing: false,
          ),
        );

      case RewardType.background:
        final bgPath =
            reward.metadata?['assetPath'] as String? ?? _assetPathFor(reward.cosmeticId);
        return Container(
          width: 200,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(bgPath, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black26],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: RarityTheme.glowColor(reward.rarity),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'FONDO DE JUEGO',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: RarityTheme.glowColor(reward.rarity),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case RewardType.boardFrame:
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 8,
                  child: Image.asset(
                    'assets/cosmetics/frames/${reward.cosmeticId}/tl.webp',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Image.asset(
                    'assets/cosmetics/frames/${reward.cosmeticId}/tr.webp',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Image.asset(
                    'assets/cosmetics/frames/${reward.cosmeticId}/bl.webp',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Image.asset(
                    'assets/cosmetics/frames/${reward.cosmeticId}/br.webp',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                Center(
                  child: Text(
                    reward.title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case RewardType.achievement:
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                RarityTheme.glowColor(reward.rarity).withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(
            Icons.emoji_events,
            size: 56,
            color: RarityTheme.glowColor(reward.rarity),
          ),
        );

      case RewardType.levelUp:
        final level = reward.metadata?['level'] as int? ?? 1;
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                RarityTheme.glowColor(reward.rarity).withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'NIVEL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: Colors.white54,
                ),
              ),
              Text(
                '$level',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: RarityTheme.glowColor(reward.rarity),
                ),
              ),
            ],
          ),
        );
    }
  }

  String _assetPathFor(String bgId) {
    try {
      return 'assets/cosmetics/backgrounds/$bgId/bg.webp';
    } catch (_) {
      return '';
    }
  }

  // ── Item Name ───────────────────────────────────────────────────────────

  Widget _buildItemName() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        widget.reward.title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Rarity Badge ────────────────────────────────────────────────────────

  Widget _buildRarityBadge(AvatarRarity rarity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: RarityTheme.gradient(rarity),
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: RarityTheme.glowColor(rarity).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 10, color: RarityTheme.glowColor(rarity)),
          const SizedBox(width: 6),
          Text(
            rarity.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: RarityTheme.glowColor(rarity),
            ),
          ),
        ],
      ),
    );
  }

  // ── Button Row ──────────────────────────────────────────────────────────

  Widget _buildButtonRow() {
    final btnOpacity = _cardCtrl.value;
    final rarity = widget.reward.rarity;

    return Opacity(
      opacity: btnOpacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PremiumButton(
            label: 'EQUIPAR',
            rarity: rarity,
            onTap: () => Navigator.pop(context, 'equip'),
          ),
          const SizedBox(height: 10),
          _GlassButton(
            label: 'VER',
            rarity: rarity,
            onTap: () => Navigator.pop(context, 'view'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.pop(context, 'continue'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              child: Text(
                'CONTINUAR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Premium Button ─────────────────────────────────────────────────────────

class _PremiumButton extends StatelessWidget {
  final String label;
  final AvatarRarity rarity;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.label,
    required this.rarity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: RarityTheme.gradient(rarity),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: RarityTheme.glowColor(rarity).withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass Button ───────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final String label;
  final AvatarRarity rarity;
  final VoidCallback onTap;

  const _GlassButton({
    required this.label,
    required this.rarity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: RarityTheme.glowColor(rarity).withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility, size: 14, color: RarityTheme.glowColor(rarity)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: RarityTheme.glowColor(rarity).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Particle System ─────────────────────────────────────────────────────────

class _Particle {
  final double x, y, size, speed, opacity;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final AnimationController controller;
  final Color color;
  final double opacity;

  _ParticlePainter({
    required this.particles,
    required this.controller,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final t = controller.value;

    for (final p in particles) {
      final yOffset = (t * p.speed * size.height) % size.height;
      final y = (p.y * size.height - yOffset + size.height) % size.height;
      final alpha = (p.opacity * opacity * (0.5 + 0.5 * (y / size.height))).clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(p.x * size.width, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

class _OrbitingParticle {
  double angle;
  final double radius, size, speed;
  final int direction;

  _OrbitingParticle({
    required this.angle,
    required this.radius,
    required this.size,
    required this.speed,
    required this.direction,
  });
}

class _OrbitalPainter extends CustomPainter {
  final List<_OrbitingParticle> particles;
  final AnimationController controller;
  final Color color;
  final double visibility;

  _OrbitalPainter({
    required this.particles,
    required this.controller,
    required this.color,
    required this.visibility,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (visibility <= 0) return;
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);
    final t = controller.value;

    for (final p in particles) {
      p.angle += p.speed * 0.02 * p.direction;
      final x = center.dx + math.cos(p.angle) * p.radius;
      final y = center.dy + math.sin(p.angle) * p.radius;
      final alpha = (0.4 + 0.3 * math.sin(t * 2 * math.pi + p.angle)) * visibility;

      paint.color = color.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitalPainter oldDelegate) => true;
}
