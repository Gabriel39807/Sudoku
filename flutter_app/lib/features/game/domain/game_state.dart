import 'game_session.dart';

export 'game_session.dart' show GameSession;

enum GameStatus { playing, won, lost }

enum HintResult { applied, noSelection, ignored }

class SudokuCell {
  final int row;
  final int col;
  final int value;
  final int solution;
  final bool isFixed;
  final Set<int> notes;

  const SudokuCell({
    required this.row,
    required this.col,
    required this.value,
    required this.solution,
    this.isFixed = false,
    this.notes = const {},
  });

  bool get isError => value != 0 && value != solution;
  bool get isEmpty => value == 0;

  SudokuCell copyWith({int? value, Set<int>? notes}) => SudokuCell(
    row: row,
    col: col,
    value: value ?? this.value,
    solution: solution,
    isFixed: isFixed,
    notes: notes ?? this.notes,
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

/// Estado UI completo. Wrappea un GameSession inmutable + UI-only fields.
class GameState {
  final GameSession? session;

  // UI-only
  final int? selectedRow;
  final int? selectedCol;
  final bool pencilMode;
  final List<Move> undoStack;
  final bool isLoading;
  final int remainingHints;
  final int usedHints;
  final int? lockedNumber;
  final bool completedWithAutocomplete;

  // Tracking de dígitos completados (1-9 -> count correct placements)
  final Map<int, int> completedDigits;

  // Sets de filas/columnas/bloques completados para animaciones
  final Set<int> completedRows;
  final Set<int> completedCols;
  final Set<int> completedBlocks;

  // Identificador de evento de animación (cambia al completar fila/col/bloque)
  final int animationEventId;

  // Computed from session
  List<List<SudokuCell>> get board {
    if (session == null) return _emptyBoard();
    return List.generate(9, (r) {
      return List.generate(9, (c) {
        final idx = r * 9 + c;
        final val = session!.currentBoard[idx];
        final sol = session!.solution[idx];
        final notes = session!.notes[idx] ?? const {};
        return SudokuCell(
          row: r,
          col: c,
          value: val,
          solution: sol,
          isFixed: session!.fixedCells.contains(idx),
          notes: notes,
        );
      });
    });
  }

  String get boardId => session?.boardId ?? '';
  String get difficulty => session?.difficulty ?? 'easy';
  int get errors => session?.mistakes ?? 0;
  int get elapsedSeconds => session?.elapsed.inSeconds ?? 0;
  bool get isPaused => session?.paused ?? false;
  GameStatus get status => session?.status ?? GameStatus.playing;

  const GameState({
    this.session,
    this.selectedRow,
    this.selectedCol,
    this.pencilMode = false,
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
  }) {
    return GameState(
      session: clearSession ? null : (session ?? this.session),
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      pencilMode: pencilMode ?? this.pencilMode,
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
    );
  }

  GameState clearSelection() => copyWith(clearSelection: true);
  GameState select(int row, int col) =>
      copyWith(selectedRow: row, selectedCol: col);

  static List<List<SudokuCell>> _emptyBoard() => List.generate(
    9,
    (r) => List.generate(
      9,
      (c) => SudokuCell(row: r, col: c, value: 0, solution: 0),
    ),
  );
}
