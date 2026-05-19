import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/settings_model.dart';

class SettingsNotifier extends Notifier<SettingsModel> {
  @override
  SettingsModel build() {
    _load();
    return const SettingsModel();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsModel(
      vibrateOnError: prefs.getBool('setting_vibrate_on_error') ?? true,
      highlightRegion: prefs.getBool('setting_highlight_region') ?? true,
      highlightSameNumbers:
          prefs.getBool('setting_highlight_same_numbers') ?? true,
      boardAnimations: prefs.getBool('setting_board_animations') ?? true,
      showAutoComplete: prefs.getBool('setting_show_auto_complete') ?? true,
    );
  }

  Future<void> setVibrateOnError(bool value) async {
    state = state.copyWith(vibrateOnError: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_vibrate_on_error', value);
  }

  Future<void> setHighlightRegion(bool value) async {
    state = state.copyWith(highlightRegion: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_highlight_region', value);
  }

  Future<void> setHighlightSameNumbers(bool value) async {
    state = state.copyWith(highlightSameNumbers: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_highlight_same_numbers', value);
  }

  Future<void> setBoardAnimations(bool value) async {
    state = state.copyWith(boardAnimations: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_board_animations', value);
  }

  Future<void> setShowAutoComplete(bool value) async {
    state = state.copyWith(showAutoComplete: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_show_auto_complete', value);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsModel>(SettingsNotifier.new);
