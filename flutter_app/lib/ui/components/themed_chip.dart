import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_extensions.dart';

class ThemedChip extends ConsumerWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final double fontSize;
  final VoidCallback? onTap;

  const ThemedChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.fontSize = 10,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.palette;
    final c = color ?? p.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: c.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(fontSize: fontSize, color: c, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
