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
    final modeStr = prefs.getString('setting_assist_mode') ?? 'classic';
    state = SettingsModel(
      vibrateOnError: prefs.getBool('setting_vibrate_on_error') ?? true,
      highlightRegion: prefs.getBool('setting_highlight_region') ?? true,
      highlightSameNumbers:
          prefs.getBool('setting_highlight_same_numbers') ?? true,
      boardAnimations: prefs.getBool('setting_board_animations') ?? true,
      intenseSubgrids: prefs.getBool('setting_intense_subgrids') ?? false,
      showAutoComplete: prefs.getBool('setting_show_auto_complete') ?? true,
      autoCandidates: prefs.getBool('setting_auto_candidates') ?? true,
      assistMode: AssistMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => AssistMode.classic,
      ),
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_vibrate_on_error', state.vibrateOnError);
    await prefs.setBool('setting_highlight_region', state.highlightRegion);
    await prefs.setBool('setting_highlight_same_numbers', state.highlightSameNumbers);
    await prefs.setBool('setting_board_animations', state.boardAnimations);
    await prefs.setBool('setting_intense_subgrids', state.intenseSubgrids);
    await prefs.setBool('setting_show_auto_complete', state.showAutoComplete);
    await prefs.setBool('setting_auto_candidates', state.autoCandidates);
    await prefs.setString('setting_assist_mode', state.assistMode.name);
  }

  Future<void> setVibrateOnError(bool value) async {
    state = state.copyWith(vibrateOnError: value);
    await _save();
  }

  Future<void> setHighlightRegion(bool value) async {
    state = state.copyWith(highlightRegion: value);
    await _save();
  }

  Future<void> setHighlightSameNumbers(bool value) async {
    state = state.copyWith(highlightSameNumbers: value);
    await _save();
  }

  Future<void> setBoardAnimations(bool value) async {
    state = state.copyWith(boardAnimations: value);
    await _save();
  }

  Future<void> setIntenseSubgrids(bool value) async {
    state = state.copyWith(intenseSubgrids: value);
    await _save();
  }

  Future<void> setShowAutoComplete(bool value) async {
    state = state.copyWith(showAutoComplete: value);
    await _save();
  }

  Future<void> setAutoCandidates(bool value) async {
    state = state.copyWith(autoCandidates: value);
    await _save();
  }

  Future<void> setAssistMode(AssistMode mode) async {
    state = state.copyWith(assistMode: mode);
    await _save();
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsModel>(SettingsNotifier.new);
