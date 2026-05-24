import 'game_session.dart';
import 'note_helpers.dart';
import 'session_stats.dart';
import '../../campaign/domain/sudoku_variant.dart';

export 'game_session.dart' show GameSession;

enum GameStatus { playing, won, lost }

enum HintResult { applied, noSelection, ignored, noHints }

class SudokuCell {
  final int row;
  final int col;
  final int value;
  final int solution;
  final bool isFixed;
  final Set<int> notes;
  final bool noteConflict;

  const SudokuCell({
    required this.row,
    required this.col,
    required this.value,
    required this.solution,
    this.isFixed = false,
    this.notes = const {},
    this.noteConflict = false,
  });

  bool get isError => value != 0 && value != solution;
  bool get isEmpty => value == 0;

  SudokuCell copyWith({int? value, Set<int>? notes, bool? noteConflict}) =>
      SudokuCell(
        row: row,
        col: col,
        value: value ?? this.value,
        solution: solution,
        isFixed: isFixed,
        notes: notes ?? this.notes,
        noteConflict: noteConflict ?? this.noteConflict,
      );
}

class Move {
  final int row;
  final int col;
  final int oldValue;
  final int newValue;
  final DateTime timestamp;
  final Set<int> oldNotes;
  final Set<int> newNotes;

  const Move({
    required this.row,
    required this.col,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
    required this.oldNotes,
    required this.newNotes,
  });
}

class GameState {
  final GameSession? session;

  final int? selectedRow;
  final int? selectedCol;
  final bool pencilMode;
  final bool advancedNotesEnabled;
  final List<Move> undoStack;
  final bool isLoading;
  final int remainingHints;
  final int usedHints;
  final int? lockedNumber;
  final bool completedWithAutocomplete;

  final Map<int, int> completedDigits;

  final Set<int> completedRows;
  final Set<int> completedCols;
  final Set<int> completedBlocks;

  final int animationEventId;

  final int correctStreak;
  final int maxCombo;
  final int pauseCount;

  final int totalMoves;
  final int correctMoves;

  final Map<int, int> cellTimeMs;
  final int noteUsageCount;
  final int autoCompleteUsed;
  final Map<int, Set<int>>? manualNotes;
  final bool advancedNotesUnlockedForRun;
  final String? errorMessage;

  List<List<SudokuCell>> get board {
    if (session == null) return _emptyBoard();
    final cfg = session!.config;
    final size = cfg.boardSize;

    final conflicts = advancedNotesEnabled
        ? NoteHelpers.findConflicts(session!.notes, session!.currentBoard, config: cfg)
        : <int, Set<int>>{};
    return List.generate(size, (r) {
      return List.generate(size, (c) {
        final idx = r * size + c;
        final val = session!.currentBoard[idx];
        final sol = session!.solution[idx];
        final notes = session!.notes[idx] ?? const {};
        final cellConflicts = conflicts[idx];
        final hasConflict = advancedNotesEnabled &&
            cellConflicts != null &&
            cellConflicts.intersection(notes).isNotEmpty;
        return SudokuCell(
          row: r,
          col: c,
          value: val,
          solution: sol,
          isFixed: session!.fixedCells.contains(idx),
          notes: notes,
          noteConflict: hasConflict,
        );
      });
    });
  }

  bool get errorsVisible => true;

  String get boardId => session?.boardId ?? '';
  String get difficulty => session?.difficulty ?? '';
  int get errors => session?.mistakes ?? 0;
  int get elapsedSeconds => session?.elapsed.inSeconds ?? 0;
  bool get isPaused => session?.paused ?? false;
  GameStatus get status => session?.status ?? GameStatus.playing;

  SessionStats get sessionStats {
    final cfg = session?.config ?? BoardConfig.normal9;
    final total = cfg.totalCells;
    final remaining = session == null ? total : session!.currentBoard.where((v) => v == 0).length;
    final filled = total - remaining;
    return SessionStats(
      elapsedSeconds: elapsedSeconds,
      errors: errors,
      remainingCells: remaining,
      completionPercent: session == null ? 0.0 : filled / total * 100.0,
      remainingHints: remainingHints,
      currentStreak: correctStreak,
      currentCombo: maxCombo,
      accuracy: totalMoves == 0 ? 1.0 : correctMoves / totalMoves,
      totalMoves: totalMoves,
      correctMoves: correctMoves,
    );
  }

