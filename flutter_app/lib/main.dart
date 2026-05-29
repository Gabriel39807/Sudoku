import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router/router.dart';
import 'app/theme/theme.dart';
import 'features/customization/application/customization_provider.dart';
import 'features/rewards/presentation/reward_overlay_widget.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SudokuApp(),
    ),
  );
}

class SudokuApp extends ConsumerWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(customizationProvider).palette;
    return MaterialApp.router(
      title: 'Sudoku Classic',
      theme: buildTheme(palette),
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Stack(
        children: [
          if (child != null) child,
          const RewardOverlayWidget(),
        ],
      ),
    );
  }
}
