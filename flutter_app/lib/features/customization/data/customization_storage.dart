import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_palette.dart';
import '../domain/game_background_theme.dart';

class CustomizationStorage {
  static const _paletteKey = 'selected_ui_palette_index';
  static const _bgKey = 'selected_game_background';

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final paletteIdx = prefs.getInt(_paletteKey);
    final bgId = prefs.getString(_bgKey);
    return {
      'palette': paletteIdx != null
          ? AppPalette.fromIndex(paletteIdx)
          : AppPalette.classic,
      'background': bgId != null
          ? GameBackgroundTheme.values.where((b) => b.id == bgId).firstOrNull ?? GameBackgroundTheme.darkSpace
          : GameBackgroundTheme.darkSpace,
    };
  }

  static Future<void> savePaletteIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paletteKey, index);
  }

  static Future<void> saveBackground(GameBackgroundTheme background) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bgKey, background.id);
  }
}
