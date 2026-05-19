import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../data/stats_storage.dart';
import '../data/stats_service.dart';
import '../domain/stats_model.dart';

class StatsNotifier extends AsyncNotifier<GameStats> {
  @override
  Future<GameStats> build() async {
    final subscription = StatsService.updates.listen((_) {
      unawaited(reload());
    });
    ref.onDispose(subscription.cancel);
    return StatsStorage.loadStats();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(StatsStorage.loadStats);
  }

  Future<void> resetStats() async {
    await StatsStorage.resetStats();
    await reload();
  }
}

final statsProvider = AsyncNotifierProvider<StatsNotifier, GameStats>(
  StatsNotifier.new,
);
