import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/game_state.dart';
import '../domain/note_helpers.dart';
import '../data/board_repository.dart';
import '../data/game_autosave.dart';
import '../../hint/hint_service.dart';
import '../../settings/domain/settings_model.dart';
import '../../settings/application/settings_provider.dart';
import '../../stats/application/stats_provider.dart';
import '../../stats/data/stats_service.dart';
import '../../stats/data/stats_storage.dart';
import '../../progression/application/progression_provider.dart';
import '../../progression/domain/xp_calculator.dart';
import '../../progression/domain/achievement.dart';
import '../../progression/data/progression_storage.dart';
import '../../cosmetics/application/cosmetic_inventory_provider.dart';
import '../data/save/global_saved_game.dart';
import '../../../shared/vibration_helper.dart';
import '../../economy/application/wallet_provider.dart';

class GameNotifier extends Notifier<GameState> {
  Timer? _timer;
  bool _isDailyChallenge = false;
  int _overlayPauseCount = 0;

  void pauseTimer() {
    _timer?.cancel();
  }

  void resumeTimer() {
    final session = state.session;
    if (session == null || session.status != GameStatus.playing) return;
    if (_overlayPauseCount > 0) return;
    _startTimer();
  }

  void onOverlayOpen() {
    if (_overlayPauseCount == 0) pauseTimer();
    _overlayPauseCount++;
    onOverlayOpenHook?.call();
  }

  void onOverlayClose() {
    if (_overlayPauseCount == 0) return;
    _overlayPauseCount--;
    if (_overlayPauseCount == 0) resumeTimer();
    onOverlayCloseHook?.call();
  }

  VoidCallback? onOverlayOpenHook;
  VoidCallback? onOverlayCloseHook;

  final _rowCompleted = StreamController<int>.broadcast();
  final _colCompleted = StreamController<int>.broadcast();
  final _blockCompleted = StreamController<int>.broadcast();
  final _digitCompleted = StreamController<int>.broadcast();
  final _comboEvent = StreamController<int>.broadcast();
  final _levelUpEvent = StreamController<int>.broadcast();
  final _achievementEvent = StreamController<String>.broadcast();
  final _backgroundUnlockEvent = StreamController<String>.broadcast();
  final _gameOverEvent = StreamController<bool>.broadcast(); // true=win, false=loss

  Stream<int> get rowCompleted => _rowCompleted.stream;
  Stream<int> get colCompleted => _colCompleted.stream;
  Stream<int> get blockCompleted => _blockCompleted.stream;
  Stream<int> get digitCompleted => _digitCompleted.stream;
  Stream<int> get comboEvent => _comboEvent.stream;
  Stream<int> get levelUpEvent => _levelUpEvent.stream;
  Stream<String> get achievementEvent => _achievementEvent.stream;
  Stream<String> get backgroundUnlockEvent => _backgroundUnlockEvent.stream;
  Stream<bool> get gameOverEvent => _gameOverEvent.stream;

