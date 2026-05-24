import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_extensions.dart';

class ThemedProgress extends ConsumerWidget {
  final double value;
  final double height;
  final Color? color;

  const ThemedProgress({
    super.key,
    required this.value,
    this.height = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: p.border,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? p.primary),
      ),
    );
  }
}
