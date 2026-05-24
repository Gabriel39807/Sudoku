import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/difficulty_model.dart';

class DifficultyCard extends StatefulWidget {
  final DifficultyModel model;
  final VoidCallback onTap;

  const DifficultyCard({super.key, required this.model, required this.onTap});

  @override
  State<DifficultyCard> createState() => _DifficultyCardState();
}

class _DifficultyCardState extends State<DifficultyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;

  static const _accentColors = {
    'easy': Color(0xFF4CAF50),
    'intermediate': Color(0xFF2196F3),
    'hard': Color(0xFFFF9800),
    'expert': Color(0xFFF44336),
    'evil': Color(0xFF9C27B0),
    'mythic': Color(0xFFFFD700),
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color get _accent =>
      _accentColors[widget.model.id] ?? Colors.grey;

  bool get _isLocked => widget.model.state == DifficultyState.locked;
  bool get _isHidden => widget.model.state == DifficultyState.hidden;
  bool get _isBlocked => _isLocked || _isHidden;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _isBlocked ? null : (_) => _animController.forward(),
        onTapUp: _isBlocked ? null : (_) {
          _animController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animController.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: _isHovered ? 0.3 : 0.12),
                  blurRadius: _isHovered ? 24 : 12,
                  spreadRadius: _isHovered ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _accent.withValues(alpha: _isHovered ? 0.6 : 0.25),
                    width: 1.5,
                  ),
                  color: const Color(0xFF1A1A2E),
                ),
                child: Column(
                  children: [
                    Expanded(flex: 68, child: _buildImageSection()),
                    Expanded(flex: 32, child: _buildFooter()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/ui/difficulties/${widget.model.id}.webp',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF16213E),
          ),
        ),
        // Gradient overlay bottom to top
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF1A1A2E).withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Full overlay for locked/hidden
        if (_isHidden)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: const Center(
              child: Text(
                '???',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white24,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        if (_isLocked) ...[
          Container(
            color: Colors.black.withValues(alpha: 0.65),
          ),
          // Blur effect via BackdropFilter
          Positioned.fill(
            child: ClipRRect(
              child: BackdropFilter(
                filter: _blurFilter,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 40, color: _accent.withValues(alpha: 0.7)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.model.unlockRequirement ?? 'Locked',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Difficulty badge top-left
        if (!_isHidden)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withValues(alpha: 0.5)),
              ),
              child: Text(
                widget.model.name,
                style: GoogleFonts.exo2(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: _accent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Static blur to avoid rebuilding
  ImageFilter get _blurFilter {
    _blur ??= ImageFilter.blur(sigmaX: 6, sigmaY: 6);
    return _blur!;
  }
  ImageFilter? _blur;

  Widget _buildFooter() {
    final progress = widget.model.totalCount > 0
        ? widget.model.completedCount / widget.model.totalCount
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isHidden ? '?????' : widget.model.name,
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _isHidden
                ? 'Locked'
                : (_isLocked
                    ? widget.model.unlockRequirement ?? ''
                    : _subtitle),
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: _accent.withValues(alpha: 0.85),
            ),
          ),
          if (!_isHidden) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.model.completedCount} / ${widget.model.totalCount}',
              style: GoogleFonts.exo2(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white38,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _subtitle => widget.model.subtitle;
}
