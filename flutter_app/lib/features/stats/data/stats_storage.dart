import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/difficulty_stats.dart';
import '../domain/stats_model.dart';
import '../../unlock/unlock_service.dart';

class StatsStorage {
  static const _difficulties = [
    'easy',
    'intermediate',
    'hard',
    'expert',
    'evil',
    'mythic',
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

  static Future<void> resetPlayedBoardsFor(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playedKey(difficulty));
    dev.log('[StatsStorage] Played boards reset for $difficulty');
  }

  // ── Game stats ───────────────────────────────────────────────────────────

  static Future<GameStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrate(prefs);

    Map<String, int> winsByDiff = {};
    Map<String, int> lossesByDiff = {};
    Map<String, int> playedByDiff = {};
    Map<String, DifficultyStats> difficultyStats = {};
    for (final d in _difficulties) {
      final wins = prefs.getInt('wins_$d') ?? 0;
      final losses = prefs.getInt('losses_$d') ?? 0;
      winsByDiff[d] = wins;
      lossesByDiff[d] = losses;
      playedByDiff[d] = (prefs.getStringList(_playedKey(d)) ?? []).length;
      difficultyStats[d] = DifficultyStats(
        gamesStarted: prefs.getInt('started_$d') ?? wins + losses,
        victories: wins,
        losses: losses,
        abandons: prefs.getInt('abandons_$d') ?? 0,
        bestTime: prefs.getInt('best_$d') ?? 0,
        totalWinTime: prefs.getInt('total_win_time_$d') ?? 0,
        perfectVictories: prefs.getInt('perfect_$d') ?? 0,
        hintsUsed: prefs.getInt('hints_used_$d') ?? 0,
        completedWithAutocomplete:
            prefs.getInt('auto_complete_$d') ?? 0,
        completedWithHints:
            prefs.getInt('completed_with_hints_$d') ?? 0,
      );
    }

    final partialStats = GameStats(
      gamesPlayed: prefs.getInt('games_played') ?? 0,
      gamesWon: prefs.getInt('games_won') ?? 0,
      gamesLost: prefs.getInt('games_lost') ?? 0,
      gamesAbandoned: prefs.getInt('games_abandoned') ?? 0,
      totalPlayTime: prefs.getInt('total_play_time') ?? 0,
      hintsUsed: prefs.getInt('hints_used') ?? 0,
      perfectVictories: prefs.getInt('perfect_victories') ?? 0,
      victoriesWithHints: prefs.getInt('victories_with_hints') ?? 0,
      completedWithAutocomplete:
          prefs.getInt('completed_with_autocomplete') ?? 0,
      completedWithHints:
          prefs.getInt('completed_with_hints') ?? 0,
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
      playedBoardsByDifficulty: playedByDiff,
      difficultyStats: difficultyStats,
    );

