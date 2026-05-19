import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/game_state.dart';
import '../data/board_repository.dart';
import '../../stats/data/stats_storage.dart';

class GameNotifier extends Notifier<GameState> {
  Timer? _timer;

  @override
  GameState build() {
    ref.onDispose(() => _timer?.cancel());
    return const GameState(isLoading: false);
  }

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init(String difficulty) async {
    final diff = difficulty.toLowerCase();
    _timer?.cancel();

    // Estado limpio de carga — sin rastro de sesión anterior
    state = const GameState(isLoading: true);

    try {
      final boardData = await BoardRepository.loadRandomBoard(diff);

      final session = GameSession.create(
        boardId: boardData.id,
        difficulty: diff,
        puzzleFlat: boardData.puzzleFlat,
        solutionFlat: boardData.solutionFlat,
      );

      state = GameState(session: session, isLoading: false);
      _startTimer();
    } catch (e) {
      dev.log('[GameProvider] init error: $e');
      state = const GameState(isLoading: false);
    }
  }

  // ── Timer ────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final s = state.session;
      if (s == null || s.status != GameStatus.playing || s.paused) return;
      state = state.copyWith(
        session: s.copyWith(elapsed: s.elapsed + const Duration(seconds: 1)),
      );
    });
  }

  // ── User inputs ──────────────────────────────────────────────────────────

  void selectCell(int row, int col) {
    if (!_canInput) return;
    if (state.selectedRow == row && state.selectedCol == col) {
      state = state.clearSelection();
    } else {
      state = state.select(row, col);
    }
  }

  void inputNumber(int number) {
    if (!_canInput) return;
    final r = state.selectedRow;
    final c = state.selectedCol;
    if (r == null || c == null) return;

    final session = state.session!;
    final idx = r * 9 + c;
    if (session.fixedCells.contains(idx)) return;

    if (state.pencilMode) {
      _handlePencil(session, idx, r, c, number);
    } else {
      _handleNumber(session, idx, r, c, number);
    }
  }

  void _handlePencil(GameSession session, int idx, int r, int c, int number) {
    final newNotes = Map<int, Set<int>>.from(session.notes);
    final cellNotes = Set<int>.from(newNotes[idx] ?? {});
    if (cellNotes.contains(number)) {
      cellNotes.remove(number);
    } else {
      cellNotes.add(number);
    }
    newNotes[idx] = cellNotes;

    final oldNotes = Set<int>.from(session.notes[idx] ?? {});
    final move = Move(
      row: r, col: c,
      oldValue: session.currentBoard[idx], newValue: session.currentBoard[idx],
      oldNotes: oldNotes, newNotes: Set<int>.from(cellNotes),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      session: session.copyWith(notes: newNotes),
      undoStack: [...state.undoStack, move],
    );
  }

  void _handleNumber(GameSession session, int idx, int r, int c, int number) {
    final oldValue = session.currentBoard[idx];
    final newValue = oldValue == number ? 0 : number;

    final newBoard = List<int>.from(session.currentBoard);
    newBoard[idx] = newValue;

    final newNotes = Map<int, Set<int>>.from(session.notes);
    newNotes.remove(idx); // limpiar notas al escribir número

    final move = Move(
      row: r, col: c,
      oldValue: oldValue, newValue: newValue,
      oldNotes: Set<int>.from(session.notes[idx] ?? {}),
      newNotes: {},
      timestamp: DateTime.now(),
    );

    var updatedSession = session.copyWith(currentBoard: newBoard, notes: newNotes);

    if (newValue != 0 && newValue != session.solution[idx]) {
      final newMistakes = updatedSession.mistakes + 1;
      if (newMistakes >= 3) {
        updatedSession = updatedSession.copyWith(
          mistakes: newMistakes,
          status: GameStatus.lost,
        );
        state = state.copyWith(
          session: updatedSession,
          undoStack: [...state.undoStack, move],
        );
        _onLost();
        return;
      }
      updatedSession = updatedSession.copyWith(mistakes: newMistakes);
    }

    state = state.copyWith(
      session: updatedSession,
      undoStack: [...state.undoStack, move],
    );

    if (newValue != 0) _checkWin();
  }

  void undo() {
    if (!_canInput || state.undoStack.isEmpty) return;
    final newStack = List<Move>.from(state.undoStack);
    final last = newStack.removeLast();

    final session = state.session!;
    final idx = last.row * 9 + last.col;
    final newBoard = List<int>.from(session.currentBoard);
    newBoard[idx] = last.oldValue;

    final newNotes = Map<int, Set<int>>.from(session.notes);
    if (last.oldNotes.isEmpty) {
      newNotes.remove(idx);
    } else {
      newNotes[idx] = Set<int>.from(last.oldNotes);
    }

    state = state.copyWith(
      session: session.copyWith(currentBoard: newBoard, notes: newNotes),
      undoStack: newStack,
      selectedRow: last.row,
      selectedCol: last.col,
    );
  }

  void erase() {
    if (!_canInput) return;
    final r = state.selectedRow;
    final c = state.selectedCol;
    if (r == null || c == null) return;

    final session = state.session!;
    final idx = r * 9 + c;
    if (session.fixedCells.contains(idx)) return;
    if (session.currentBoard[idx] == 0 && (session.notes[idx]?.isEmpty ?? true)) return;

    final move = Move(
      row: r, col: c,
      oldValue: session.currentBoard[idx], newValue: 0,
      oldNotes: Set<int>.from(session.notes[idx] ?? {}), newNotes: {},
      timestamp: DateTime.now(),
    );

    final newBoard = List<int>.from(session.currentBoard);
    newBoard[idx] = 0;
    final newNotes = Map<int, Set<int>>.from(session.notes);
    newNotes.remove(idx);

    state = state.copyWith(
      session: session.copyWith(currentBoard: newBoard, notes: newNotes),
      undoStack: [...state.undoStack, move],
    );
  }

  void togglePencil() {
    if (!_canInput) return;
    state = state.copyWith(pencilMode: !state.pencilMode);
  }

  void togglePause() {
    final session = state.session;
    if (session == null || session.status != GameStatus.playing) return;
    state = state.copyWith(
      session: session.copyWith(paused: !session.paused),
    );
  }

  // ── Win / Loss ───────────────────────────────────────────────────────────

  void _checkWin() {
    final session = state.session;
    if (session == null) return;
    final complete = session.currentBoard
        .asMap()
        .entries
        .every((e) => e.value != 0 && e.value == session.solution[e.key]);
    if (!complete) return;

    _timer?.cancel();
    state = state.copyWith(
      session: session.copyWith(status: GameStatus.won),
    );
    _onWon(session.difficulty, session.elapsed.inSeconds, session.boardId);
  }

  void _onWon(String diff, int elapsed, String boardId) {
    StatsStorage.recordWin(diff, elapsed);
    StatsStorage.markBoardPlayed(diff, boardId);
  }

  void _onLost() {
    _timer?.cancel();
    final session = state.session;
    if (session == null) return;
    StatsStorage.recordLoss(session.difficulty);
    StatsStorage.markBoardPlayed(session.difficulty, session.boardId);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool get _canInput {
    final s = state.session;
    return s != null && s.status == GameStatus.playing && !s.paused;
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