  @override
  GameState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _rowCompleted.close();
      _colCompleted.close();
      _blockCompleted.close();
      _digitCompleted.close();
      _comboEvent.close();
      _levelUpEvent.close();
      _achievementEvent.close();
      _backgroundUnlockEvent.close();
      _gameOverEvent.close();
    });
    return const GameState(isLoading: false);
  }

  // ── Assist mode helpers ──────────────────────────────────────────────────

  bool get _isClassic => _mode == AssistMode.classic;
  bool get _isExpert => _mode == AssistMode.expert;
  bool get _isExtreme => _mode == AssistMode.extreme;

  AssistMode get _mode => ref.read(settingsProvider).assistMode;

  int get _maxMistakes {
    if (_isExtreme) return 1;
    if (_isClassic) return 999;
    return 3;
  }

  bool get _canUseHints {
    if (_isExpert || _isExtreme) return false;
    return true;
  }

  bool get _canPause => !_isExtreme;

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init(String difficulty) async {
    final diff = difficulty.toLowerCase();
    _timer?.cancel();
    _overlayPauseCount = 0;
    state = const GameState(isLoading: true);

    try {
      final boardData = await BoardRepository.loadRandomBoard(diff);
      final session = GameSession.create(
        boardId: boardData.id,
        difficulty: diff,
        puzzleFlat: boardData.puzzleFlat,
        solutionFlat: boardData.solutionFlat,
      );

      final maxHints = _canUseHints ? HintService.maxHintsFor(diff) : 0;

      state = GameState(
        session: session,
        isLoading: false,
        remainingHints: maxHints,
        advancedNotesEnabled: false,
        completedDigits: _computeCompletedDigits(session),
      );
      await HintService.resetCurrentGame();
      await StatsService.onGameStart(diff);
      await _reloadStats();
      await GameAutosave.clear();
      _startTimer();
    } catch (e, st) {
      dev.log('[GameProvider] init ERROR: $e\n$st');
      state = const GameState(isLoading: false);
    }
  }

  Future<void> initDaily(BoardData boardData) async {
    _isDailyChallenge = true;
    _timer?.cancel();
    _overlayPauseCount = 0;
    state = const GameState(isLoading: true);

    try {
      final session = GameSession.create(
        boardId: boardData.id,
        difficulty: 'daily',
        puzzleFlat: boardData.puzzleFlat,
        solutionFlat: boardData.solutionFlat,
      );

      state = GameState(
        session: session,
        isLoading: false,
        remainingHints: 3,
        advancedNotesEnabled: false,
        completedDigits: _computeCompletedDigits(session),
      );
      await HintService.resetCurrentGame();
      _startTimer();
    } catch (e) {
      state = const GameState(isLoading: false);
    }
  }

  void restartCurrentBoard() {
    final session = state.session;
    if (session == null) return;

    _timer?.cancel();
    _overlayPauseCount = 0;
    _isDailyChallenge = false;

    final newSession = GameSession.create(
      boardId: session.boardId,
      difficulty: session.difficulty,
      puzzleFlat: session.initialBoard,
      solutionFlat: session.solution,
    );

    final maxHints = _canUseHints ? HintService.maxHintsFor(session.difficulty) : 0;

    state = GameState(
      session: newSession,
      isLoading: false,
      remainingHints: maxHints,
      advancedNotesEnabled: false,
      completedDigits: _computeCompletedDigits(newSession),
    );

    unawaited(HintService.resetCurrentGame());
    unawaited(GameAutosave.clear());
    _startTimer();
  }

  Future<void> restoreGame(GameState savedState) async {
    _timer?.cancel();
    _overlayPauseCount = 0;
    state = savedState.copyWith(isLoading: false);

    final maxHints = _canUseHints
        ? HintService.maxHintsFor(savedState.difficulty)
        : 0;

    state = state.copyWith(remainingHints: maxHints);

    await _reloadStats();
    _startTimer();
  }

  // ── Timer ────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final s = state.session;
      if (s == null || s.status != GameStatus.playing || s.paused) return;
      final cellMs = Map<int, int>.from(state.cellTimeMs);
      final r = state.selectedRow;
      final c = state.selectedCol;
      if (r != null && c != null && s.currentBoard[r * 9 + c] == 0) {
        final idx = r * 9 + c;
        cellMs[idx] = (cellMs[idx] ?? 0) + 100;
      }
      state = state.copyWith(
        session: s.copyWith(elapsed: s.elapsed + const Duration(milliseconds: 100)),
        cellTimeMs: cellMs,
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
        if (session.currentBoard[r * 9 + c] != session.solution[r * 9 + c]) {
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
        if (session.currentBoard[r * 9 + c] != session.solution[r * 9 + c]) {
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
            if (session.currentBoard[r * 9 + c] != session.solution[r * 9 + c]) {
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
      if (!oldRows.contains(r)) { eventId++; _rowCompleted.add(r); }
    }
    for (final c in newCols) {
      if (!oldCols.contains(c)) { eventId++; _colCompleted.add(c); }
    }
    for (final b in newBlocks) {
      if (!oldBlocks.contains(b)) { eventId++; _blockCompleted.add(b); }
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
    if (session == null) return;

    final idx = row * 9 + col;
    final cellValue = session.currentBoard[idx];

    if (cellValue != 0) {
      final completed = state.completedDigits;
      if ((completed[cellValue] ?? 0) < 9 && state.lockedNumber != cellValue) {
        state = state.copyWith(lockedNumber: cellValue);
      }
      return;
    }

    if (locked == null) return;
    if (session.fixedCells.contains(idx)) return;
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

    final oldValue = session.currentBoard[idx];
    if (oldValue != 0 && oldValue == session.solution[idx]) return;

    if (state.pencilMode) {
      _handlePencil(session, idx, r, c, number);
    } else {
      _handleNumber(session, idx, r, c, number);
    }
  }

  void _handlePencil(GameSession session, int idx, int r, int c, int number) {
    final oldState = state;
    final newNotes = Map<int, Set<int>>.from(session.notes);
    final cellNotes = Set<int>.from(newNotes[idx] ?? {});

    if (cellNotes.contains(number)) {
      cellNotes.remove(number);
    } else if (_isNoteAllowed(session.currentBoard, idx, number)) {
      cellNotes.add(number);
    } else {
      return; // silently block invalid note
    }
    newNotes[idx] = cellNotes;

    final oldNotes = Set<int>.from(session.notes[idx] ?? {});
    final move = Move(
      row: r, col: c,
      oldValue: session.currentBoard[idx],
      newValue: session.currentBoard[idx],
      oldNotes: oldNotes,
      newNotes: Set<int>.from(cellNotes),
      timestamp: DateTime.now(),
    );

    state = oldState.copyWith(
      session: session.copyWith(notes: newNotes),
      undoStack: [...oldState.undoStack, move],
      noteUsageCount: oldState.noteUsageCount + 1,
    );
    _autosave();
  }

  bool _isNoteAllowed(List<int> board, int idx, int number) {
    final row = idx ~/ 9;
    final col = idx % 9;
    final br = row ~/ 3;
    final bc = col ~/ 3;

    for (var c = 0; c < 9; c++) {
      if (board[row * 9 + c] == number) return false;
    }
    for (var r = 0; r < 9; r++) {
      if (board[r * 9 + col] == number) return false;
    }
    for (var dr = 0; dr < 3; dr++) {
      for (var dc = 0; dc < 3; dc++) {
        if (board[(br * 3 + dr) * 9 + (bc * 3 + dc)] == number) return false;
      }
    }
    return true;
  }

  void _handleNumber(GameSession session, int idx, int r, int c, int number) {
    final oldState = state;
    final oldValue = session.currentBoard[idx];
    final newValue = oldValue == number ? 0 : number;

    final newBoard = List<int>.from(session.currentBoard);
    newBoard[idx] = newValue;

    final settings = ref.read(settingsProvider);
    var updatedNotes = Map<int, Set<int>>.from(session.notes);
    updatedNotes.remove(idx);

    var newStreak = oldState.correctStreak;
    var newMaxCombo = oldState.maxCombo;
    var newCorrect = oldState.correctMoves;
    var newTotal = oldState.totalMoves + 1;

    if (newValue != 0) {
      if (newValue == session.solution[idx]) {
        newStreak++;
        newCorrect++;
        if (newStreak > newMaxCombo) newMaxCombo = newStreak;
        _comboEvent.add(newStreak);

        // ALWAYS clean notes same house; recompute auto-candidates only if ADV enabled
        updatedNotes = NoteHelpers.afterNumberPlacement(
          updatedNotes, idx, newValue,
          oldState.advancedNotesEnabled, newBoard, session.solution,
        );
      } else {
        newStreak = 0;
        _comboEvent.add(0);
        _vibrateOnError(settings);

        final newMistakes = session.mistakes + 1;
        if (newMistakes >= _maxMistakes) {
          _endGame(false, session.copyWith(
            mistakes: newMistakes,
            status: GameStatus.lost,
            currentBoard: newBoard,
          ), oldState, idx, r, c, oldValue, newValue);
          return;
        }
        state = oldState.copyWith(
          session: session.copyWith(
            mistakes: newMistakes,
            currentBoard: newBoard,
            notes: updatedNotes,
          ),
          undoStack: [...oldState.undoStack, _makeMove(r, c, oldValue, newValue, session, {})],
          correctStreak: newStreak,
          maxCombo: newMaxCombo,
          totalMoves: newTotal,
          correctMoves: newCorrect,
        );
        _autosave();
        return;
      }
    }

    final updatedSession = session.copyWith(
      currentBoard: newBoard,
      notes: updatedNotes,
    );

    _applyBoardChange(updatedSession, oldState.copyWith(
      correctStreak: newStreak,
      maxCombo: newMaxCombo,
      totalMoves: newTotal,
      correctMoves: newCorrect,
    ), undoStack: [...oldState.undoStack, _makeMove(r, c, oldValue, newValue, session, {})]);

    _autosave();
    if (newValue != 0) unawaited(_checkWin());
  }

  void _endGame(bool won, GameSession session, GameState oldState, int idx, int r, int c, int oldValue, int newValue) {
    _timer?.cancel();
    _overlayPauseCount = 0;
    state = oldState.copyWith(
      session: session,
      clearLockedNumber: true,
      undoStack: [...oldState.undoStack, _makeMove(r, c, oldValue, newValue, oldState.session!, {})],
    );

    if (_isDailyChallenge) {
      _gameOverEvent.add(won);
      return;
    }

    if (won) {
      _onWon(session.difficulty, session.elapsed.inSeconds, session.boardId);
    } else {
      _onLost(session.difficulty, session.boardId);
    }

    _gameOverEvent.add(won);
  }

  Move _makeMove(int r, int c, int oldV, int newV, GameSession s, Set<int> oldN) {
    return Move(
      row: r, col: c,
      oldValue: oldV, newValue: newV,
      oldNotes: Set<int>.from(s.notes[r * 9 + c] ?? oldN),
      newNotes: {},
      timestamp: DateTime.now(),
    );
  }

  void _vibrateOnError(SettingsModel settings) {
    if (!settings.vibrateOnError || _isExpert) return;
    unawaited(VibrationHelper.vibrateError());
  }

  void _awardCoins(String difficulty) {
    final souls = switch (difficulty) {
      'easy' => 5,
      'intermediate' => 8,
      'hard' => 12,
      'expert' => 18,
      'evil' => 25,
      'mythic' => 40,
      _ => 0,
    };
    final tokens = 1;

    var finalSouls = souls;
    var finalTokens = tokens;

    if (state.errors == 0 && state.usedHints == 0 && !state.completedWithAutocomplete) {
      finalSouls = souls + (souls * 0.5).round();
      finalTokens = tokens + 1;
    } else if (state.errors == 0) {
      finalSouls = souls + (souls * 0.25).round();
    }

    unawaited(ref.read(walletProvider.notifier).addSouls(finalSouls));
    unawaited(ref.read(walletProvider.notifier).addTokens(finalTokens));
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
    _autosave();
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
    if (session.currentBoard[idx] != 0 && session.currentBoard[idx] == session.solution[idx]) return;
    if (session.currentBoard[idx] == 0 && (session.notes[idx]?.isEmpty ?? true)) return;

    final move = _makeMove(r, c, session.currentBoard[idx], 0, session, session.notes[idx] ?? {});

    final newBoard = List<int>.from(session.currentBoard);
    newBoard[idx] = 0;
    final newNotes = Map<int, Set<int>>.from(session.notes);
    newNotes.remove(idx);

    _applyBoardChange(
      session.copyWith(currentBoard: newBoard, notes: newNotes),
      oldState,
      undoStack: [...oldState.undoStack, move],
    );
    _autosave();
  }

  void togglePencil() {
    if (!_canInput) return;
    state = state.copyWith(pencilMode: !state.pencilMode);
  }

  Future<bool> toggleAdvancedNotes() async {
    if (state.session == null || state.status != GameStatus.playing) return false;
    final enabling = !state.advancedNotesEnabled;

    if (enabling) {
      final wallet = ref.read(walletProvider);
      if (wallet.advancedNoteConsumables <= 0) return false;
      await ref.read(walletProvider.notifier).consumeAdvancedNote();
      final session = state.session!;
      final candidates = NoteHelpers.computeAllCandidates(
        session.currentBoard,
        session.solution,
      );
      // Merge: keep existing manual notes, add auto candidates for empty cells
      final merged = Map<int, Set<int>>.from(candidates);
      for (final e in session.notes.entries) {
        if (e.value.isNotEmpty) {
          final existing = merged[e.key] ?? <int>{};
          merged[e.key] = {...existing, ...e.value};
        }
      }
      state = state.copyWith(
        advancedNotesEnabled: true,
        manualNotes: Map<int, Set<int>>.from(session.notes),
        session: session.copyWith(notes: merged),
      );
    } else {
      final session = state.session!;
      final saved = state.manualNotes;
      state = state.copyWith(
        advancedNotesEnabled: false,
        manualNotes: null,
        session: saved != null
            ? session.copyWith(notes: saved)
            : session,
      );
    }
    return true;
  }

  Future<HintResult> useHint() async {
    if (!_canInput || !_canUseHints) return HintResult.ignored;
    if (state.remainingHints == 0) {
      final wallet = ref.read(walletProvider);
      if (wallet.hintConsumables <= 0) return HintResult.noHints;
      await ref.read(walletProvider.notifier).consumeHint();
    }
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

  void toggleLockedNumber(int number) {
    if (!_canInput) return;
    state = state.lockedNumber == number
        ? state.copyWith(clearLockedNumber: true)
        : state.copyWith(lockedNumber: number);
  }

  void clearLockedNumber() {
    state = state.copyWith(clearLockedNumber: true);
  }

  void saveToGlobalSlot() {
    final session = state.session;
    if (session == null || session.status != GameStatus.playing) return;

    final game = GlobalSavedGame(
      difficulty: session.difficulty,
      boardId: session.boardId,
      initialBoard: List<int>.from(session.initialBoard),
      currentBoard: List<int>.from(session.currentBoard),
      solution: List<int>.from(session.solution),
      fixedCells: Set<int>.from(session.fixedCells),
      notes: Map.from(session.notes),
      mistakes: session.mistakes,
      elapsedSeconds: session.elapsed.inSeconds,
      hintsUsed: state.usedHints,
      remainingHints: state.remainingHints,
      correctStreak: state.correctStreak,
      maxCombo: state.maxCombo,
      totalMoves: state.totalMoves,
      correctMoves: state.correctMoves,
      noteUsageCount: state.noteUsageCount,
      advancedNotesEnabled: state.advancedNotesEnabled,
      cellTimeMs: Map<int, int>.from(state.cellTimeMs),
      manualNotes: state.manualNotes != null ? Map<int, Set<int>>.from(state.manualNotes!) : null,
      completedWithAutocomplete: state.completedWithAutocomplete,
      autoCompleteUsed: state.autoCompleteUsed,
      savedAt: DateTime.now(),
    );
    unawaited(GlobalSaveStorage.save(game));
    ref.invalidate(globalSavedGameProvider);
  }

  void abandonGame() {
    _timer?.cancel();
    _overlayPauseCount = 0;
    final session = state.session;
    state = state.copyWith(clearLockedNumber: true);
    if (session != null && session.status == GameStatus.playing) {
      unawaited(StatsService.onGameExit(session.difficulty, session.elapsed.inSeconds));
    }
    GameAutosave.clear();
  }

  void _revealCell(GameSession session, int idx, int r, int c) {
    final oldState = state;
    final newBoard = List<int>.from(session.currentBoard);
    var newNotes = NoteHelpers.eliminateNumber(
      session.notes,
      idx,
      session.solution[idx],
    );
    final oldNotes = Set<int>.from(session.notes[idx] ?? {});
    newBoard[idx] = session.solution[idx];
    newNotes.remove(idx);

    final move = _makeMove(r, c, session.currentBoard[idx], session.solution[idx], session, oldNotes);

    final used = oldState.usedHints + 1;
    state = oldState.copyWith(usedHints: used, remainingHints: oldState.remainingHints - 1);

    _applyBoardChange(
      session.copyWith(currentBoard: newBoard, notes: newNotes),
      state,
      undoStack: [...oldState.undoStack, move],
    );
    _autosave();
    unawaited(_checkWin());
  }

  void togglePause() {
    if (!_canPause) return;
    final session = state.session;
    if (session == null || session.status != GameStatus.playing) return;
    final wasPaused = session.paused;
    state = state.copyWith(
      session: session.copyWith(paused: !wasPaused),
      pauseCount: wasPaused ? state.pauseCount : state.pauseCount + 1,
    );
    _autosave();
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

    final updatedSession = session.copyWith(currentBoard: newBoard, notes: newNotes);
    _applyBoardChange(updatedSession, oldState, undoStack: oldState.undoStack);

    state = state.copyWith(
      completedWithAutocomplete: true,
      autoCompleteUsed: oldState.autoCompleteUsed + 1,
    );
    _autosave();
    unawaited(_checkWin());
  }

  // ── Win / Loss ───────────────────────────────────────────────────────────

  Future<void> _checkWin() async {
    final session = state.session;
    if (session == null) return;
    final complete = session.currentBoard.asMap().entries.every(
      (e) => e.value != 0 && e.value == session.solution[e.key],
    );
    if (!complete) return;

    _timer?.cancel();
    _overlayPauseCount = 0;
    await GameAutosave.clear();

    state = state.copyWith(
      session: session.copyWith(status: GameStatus.won),
      clearLockedNumber: true,
    );

    if (_isDailyChallenge) {
      _gameOverEvent.add(true);
      return;
    }

    // Award XP
    final xpResult = XpCalculator.compute(state);
    final levelUps = await ref.read(playerLevelProvider.notifier).addXp(xpResult.total);
    for (var i = 0; i < levelUps; i++) {
      _levelUpEvent.add(state.session!.solution[0]);
    }

    // Award coins
    _awardCoins(session.difficulty);

    // Check background unlocks
    if (levelUps > 0) {
      final newLevel = ref.read(playerLevelProvider).level;
      final newBgIds = ref.read(cosmeticInventoryProvider.notifier).checkNewUnlocksAtLevel(newLevel);
      for (final id in newBgIds) {
        _backgroundUnlockEvent.add(id);
      }
    }

    // Check achievements
    final achievementsToCheck = await _computeAchievements(state);
    final newlyUnlocked = await ref.read(achievementsProvider.notifier).checkBatch(achievementsToCheck);
    for (final id in newlyUnlocked) {
      _achievementEvent.add(id);
    }

    // Update missions
    await _updateMissions(state);

    // Record stats
    _onWon(session.difficulty, session.elapsed.inSeconds, session.boardId);
    _gameOverEvent.add(true);
  }

  Future<Map<String, int>> _computeAchievements(GameState state) async {
    final stats = ref.read(statsProvider).asData?.value;
    final wins = stats?.gamesWon ?? 0;
    final diffWins = Map<String, int>.from(stats?.winsByDifficulty ?? {});
    final easyWins = diffWins['easy'] ?? 0;
    final interWins = diffWins['intermediate'] ?? 0;
    final hardWins = diffWins['hard'] ?? 0;
    final expertWins = diffWins['expert'] ?? 0;
    final evilWins = diffWins['evil'] ?? 0;
    final mythicWins = diffWins['mythic'] ?? 0;
    final perfects = stats?.perfectVictories ?? 0;
    final combos = state.maxCombo;
    final hintsTotal = stats?.hintsUsed ?? 0;
    final winsNoHints = wins - (stats?.victoriesWithHints ?? 0);
    final bestStreak = stats?.bestWinStreak ?? 0;
    final errorsState = state.errors;
    final diff = state.difficulty;
    final elapsed = state.elapsedSeconds;
    final lost = stats?.gamesLost ?? 0;
    final totalMissions = await ProgressionStorage.loadTotalMissionsCompleted();
    final modesPlayed = [easyWins, interWins, hardWins, expertWins, evilWins, mythicWins]
        .where((c) => c > 0).length;
    final achievementsMap = ref.read(achievementsProvider);
    final unlockedCount = achievementsMap.values.where((a) => a.unlocked).length;
    final totalAchievements = AchievementRegistry.all().length;

    return {
      // General
      'wins_1': wins,
      'wins_10': wins,
      'wins_50': wins,
      'wins_100': wins,
      'wins_250': wins,
      'wins_500': wins,
      'wins_1000': wins,
      // Perfect
      'perfect_1': perfects,
      'perfect_10': perfects,
      'perfect_25': perfects,
      'perfect_50': perfects,
      'perfect_100': perfects,
      // Difficulty
      'easy_10': easyWins,
      'easy_50': easyWins,
      'easy_100': easyWins,
      'intermediate_10': interWins,
      'intermediate_50': interWins,
      'hard_5': hardWins,
      'hard_25': hardWins,
      'hard_75': hardWins,
      'expert_1': expertWins,
      'expert_10': expertWins,
      'expert_50': expertWins,
      'evil_1': evilWins,
      'evil_10': evilWins,
      'evil_25': evilWins,
      'mythic_1': mythicWins,
      'mythic_10': mythicWins,
      'mythic_25': mythicWins,
      // Time (event-based: only progress if this game qualifies)
      'time_easy_5m': (diff == 'easy' && elapsed < 300) ? 1 : 0,
      'time_intermediate_8m': (diff == 'intermediate' && elapsed < 480) ? 1 : 0,
      'time_hard_10m': (diff == 'hard' && elapsed < 600) ? 1 : 0,
      'time_expert_12m': (diff == 'expert' && elapsed < 720) ? 1 : 0,
      // Combos
      'combo_5': combos,
      'combo_10': combos,
      'combo_20': combos,
      'combo_50': combos,
      // Winstreaks
      'perfect_streak_5': state.errors == 0 && state.usedHints == 0 && !state.completedWithAutocomplete ? 1 : 0,
      'win_streak_10': bestStreak,
      // Hints
      'hints_10': hintsTotal,
      'hints_50': hintsTotal,
      'hints_100': hintsTotal,
      'no_hints_10': winsNoHints,
      'no_hints_50': winsNoHints,
      // Errors
      'lost_10': lost,
      'expert_no_errors': (diff == 'expert' && errorsState == 0) ? 1 : 0,
      'mythic_no_errors': (diff == 'mythic' && errorsState == 0) ? 1 : 0,
      // Missions
      'missions_1': totalMissions,
      'missions_25': totalMissions,
      'missions_100': totalMissions,
      // Completion
      'all_modes': modesPlayed,
      'all_achievements': unlockedCount >= totalAchievements ? 1 : 0,
    };
  }

  Future<void> _updateMissions(GameState state) async {
    final empty = state.session?.currentBoard.where((v) => v == 0).length ?? 0;
    final solved = 81 - empty;

    // Snapshot before updates
    final before = Map.fromEntries(
      ref.read(missionsProvider).map((m) => MapEntry(m.id, m.completed)),
    );

    await ref.read(missionsProvider.notifier).updateProgress('play_three', 1);
    await ref.read(missionsProvider.notifier).updateProgress('solve_50', solved);
    if (state.difficulty == 'easy') {
      await ref.read(missionsProvider.notifier).updateProgress('complete_easy', 1);
    }
    if (state.difficulty == 'expert') {
      await ref.read(missionsProvider.notifier).updateProgress('complete_expert', 1);
    }
    if (state.errors == 0 && state.usedHints == 0 && !state.completedWithAutocomplete) {
      await ref.read(missionsProvider.notifier).updateProgress('perfect_win', 1);
    }
    if (state.usedHints == 0) {
      await ref.read(missionsProvider.notifier).updateProgress('no_hints', 1);
    }
    if (state.errors == 0) {
      await ref.read(missionsProvider.notifier).updateProgress('zero_errors', 1);
    }
    if (state.maxCombo >= 3) {
      await ref.read(missionsProvider.notifier).updateProgress('three_combos', 1);
    }

    // Track total missions completed
    final after = ref.read(missionsProvider);
    final newlyCompleted = after.where((m) => m.completed && !(before[m.id] ?? false)).length;
    if (newlyCompleted > 0) {
      final current = await ProgressionStorage.loadTotalMissionsCompleted();
      await ProgressionStorage.saveTotalMissionsCompleted(current + newlyCompleted);
    }
  }

  void _onLost(String diff, String boardId) {
    _timer?.cancel();
    _overlayPauseCount = 0;
    GameAutosave.clear();
    unawaited(GlobalSaveStorage.delete());
    ref.invalidate(globalSavedGameProvider);
    unawaited(_recordLost(diff, boardId));
    unawaited(ref.read(missionsProvider.notifier).updateProgress('play_three', 1));
    _gameOverEvent.add(false);
  }

  void _onWon(String diff, int elapsed, String boardId) {
    unawaited(GlobalSaveStorage.delete());
    ref.invalidate(globalSavedGameProvider);
    unawaited(_recordWon(diff, elapsed, boardId));
  }

  Future<void> _recordWon(String diff, int elapsed, String boardId) async {
    await StatsStorage.markBoardPlayed(diff, boardId);
    final session = state.session;
    await StatsService.onVictory(
      diff, elapsed,
      mistakes: session?.mistakes ?? 0,
      hintsUsed: state.usedHints,
      completedWithAutocomplete: state.completedWithAutocomplete ? 1 : 0,
      maxCombo: state.maxCombo,
      totalNoteUsage: state.noteUsageCount,
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

  // ── Autosave ─────────────────────────────────────────────────────────────

  void _autosave() {
    if (state.status != GameStatus.playing) return;
    if (_isDailyChallenge) return;
    unawaited(GameAutosave.save(state));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool get _canInput {
    if (_isExtreme && state.isPaused) return false;
    final s = state.session;
    return s != null && s.status == GameStatus.playing && !s.paused;
  }

  bool get hintsEnabled => _canUseHints;
  bool get pauseEnabled => _canPause;
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);
