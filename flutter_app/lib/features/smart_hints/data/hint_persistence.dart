import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/hint_state_model.dart';

class HintPersistence {
  static const _key = 'smart_hints_state';

  static Future<HintState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const HintState();
      final json = Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );
      return HintState.fromJson(json);
    } catch (_) {
      return const HintState();
    }
  }

  static Future<void> save(HintState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}