import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../onboarding/difficulty_intro_service.dart';
import '../../onboarding/difficulty_unlock_dialog.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/settings_model.dart';
import '../../stats/data/stats_service.dart';
import '../application/game_provider.dart';
import '../domain/game_state.dart';
import '../domain/game_session_context.dart';
import '../domain/session_stats.dart';
import '../data/game_autosave.dart';
import 'widgets/sudoku_board.dart';
import 'widgets/keypad_widget.dart';
import 'widgets/actions_widget.dart';
import '../../../shared/widgets/gameplay_overlay_guard.dart';
import '../data/save/global_saved_game.dart';
import '../../../shared/widgets/game_modal_card.dart';
import '../../../shared/widgets/game_exit_dialog.dart';
import '../../../shared/widgets/pause_dialog.dart';
import '../../smart_hints/domain/hint_target_keys.dart';
import '../../smart_hints/application/hint_engine.dart';
import '../../smart_hints/presentation/hint_overlay_manager.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String difficulty;
  const GameScreen({super.key, required this.difficulty});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  OverlayEntry? _digitFeedback;
  OverlayEntry? _comboFeedback;
  StreamSubscription<int>? _comboSub;
  StreamSubscription<bool>? _gameOverSub;

  final _hintKeys = HintTargetKeys();
  final _hintOverlayManager = HintOverlayManager();
  int _lastMistakeCount = 0;
  StreamSubscription<int>? _digitSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initGame();
      if (!mounted) return;
      await _showDifficultyIntroIfNeeded();
      _listenToDigitCompleted();
      _listenToCombo();
      _listenToGameOver();
      _setupHintEngine();
    });
  }

  Future<void> _initGame() async {
    final diff = widget.difficulty;
    dev.log('[GameScreen] >>> _initGame for difficulty="$diff"');
    final currentState = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    if (currentState.session != null && !currentState.isLoading) {
      final ctx = notifier.currentContext;
      if (ctx != null && ctx.mode == GameMode.normal && ctx.difficulty == diff && currentState.session!.status == GameStatus.playing) {
        dev.log('[GameScreen] Context match for $diff — skipping init');
        return;
      }
      if (currentState.session!.status == GameStatus.playing) {
        dev.log('[GameScreen] Context mismatch (expected normal/$diff, got ${ctx?.mode}/${ctx?.difficulty}) — clearing stale session');
        notifier.abandonGame();
      }
    }

    final globalSave = await GlobalSaveStorage.load();
    if (globalSave != null && globalSave.difficulty == diff && mounted) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => GameplayOverlayGuard(
          child: GameModalCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save, size: 40, color: Colors.amber.shade300)
                    .animate().fade().scale(begin: Offset(0, 0)),
                const SizedBox(height: 16),
                Text('PARTIDA GUARDADA',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2,
                        color: Colors.amber.shade200)),
                const SizedBox(height: 12),
                Text('Tienes una partida guardada en ${diff.toUpperCase()} del ${_fmtDate(globalSave.savedAt)}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('CONTINUAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('NUEVA PARTIDA', style: TextStyle(fontSize: 13, color: Colors.white54)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (shouldContinue == true && mounted) {
         final session = GameSession.restore(
           boardId: globalSave.boardId,
           difficulty: globalSave.difficulty,
           initialBoard: globalSave.initialBoard,
           currentBoard: globalSave.currentBoard,
           solution: globalSave.solution,
           fixedCells: globalSave.fixedCells,
           notes: Map<int, Set<int>>.from(globalSave.notes),
           mistakes: globalSave.mistakes,
           hintsUsed: globalSave.hintsUsed,
           retries: globalSave.retries,
           continuesUsed: globalSave.continuesUsed,
           elapsed: Duration(seconds: globalSave.elapsedSeconds),
           paused: false,
           status: GameStatus.playing,
         );
        final state = GameState(
          session: session,
          isLoading: false,
          remainingHints: globalSave.remainingHints,
          usedHints: globalSave.hintsUsed,
          correctStreak: globalSave.correctStreak,
          maxCombo: globalSave.maxCombo,
          totalMoves: globalSave.totalMoves,
          correctMoves: globalSave.correctMoves,
          noteUsageCount: globalSave.noteUsageCount,
          advancedNotesEnabled: globalSave.advancedNotesEnabled,
          advancedNotesUnlockedForRun: globalSave.advancedNotesUnlockedForRun,
          cellTimeMs: Map<int, int>.from(globalSave.cellTimeMs),
          manualNotes: globalSave.manualNotes != null ? Map<int, Set<int>>.from(globalSave.manualNotes!) : null,
          completedWithAutocomplete: globalSave.completedWithAutocomplete,
          autoCompleteUsed: globalSave.autoCompleteUsed,
        );
        await ref.read(gameProvider.notifier).restoreGame(state);
        return;
      }
    }

    final saved = await GameAutosave.restoreForDifficulty(diff);

    if (saved != null && mounted) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => GameplayOverlayGuard(
          child: GameModalCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.autorenew, size: 40, color: Colors.blue.shade300)
                    .animate().fade().scale(begin: Offset(0, 0)),
                const SizedBox(height: 16),
                Text('PARTIDA ENCONTRADA',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2,
                        color: Colors.blue.shade200)),
                const SizedBox(height: 12),
                Text('Tienes una partida sin terminar en ${diff.toUpperCase()}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('CONTINUAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('NUEVA PARTIDA', style: TextStyle(fontSize: 13, color: Colors.white54)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (shouldContinue == true && mounted) {
        await ref.read(gameProvider.notifier).restoreGame(saved);
        return;
      }
    }

    if (mounted) {
      await ref.read(gameProvider.notifier).init(diff);
    }
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  void _listenToDigitCompleted() {
    final notifier = ref.read(gameProvider.notifier);
    _digitSub = notifier.digitCompleted.listen((digit) {
      _showDigitFeedback(digit);
      if (!mounted) return;
      ref.read(hintEngineProvider.notifier).onNumberCompleted();
    });
  }

  void _listenToCombo() {
    _comboSub?.cancel();
    _comboSub = ref.read(gameProvider.notifier).comboEvent.listen((streak) {
      if (streak > 1) {
        _showComboFeedback(streak);
      } else {
        _comboFeedback?.remove();
        _comboFeedback = null;
      }
    });
  }

  void _listenToGameOver() {
    _gameOverSub?.cancel();
    _gameOverSub = ref.read(gameProvider.notifier).gameOverEvent.listen((won) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (won) {
          context.pushReplacement('/victory', extra: widget.difficulty);
        } else {
          context.pushReplacement('/defeat', extra: widget.difficulty);
        }
      });
    });
  }

  void _setupHintEngine() {
    final engine = ref.read(hintEngineProvider.notifier);

    engine.onShowHint = (event) {
      if (!mounted) return;
      _hintOverlayManager.show(
        context: context,
        event: event,
        targetKeys: _hintKeys.asMap,
        onDismiss: () {
          engine.onHintDismissed();
        },
      );
    };

    engine.onHideHint = () {
      _hintOverlayManager.hide();
    };

// Listen for game state changes to detect mistakes and actions
    ref.listen(gameProvider, (prev, next) {
      if (prev == null || next.session == null) return;

      if (next.errors > _lastMistakeCount) {
        _lastMistakeCount = next.errors;
        engine.onMistake();
      }

      if (next.pencilMode && !prev.pencilMode) {
        engine.onPencilUsed();
      }

      if (next.advancedNotesEnabled && !prev.advancedNotesEnabled) {
        engine.onAdvancedNotesToggled();
      }

      if (next.totalMoves > prev.totalMoves) {
        engine.resetStuckTimer();
      }
    });

    engine.onGameInit();
    engine.startStuckDetection();
  }

  void _showDigitFeedback(int digit) {
    if (!mounted) return;
    _digitFeedback?.remove();
    final overlay = Overlay.of(context);
    _digitFeedback = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 100,
        left: 0, right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Digit $digit completed',
                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_digitFeedback!);
    Future.delayed(const Duration(seconds: 2), () {
      _digitFeedback?.remove();
      _digitFeedback = null;
    });
  }

  void _showComboFeedback(int streak) {
    if (!mounted) return;
    _comboFeedback?.remove();
    final overlay = Overlay.of(context);
    _comboFeedback = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 150,
        left: 0, right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.scale(scale: 1 + (1 - value) * 0.2, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orangeAccent.withValues(alpha: 0.2), Colors.deepOrangeAccent.withValues(alpha: 0.15)],
                  ),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.whatshot, color: Colors.orangeAccent, size: 18),
                    const SizedBox(width: 8),
                    Text('Combo x$streak', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_comboFeedback!);
    Future.delayed(const Duration(seconds: 2), () {
      _comboFeedback?.remove();
      _comboFeedback = null;
    });
  }

  Future<void> _showDifficultyIntroIfNeeded() async {
    final gs = ref.read(gameProvider);
    if (gs.session != null && gs.session!.status != GameStatus.playing) return;
    final difficulty = widget.difficulty.toLowerCase();
    final shouldShow = await DifficultyIntroService.shouldShow(difficulty);
    if (!shouldShow || !mounted) return;
    await DifficultyIntroService.markSeen(difficulty);
    await StatsService.onFirstDifficultyOpen(difficulty);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DifficultyUnlockDialog(
        difficulty: difficulty,
        onPlay: () {
          if (mounted) context.pop();
        },
        onBack: () {
          if (mounted) context.pop();
          if (mounted) context.pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _digitFeedback?.remove();
    _comboFeedback?.remove();
    _comboSub?.cancel();
    _gameOverSub?.cancel();
    _digitSub?.cancel();
    _hintOverlayManager.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final settings = ref.watch(settingsProvider);
    final isExtreme = settings.assistMode == AssistMode.extreme;
    final isExpert = settings.assistMode == AssistMode.expert;

    final remainingCells = state.sessionStats.remainingCells;
    final showAutoComplete = settings.showAutoComplete &&
        !isExpert && !isExtreme &&
        remainingCells > 0 && remainingCells <= 8;

    return Scaffold(
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(1),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: state.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade300, fontSize: 16),
                        ),
                      ),
                    )
                  : state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        Column(
                          children: [
                            GameHeaderWidget(state: state, settings: settings, onExit: () => _showExitDialog(context)),
                            SessionStatsBarWidget(stats: state.sessionStats, mode: settings.assistMode),
                            Expanded(
                              flex: 58,
                              child: BoardAreaWidget(),
                            ),
                            Expanded(
                              flex: 42,
                              child: ControlsAreaWidget(
                                showAutoComplete: showAutoComplete,
                                onAutoComplete: () => ref.read(gameProvider.notifier).autoComplete(),
                                hintKeys: _hintKeys,
                              ),
                            ),
                          ],
                        ),
                        if (state.isPaused) PauseOverlayWidget(
                          difficulty: widget.difficulty,
                          onExit: () => _showExitDialog(context),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final action = await showGameExitDialog(context, ref, widget.difficulty);
    if (action == null || !mounted) return;
    await Future.microtask(() {});
    if (!mounted) return;
    switch (action) {
      case GameExitAction.save:
        ref.read(gameProvider.notifier).saveToGlobalSlot();
        ref.read(gameProvider.notifier).abandonGame();
        if (mounted) context.pop();
      case GameExitAction.abandon:
        ref.read(gameProvider.notifier).abandonGame();
        if (mounted) context.pop();
      case GameExitAction.cancel:
        break;
    }
  }
}

