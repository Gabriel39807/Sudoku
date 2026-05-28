import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/player_level.dart';
import '../domain/achievement.dart';
import '../domain/daily_mission.dart';
import '../data/progression_storage.dart';
import '../../economy/application/wallet_provider.dart';

/// Notifier for player level & XP.
class PlayerLevelNotifier extends Notifier<PlayerLevel> {
  @override
  PlayerLevel build() {
    _load();
    return const PlayerLevel();
  }

  Future<void> _load() async {
    state = await ProgressionStorage.loadPlayerLevel();
  }

  /// Add XP, auto level-up, return number of levels gained.
  Future<int> addXp(int amount) async {
    final oldLevel = state.level;
    state = PlayerLevel.addXp(state, amount);
    await ProgressionStorage.savePlayerLevel(state);
    final levelsGained = state.level - oldLevel;
    if (levelsGained > 0) {
      final rng = math.Random();
      final gems = 5 + rng.nextInt(6); // 5–10 gems per level
      await ref.read(walletProvider.notifier).addGems(gems * levelsGained);
    }
    return levelsGained;
  }

  Future<void> reload() async {
    state = await ProgressionStorage.loadPlayerLevel();
  }
}

final playerLevelProvider = NotifierProvider<PlayerLevelNotifier, PlayerLevel>(
  PlayerLevelNotifier.new,
);

// ── Achievements ────────────────────────────────────────────────────────────

class AchievementNotifier extends Notifier<Map<String, Achievement>> {
  @override
  Map<String, Achievement> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    state = await ProgressionStorage.loadAchievements();
  }

  Future<void> checkAndUpdate(String id, int newProgress) async {
    final registry = AchievementRegistry.byId(id);
    if (registry == null) return;
    final current = state[id] ?? registry;
    if (current.unlocked) return;

    final progress = newProgress > current.progress ? newProgress : current.progress;
    final unlocked = progress >= current.target && !current.unlocked;

    state = {
      ...state,
      id: current.copyWith(
        progress: progress,
        unlocked: unlocked,
        unlockedAt: unlocked ? DateTime.now() : null,
      ),
    };

    if (unlocked) {
      await ProgressionStorage.saveAchievements(state);
    }
  }

  // Batch update multiple achievements at once
  Future<List<String>> checkBatch(Map<String, int> updates) async {
    final newlyUnlocked = <String>[];
    var changed = false;

    for (final e in updates.entries) {
      final registry = AchievementRegistry.byId(e.key);
      if (registry == null) continue;
      final current = state[e.key] ?? registry;
      if (current.unlocked) continue;

      final progress = e.value > current.progress ? e.value : current.progress;
      final unlocked = progress >= current.target && !current.unlocked;

      if (unlocked) newlyUnlocked.add(e.key);
      if (progress != current.progress || unlocked) {
        changed = true;
        state = {
          ...state,
          e.key: current.copyWith(
            progress: progress,
            unlocked: unlocked,
            unlockedAt: unlocked ? DateTime.now() : null,
          ),
        };
      }
    }

    if (changed) {
      await ProgressionStorage.saveAchievements(state);
    }
    return newlyUnlocked;
  }

  Future<void> reload() async {
    state = await ProgressionStorage.loadAchievements();
  }
}

final achievementsProvider = NotifierProvider<AchievementNotifier, Map<String, Achievement>>(
  AchievementNotifier.new,
);

// ── Daily Missions ──────────────────────────────────────────────────────────

class MissionNotifier extends Notifier<List<DailyMission>> {
  @override
  List<DailyMission> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    state = await ProgressionStorage.loadMissions();
  }

  Future<void> updateProgress(String id, int delta) async {
    var changed = false;
    state = state.map((m) {
      if (m.id != id || m.completed) return m;
      final newProgress = m.progress + delta;
      final completed = newProgress >= m.target;
      if (newProgress != m.progress || completed != m.completed) changed = true;
      return m.copyWith(progress: newProgress.clamp(0, m.target), completed: completed);
    }).toList();

    if (changed) {
      await ProgressionStorage.saveMissions(state);
    }
  }

  Future<void> reload() async {
    state = await ProgressionStorage.loadMissions();
  }
}

final missionsProvider = NotifierProvider<MissionNotifier, List<DailyMission>>(
  MissionNotifier.new,
);
