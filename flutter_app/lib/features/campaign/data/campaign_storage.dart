import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../domain/campaign_progress.dart';

class CampaignStorage {
  static const _key = 'campaign_progress';

  static Future<CampaignProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const CampaignProgress();
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return CampaignProgress.fromJson(data);
    } catch (_) {
      return const CampaignProgress();
    }
  }

  static Future<void> save(CampaignProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(progress.toJson()));
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
