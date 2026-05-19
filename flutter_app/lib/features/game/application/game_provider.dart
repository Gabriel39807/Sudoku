import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/game_state.dart';
import '../data/board_repository.dart';

// ------------------------------------------------------------------ //
// Provider de historial — persistido por clave played_{difficulty}    //
// ------------------------------------------------------------------ //

class PlayedBoardsNotifier extends AsyncNotifier<Map<String, Set<String>>> {
  static String _key(String diff) => 'played_${diff.toLowerCase()}';

  @override
  Future<Map<String, Set<String>>> build() async {
    final prefs = await SharedPreferences.getInstance();
    const diffs = ['easy', 'intermediate', 'hard', 'expert', 'evil', 'mythic'];
    return {
      for (final d in diffs)
        d: (prefs.getStringList(_key(d)) ?? []).toSet(),
    };
  }

  Future<void> mark(String difficulty, String boardId) async {
    final diff = difficulty.toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final current = Map<String, Set<String>>.from(state.value ?? {});
    final updated = Set<String>.from(current[diff] ?? {})..add(boardId);
    current[diff] = updated;
    await prefs.setStringList(_key(diff), updated.toList());
    state = AsyncData(Map.from(current));
    dev.log('[PlayedBoards] Marked $boardId as played for $diff (total: ${updated.length})');
  }

  Future<void> reset(String difficulty) async {
    final diff = difficulty.toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(diff));
    final current = Map<String, Set<String>>.from(state.value ?? {});
    current[diff] = {};
    state = AsyncData(current);
    dev.log('[PlayedBoards] Reset history for $diff');
  }

  Set<String> getPlayed(String difficulty) {
    return state.value?[difficulty.toLowerCase()] ?? {};
  }
}

final playedBoardsProvider =
    AsyncNotifierProvider<PlayedBoardsNotifier, Map<String, Set<String>>>(
  PlayedBoardsNotifier.new,
);

// ------------------------------------------------------------------ //
// GameNotifier                                                        //
// ------------------------------------------------------------------ //

class GameNotifier extends Notifier<GameState> {
  Timer? _timer;
  String? _lastBoardId;

  @override
  GameState build() {
    ref.onDispose(() => _timer?.cancel());
    return GameState(
      board: _emptyBoard(),
      difficulty: 'easy',
      isLoading: true,
    );
  }

  List<List<SudokuCell>> _emptyBoard() => List.generate(
        9,
        (r) => List.generate(
          9,
          (c) => SudokuCell(row: r, col: c, value: 0, solution: 0),
        ),
      );

  // ---------------------------------------------------------------- //
  // init — punto de entrada al cargar una nueva partida              //
  // ---------------------------------------------------------------- //

  Future<void> init(String difficulty) async {
    final diff = difficulty.toLowerCase();
    _timer?.cancel();

    state = state.copyWith(
      isLoading: true,
      isPaused: false,
      status: GameStatus.playing,
      elapsedSeconds: 0,
      errors: 0,
      undoStack: [],
      pencilMode: false,
    );

    await _loadNextBoard(diff);
  }

  Future<void> _loadNextBoard(String diff) async {
    // Esperar a que playedBoardsProvider esté listo
    final playedAsync = ref.read(playedBoardsProvider);
    await playedAsync.when(
      data: (_) async {},
      loading: () async {
        await Future.delayed(const Duration(milliseconds: 100));
      },
      error: (err, st) async {},
    );

    final played = ref.read(playedBoardsProvider.notifier).getPlayed(diff);

    dev.log('[GameProvider] Loading $diff | played=${played.length} | last=$_lastBoardId');

    final boardData = await BoardRepository.loadRandomBoard(
      difficulty: diff,
      playedIds: played,
      lastBoardId: _lastBoardId,
    );

    dev.log('[GameProvider] BOARD ID: ${boardData.id} | DIFFICULTY: $diff | CELLS: ${boardData.puzzleFlat.length}');

    final board = List.generate(9, (r) {
      return List.generate(9, (c) {
        final idx = r * 9 + c;
        final val = boardData.puzzleFlat[idx];
        final sol = boardData.solutionFlat[idx];
        return SudokuCell(
          row: r, col: c, value: val, solution: sol, isFixed: val != 0,
        );
      });
    });

    _lastBoardId = boardData.id;

    state = GameState(
      board: board,
      boardId: boardData.id,
      difficulty: diff,
      isLoading: false,
    );

    _startTimer();
  }

