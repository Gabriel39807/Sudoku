enum GameStatus { playing, won, lost }

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

  SudokuCell copyWith({
    int? value,
    Set<int>? notes,
  }) {
    return SudokuCell(
      row: row,
      col: col,
      value: value ?? this.value,
      solution: solution,
      isFixed: isFixed,
      notes: notes ?? this.notes,
    );
  }
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
  final List<List<SudokuCell>> board;
  final String boardId;
  final int? selectedRow;
  final int? selectedCol;
  final int errors;
  final int elapsedSeconds;
  final bool pencilMode;
  final String difficulty;
  final GameStatus status;
  final bool isPaused;
  final List<Move> undoStack;
  final bool isLoading;

  const GameState({
    required this.board,
    this.boardId = '',
    this.selectedRow,
    this.selectedCol,
    this.errors = 0,
    this.elapsedSeconds = 0,
    this.pencilMode = false,
    required this.difficulty,
    this.status = GameStatus.playing,
    this.isPaused = false,
    this.undoStack = const [],
    this.isLoading = false,
  });

  GameState copyWith({
    List<List<SudokuCell>>? board,
    String? boardId,
    int? selectedRow,
    int? selectedCol,
    bool clearSelection = false,
    int? errors,
    int? elapsedSeconds,
    bool? pencilMode,
    GameStatus? status,
    bool? isPaused,
    List<Move>? undoStack,
    bool? isLoading,
  }) {
    return GameState(
      board: board ?? this.board,
      boardId: boardId ?? this.boardId,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow), 
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      errors: errors ?? this.errors,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      pencilMode: pencilMode ?? this.pencilMode,
      difficulty: difficulty,
      status: status ?? this.status,
      isPaused: isPaused ?? this.isPaused,
      undoStack: undoStack ?? this.undoStack,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  GameState clearSelection() {
    return copyWith(clearSelection: true);
  }

  GameState select(int row, int col) {
    return copyWith(selectedRow: row, selectedCol: col);
  }
}
