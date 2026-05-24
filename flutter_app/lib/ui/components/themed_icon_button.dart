import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_extensions.dart';

class ThemedIconButton extends ConsumerWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;

  const ThemedIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.palette;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.cardBackground,
            border: Border.all(color: p.cardBorder),
          ),
          child: Icon(icon, size: size * 0.45),
        ),
      ),
    );
  }
}
