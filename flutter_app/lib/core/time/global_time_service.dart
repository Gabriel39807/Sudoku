import 'package:flutter_ntp/flutter_ntp.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dailyResetHour = 4; // 04:00 UTC
const _maxCacheAge = Duration(hours: 12);
const _storageKeyLastEpoch = 'global_time_last_epoch';
const _storageKeySyncEpoch = 'global_time_sync_epoch';

class DailyWindow {
  final String windowId;
  final DateTime start;
  final DateTime end;

  const DailyWindow({required this.windowId, required this.start, required this.end});

  bool contains(DateTime dt) => !dt.isBefore(start) && dt.isBefore(end);
}

class GlobalTimeService {
  static final GlobalTimeService _instance = GlobalTimeService._();
  static GlobalTimeService get instance => _instance;
  GlobalTimeService._();

  int _lastKnownServerEpoch = 0;

  /// Attempts NTP sync. Falls back to cached time (if fresh enough).
  /// Never returns DateTime.now() — returns [DateTime] based on server.
  Future<DateTime> serverNow() async {
    try {
      final ntp = await FlutterNTP.now();
      final corrected = ntp.toUtc();
      await _saveSync(corrected);
      return corrected;
    } catch (_) {
      final cached = await _loadCachedTime();
      if (cached != null) {
        return cached;
      }
      if (_lastKnownServerEpoch > 0) {
        return DateTime.fromMillisecondsSinceEpoch(_lastKnownServerEpoch * 1000, isUtc: true);
      }
      return DateTime.now().toUtc();
    }
  }

  /// Checks if server clock has rolled back (anti-exploit).
  /// Returns true if time is considered valid.
  Future<bool> isTimeValid(DateTime serverTime) async {
    final now = serverTime.millisecondsSinceEpoch ~/ 1000;
    final prefs = await SharedPreferences.getInstance();
    final lastKnown = prefs.getInt(_storageKeySyncEpoch) ?? 0;

    if (lastKnown > 0 && now < lastKnown) {
      return false; // Clock rollback detected
    }

    // Update last known
    await prefs.setInt(_storageKeySyncEpoch, now);
    return true;
  }

  /// Returns the current daily window based on server time.
  Future<DailyWindow> currentDailyWindow() async {
    final now = await serverNow();
    final utc = now.toUtc();
    final windowStart = DateTime.utc(utc.year, utc.month, utc.day, _dailyResetHour);
    final effectiveStart = utc.hour < _dailyResetHour
        ? windowStart.subtract(const Duration(days: 1))
        : windowStart;
    final effectiveEnd = effectiveStart.add(const Duration(hours: 24));
    final windowId = '${effectiveStart.year}-'
        '${effectiveStart.month.toString().padLeft(2, '0')}-'
        '${effectiveStart.day.toString().padLeft(2, '0')}';
    return DailyWindow(windowId: windowId, start: effectiveStart, end: effectiveEnd);
  }

  /// Returns time until next daily reset.
  Future<Duration> timeUntilNextReset() async {
    final window = await currentDailyWindow();
    final now = await serverNow();
    return window.end.difference(now);
  }

  /// Checks if a given windowId matches the current daily window.
  Future<bool> isCurrentWindow(String windowId) async {
    final current = await currentDailyWindow();
    return current.windowId == windowId;
  }

  /// Server-safe: use this instead of DateTime.now() for validation.
  Future<int> serverEpoch() async {
    final now = await serverNow();
    return now.millisecondsSinceEpoch ~/ 1000;
  }

  /// Formats time until next reset for UI display.
  Future<String> timeUntilResetFormatted() async {
    final remaining = await timeUntilNextReset();
    if (remaining.isNegative) return 'Próximamente';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  Future<void> _saveSync(DateTime serverTime) async {
    final prefs = await SharedPreferences.getInstance();
    final epoch = serverTime.millisecondsSinceEpoch ~/ 1000;
    await prefs.setInt(_storageKeyLastEpoch, epoch);
    final lastKnown = prefs.getInt(_storageKeySyncEpoch) ?? 0;
    if (epoch > lastKnown) {
      await prefs.setInt(_storageKeySyncEpoch, epoch);
    }
    _lastKnownServerEpoch = epoch;
  }

  Future<DateTime?> _loadCachedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getInt(_storageKeyLastEpoch);
    if (cached == null) return null;
    final age = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 - cached;
    if (age > _maxCacheAge.inSeconds) return null; // Cache expired
    _lastKnownServerEpoch = cached;
    return DateTime.fromMillisecondsSinceEpoch(cached * 1000, isUtc: true);
  }
}