  // ---------------------------------------------------------------- //
  // Timer                                                             //
  // ---------------------------------------------------------------- //

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.status == GameStatus.playing && !state.isPaused) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  // ---------------------------------------------------------------- //
  // Inputs                                                            //
  // ---------------------------------------------------------------- //

  void selectCell(int row, int col) {
    if (state.status != GameStatus.playing || state.isPaused) return;
    if (state.selectedRow == row && state.selectedCol == col) {
      state = state.clearSelection();
    } else {
      state = state.select(row, col);
    }
  }

  void inputNumber(int number) {
    if (state.status != GameStatus.playing || state.isPaused) return;
    if (state.selectedRow == null || state.selectedCol == null) return;

    final r = state.selectedRow!;
    final c = state.selectedCol!;
    final cell = state.board[r][c];
    if (cell.isFixed) return;

    if (state.pencilMode) {
      final newNotes = Set<int>.from(cell.notes);
      if (newNotes.contains(number)) {
        newNotes.remove(number);
      } else {
        newNotes.add(number);
      }
      final move = Move(
        row: r, col: c,
        oldValue: cell.value, newValue: cell.value,
        oldNotes: cell.notes, newNotes: newNotes,
        timestamp: DateTime.now(),
      );
      _updateCellAndPushMove(cell.copyWith(notes: newNotes), move);
    } else {
      final newValue = cell.value == number ? 0 : number;
      final move = Move(
        row: r, col: c,
        oldValue: cell.value, newValue: newValue,
        oldNotes: cell.notes, newNotes: {},
        timestamp: DateTime.now(),
      );
      _updateCellAndPushMove(cell.copyWith(value: newValue, notes: {}), move);

      if (newValue != 0 && newValue != cell.solution) {
        final newErrors = state.errors + 1;
        if (newErrors >= 3) {
          state = state.copyWith(errors: newErrors, status: GameStatus.lost);
          _onBoardConsumed(); // marcar y preparar siguiente
        } else {
          state = state.copyWith(errors: newErrors);
        }
      } else {
        _checkWinCondition();
      }
    }
  }

  void undo() {
    if (state.status != GameStatus.playing || state.isPaused) return;
    if (state.undoStack.isEmpty) return;

    final newStack = List<Move>.from(state.undoStack);
    final lastMove = newStack.removeLast();
    final cell = state.board[lastMove.row][lastMove.col];
    final restored = cell.copyWith(value: lastMove.oldValue, notes: lastMove.oldNotes);

    final newBoard = state.board.map((row) => List<SudokuCell>.from(row)).toList();
    newBoard[restored.row][restored.col] = restored;

    state = state.copyWith(
      board: newBoard,
      undoStack: newStack,
      selectedRow: lastMove.row,
      selectedCol: lastMove.col,
    );
  }

  void togglePencil() {
    if (state.status != GameStatus.playing || state.isPaused) return;
    state = state.copyWith(pencilMode: !state.pencilMode);
  }

  void togglePause() {
    if (state.status != GameStatus.playing) return;
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void erase() {
    if (state.status != GameStatus.playing || state.isPaused) return;
    if (state.selectedRow == null || state.selectedCol == null) return;
    final r = state.selectedRow!;
    final c = state.selectedCol!;
    final cell = state.board[r][c];
    if (cell.isFixed || (cell.value == 0 && cell.notes.isEmpty)) return;

    final move = Move(
      row: r, col: c,
      oldValue: cell.value, newValue: 0,
      oldNotes: cell.notes, newNotes: {},
      timestamp: DateTime.now(),
    );
    _updateCellAndPushMove(cell.copyWith(value: 0, notes: {}), move);
  }

  // ---------------------------------------------------------------- //
  // Condición de victoria y consumo de tablero                       //
  // ---------------------------------------------------------------- //

  void _checkWinCondition() {
    final complete = state.board.every(
      (row) => row.every((c) => c.value != 0 && c.value == c.solution),
    );
    if (complete) {
      state = state.copyWith(status: GameStatus.won);
      _onBoardConsumed();
    }
  }

  /// Marca el tablero actual como jugado y NO carga el siguiente aquí:
  /// el próximo init() ya se encargará de excluirlo.
  void _onBoardConsumed() {
    final diff = state.difficulty.toLowerCase();
    final boardId = state.boardId;
    if (boardId.isNotEmpty) {
      ref.read(playedBoardsProvider.notifier).mark(diff, boardId);
      dev.log('[GameProvider] Board consumed: $boardId ($diff)');
    }
  }

  void _updateCellAndPushMove(SudokuCell newCell, Move move) {
    final newBoard = state.board.map((row) => List<SudokuCell>.from(row)).toList();
    newBoard[newCell.row][newCell.col] = newCell;
    final newStack = List<Move>.from(state.undoStack)..add(move);
    state = state.copyWith(board: newBoard, undoStack: newStack);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
