import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TrophyCollection {
  final Set<String> completedDates;

  const TrophyCollection({this.completedDates = const {}});

  static const _storageKey = 'trophy_collection';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(completedDates.toList()));
  }

  static Future<TrophyCollection> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return const TrophyCollection();
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return TrophyCollection(completedDates: list.toSet());
    } catch (_) {
      return const TrophyCollection();
    }
  }

  static Future<TrophyCollection> markDate(DateTime date) async {
    final key = _dateKey(date);
    final existing = await load();
    final updated = TrophyCollection(
      completedDates: {...existing.completedDates, key},
    );
    await updated.save();
    return updated;
  }

  bool isCompleted(DateTime date) => completedDates.contains(_dateKey(date));

  int countForMonth(int year, int month) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    return completedDates.where((d) => d.startsWith(prefix)).length;
  }

  int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String dateKey(DateTime date) => _dateKey(date);
}
