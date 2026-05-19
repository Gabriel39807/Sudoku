import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/stats_model.dart';

/// Capa de acceso a SharedPreferences para estadísticas y tableros jugados.
/// Todos los métodos son static — sin estado interno.
class StatsStorage {
  static const _difficulties = [
    'easy', 'intermediate', 'hard', 'expert', 'evil', 'mythic'
  ];

  // ── Played boards ────────────────────────────────────────────────────────

  static String _playedKey(String diff) => 'played_${diff.toLowerCase()}';

  static Future<Set<String>> getPlayedBoards(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_playedKey(difficulty)) ?? [];
    return list.toSet();
  }

  static Future<void> markBoardPlayed(String difficulty, String boardId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _playedKey(difficulty);
    final current = prefs.getStringList(key) ?? [];
    if (!current.contains(boardId)) {
      current.add(boardId);
      await prefs.setStringList(key, current);
      dev.log('[StatsStorage] Marked $boardId played ($difficulty)');
    }
  }

  static Future<void> resetPlayedBoards() async {
    final prefs = await SharedPreferences.getInstance();
    for (final d in _difficulties) {
      await prefs.remove(_playedKey(d));
    }
    dev.log('[StatsStorage] All played boards reset');
  }

  // ── Game stats ───────────────────────────────────────────────────────────

  static Future<GameStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, int> winsByDiff = {};
    Map<String, int> lossesByDiff = {};
    for (final d in _difficulties) {
      winsByDiff[d] = prefs.getInt('wins_$d') ?? 0;
      lossesByDiff[d] = prefs.getInt('losses_$d') ?? 0;
    }

    return GameStats(
      gamesPlayed: prefs.getInt('games_played') ?? 0,
      gamesWon: prefs.getInt('games_won') ?? 0,
      gamesLost: prefs.getInt('games_lost') ?? 0,
      bestEasy: prefs.getInt('best_easy') ?? 0,
      bestIntermediate: prefs.getInt('best_intermediate') ?? 0,
      bestHard: prefs.getInt('best_hard') ?? 0,
      bestExpert: prefs.getInt('best_expert') ?? 0,
      bestEvil: prefs.getInt('best_evil') ?? 0,
      bestMythic: prefs.getInt('best_mythic') ?? 0,
      winStreak: prefs.getInt('win_streak') ?? 0,
      bestWinStreak: prefs.getInt('best_win_streak') ?? 0,
      winsByDifficulty: winsByDiff,
      lossesByDifficulty: lossesByDiff,
    );
  }

  static Future<void> recordWin(String difficulty, int elapsedSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final diff = difficulty.toLowerCase();

    final played = (prefs.getInt('games_played') ?? 0) + 1;
    final won = (prefs.getInt('games_won') ?? 0) + 1;
    final streak = (prefs.getInt('win_streak') ?? 0) + 1;
    final bestStreak = streak > (prefs.getInt('best_win_streak') ?? 0)
        ? streak
        : prefs.getInt('best_win_streak') ?? 0;
    final wins = (prefs.getInt('wins_$diff') ?? 0) + 1;

    await prefs.setInt('games_played', played);
    await prefs.setInt('games_won', won);
    await prefs.setInt('win_streak', streak);
    await prefs.setInt('best_win_streak', bestStreak);
    await prefs.setInt('wins_$diff', wins);

    // Best time — menor es mejor; 0 = no registrado
    final bestKey = 'best_$diff';
    final currentBest = prefs.getInt(bestKey) ?? 0;
    if (currentBest == 0 || elapsedSeconds < currentBest) {
      await prefs.setInt(bestKey, elapsedSeconds);
    }

    dev.log('[StatsStorage] Win recorded: $diff | elapsed=$elapsedSeconds | streak=$streak');
  }

  static Future<void> recordLoss(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final diff = difficulty.toLowerCase();

    final played = (prefs.getInt('games_played') ?? 0) + 1;
    final lost = (prefs.getInt('games_lost') ?? 0) + 1;
    final losses = (prefs.getInt('losses_$diff') ?? 0) + 1;

    await prefs.setInt('games_played', played);
    await prefs.setInt('games_lost', lost);
    await prefs.setInt('losses_$diff', losses);
    await prefs.setInt('win_streak', 0); // reset streak

    dev.log('[StatsStorage] Loss recorded: $diff');
  }

  static Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      'games_played', 'games_won', 'games_lost',
      'win_streak', 'best_win_streak',
      for (final d in _difficulties) ...[
        'best_$d', 'wins_$d', 'losses_$d',
      ],
    ];
    for (final k in keys) {
      await prefs.remove(k);
    }
    dev.log('[StatsStorage] Stats reset');
  }

  /// Borra TODO: tableros jugados + estadísticas + claves legacy.
  static Future<void> resetAllGameData() async {
    final prefs = await SharedPreferences.getInstance();
    const legacyKeys = ['last_board', 'active_game', 'game_cache', 'old_moves'];
    for (final k in legacyKeys) {
      await prefs.remove(k);
    }
    await resetPlayedBoards();
    await resetStats();
    dev.log('[StatsStorage] Full game data reset');
  }
}
