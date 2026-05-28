import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/time/global_time_service.dart';

class WheelStorage {
  static const _lastSpinEpoch = 'wheel_last_spin_epoch';
  static const _lastKnownEpoch = 'wheel_last_known_epoch';
  static const _dailyWindowKey = 'wheel_daily_window';
  static const _freeUsedKey = 'wheel_free_used';
  static const _extraKey = 'wheel_extra_spins';
  static const _adSpinsKey = 'wheel_ad_spins';

  // ── Free daily spin ─────────────────────────────────────────────────────

  static Future<bool> hasFreeSpinAvailable() async {
    final service = GlobalTimeService.instance;
    final window = await service.currentDailyWindow();
    final prefs = await SharedPreferences.getInstance();
    final storedWindow = prefs.getString(_dailyWindowKey);
    if (storedWindow != window.windowId) return true; // New window = new free spin
    return !(prefs.getBool(_freeUsedKey) ?? false);
  }

  static Future<void> useFreeSpin() async {
    final service = GlobalTimeService.instance;
    final window = await service.currentDailyWindow();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyWindowKey, window.windowId);
    await prefs.setBool(_freeUsedKey, true);
    await _recordSpinTime(await service.serverEpoch());
  }

  // ── Extra spins (from tokens/ads/rewards) ─────────────────────────────

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

  // ── Ad spins (future) ───────────────────────────────────────────────────

  static Future<int> getAdSpins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_adSpinsKey) ?? 0;
  }

  static Future<void> addAdSpin() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_adSpinsKey) ?? 0;
    await prefs.setInt(_adSpinsKey, current + 1);
  }

  static Future<bool> useAdSpin() async {
    final current = await getAdSpins();
    if (current <= 0) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_adSpinsKey, current - 1);
    return true;
  }

  // ── Anti-exploit: epoch tracking ──────────────────────────────────────

  static Future<void> _recordSpinTime(int epoch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSpinEpoch, epoch);
    final lastKnown = prefs.getInt(_lastKnownEpoch) ?? 0;
    if (epoch > lastKnown) {
      await prefs.setInt(_lastKnownEpoch, epoch);
    }
  }

  static Future<int> getLastSpinEpoch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSpinEpoch) ?? 0;
  }

  /// Returns true if the time is safe (not rolled back).
  static Future<bool> isTimeSafe(int serverEpoch) async {
    final prefs = await SharedPreferences.getInstance();
    final lastKnown = prefs.getInt(_lastKnownEpoch) ?? 0;
    if (lastKnown > 0 && serverEpoch < lastKnown) return false;
    final diff = (serverEpoch - lastKnown).abs();
    if (diff > 86400 * 7) return false; // >7 day jump is suspicious
    return true;
  }

  // ── Reset ────────────────────────────────────────────────────────────────

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSpinEpoch);
    await prefs.remove(_dailyWindowKey);
    await prefs.remove(_freeUsedKey);
    await prefs.remove(_extraKey);
    await prefs.remove(_adSpinsKey);
  }
}
