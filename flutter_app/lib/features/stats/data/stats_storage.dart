import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/difficulty_stats.dart';
import '../domain/game_result.dart';
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
        maxCombo: prefs.getInt('max_combo_$d') ?? 0,
        totalNoteUsage: prefs.getInt('note_usage_$d') ?? 0,
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
      maxCombo: prefs.getInt('max_combo') ?? 0,
      totalNoteUsage: prefs.getInt('total_note_usage') ?? 0,
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
    int maxCombo = 0,
    int totalNoteUsage = 0,
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

    // Combo & note usage
    final globalCombo = prefs.getInt('max_combo') ?? 0;
    if (maxCombo > globalCombo) {
      await prefs.setInt('max_combo', maxCombo);
    }
    final diffCombo = prefs.getInt('max_combo_$diff') ?? 0;
    if (maxCombo > diffCombo) {
      await prefs.setInt('max_combo_$diff', maxCombo);
    }
    final globalNotes = prefs.getInt('total_note_usage') ?? 0;
    await prefs.setInt('total_note_usage', globalNotes + totalNoteUsage);
    final diffNotes = prefs.getInt('note_usage_$diff') ?? 0;
    await prefs.setInt('note_usage_$diff', diffNotes + totalNoteUsage);

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
      'max_combo',
      'total_note_usage',
      for (final d in _difficulties) ...['best_$d', 'wins_$d', 'losses_$d'],
      'campaign_games',
      'campaign_wins',
      'campaign_losses',
      'campaign_streak',
      'campaign_best_streak',
      'campaign_total_mistakes',
      'campaign_bosses',
      'campaign_boss_perfect',
      'daily_games_played',
      'daily_games_won',
      'daily_games_lost',
      'daily_best_time',
      'daily_total_time',
      'daily_mistakes',
      'daily_hints_used',
      'daily_perfect',
      for (final d in _difficulties) ...[
        'started_$d',
        'abandons_$d',
        'total_win_time_$d',
        'perfect_$d',
        'hints_used_$d',
        'auto_complete_$d',
        'completed_with_hints_$d',
        'max_combo_$d',
        'note_usage_$d',
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

  // ── Unified Game Result (ALL modes) ────────────────────────────────────

  static Future<void> recordGameResult(GameResult result) async {
    final prefs = await SharedPreferences.getInstance();

    if (result.mode.isClassic) {
      if (result.boardId != null) {
        await markBoardPlayed(result.difficulty, result.boardId!);
      }
      if (result.won) {
        await recordWin(result.difficulty, result.elapsedSeconds,
          mistakes: result.mistakes, hintsUsed: result.hintsUsed,
          completedWithAutocomplete: result.completedWithAutocomplete ? 1 : 0,
          maxCombo: result.maxCombo, totalNoteUsage: result.totalNoteUsage,
        );
      } else {
        await recordLoss(result.difficulty, result.elapsedSeconds);
      }
      return;
    }

    if (result.mode.isCampaign) {
      await _recordCampaignGameResult(prefs, result);
    }

    if (result.mode.isDaily) {
      await _recordDailyGameResult(prefs, result);
    }
  }

  static Future<void> _recordCampaignGameResult(
    SharedPreferences prefs,
    GameResult result,
  ) async {
    final played = (prefs.getInt('campaign_games') ?? 0) + 1;
    await prefs.setInt('campaign_games', played);
    await prefs.setInt(
      'total_play_time',
      (prefs.getInt('total_play_time') ?? 0) + result.elapsedSeconds,
    );
    await prefs.setInt(
      'games_played',
      (prefs.getInt('games_played') ?? 0) + 1,
    );

    if (result.won) {
      final won = (prefs.getInt('campaign_wins') ?? 0) + 1;
      await prefs.setInt('campaign_wins', won);
      await prefs.setInt('games_won', (prefs.getInt('games_won') ?? 0) + 1);

      final streak = (prefs.getInt('campaign_streak') ?? 0) + 1;
      await prefs.setInt('campaign_streak', streak);
      final bestStreak = prefs.getInt('campaign_best_streak') ?? 0;
      if (streak > bestStreak) {
        await prefs.setInt('campaign_best_streak', streak);
      }

      final totalMistakes = (prefs.getInt('campaign_total_mistakes') ?? 0) + result.mistakes;
      await prefs.setInt('campaign_total_mistakes', totalMistakes);

      if (result.isCampaignBoss == true) {
        await prefs.setInt(
          'campaign_bosses',
          (prefs.getInt('campaign_bosses') ?? 0) + 1,
        );
        if (result.perfect) {
          await prefs.setInt(
            'campaign_boss_perfect',
            (prefs.getInt('campaign_boss_perfect') ?? 0) + 1,
          );
        }
      }

      dev.log('[StatsStorage] Campaign win: ${result.campaignLevel ?? '?'} | stars=${result.campaignStars}');
    } else {
      await prefs.setInt('campaign_losses', (prefs.getInt('campaign_losses') ?? 0) + 1);
      await prefs.setInt('games_lost', (prefs.getInt('games_lost') ?? 0) + 1);
      await prefs.setInt('campaign_streak', 0);

      dev.log('[StatsStorage] Campaign loss: ${result.campaignLevel ?? '?'}');
    }

    await _updateGlobalStreakFromCampaign(prefs);
  }

  static Future<void> _updateGlobalStreakFromCampaign(SharedPreferences prefs) async {
    final classicStreak = prefs.getInt('win_streak') ?? 0;
    final campaignStreak = prefs.getInt('campaign_streak') ?? 0;
    final combinedStreak = classicStreak + campaignStreak;
    if (combinedStreak > (prefs.getInt('best_win_streak') ?? 0)) {
      await prefs.setInt('best_win_streak', combinedStreak);
    }
  }

  static Future<void> _recordDailyGameResult(
    SharedPreferences prefs,
    GameResult result,
  ) async {
    if (result.boardId != null) {
      await markBoardPlayed(result.difficulty, result.boardId!);
    }
    if (result.won) {
      await recordWin(result.difficulty, result.elapsedSeconds,
        mistakes: result.mistakes, hintsUsed: result.hintsUsed,
        completedWithAutocomplete: result.completedWithAutocomplete ? 1 : 0,
        maxCombo: result.maxCombo, totalNoteUsage: result.totalNoteUsage,
      );
    } else {
      await recordLoss(result.difficulty, result.elapsedSeconds);
    }

    final dailyGames = (prefs.getInt('daily_games_played') ?? 0) + 1;
    final dailyTime = (prefs.getInt('daily_total_time') ?? 0) + result.elapsedSeconds;
    await prefs.setInt('daily_games_played', dailyGames);
    await prefs.setInt('daily_total_time', dailyTime);

    if (result.won) {
      await prefs.setInt('daily_games_won', (prefs.getInt('daily_games_won') ?? 0) + 1);

      final prevBest = prefs.getInt('daily_best_time') ?? 0;
      if (prevBest == 0 || result.elapsedSeconds < prevBest) {
        await prefs.setInt('daily_best_time', result.elapsedSeconds);
      }

      await prefs.setInt('daily_mistakes', (prefs.getInt('daily_mistakes') ?? 0) + result.mistakes);
      await prefs.setInt('daily_hints_used', (prefs.getInt('daily_hints_used') ?? 0) + result.hintsUsed);

      if (result.perfect) {
        await prefs.setInt('daily_perfect', (prefs.getInt('daily_perfect') ?? 0) + 1);
      }
    } else {
      await prefs.setInt('daily_games_lost', (prefs.getInt('daily_games_lost') ?? 0) + 1);
    }
  }

  static Future<Map<String, int>> loadCampaignStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'games': prefs.getInt('campaign_games') ?? 0,
      'wins': prefs.getInt('campaign_wins') ?? 0,
      'losses': prefs.getInt('campaign_losses') ?? 0,
      'streak': prefs.getInt('campaign_streak') ?? 0,
      'bestStreak': prefs.getInt('campaign_best_streak') ?? 0,
      'totalMistakes': prefs.getInt('campaign_total_mistakes') ?? 0,
      'bossesDefeated': prefs.getInt('campaign_bosses') ?? 0,
      'bossPerfectWins': prefs.getInt('campaign_boss_perfect') ?? 0,
    };
  }

  static Future<void> resetCampaignStats() async {
    final prefs = await SharedPreferences.getInstance();
    const keys = [
      'campaign_games', 'campaign_wins', 'campaign_losses',
      'campaign_streak', 'campaign_best_streak',
      'campaign_total_mistakes', 'campaign_bosses', 'campaign_boss_perfect',
    ];
    for (final k in keys) await prefs.remove(k);
  }

  static Future<Map<String, int>> loadDailyStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'gamesPlayed': prefs.getInt('daily_games_played') ?? 0,
      'wins': prefs.getInt('daily_games_won') ?? 0,
      'losses': prefs.getInt('daily_games_lost') ?? 0,
      'bestTime': prefs.getInt('daily_best_time') ?? 0,
      'totalTime': prefs.getInt('daily_total_time') ?? 0,
      'totalMistakes': prefs.getInt('daily_mistakes') ?? 0,
      'hintsUsed': prefs.getInt('daily_hints_used') ?? 0,
      'perfect': prefs.getInt('daily_perfect') ?? 0,
    };
  }

  static Future<void> resetDailyStats() async {
    final prefs = await SharedPreferences.getInstance();
    const keys = [
      'daily_games_played', 'daily_games_won', 'daily_games_lost',
      'daily_best_time', 'daily_total_time',
      'daily_mistakes', 'daily_hints_used', 'daily_perfect',
    ];
    for (final k in keys) await prefs.remove(k);
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
