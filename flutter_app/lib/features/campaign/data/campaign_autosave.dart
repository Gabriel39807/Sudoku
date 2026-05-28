import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../game/domain/game_state.dart';
import '../domain/sudoku_variant.dart';

class CampaignAutosave {
  static const _key = 'autosave_campaign';

  static Future<void> save(GameState state, int level, SudokuVariant variant) async {
    final session = state.session;
    if (session == null || session.status != GameStatus.playing) {
      await clear();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final data = {
      'level': level,
      'variant': variant.name,
      'boardId': session.boardId,
      'difficulty': session.difficulty,
      'initialBoard': session.initialBoard,
      'currentBoard': session.currentBoard,
      'solution': session.solution,
      'fixedCells': session.fixedCells.toList(),
      'notes': session.notes.map((k, v) => MapEntry(k.toString(), v.toList())),
      'mistakes': session.mistakes,
      'retries': session.retries,
      'continuesUsed': session.continuesUsed,
      'elapsed': session.elapsed.inMilliseconds,
      'paused': session.paused,
      'status': session.status.index,
      'correctStreak': state.correctStreak,
      'maxCombo': state.maxCombo,
      'hintsUsed': state.usedHints,
      'remainingHints': state.remainingHints,
      'cellTimeMs': state.cellTimeMs.map((k, v) => MapEntry(k.toString(), v)),
      'noteUsageCount': state.noteUsageCount,
      'totalMoves': state.totalMoves,
      'correctMoves': state.correctMoves,
      'advancedNotesEnabled': state.advancedNotesEnabled,
      'advancedNotesUnlockedForRun': state.advancedNotesUnlockedForRun,
      'manualNotes': state.manualNotes
          ?.map((k, v) => MapEntry(k.toString(), v.toList())),
    };
    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<({GameState state, int level, SudokuVariant variant})?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      final level = d['level'] as int;
      final variantName = d['variant'] as String;
      final variant = SudokuVariant.values.firstWhere((v) => v.name == variantName);
      final currentBoard = (d['currentBoard'] as List<dynamic>).cast<int>();
      final initialBoard = (d['initialBoard'] as List<dynamic>).cast<int>();
      final solution = (d['solution'] as List<dynamic>).cast<int>();
      if (currentBoard.length != 81 || initialBoard.length != 81 || solution.length != 81) {
        await clear();
        return null;
      }

      final boardId = d['boardId'] as String;
      final fixedCells = Set<int>.from((d['fixedCells'] as List<dynamic>).cast<int>());
      final notesRaw = d['notes'] as Map<String, dynamic>;
      final notes = notesRaw.map((k, v) => MapEntry(int.parse(k), Set<int>.from((v as List<dynamic>).cast<int>())));
      final mistakes = d['mistakes'] as int;
      final hintsUsed = d['hintsUsed'] as int? ?? 0;
      final retries = d['retries'] as int? ?? 0;
      final continuesUsed = d['continuesUsed'] as int? ?? 0;
      final elapsed = Duration(milliseconds: d['elapsed'] as int);
      final paused = d['paused'] as bool;
      final statusIdx = d['status'] as int;
      final status = GameStatus.values[statusIdx];

      final session = GameSession.restore(
        boardId: boardId,
        difficulty: d['difficulty'] as String,
        initialBoard: initialBoard,
        currentBoard: currentBoard,
        solution: solution,
        fixedCells: fixedCells,
        notes: notes,
        mistakes: mistakes,
        hintsUsed: hintsUsed,
        retries: retries,
        continuesUsed: continuesUsed,
        elapsed: elapsed,
        paused: paused,
        status: status,
      );

      final gameState = GameState(
        session: session,
        isLoading: false,
        correctStreak: d['correctStreak'] as int? ?? 0,
        maxCombo: d['maxCombo'] as int? ?? 0,
        usedHints: d['hintsUsed'] as int? ?? 0,
        remainingHints: d['remainingHints'] as int? ?? 3,
        cellTimeMs: (d['cellTimeMs'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(int.parse(k), v as int)),
        noteUsageCount: d['noteUsageCount'] as int? ?? 0,
        totalMoves: d['totalMoves'] as int? ?? 0,
        correctMoves: d['correctMoves'] as int? ?? 0,
        advancedNotesEnabled: d['advancedNotesEnabled'] as bool? ?? false,
        advancedNotesUnlockedForRun: d['advancedNotesUnlockedForRun'] as bool? ?? false,
        manualNotes: d['manualNotes'] != null
            ? (d['manualNotes'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(int.parse(k), Set<int>.from((v as List<dynamic>).cast<int>())),
              )
            : null,
      );

      return (state: gameState, level: level, variant: variant);
    } catch (e) {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
