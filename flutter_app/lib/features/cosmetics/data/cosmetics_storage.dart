import 'package:shared_preferences/shared_preferences.dart';

class CosmeticsStorage {
  static const _keyTheme = 'cosmetic_selected_theme';
  static const _keyFrame = 'cosmetic_selected_frame';

  Future<void> saveSelectedTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, themeId);
  }

  Future<String> loadSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTheme) ?? 'default';
  }

  Future<void> saveSelectedFrame(String frameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFrame, frameId);
  }

  Future<String> loadSelectedFrame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFrame) ?? 'default';
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTheme);
    await prefs.remove(_keyFrame);
  }
}
