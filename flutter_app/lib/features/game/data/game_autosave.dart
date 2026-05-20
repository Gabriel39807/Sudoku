import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/game_state.dart';

class GameAutosave {
  static const _key = 'autosave_game';

  static Future<void> save(GameState state) async {
    final session = state.session;
    if (session == null || session.status != GameStatus.playing) {
      await clear();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final data = {
      'boardId': session.boardId,
      'difficulty': session.difficulty,
      'initialBoard': session.initialBoard,
      'currentBoard': session.currentBoard,
      'solution': session.solution,
      'fixedCells': session.fixedCells.toList(),
      'notes': session.notes.map((k, v) => MapEntry(k.toString(), v.toList())),
      'mistakes': session.mistakes,
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
      'manualNotes': state.manualNotes
          ?.map((k, v) => MapEntry(k.toString(), v.toList())),
    };
    await prefs.setString(_key, jsonEncode(data));
  }

  /// Restore only if saved difficulty matches [diff] AND boards are valid.
  /// Returns null if no save, wrong difficulty, or corrupt data.
  static Future<GameState?> restoreForDifficulty(String diff) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      final difficulty = d['difficulty'] as String;

      // Phase 2: must match requested difficulty
      if (difficulty != diff) return null;

      final currentBoard = (d['currentBoard'] as List<dynamic>).cast<int>();
      final initialBoard = (d['initialBoard'] as List<dynamic>).cast<int>();
      final solution = (d['solution'] as List<dynamic>).cast<int>();

      // Phase 3: validate board length
      if (!_isValidBoard(currentBoard) ||
          !_isValidBoard(initialBoard) ||
          !_isValidBoard(solution)) {
        await clear();
        return null;
      }

      final boardId = d['boardId'] as String;
      final fixedCells = Set<int>.from((d['fixedCells'] as List<dynamic>).cast<int>());
      final notesRaw = d['notes'] as Map<String, dynamic>;
      final notes = notesRaw.map((k, v) => MapEntry(int.parse(k), Set<int>.from((v as List<dynamic>).cast<int>())));
      final mistakes = d['mistakes'] as int;
      final elapsed = Duration(milliseconds: d['elapsed'] as int);
      final paused = d['paused'] as bool;
      final statusIdx = d['status'] as int;
      final status = GameStatus.values[statusIdx];

      final session = GameSession.restore(
        boardId: boardId,
        difficulty: difficulty,
        initialBoard: initialBoard,
        currentBoard: currentBoard,
        solution: solution,
        fixedCells: fixedCells,
        notes: notes,
        mistakes: mistakes,
        elapsed: elapsed,
        paused: paused,
        status: status,
      );

      return GameState(
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
        manualNotes: d['manualNotes'] != null
            ? (d['manualNotes'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(
                  int.parse(k),
                  Set<int>.from((v as List<dynamic>).cast<int>()),
                ),
              )
            : null,
      );
    } catch (e) {
      await clear();
      return null;
    }
  }

  static bool _isValidBoard(List<int> board) => board.length == 81;

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