  const GameState({
    this.session,
    this.selectedRow,
    this.selectedCol,
    this.pencilMode = false,
    this.advancedNotesEnabled = false,
    this.undoStack = const [],
    this.isLoading = false,
    this.remainingHints = 3,
    this.usedHints = 0,
    this.lockedNumber,
    this.completedWithAutocomplete = false,
    this.completedDigits = const {},
    this.completedRows = const {},
    this.completedCols = const {},
    this.completedBlocks = const {},
    this.animationEventId = 0,
    this.correctStreak = 0,
    this.maxCombo = 0,
    this.pauseCount = 0,
    this.totalMoves = 0,
    this.correctMoves = 0,
    this.cellTimeMs = const {},
    this.noteUsageCount = 0,
    this.autoCompleteUsed = 0,
    this.manualNotes,
    this.advancedNotesUnlockedForRun = false,
    this.errorMessage,
  });

  factory GameState.loading(String difficulty) =>
      const GameState(isLoading: true);

  GameState copyWith({
    GameSession? session,
    bool clearSession = false,
    int? selectedRow,
    int? selectedCol,
    bool clearSelection = false,
    bool? pencilMode,
    bool? advancedNotesEnabled,
    List<Move>? undoStack,
    bool? isLoading,
    int? remainingHints,
    int? usedHints,
    int? lockedNumber,
    bool clearLockedNumber = false,
    bool? completedWithAutocomplete,
    Map<int, int>? completedDigits,
    Set<int>? completedRows,
    Set<int>? completedCols,
    Set<int>? completedBlocks,
    int? animationEventId,
    int? correctStreak,
    int? maxCombo,
    int? pauseCount,
    int? totalMoves,
    int? correctMoves,
    Map<int, int>? cellTimeMs,
    int? noteUsageCount,
    int? autoCompleteUsed,
    Map<int, Set<int>>? manualNotes,
    bool? advancedNotesUnlockedForRun,
    String? errorMessage,
  }) {
    return GameState(
      session: clearSession ? null : (session ?? this.session),
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      pencilMode: pencilMode ?? this.pencilMode,
      advancedNotesEnabled: advancedNotesEnabled ?? this.advancedNotesEnabled,
      undoStack: undoStack ?? this.undoStack,
      isLoading: isLoading ?? this.isLoading,
      remainingHints: remainingHints ?? this.remainingHints,
      usedHints: usedHints ?? this.usedHints,
      lockedNumber: clearLockedNumber
          ? null
          : (lockedNumber ?? this.lockedNumber),
      completedWithAutocomplete:
          completedWithAutocomplete ?? this.completedWithAutocomplete,
      completedDigits: completedDigits ?? this.completedDigits,
      completedRows: completedRows ?? this.completedRows,
      completedCols: completedCols ?? this.completedCols,
      completedBlocks: completedBlocks ?? this.completedBlocks,
      animationEventId: animationEventId ?? this.animationEventId,
      correctStreak: correctStreak ?? this.correctStreak,
      maxCombo: maxCombo ?? this.maxCombo,
      pauseCount: pauseCount ?? this.pauseCount,
      totalMoves: totalMoves ?? this.totalMoves,
      correctMoves: correctMoves ?? this.correctMoves,
      cellTimeMs: cellTimeMs ?? this.cellTimeMs,
      noteUsageCount: noteUsageCount ?? this.noteUsageCount,
      autoCompleteUsed: autoCompleteUsed ?? this.autoCompleteUsed,
      manualNotes: manualNotes ?? this.manualNotes,
      advancedNotesUnlockedForRun:
          advancedNotesUnlockedForRun ?? this.advancedNotesUnlockedForRun,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  GameState clearSelection() => copyWith(clearSelection: true);
  GameState select(int row, int col) =>
      copyWith(selectedRow: row, selectedCol: col);

  List<List<SudokuCell>> _emptyBoard() {
    final size = session?.config.boardSize ?? 9;
    return List.generate(
      size,
      (r) => List.generate(
        size,
        (c) => SudokuCell(row: r, col: c, value: 0, solution: 0),
      ),
    );
  }
}
