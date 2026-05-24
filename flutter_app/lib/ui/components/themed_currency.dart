import 'package:flutter/material.dart';
import '../../core/theme/theme_tokens.dart';
import '../currency/currency_type.dart';
import '../currency/currency_assets.dart';

class ThemedCurrency extends StatelessWidget {
  final CurrencyType type;
  final int amount;
  final double size;
  final bool showLabel;
  final bool animated;
  final bool glow;
  final bool compact;

  const ThemedCurrency({
    super.key,
    required this.type,
    required this.amount,
    this.size = ThemeTokens.currencySize,
    this.showLabel = false,
    this.animated = true,
    this.glow = false,
    this.compact = false,
  });

  Color _color() {
    switch (type) {
      case CurrencyType.tokens:
        return const Color(0xFF42A5F5);
      case CurrencyType.souls:
        return const Color(0xFF66BB6A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = CurrencyAssets.iconFor(type);
    final color = _color();
    final label = CurrencyAssets.labelFor(type);

    Widget content;
    if (compact) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          SizedBox(width: ThemeTokens.currencyIconGap),
          Text('$amount',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: size * 0.7, color: color)),
        ],
      );
    } else {
      content = Container(
        padding: EdgeInsets.symmetric(horizontal: size * 0.4, vertical: size * 0.25),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ThemeTokens.radiusFull),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: size, color: color),
            const SizedBox(width: 6),
            Text('$amount',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: size * 0.65, color: color)),
            if (showLabel) ...[
              const SizedBox(width: ThemeTokens.currencyIconGap),
              Text(label,
                  style: TextStyle(fontSize: size * 0.45, color: color.withValues(alpha: 0.6), letterSpacing: 1)),
            ],
          ],
        ),
      );
    }

    if (glow) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ThemeTokens.radiusFull),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: size * 0.5, spreadRadius: size * 0.15),
          ],
        ),
        child: content,
      );
    }

    if (animated) {
      content = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.5 + value * 0.5, child: child),
          );
        },
        child: content,
      );
    }

    return content;
  }
}
