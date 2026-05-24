import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/theme_tokens.dart';

class ThemedCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? borderColor;
  final bool glow;
  final double? glowColorOpacity;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.glow = false,
    this.glowColorOpacity,
    this.width,
    this.margin,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.palette;
    final br = borderRadius ?? ThemeTokens.cardRadius;
    final pad = padding ?? EdgeInsets.all(ThemeTokens.cardPadding);

    List<BoxShadow> shadows;
    if (boxShadow != null) {
      shadows = boxShadow!;
    } else if (glow) {
      shadows = [
        BoxShadow(
          color: p.glow.withValues(alpha: glowColorOpacity ?? 0.15),
          blurRadius: 24,
          spreadRadius: 4,
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    }

    return Container(
      width: width,
      margin: margin,
      padding: pad,
      decoration: BoxDecoration(
        color: p.cardBackground,
        borderRadius: BorderRadius.circular(br),
        border: Border.all(color: borderColor ?? p.cardBorder),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
