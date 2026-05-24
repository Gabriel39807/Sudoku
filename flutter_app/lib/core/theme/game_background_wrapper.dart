import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/customization/application/customization_provider.dart';

class GameBackgroundWrapper extends ConsumerWidget {
  final Widget child;

  const GameBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = ref.watch(customizationProvider).background;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bg.gradientColors,
        ),
      ),
      child: child,
    );
  }
}
