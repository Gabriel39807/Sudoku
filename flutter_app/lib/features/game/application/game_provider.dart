import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/game_state.dart';
import '../data/board_repository.dart';
import '../../hint/hint_service.dart';
import '../../settings/application/settings_provider.dart';
import '../../stats/application/stats_provider.dart';
import '../../stats/data/stats_service.dart';
import '../../stats/data/stats_storage.dart';

class GameNotifier extends Notifier<GameState> {
  Timer? _timer;

  // Streams para eventos de animación
  final _rowCompleted = StreamController<int>.broadcast();
  final _colCompleted = StreamController<int>.broadcast();
  final _blockCompleted = StreamController<int>.broadcast();
  final _digitCompleted = StreamController<int>.broadcast();

  Stream<int> get rowCompleted => _rowCompleted.stream;
  Stream<int> get colCompleted => _colCompleted.stream;
  Stream<int> get blockCompleted => _blockCompleted.stream;
  Stream<int> get digitCompleted => _digitCompleted.stream;

  @override
  GameState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _rowCompleted.close();
      _colCompleted.close();
      _blockCompleted.close();
      _digitCompleted.close();
    });
    return const GameState(isLoading: false);
  }

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init(String difficulty) async {
    final diff = difficulty.toLowerCase();
    _timer?.cancel();

    state = const GameState(isLoading: true);

    try {
      final boardData = await BoardRepository.loadRandomBoard(diff);
      final session = GameSession.create(
        boardId: boardData.id,
        difficulty: diff,
        puzzleFlat: boardData.puzzleFlat,
        solutionFlat: boardData.solutionFlat,
      );

      final maxHints = HintService.maxHintsFor(diff);
      state = GameState(
        session: session,
        isLoading: false,
        remainingHints: maxHints,
        completedDigits: _computeCompletedDigits(session),
      );
      await HintService.resetCurrentGame();
      await StatsService.onGameStart(diff);
      await _reloadStats();
      _startTimer();
    } catch (e, st) {
      dev.log('[GameProvider] init ERROR: $e\n$st');
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

  // ── Helpers de tracking ──────────────────────────────────────────────────

  Map<int, int> _computeCompletedDigits(GameSession session) {
    final counts = <int, int>{};
    for (var i = 1; i <= 9; i++) { counts[i] = 0; }
    for (var i = 0; i < 81; i++) {
      final val = session.currentBoard[i];
      if (val != 0 && val == session.solution[i]) {
        counts[val] = counts[val]! + 1;
      }
    }
    return counts;
  }

  Set<int> _computeCompletedRows(GameSession session) {
    final rows = <int>{};
    for (var r = 0; r < 9; r++) {
      var complete = true;
      for (var c = 0; c < 9; c++) {
        final idx = r * 9 + c;
        if (session.currentBoard[idx] != session.solution[idx]) {
          complete = false;
          break;
        }
      }
      if (complete) rows.add(r);
    }
    return rows;
  }

  Set<int> _computeCompletedCols(GameSession session) {
    final cols = <int>{};
    for (var c = 0; c < 9; c++) {
      var complete = true;
      for (var r = 0; r < 9; r++) {
        final idx = r * 9 + c;
        if (session.currentBoard[idx] != session.solution[idx]) {
          complete = false;
          break;
        }
      }
      if (complete) cols.add(c);
    }
    return cols;
  }

  Set<int> _computeCompletedBlocks(GameSession session) {
    final blocks = <int>{};
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        final blockIdx = br * 3 + bc;
        var complete = true;
        for (var dr = 0; dr < 3; dr++) {
          for (var dc = 0; dc < 3; dc++) {
            final r = br * 3 + dr;
            final c = bc * 3 + dc;
            final idx = r * 9 + c;
            if (session.currentBoard[idx] != session.solution[idx]) {
              complete = false;
              break;
            }
          }
          if (!complete) break;
        }
        if (complete) blocks.add(blockIdx);
      }
    }
    return blocks;
  }

  void _applyBoardChange(
    GameSession session,
    GameState oldState, {
    List<Move>? undoStack,
  }) {
    final newDigits = _computeCompletedDigits(session);
    final newRows = _computeCompletedRows(session);
    final newCols = _computeCompletedCols(session);
    final newBlocks = _computeCompletedBlocks(session);

    final oldDigits = oldState.completedDigits;
    final oldRows = oldState.completedRows;
    final oldCols = oldState.completedCols;
    final oldBlocks = oldState.completedBlocks;

    var eventId = oldState.animationEventId;

    for (var d = 1; d <= 9; d++) {
      final oldCount = oldDigits[d] ?? 0;
      final newCount = newDigits[d] ?? 0;
      if (oldCount < 9 && newCount >= 9) {
        eventId++;
        _digitCompleted.add(d);
      }
    }

    for (final r in newRows) {
      if (!oldRows.contains(r)) {
        eventId++;
        _rowCompleted.add(r);
      }
    }

    for (final c in newCols) {
      if (!oldCols.contains(c)) {
        eventId++;
        _colCompleted.add(c);
      }
    }

    for (final b in newBlocks) {
      if (!oldBlocks.contains(b)) {
        eventId++;
        _blockCompleted.add(b);
      }
    }

    state = oldState.copyWith(
      session: session,
      undoStack: undoStack ?? oldState.undoStack,
      completedDigits: newDigits,
      completedRows: newRows,
      completedCols: newCols,
      completedBlocks: newBlocks,
      animationEventId: eventId,
    );
  }

  // ── User inputs ──────────────────────────────────────────────────────────

  void selectCell(int row, int col) {
    if (!_canInput) return;
    final locked = state.lockedNumber;
    if (state.selectedRow == row && state.selectedCol == col) {
      if (locked == null) {
        state = state.clearSelection();
      }
    } else {
      state = state.select(row, col);
    }

    final session = state.session;
    if (locked == null || session == null) return;

    final idx = row * 9 + col;
    if (session.fixedCells.contains(idx) || session.currentBoard[idx] != 0) {
      return;
    }
    inputNumber(locked);
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
      row: r,
      col: c,
      oldValue: session.currentBoard[idx],
      newValue: session.currentBoard[idx],
      oldNotes: oldNotes,
      newNotes: Set<int>.from(cellNotes),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      session: session.copyWith(notes: newNotes),
      undoStack: [...state.undoStack, move],
    );
  }

  void _handleNumber(GameSession session, int idx, int r, int c, int number) {
    final oldState = state;
    final oldValue = session.currentBoard[idx];
    final newValue = oldValue == number ? 0 : number;

    final newBoard = List<int>.from(session.currentBoard);
    newBoard[idx] = newValue;

    final newNotes = Map<int, Set<int>>.from(session.notes);
    newNotes.remove(idx);

    final move = Move(
      row: r,
      col: c,
      oldValue: oldValue,
      newValue: newValue,
      oldNotes: Set<int>.from(session.notes[idx] ?? {}),
      newNotes: {},
      timestamp: DateTime.now(),
    );

    var updatedSession = session.copyWith(
      currentBoard: newBoard,
      notes: newNotes,
    );

    if (newValue != 0 && newValue != session.solution[idx]) {
      _vibrateOnError();
      final newMistakes = updatedSession.mistakes + 1;
      if (newMistakes >= 3) {
        updatedSession = updatedSession.copyWith(
          mistakes: newMistakes,
          status: GameStatus.lost,
        );
        state = oldState.copyWith(
          session: updatedSession,
          undoStack: [...oldState.undoStack, move],
        );
        _onLost();
        return;
      }
      updatedSession = updatedSession.copyWith(mistakes: newMistakes);
    }

    _applyBoardChange(updatedSession, oldState, undoStack: [...oldState.undoStack, move]);

    if (newValue != 0) _checkWin();
  }

  void _vibrateOnError() {
    final settings = ref.read(settingsProvider);
    if (settings.vibrateOnError) {
      HapticFeedback.mediumImpact();
    }
  }

  void undo() {
    if (!_canInput || state.undoStack.isEmpty) return;
    final oldState = state;
    final newStack = List<Move>.from(oldState.undoStack);
    final last = newStack.removeLast();

    final session = oldState.session!;
    final idx = last.row * 9 + last.col;
    final newBoard = List<int>.from(session.currentBoard);
    newBoard[idx] = last.oldValue;

    final newNotes = Map<int, Set<int>>.from(session.notes);
    if (last.oldNotes.isEmpty) {
      newNotes.remove(idx);
    } else {
      newNotes[idx] = Set<int>.from(last.oldNotes);
    }

    _applyBoardChange(
      session.copyWith(currentBoard: newBoard, notes: newNotes),
      oldState,
      undoStack: newStack,
    );
  }

  void erase() {
    if (!_canInput) return;
    final oldState = state;
    final r = oldState.selectedRow;
    final c = oldState.selectedCol;
    if (r == null || c == null) return;

    final session = oldState.session!;
    final idx = r * 9 + c;
    if (session.fixedCells.contains(idx)) return;
    if (session.currentBoard[idx] == 0 &&
        (session.notes[idx]?.isEmpty ?? true)) {
      return;
    }

    final move = Move(
      row: r,
      col: c,
      oldValue: session.currentBoard[idx],
      newValue: 0,
      oldNotes: Set<int>.from(session.notes[idx] ?? {}),
      newNotes: {},
      timestamp: DateTime.now(),
    );

    final newBoard = List<int>.from(session.currentBoard);
    newBoard[idx] = 0;
    final newNotes = Map<int, Set<int>>.from(session.notes);
    newNotes.remove(idx);

    _applyBoardChange(
      session.copyWith(currentBoard: newBoard, notes: newNotes),
      oldState,
      undoStack: [...oldState.undoStack, move],
    );
  }

  void togglePencil() {
    if (!_canInput) return;
    state = state.copyWith(pencilMode: !state.pencilMode);
  }

  HintResult useHint() {
    if (!_canInput) return HintResult.ignored;
    if (state.remainingHints == 0) return HintResult.ignored;
    final r = state.selectedRow;
    final c = state.selectedCol;
    if (r == null || c == null) return HintResult.noSelection;

    final session = state.session!;
    final idx = r * 9 + c;
    if (session.fixedCells.contains(idx) || session.currentBoard[idx] != 0) {
      return HintResult.ignored;
    }

    _revealCell(session, idx, r, c);
    unawaited(_recordHintUsed(session.difficulty));
    return HintResult.applied;
  }

  void unlockHints() {}

  void buyHints() {}

  void toggleLockedNumber(int number) {
    if (!_canInput) return;
    state = state.lockedNumber == number
        ? state.copyWith(clearLockedNumber: true)
        : state.copyWith(lockedNumber: number);
  }

  void clearLockedNumber() {
    state = state.copyWith(clearLockedNumber: true);
  }

  void abandonGame() {
    _timer?.cancel();
    final session = state.session;
    state = state.copyWith(clearLockedNumber: true);
    if (session != null && session.status == GameStatus.playing) {
      unawaited(
        StatsService.onGameExit(session.difficulty, session.elapsed.inSeconds),
      );
    }
  }

  void _revealCell(GameSession session, int idx, int r, int c) {
    final oldState = state;
    final newBoard = List<int>.from(session.currentBoard);
    final newNotes = Map<int, Set<int>>.from(session.notes);
    final oldNotes = Set<int>.from(session.notes[idx] ?? {});
    newBoard[idx] = session.solution[idx];
    newNotes.remove(idx);

    final move = Move(
      row: r,
      col: c,
      oldValue: session.currentBoard[idx],
      newValue: session.solution[idx],
      oldNotes: oldNotes,
      newNotes: {},
      timestamp: DateTime.now(),
    );

    _applyBoardChange(
      session.copyWith(currentBoard: newBoard, notes: newNotes),
      oldState,
      undoStack: [...oldState.undoStack, move],
    );

    _checkWin();
  }

  void togglePause() {
    final session = state.session;
    if (session == null || session.status != GameStatus.playing) return;
    state = state.copyWith(session: session.copyWith(paused: !session.paused));
  }

  // ── Auto Complete ────────────────────────────────────────────────────────

  void autoComplete() {
    if (!_canInput) return;
    final session = state.session;
    if (session == null) return;

    final oldState = state;
    final newBoard = List<int>.from(session.currentBoard);
    final newNotes = Map<int, Set<int>>.from(session.notes);

    for (var i = 0; i < 81; i++) {
      if (newBoard[i] == 0) {
        newBoard[i] = session.solution[i];
        newNotes.remove(i);
      }
    }

    final updatedSession = session.copyWith(
      currentBoard: newBoard,
      notes: newNotes,
    );

    _applyBoardChange(updatedSession, oldState, undoStack: oldState.undoStack);

    state = state.copyWith(
      completedWithAutocomplete: true,
    );

    _checkWin();
  }

  // ── Win / Loss ───────────────────────────────────────────────────────────

  void _checkWin() {
    final session = state.session;
    if (session == null) return;
    final complete = session.currentBoard.asMap().entries.every(
      (e) => e.value != 0 && e.value == session.solution[e.key],
    );
    if (!complete) return;

    _timer?.cancel();
    state = state.copyWith(
      session: session.copyWith(status: GameStatus.won),
      clearLockedNumber: true,
    );
    _onWon(
      session.difficulty,
      session.elapsed.inSeconds,
      session.boardId,
    );
  }

  void _onWon(
    String diff,
    int elapsed,
    String boardId,
  ) {
    unawaited(_recordWon(diff, elapsed, boardId));
  }

  void _onLost() {
    _timer?.cancel();
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(clearLockedNumber: true);
    unawaited(_recordLost(session.difficulty, session.boardId));
  }

  Future<void> _recordWon(
    String diff,
    int elapsed,
    String boardId,
  ) async {
    await StatsStorage.markBoardPlayed(diff, boardId);
    final session = state.session;
    await StatsService.onVictory(
      diff,
      elapsed,
      mistakes: session?.mistakes ?? 0,
      hintsUsed: state.usedHints,
      completedWithAutocomplete:
          state.completedWithAutocomplete ? 1 : 0,
    );
  }

  Future<void> _recordLost(String diff, String boardId) async {
    final session = state.session;
    await StatsStorage.markBoardPlayed(diff, boardId);
    await StatsService.onDefeat(diff, session?.elapsed.inSeconds ?? 0);
  }

  Future<void> _recordHintUsed(String diff) async {
    await HintService.persistCurrentGameHintUsed(state.usedHints);
    await StatsService.onHintUsed(diff);
  }

  Future<void> _reloadStats() async {
    await ref.read(statsProvider.notifier).reload();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool get _canInput {
    final s = state.session;
    return s != null && s.status == GameStatus.playing && !s.paused;
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);