    return partialStats.copyWith(
      unlockProgress: UnlockService.buildProgress(partialStats),
    );
  }

  static Future<void> recordWin(
    String difficulty,
    int elapsedSeconds, {
    required int mistakes,
    required int hintsUsed,
    required int completedWithAutocomplete,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final diff = difficulty.toLowerCase();

    final won = (prefs.getInt('games_won') ?? 0) + 1;
    final streak = (prefs.getInt('win_streak') ?? 0) + 1;
    final bestStreak = streak > (prefs.getInt('best_win_streak') ?? 0)
        ? streak
        : prefs.getInt('best_win_streak') ?? 0;
    final wins = (prefs.getInt('wins_$diff') ?? 0) + 1;

    await prefs.setInt('games_won', won);
    await prefs.setInt('win_streak', streak);
    await prefs.setInt('best_win_streak', bestStreak);
    await prefs.setInt('wins_$diff', wins);
    await prefs.setInt(
      'total_play_time',
      (prefs.getInt('total_play_time') ?? 0) + elapsedSeconds,
    );
    await prefs.setInt(
      'total_win_time_$diff',
      (prefs.getInt('total_win_time_$diff') ?? 0) + elapsedSeconds,
    );

    if (hintsUsed > 0) {
      await prefs.setInt(
        'victories_with_hints',
        (prefs.getInt('victories_with_hints') ?? 0) + 1,
      );
      await prefs.setInt(
        'completed_with_hints_$diff',
        (prefs.getInt('completed_with_hints_$diff') ?? 0) + 1,
      );
      await prefs.setInt(
        'completed_with_hints',
        (prefs.getInt('completed_with_hints') ?? 0) + 1,
      );
    }

    if (completedWithAutocomplete > 0) {
      await prefs.setInt(
        'completed_with_autocomplete',
        (prefs.getInt('completed_with_autocomplete') ?? 0) + 1,
      );
      await prefs.setInt(
        'auto_complete_$diff',
        (prefs.getInt('auto_complete_$diff') ?? 0) + 1,
      );
    }

    if (hintsUsed == 0 && mistakes == 0 && completedWithAutocomplete == 0) {
      await prefs.setInt(
        'perfect_victories',
        (prefs.getInt('perfect_victories') ?? 0) + 1,
      );
      await prefs.setInt(
        'perfect_$diff',
        (prefs.getInt('perfect_$diff') ?? 0) + 1,
      );
    }

    final bestKey = 'best_$diff';
    final currentBest = prefs.getInt(bestKey) ?? 0;
    if (currentBest == 0 || elapsedSeconds < currentBest) {
      await prefs.setInt(bestKey, elapsedSeconds);
    }

    dev.log(
      '[StatsStorage] Win recorded: $diff | elapsed=$elapsedSeconds | streak=$streak',
    );
  }

  static Future<void> recordLoss(String difficulty, int elapsedSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final diff = difficulty.toLowerCase();

    final lost = (prefs.getInt('games_lost') ?? 0) + 1;
    final losses = (prefs.getInt('losses_$diff') ?? 0) + 1;

    await prefs.setInt('games_lost', lost);
    await prefs.setInt('losses_$diff', losses);
    await prefs.setInt('win_streak', 0);
    await prefs.setInt(
      'total_play_time',
      (prefs.getInt('total_play_time') ?? 0) + elapsedSeconds,
    );

    dev.log('[StatsStorage] Loss recorded: $diff');
  }

  static Future<void> recordGameStarted(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final diff = difficulty.toLowerCase();
    final played = (prefs.getInt('games_played') ?? 0) + 1;
    await prefs.setInt('games_played', played);
    await prefs.setInt(
      'started_$diff',
      (prefs.getInt('started_$diff') ?? 0) + 1,
    );
    dev.log('[StatsStorage] Game started: $diff');
  }

  static Future<void> recordGameExit(
    String difficulty,
    int elapsedSeconds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final diff = difficulty.toLowerCase();
    await prefs.setInt(
      'games_abandoned',
      (prefs.getInt('games_abandoned') ?? 0) + 1,
    );
    await prefs.setInt(
      'abandons_$diff',
      (prefs.getInt('abandons_$diff') ?? 0) + 1,
    );
    await prefs.setInt(
      'total_play_time',
      (prefs.getInt('total_play_time') ?? 0) + elapsedSeconds,
    );
    dev.log('[StatsStorage] Game abandoned: $diff');
  }

  static Future<void> recordHintUsed(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final diff = difficulty.toLowerCase();
    await prefs.setInt('hints_used', (prefs.getInt('hints_used') ?? 0) + 1);
    await prefs.setInt(
      'hints_used_$diff',
      (prefs.getInt('hints_used_$diff') ?? 0) + 1,
    );
  }

  static Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      'games_played',
      'games_won',
      'games_lost',
      'win_streak',
      'best_win_streak',
      'games_abandoned',
      'total_play_time',
      'hints_used',
      'perfect_victories',
      'victories_with_hints',
      'completed_with_autocomplete',
      'completed_with_hints',
      for (final d in _difficulties) ...['best_$d', 'wins_$d', 'losses_$d'],
      for (final d in _difficulties) ...[
        'started_$d',
        'abandons_$d',
        'total_win_time_$d',
        'perfect_$d',
        'hints_used_$d',
        'auto_complete_$d',
        'completed_with_hints_$d',
      ],
    ];
    for (final k in keys) {
      await prefs.remove(k);
    }
    dev.log('[StatsStorage] Stats reset');
  }

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

  static Future<void> _migrate(SharedPreferences prefs) async {
    if (prefs.getBool('stats_v2_migrated') ?? false) return;
    for (final d in _difficulties) {
      final wins = prefs.getInt('wins_$d') ?? 0;
      final losses = prefs.getInt('losses_$d') ?? 0;
      prefs.setInt('started_$d', prefs.getInt('started_$d') ?? wins + losses);
      prefs.setInt('abandons_$d', prefs.getInt('abandons_$d') ?? 0);
      prefs.setInt('total_win_time_$d', prefs.getInt('total_win_time_$d') ?? 0);
      prefs.setInt('perfect_$d', prefs.getInt('perfect_$d') ?? 0);
      prefs.setInt('hints_used_$d', prefs.getInt('hints_used_$d') ?? 0);
    }
    prefs.setInt('games_abandoned', prefs.getInt('games_abandoned') ?? 0);
    prefs.setInt('total_play_time', prefs.getInt('total_play_time') ?? 0);
    prefs.setInt('hints_used', prefs.getInt('hints_used') ?? 0);
    prefs.setInt('perfect_victories', prefs.getInt('perfect_victories') ?? 0);
    prefs.setInt(
      'victories_with_hints',
      prefs.getInt('victories_with_hints') ?? 0,
    );
    await prefs.setBool('stats_v2_migrated', true);
  }
}
