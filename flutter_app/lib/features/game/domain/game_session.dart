import 'game_state.dart';

/// Snapshot inmutable de una partida. Cada partida nueva = objeto nuevo.
/// NUNCA compartir referencias de listas entre instancias.
class GameSession {
  final String boardId;
  final String difficulty;

  final List<int> initialBoard;  // snapshot original, nunca muta
  final List<int> currentBoard;  // estado actual del tablero
  final List<int> solution;

  final Set<int> fixedCells;          // índices (row*9+col) de celdas fijas
  final Map<int, Set<int>> notes;     // índice → conjunto de notas

  final int mistakes;
  final Duration elapsed;
  final bool paused;
  final GameStatus status;

  const GameSession._({
    required this.boardId,
    required this.difficulty,
    required this.initialBoard,
    required this.currentBoard,
    required this.solution,
    required this.fixedCells,
    required this.notes,
    required this.mistakes,
    required this.elapsed,
    required this.paused,
    required this.status,
  });

  /// Restore from autosave data.
  factory GameSession.restore({
    required String boardId,
    required String difficulty,
    required List<int> initialBoard,
    required List<int> currentBoard,
    required List<int> solution,
    required Set<int> fixedCells,
    required Map<int, Set<int>> notes,
    required int mistakes,
    required Duration elapsed,
    required bool paused,
    required GameStatus status,
  }) {
    return GameSession._(
      boardId: boardId,
      difficulty: difficulty,
      initialBoard: List<int>.from(initialBoard),
      currentBoard: List<int>.from(currentBoard),
      solution: List<int>.from(solution),
      fixedCells: Set<int>.from(fixedCells),
      notes: _deepCopyNotes(notes),
      mistakes: mistakes,
      elapsed: elapsed,
      paused: paused,
      status: status,
    );
  }

  /// Siempre crea listas frescas — sin referencias compartidas.
  factory GameSession.create({
    required String boardId,
    required String difficulty,
    required List<int> puzzleFlat,
    required List<int> solutionFlat,
  }) {
    final fixed = <int>{};
    for (var i = 0; i < puzzleFlat.length; i++) {
      if (puzzleFlat[i] != 0) fixed.add(i);
    }
    return GameSession._(
      boardId: boardId,
      difficulty: difficulty,
      initialBoard: List<int>.from(puzzleFlat),
      currentBoard: List<int>.from(puzzleFlat),
      solution: List<int>.from(solutionFlat),
      fixedCells: Set<int>.from(fixed),
      notes: {},
      mistakes: 0,
      elapsed: Duration.zero,
      paused: false,
      status: GameStatus.playing,
    );
  }

  /// copyWith con copias profundas de mutable containers.
  GameSession copyWith({
    List<int>? currentBoard,
    Map<int, Set<int>>? notes,
    int? mistakes,
    Duration? elapsed,
    bool? paused,
    GameStatus? status,
  }) {
    return GameSession._(
      boardId: boardId,
      difficulty: difficulty,
      initialBoard: initialBoard,   // inmutable, reusar referencia
      currentBoard: currentBoard != null
          ? List<int>.from(currentBoard)
          : List<int>.from(this.currentBoard),
      solution: solution,           // inmutable, reusar referencia
      fixedCells: fixedCells,       // inmutable, reusar referencia
      notes: _deepCopyNotes(notes ?? this.notes),
      mistakes: mistakes ?? this.mistakes,
      elapsed: elapsed ?? this.elapsed,
      paused: paused ?? this.paused,
      status: status ?? this.status,
    );
  }

  static Map<int, Set<int>> _deepCopyNotes(Map<int, Set<int>> src) =>
      {for (final e in src.entries) e.key: Set<int>.from(e.value)};
}
