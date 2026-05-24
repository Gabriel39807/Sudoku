import 'package:flutter/material.dart';
import 'currency_type.dart';
import 'currency_assets.dart';

class CurrencyWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final icon = CurrencyAssets.iconFor(type);
    final color = CurrencyAssets.colorFor(type);
    final label = CurrencyAssets.labelFor(type);

    Widget content;
    if (compact) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(width: 4),
          Text(
            '$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.7,
              color: color,
            ),
          ),
        ],
      );
    } else {
      content = Container(
        padding: EdgeInsets.symmetric(horizontal: size * 0.4, vertical: size * 0.25),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: size, color: color),
            const SizedBox(width: 6),
            Text(
              '$amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: size * 0.65,
                color: color,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: size * 0.45,
                  color: color.withValues(alpha: 0.6),
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (glow) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: size * 0.5,
              spreadRadius: size * 0.15,
            ),
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
