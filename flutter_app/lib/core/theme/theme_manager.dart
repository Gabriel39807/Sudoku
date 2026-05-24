import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/customization/application/customization_provider.dart';
import '../../features/customization/domain/game_background_theme.dart';
import 'theme_palette.dart';

final themePaletteProvider = Provider<AppPalette>((ref) {
  return ref.watch(customizationProvider).palette;
});

final themeBackgroundProvider = Provider<GameBackgroundTheme>((ref) {
  return ref.watch(customizationProvider).background;
});
