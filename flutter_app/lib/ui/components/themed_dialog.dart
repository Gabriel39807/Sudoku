import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/theme_tokens.dart';
import '../../shared/widgets/game_modal_card.dart';

class ThemedDialog extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onClose;

  const ThemedDialog({
    super.key,
    required this.child,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.palette;
    return GameModalCard(
      onClose: onClose ?? () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ThemeTokens.cardRadius),
          border: Border.all(color: p.cardBorder),
        ),
        child: child,
      ),
    );
  }
}
