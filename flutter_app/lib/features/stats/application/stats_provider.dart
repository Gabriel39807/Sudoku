import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stats_storage.dart';
import '../domain/stats_model.dart';

class StatsNotifier extends AsyncNotifier<GameStats> {
  @override
  Future<GameStats> build() => StatsStorage.loadStats();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(StatsStorage.loadStats);
  }

  Future<void> resetStats() async {
    await StatsStorage.resetStats();
    await reload();
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, GameStats>(StatsNotifier.new);
