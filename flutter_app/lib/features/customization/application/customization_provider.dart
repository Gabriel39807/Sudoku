import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_palette.dart';
import '../domain/game_background_theme.dart';
import '../data/customization_storage.dart';

class CustomizationState {
  final AppPalette? _palette;
  final GameBackgroundTheme background;

  AppPalette get palette => _palette ?? AppPalette.classic;

  CustomizationState({
    AppPalette? palette,
    this.background = GameBackgroundTheme.darkSpace,
  }) : _palette = palette;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomizationState &&
          runtimeType == other.runtimeType &&
          palette == other.palette &&
          background == other.background;

  @override
  int get hashCode => Object.hash(palette, background);

  CustomizationState copyWith({AppPalette? palette, GameBackgroundTheme? background}) {
    return CustomizationState(
      palette: palette ?? this.palette,
      background: background ?? this.background,
    );
  }
}

class CustomizationNotifier extends Notifier<CustomizationState> {
  @override
  CustomizationState build() {
    _load();
    return CustomizationState();
  }

  Future<void> _load() async {
    final data = await CustomizationStorage.load();
    state = CustomizationState(
      palette: data['palette'] as AppPalette? ?? AppPalette.classic,
      background: data['background'] as GameBackgroundTheme? ?? GameBackgroundTheme.darkSpace,
    );
  }

  Future<void> setPalette(AppPalette palette) async {
    state = state.copyWith(palette: palette);
    await CustomizationStorage.savePaletteIndex(AppPalette.all.indexOf(palette));
  }

  Future<void> setBackground(GameBackgroundTheme background) async {
    state = state.copyWith(background: background);
    await CustomizationStorage.saveBackground(background);
  }
}

final customizationProvider = NotifierProvider<CustomizationNotifier, CustomizationState>(
  CustomizationNotifier.new,
);
