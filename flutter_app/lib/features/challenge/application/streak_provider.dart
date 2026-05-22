import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/daily_streak.dart';
import '../data/streak_storage.dart';

class StreakNotifier extends Notifier<DailyStreak> {
  @override
  DailyStreak build() {
    _load();
    return const DailyStreak();
  }

  Future<void> _load() async {
    state = await StreakStorage.load();
  }

  Future<void> reload() async {
    state = await StreakStorage.load();
  }

  Future<void> onDailyWin() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastDate = state.lastDailyDate != null
        ? DateTime(state.lastDailyDate!.year, state.lastDailyDate!.month, state.lastDailyDate!.day)
        : null;

    final yesterday = today.subtract(const Duration(days: 1));

    int newStreak;
    if (lastDate == null || lastDate.isBefore(yesterday)) {
      newStreak = 1;
    } else if (lastDate == yesterday) {
      newStreak = state.currentStreak + 1;
    } else if (lastDate == today) {
      return;
    } else {
      newStreak = 1;
    }

    final newBest = newStreak > state.bestStreak ? newStreak : state.bestStreak;

    state = DailyStreak(
      currentStreak: newStreak,
      bestStreak: newBest,
      lastDailyDate: today,
    );

    await StreakStorage.save(state);
  }
}

final streakProvider = NotifierProvider<StreakNotifier, DailyStreak>(
  StreakNotifier.new,
);
