import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/avatar_def.dart';
import '../../domain/avatar_frame_def.dart';

class PlayerProfileAvatar extends StatefulWidget {
  final String? avatarId;
  final String? frameId;
  final double size;
  final bool showGlow;
  final bool showBreathing;
  final VoidCallback? onTap;

  const PlayerProfileAvatar({
    super.key,
    this.avatarId,
    this.frameId,
    this.size = 64,
    this.showGlow = true,
    this.showBreathing = true,
    this.onTap,
  });

  @override
  State<PlayerProfileAvatar> createState() => _PlayerProfileAvatarState();
}

class _PlayerProfileAvatarState extends State<PlayerProfileAvatar>
    with TickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _rotateCtrl.dispose();
    _glowCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.onTap == null) return;
    _tapCtrl.forward().then((_) => _tapCtrl.reverse());
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final avatar =
        AvatarCatalog.byId(widget.avatarId ?? AvatarCatalog.defaultId) ??
            AvatarCatalog.defaultAvatar;
    final frame = widget.frameId != null
        ? AvatarFrameCatalog.byId(widget.frameId!)
        : null;

    final frameThickness = frame?.thickness ?? 0;
    final glowRadius = (widget.showGlow ? frame?.glowRadius ?? 0 : 0);
    final totalSize = widget.size + frameThickness * 2 + glowRadius;

    return AnimatedBuilder(
      animation: Listenable.merge([_breathCtrl, _rotateCtrl, _glowCtrl, _tapCtrl]),
      builder: (context, _) {
        final breath =
            1.0 + (widget.showBreathing ? _breathCtrl.value * 0.03 : 0);
        final angle = _rotateCtrl.value * 2 * math.pi;
        final glowPulse = _glowCtrl.value;
        final tapScale = 1.0 - _tapCtrl.value * 0.05;

        final child = Transform.scale(
          scale: breath * tapScale,
          child: SizedBox(
            width: totalSize,
            height: totalSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (frame != null && frameThickness > 0)
                  _buildFrameRing(
                    frame,
                    totalSize,
                    angle,
                    avatar.isAnimated || frame.isAnimated,
                    glowPulse,
                  ),
                _buildAvatarDisk(avatar),
              ],
            ),
          ),
        );

        if (widget.onTap != null) {
          return GestureDetector(onTap: _onTap, child: child);
        }
        return child;
      },
    );
  }

  Widget _buildFrameRing(
    AvatarFrameDef frame,
    double totalSize,
    double angle,
    bool animated,
    double glowPulse,
  ) {
    final glowRadius = frame.glowRadius;

    return Container(
      width: totalSize,
      height: totalSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: animated
            ? SweepGradient(
                colors: [
                  frame.primaryColor,
                  frame.secondaryColor,
                  frame.primaryColor,
                  frame.secondaryColor,
                  frame.primaryColor,
                ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                transform: GradientRotation(angle),
              )
            : SweepGradient(
                colors: [
                  frame.primaryColor,
                  frame.secondaryColor,
                  frame.primaryColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
        boxShadow: glowRadius > 0
            ? [
                BoxShadow(
                  color: frame.primaryColor
                      .withValues(alpha: 0.3 + glowPulse * 0.25),
                  blurRadius: glowRadius + glowPulse * 6,
                  spreadRadius: glowRadius * 0.3,
                ),
                BoxShadow(
                  color: frame.secondaryColor.withValues(alpha: 0.15 + glowPulse * 0.15),
                  blurRadius: glowRadius * 1.5,
                  spreadRadius: 1 + glowPulse * 2,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(frame.thickness),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF121212),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarDisk(AvatarDef avatar) {
    final diskSize = widget.size;
    final isMythic = avatar.rarity == AvatarRarity.mythic;
    final isLegendary = avatar.rarity == AvatarRarity.legendary;

    return Container(
      width: diskSize,
      height: diskSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isMythic
            ? SweepGradient(
                colors: [
                  avatar.color1,
                  avatar.color2,
                  avatar.color1.withValues(alpha: 0.7),
                  avatar.color2,
                  avatar.color1,
                ],
                stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
              )
            : LinearGradient(
                colors: [avatar.color1, avatar.color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: isLegendary || isMythic
            ? [
                BoxShadow(
                  color: avatar.color1.withValues(alpha: 0.35 + _glowCtrl.value * 0.2),
                  blurRadius: 12,
                  spreadRadius: 2 + _glowCtrl.value * 3,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          avatar.icon,
          size: diskSize * 0.45,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
