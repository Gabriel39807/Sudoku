import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/theme_tokens.dart';

class ThemedPanel extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ThemedPanel({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.palette;
    return Container(
      padding: padding ?? const EdgeInsets.all(ThemeTokens.cardPadding),
      decoration: BoxDecoration(
        color: p.cardBackground,
        borderRadius: BorderRadius.circular(ThemeTokens.cardRadius),
        border: Border.all(color: p.cardBorder),
      ),
      child: child,
    );
  }
}
