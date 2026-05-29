import 'dart:async';

import '../domain/game_result.dart';
import 'stats_storage.dart';

class StatsService {
  static final _updates = StreamController<void>.broadcast();

  static Stream<void> get updates => _updates.stream;

  static Future<void> recordGameResult(GameResult result) async {
    await StatsStorage.recordGameResult(result);
    _emit();
  }

  static Future<void> onGameStart(String difficulty) async {
    await StatsStorage.recordGameStarted(difficulty);
    await onUnlockProgress();
  }

  static Future<void> onGameExit(String difficulty, int elapsedSeconds) async {
    await StatsStorage.recordGameExit(difficulty, elapsedSeconds);
    _emit();
  }

  static Future<void> onVictory(
    String difficulty,
    int elapsedSeconds, {
    required int mistakes,
    required int hintsUsed,
    int completedWithAutocomplete = 0,
    int maxCombo = 0,
    int totalNoteUsage = 0,
  }) async {
    await StatsStorage.recordWin(
      difficulty,
      elapsedSeconds,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
      completedWithAutocomplete: completedWithAutocomplete,
      maxCombo: maxCombo,
      totalNoteUsage: totalNoteUsage,
    );
    await onUnlockProgress();
  }

  static Future<void> onDefeat(String difficulty, int elapsedSeconds) async {
    await StatsStorage.recordLoss(difficulty, elapsedSeconds);
    _emit();
  }

  static Future<void> onHintUsed(String difficulty) async {
    await StatsStorage.recordHintUsed(difficulty);
    _emit();
  }

  static Future<void> onFirstDifficultyOpen(String difficulty) async {
    _emit();
  }

  static Future<void> onUnlockProgress() async {
    _emit();
  }

  static void _emit() {
    if (!_updates.isClosed) _updates.add(null);
  }
}