// ── Board Area ───────────────────────────────────────────────────────────────

class BoardAreaWidget extends StatelessWidget {
  const BoardAreaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const SudokuBoardWidget()
            .animate()
            .fade(duration: 400.ms)
            .scale(begin: Offset(0.95, 0.95)),
      ),
    );
  }
}

// ── Controls Area ────────────────────────────────────────────────────────────

class ControlsAreaWidget extends ConsumerWidget {
  final bool showAutoComplete;
  final VoidCallback onAutoComplete;
  final HintTargetKeys? hintKeys;

  const ControlsAreaWidget({
    super.key,
    required this.showAutoComplete,
    required this.onAutoComplete,
    this.hintKeys,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 8),
            ActionsWidget(
              onShopRequested: () => context.push('/shop'),
              hintKeys: hintKeys,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                child: KeypadWidget(),
              ),
            ),
          ],
        ),
        if (showAutoComplete)
          Positioned(
            left: 0,
            right: 0,
            top: 52,
              child: AutoCompleteButtonWidget(onTap: onAutoComplete),
          ),
      ],
    );
  }
}

class AutoCompleteButtonWidget extends StatelessWidget {
  final VoidCallback onTap;

  const AutoCompleteButtonWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.auto_fix_high, size: 16),
          label: const Text('AUTO COMPLETE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
          ),
          onPressed: onTap,
        ),
      ),
    ).animate().fade(duration: 300.ms).scale(begin: const Offset(0.85, 0.85));
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class GameHeaderWidget extends ConsumerWidget {
  final GameState state;
  final dynamic settings;
  final VoidCallback onExit;

  const GameHeaderWidget({super.key, required this.state, required this.settings, required this.onExit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(state.difficulty, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(_fmtTime(state.elapsedSeconds), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.exit_to_app, size: 20),
                  onPressed: onExit,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ── Session Stats Bar ──────────────────────────────────────────────────────

class SessionStatsBarWidget extends StatelessWidget {
  final SessionStats stats;
  final AssistMode mode;

  const SessionStatsBarWidget({super.key, required this.stats, required this.mode});

  @override
  Widget build(BuildContext context) {
    final maxErrors = switch (mode) { AssistMode.classic => 999, AssistMode.extreme => 1, _ => 3 };
    final accuracyStr = '${(stats.accuracy * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _pill('⏱ ${stats.elapsedSeconds}s'),
          _pill('✕ ${stats.errors}/$maxErrors'),
          _pill('◻ ${stats.remainingCells}'),
          if (stats.currentCombo > 1) _pill('🔥 x${stats.currentCombo}', color: Colors.orangeAccent),
          _pill('🎯 $accuracyStr'),
        ].map((w) => w.animate().fade(duration: 300.ms)).toList(),
      ),
    );
  }

  Widget _pill(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color ?? Colors.white70)),
    );
  }
}


