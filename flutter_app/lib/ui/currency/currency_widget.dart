import 'package:flutter/material.dart';
import 'currency_type.dart';
import 'currency_assets.dart';

class CurrencyWidget extends StatefulWidget {
  final CurrencyType type;
  final int amount;
  final double size;
  final bool showLabel;
  final bool animated;
  final bool compact;
  final bool glow;

  const CurrencyWidget({
    super.key,
    required this.type,
    required this.amount,
    this.size = 24,
    this.showLabel = false,
    this.animated = true,
    this.compact = false,
    this.glow = false,
  });

  @override
  State<CurrencyWidget> createState() => _CurrencyWidgetState();
}

class _CurrencyWidgetState extends State<CurrencyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _popCtrl;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    if (widget.animated && widget.amount > 0) {
      _popCtrl.forward();
    }
  }

  @override
  void didUpdateWidget(CurrencyWidget old) {
    super.didUpdateWidget(old);
    if (old.amount < widget.amount && widget.amount > 0) {
      _popCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = CurrencyAssets.iconFor(widget.type);
    final color = CurrencyAssets.colorFor(widget.type);
    final label = CurrencyAssets.labelFor(widget.type);
    final isGem = widget.type == CurrencyType.gems;

    Widget content;
    if (widget.compact) {
      content = _buildCompact(icon, color, label, isGem);
    } else {
      content = _buildPill(icon, color, label, isGem);
    }

    if (widget.glow) {
      final glowColor = isGem
          ? color.withValues(alpha: 0.3)
          : color.withValues(alpha: 0.4);
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: widget.size * 0.5,
              spreadRadius: widget.size * 0.15,
            ),
          ],
        ),
        child: content,
      );
    }

    return AnimatedBuilder(
      animation: _popCtrl,
      builder: (context, child) {
        final pop = _popCtrl.value;
        final scale = pop > 0
            ? (pop > 0.5
                ? 1.0 + (1.0 - pop) * 0.12
                : 1.0 + pop * 0.2)
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: content,
    );
  }

  Widget _buildCompact(IconData icon, Color color, String label, bool isGem) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(icon, color, isGem),
        const SizedBox(width: 4),
        _buildAmount(color),
      ],
    );
  }

  Widget _buildPill(IconData icon, Color color, String label, bool isGem) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.size * 0.4,
        vertical: widget.size * 0.25,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(icon, color, isGem),
          const SizedBox(width: 6),
          _buildAmount(color),
          if (widget.showLabel) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: widget.size * 0.45,
                color: color.withValues(alpha: 0.6),
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color, bool isGem) {
    if (!isGem) {
      return Icon(icon, size: widget.size, color: color);
    }

    return Container(
      width: widget.size * 1.1,
      height: widget.size * 1.1,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: widget.size * 0.3,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Icon(icon, size: widget.size, color: color),
    );
  }

  Widget _buildAmount(Color color) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [color, color.withValues(alpha: 0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        '${widget.amount}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: widget.compact ? widget.size * 0.7 : widget.size * 0.65,
          color: Colors.white,
        ),
      ),
    );
  }
}
