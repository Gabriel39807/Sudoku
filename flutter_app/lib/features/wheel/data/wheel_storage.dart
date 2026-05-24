import 'package:shared_preferences/shared_preferences.dart';

class WheelStorage {
  static const _key = 'wheel_last_spin_date';
  static const _extraKey = 'wheel_extra_spins';

  static Future<bool> isSpunToday() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_key);
    if (last == null) return false;
    return last == _todayKey();
  }

  static Future<void> markSpun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _todayKey());
  }

  static Future<int> getExtraSpins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_extraKey) ?? 0;
  }

  static Future<void> addExtraSpins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_extraKey) ?? 0;
    await prefs.setInt(_extraKey, current + amount);
  }

  static Future<bool> useExtraSpin() async {
    final current = await getExtraSpins();
    if (current <= 0) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_extraKey, current - 1);
    return true;
  }

  /// Premium spin pack: adds 5 extra spins (purchased)
  static Future<void> premiumSpinPack() async {
    await addExtraSpins(5);
  }

  /// Token spin pack: costs tokens, adds 3 extra spins
  static Future<bool> tokenSpinPack() async {
    return useExtraSpin();
  }

  static String _todayKey() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
