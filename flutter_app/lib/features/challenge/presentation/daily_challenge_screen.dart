import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/application/game_provider.dart';
import '../../game/domain/game_state.dart';
import '../../../shared/widgets/pause_dialog.dart';
import '../../game/presentation/game_screen.dart';
import '../../settings/application/settings_provider.dart';
import '../data/daily_challenge_service.dart';
import '../data/daily_challenge_storage.dart';
import '../application/streak_provider.dart';
import 'daily_resume_dialog.dart';
import 'daily_exit_dialog.dart';

class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  StreamSubscription<bool>? _gameOverSub;
  bool _loading = true;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final completed = await DailyChallengeStorage.isCompletedToday();
    if (!mounted) return;

    if (completed) {
      setState(() { _loading = false; _completed = true; });
      return;
    }

    final savedData = await DailyChallengeStorage.loadGameState();
    if (!mounted) return;

    if (savedData != null) {
      final action = await showDailyResumeDialog(context, savedData);
      if (!mounted) return;

      switch (action) {
        case DailyResumeAction.resume:
          await _startGame(restore: true, savedData: savedData);
          return;
        case DailyResumeAction.restart:
          await DailyChallengeStorage.clearGameState();
          break;
        case DailyResumeAction.goHome:
          context.pop();
          return;
      }
    }

    final boardData = await DailyChallengeService.loadDailyBoard();
    if (!mounted) return;

    await ref.read(gameProvider.notifier).initDaily(boardData);
    await DailyChallengeStorage.saveBoardId(boardData.id);

    _setupGameOverListener();
    if (!mounted) return;
    setState(() { _loading = false; });
  }

  Future<void> _startGame({required bool restore, required Map<String, dynamic> savedData}) async {
    final boardData = await DailyChallengeService.loadDailyBoard();
    if (!mounted) return;

    await ref.read(gameProvider.notifier).initDaily(boardData);

    try {
      final session = GameSession.restore(
        boardId: savedData['boardId'] as String,
        difficulty: savedData['difficulty'] as String,
        initialBoard: (savedData['initialBoard'] as List).cast<int>(),
        currentBoard: (savedData['currentBoard'] as List).cast<int>(),
        solution: (savedData['solution'] as List).cast<int>(),
        fixedCells: Set<int>.from((savedData['fixedCells'] as List).cast<int>()),
        notes: (savedData['notes'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(int.parse(k), Set<int>.from((v as List).cast<int>())),
        ),
        mistakes: savedData['mistakes'] as int,
        elapsed: Duration(milliseconds: savedData['elapsed'] as int),
        paused: savedData['paused'] as bool,
        status: GameStatus.values[savedData['status'] as int],
      );
      final restored = GameState(
        session: session,
        isLoading: false,
        correctStreak: savedData['correctStreak'] as int? ?? 0,
        maxCombo: savedData['maxCombo'] as int? ?? 0,
        usedHints: savedData['hintsUsed'] as int? ?? 0,
        remainingHints: savedData['remainingHints'] as int? ?? 3,
        cellTimeMs: (savedData['cellTimeMs'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(int.parse(k), v as int)),
        noteUsageCount: savedData['noteUsageCount'] as int? ?? 0,
        totalMoves: savedData['totalMoves'] as int? ?? 0,
        correctMoves: savedData['correctMoves'] as int? ?? 0,
        advancedNotesEnabled: savedData['advancedNotesEnabled'] as bool? ?? false,
        advancedNotesUnlockedForRun: savedData['advancedNotesUnlockedForRun'] as bool? ?? false,
        manualNotes: savedData['manualNotes'] != null
            ? (savedData['manualNotes'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(int.parse(k), Set<int>.from((v as List).cast<int>())),
              )
            : null,
        completedWithAutocomplete: savedData['completedWithAutocomplete'] as bool? ?? false,
        autoCompleteUsed: savedData['autoCompleteUsed'] as int? ?? 0,
      );
      await ref.read(gameProvider.notifier).restoreGame(restored);
    } catch (_) {
      // if restore fails, already have fresh board from initDaily
    }

    _setupGameOverListener();
    if (!mounted) return;
    setState(() { _loading = false; });
  }

  void _setupGameOverListener() {
    _gameOverSub?.cancel();
    _gameOverSub = ref.read(gameProvider.notifier).gameOverEvent.listen((won) {
      if (!mounted) return;
      if (won) {
        DailyChallengeStorage.markCompleted();
        ref.read(streakProvider.notifier).onDailyWin();
        if (!mounted) return;
        context.pushReplacement('/victory', extra: 'daily');
      }
    });
  }

  @override
  void dispose() {
    _gameOverSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Cargando desafío diario…',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (_completed) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
          title: const Text('DESAFÍO DIARIO',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 80,
                    color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                Text('¡Desafío completado!',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 12),
                Text('Nuevo puzzle mañana.',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Volver al menú'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _DailyGameContent(onExit: () => showDailyExitDialog(context));
  }
}

// ── Daily Game Body ──────────────────────────────────────────────────────────

class _DailyGameContent extends ConsumerStatefulWidget {
  final VoidCallback onExit;
  const _DailyGameContent({required this.onExit});

  @override
  ConsumerState<_DailyGameContent> createState() => _DailyGameContentState();
}

class _DailyGameContentState extends ConsumerState<_DailyGameContent> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final settings = ref.watch(settingsProvider);

    ref.listen<GameState>(gameProvider, (prev, next) {
      if (next.session == null || next.status != GameStatus.playing) return;
      DailyChallengeStorage.saveGameState({
        'boardId': next.session!.boardId,
        'difficulty': next.session!.difficulty,
        'initialBoard': next.session!.initialBoard,
        'currentBoard': next.session!.currentBoard,
        'solution': next.session!.solution,
        'fixedCells': next.session!.fixedCells.toList(),
        'notes': next.session!.notes.map((k, v) => MapEntry(k.toString(), v.toList())),
        'mistakes': next.session!.mistakes,
        'elapsed': next.session!.elapsed.inMilliseconds,
        'paused': next.session!.paused,
        'status': next.session!.status.index,
        'correctStreak': next.correctStreak,
        'maxCombo': next.maxCombo,
        'hintsUsed': next.usedHints,
        'remainingHints': next.remainingHints,
        'cellTimeMs': next.cellTimeMs.map((k, v) => MapEntry(k.toString(), v)),
        'noteUsageCount': next.noteUsageCount,
        'totalMoves': next.totalMoves,
        'correctMoves': next.correctMoves,
        'advancedNotesEnabled': next.advancedNotesEnabled,
        'advancedNotesUnlockedForRun': next.advancedNotesUnlockedForRun,
        'manualNotes': next.manualNotes?.map((k, v) => MapEntry(k.toString(), v.toList())),
        'completedWithAutocomplete': next.completedWithAutocomplete,
        'autoCompleteUsed': next.autoCompleteUsed,
      });
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: state.isLoading || state.session == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      Column(
                        children: [
                          _DailyHeader(
                            state: state,
                            onExit: widget.onExit,
                          ),
                          SessionStatsBarWidget(
                            stats: state.sessionStats,
                            mode: settings.assistMode,
                          ),
                          const Expanded(
                            flex: 58,
                            child: BoardAreaWidget(),
                          ),
                          Expanded(
                            flex: 42,
                            child: ControlsAreaWidget(
                              showAutoComplete: false,
                              onAutoComplete: () =>
                                  ref.read(gameProvider.notifier).autoComplete(),
                            ),
                          ),
                        ],
                      ),
                      if (state.isPaused)
                        PauseOverlayWidget(
                          difficulty: 'daily',
                          onRestart: () => _restartDaily(context, ref),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _restartDaily(BuildContext context, WidgetRef ref) async {
    final boardData = await DailyChallengeService.loadDailyBoard();
    if (!context.mounted) return;
    await DailyChallengeStorage.clearGameState();
    await ref.read(gameProvider.notifier).initDaily(boardData);
  }
}

class _DailyHeader extends StatelessWidget {
  final GameState state;
  final VoidCallback onExit;

  const _DailyHeader({required this.state, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
    final diff = DailyChallengeService.currentDifficulty?.toUpperCase() ?? '???';
    final boardId = DailyChallengeService.currentBoardId ?? '';

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DESAFÍO DIARIO · $diff',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Theme.of(context).primaryColor)),
                Text('$dateStr · $boardId',
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(_fmtTime(state.elapsedSeconds),
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 16)),
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
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
