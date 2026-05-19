import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/game_state.dart';
import '../data/board_repository.dart';
import '../data/played_boards_manager.dart';

class GameNotifier extends Notifier<GameState> {
  Timer? _timer;

  @override
  GameState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    // Return empty board initially
    return GameState(board: _createEmptyBoard(), difficulty: 'easy', isLoading: true);
  }

  List<List<SudokuCell>> _createEmptyBoard() {
    return List.generate(9, (r) => List.generate(9, (c) => SudokuCell(row: r, col: c, value: 0, solution: 0)));
  }

  Future<void> init(String difficulty) async {
    state = state.copyWith(isLoading: true, isPaused: false, status: GameStatus.playing, elapsedSeconds: 0, errors: 0, undoStack: [], pencilMode: false);
    _timer?.cancel();
    
    final allBoards = await BoardRepository.getAvailableBoards(difficulty);
    final playedBoards = await PlayedBoardsManager.getPlayedBoards(difficulty);
    
    List<String> unplayed = allBoards.where((path) {
      final id = path.split('/').last.replaceAll('.json', '');
      return !playedBoards.contains(id);
    }).toList();
    
    if (unplayed.isEmpty) {
      await PlayedBoardsManager.clearPlayedBoards(difficulty);
      unplayed = allBoards;
    }
    
    if (unplayed.isEmpty) {
      state = state.copyWith(isLoading: false);
      return; // No boards found
    }
    
    final randomPath = unplayed[Random().nextInt(unplayed.length)];
    final boardData = await BoardRepository.loadBoard(randomPath);

    // BoardRepository ya normalizó el puzzle a List<int>[81]
    final puzzleFlat = boardData['puzzleFlat'] as List<int>;
    final solutionFlat = boardData['solutionFlat'] as List<int>;
    final boardId = boardData['id'] as String;
    final diffKey = difficulty.toLowerCase(); // ← siempre lowercase

    dev.log('[GameProvider] BOARD ID: $boardId | DIFFICULTY: $diffKey | CELLS: ${puzzleFlat.length}');

    List<List<SudokuCell>> board = List.generate(9, (r) {
      return List.generate(9, (c) {
        final idx = r * 9 + c;
        final val = puzzleFlat[idx];
        final sol = solutionFlat[idx];
        return SudokuCell(
          row: r, col: c, value: val, solution: sol, isFixed: val != 0,
        );
      });
    });

    state = GameState(
      board: board,
      boardId: boardId,
      difficulty: diffKey,
      isLoading: false,
    );
    
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == GameStatus.playing && !state.isPaused) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

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
        row: r, col: c, oldValue: cell.value, newValue: cell.value,
        oldNotes: cell.notes, newNotes: newNotes, timestamp: DateTime.now()
      );
      
      _updateCellAndPushMove(cell.copyWith(notes: newNotes), move);
    } else {
      final newValue = cell.value == number ? 0 : number;
      final move = Move(
        row: r, col: c, oldValue: cell.value, newValue: newValue,
        oldNotes: cell.notes, newNotes: {}, timestamp: DateTime.now()
      );
      
      _updateCellAndPushMove(cell.copyWith(value: newValue, notes: {}), move);
      
      if (newValue != 0 && newValue != cell.solution) {
        final newErrors = state.errors + 1;
        if (newErrors >= 3) {
          state = state.copyWith(errors: newErrors, status: GameStatus.lost);
          PlayedBoardsManager.markBoardAsPlayed(state.difficulty, state.boardId);
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
    final restoredCell = cell.copyWith(value: lastMove.oldValue, notes: lastMove.oldNotes);
    
    final newBoard = state.board.map((row) => List<SudokuCell>.from(row)).toList();
    newBoard[restoredCell.row][restoredCell.col] = restoredCell;
    
    state = state.copyWith(
      board: newBoard, 
      undoStack: newStack,
      selectedRow: lastMove.row,
      selectedCol: lastMove.col,
    );
  }

  void _checkWinCondition() {
    bool isComplete = true;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final cell = state.board[r][c];
        if (cell.value == 0 || cell.value != cell.solution) {
          isComplete = false;
          break;
        }
      }
    }
    if (isComplete) {
      state = state.copyWith(status: GameStatus.won);
      PlayedBoardsManager.markBoardAsPlayed(state.difficulty, state.boardId);
    }
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
    if (cell.isFixed) return;
    if (cell.value == 0 && cell.notes.isEmpty) return;
    
    final move = Move(
      row: r, col: c, oldValue: cell.value, newValue: 0,
      oldNotes: cell.notes, newNotes: {}, timestamp: DateTime.now()
    );
      
    _updateCellAndPushMove(cell.copyWith(value: 0, notes: {}), move);
  }

  void _updateCellAndPushMove(SudokuCell newCell, Move move) {
    final newBoard = state.board.map((row) => List<SudokuCell>.from(row)).toList();
    newBoard[newCell.row][newCell.col] = newCell;
    
    final newStack = List<Move>.from(state.undoStack)..add(move);
    state = state.copyWith(board: newBoard, undoStack: newStack);
  }

}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
