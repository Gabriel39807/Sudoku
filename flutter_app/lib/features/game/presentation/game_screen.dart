import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../onboarding/difficulty_intro_service.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/settings_model.dart';
import '../../stats/data/stats_service.dart';
import '../application/game_provider.dart';
import '../domain/game_state.dart';
import '../domain/session_stats.dart';
import '../data/game_autosave.dart';
import 'widgets/sudoku_board.dart';
import 'widgets/keypad_widget.dart';
import 'widgets/actions_widget.dart';
import '../../cosmetics/models/background_catalog.dart';
import '../../cosmetics/presentation/unlock_popup.dart';

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
  StreamSubscription<String>? _bgUnlockSub;

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
      _listenToBackgroundUnlocks();
    });
  }

  Future<void> _initGame() async {
    final diff = widget.difficulty;
    final saved = await GameAutosave.restoreForDifficulty(diff);

    if (saved != null && mounted) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: const Text('Partida encontrada'),
          content: Text('Tienes una partida sin terminar en ${diff.toUpperCase()}.\nQuieres continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nueva partida', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
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

  void _listenToDigitCompleted() {
    final notifier = ref.read(gameProvider.notifier);
    notifier.digitCompleted.listen(_showDigitFeedback);
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
      if (won) {
        context.pushReplacement('/victory', extra: widget.difficulty);
      } else {
        context.pushReplacement('/defeat', extra: widget.difficulty);
      }
    });
  }

  void _listenToBackgroundUnlocks() {
    _bgUnlockSub?.cancel();
    _bgUnlockSub = ref.read(gameProvider.notifier).backgroundUnlockEvent.listen((id) {
      if (!mounted) return;
      final bg = BackgroundCatalog.byId(id);
      if (bg == null) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => UnlockPopup(background: bg),
      );
    });
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
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Dificultad ${difficulty.toUpperCase()}'),
        content: const Text('Max hints ilimitadas\nErrores permitidos: 3'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _digitFeedback?.remove();
    _comboFeedback?.remove();
    _comboSub?.cancel();
    _gameOverSub?.cancel();
    _bgUnlockSub?.cancel();
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
              child: state.isLoading || state.session == null
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        Column(
                          children: [
                            _Header(state: state, settings: settings, onExit: () => _showExitDialog(context)),
                            _SessionStatsBar(stats: state.sessionStats, mode: settings.assistMode),
                            Expanded(
                              flex: 58,
                              child: _BoardArea(),
                            ),
                            Expanded(
                              flex: 42,
                              child: _ControlsArea(
                                showAutoComplete: showAutoComplete,
                                onAutoComplete: () => ref.read(gameProvider.notifier).autoComplete(),
                              ),
                            ),
                          ],
                        ),
                        if (state.isPaused) _PauseOverlay(difficulty: widget.difficulty),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showExitDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text('Leave game?'),
        content: const Text('Are you sure you want to exit? Your progress will be saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameProvider.notifier).abandonGame();
              context.pop();
            },
            child: const Text('Exit', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Board Area ───────────────────────────────────────────────────────────────

class _BoardArea extends StatelessWidget {
  const _BoardArea();

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

class _ControlsArea extends ConsumerWidget {
  final bool showAutoComplete;
  final VoidCallback onAutoComplete;

  const _ControlsArea({
    required this.showAutoComplete,
    required this.onAutoComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 8),
            const ActionsWidget(),
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
            child: _AutoCompleteButton(onTap: onAutoComplete),
          ),
      ],
    );
  }
}

class _AutoCompleteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AutoCompleteButton({required this.onTap});

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

class _Header extends ConsumerWidget {
  final GameState state;
  final dynamic settings;
  final VoidCallback onExit;

  const _Header({required this.state, required this.settings, required this.onExit});

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

class _SessionStatsBar extends StatelessWidget {
  final SessionStats stats;
  final AssistMode mode;

  const _SessionStatsBar({required this.stats, required this.mode});

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

// ── Pause Overlay ──────────────────────────────────────────────────────────

class _PauseOverlay extends ConsumerWidget {
  final String difficulty;
  const _PauseOverlay({required this.difficulty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('PAUSED', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4))
                .animate().fade().scale(),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => ref.read(gameProvider.notifier).togglePause(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.read(gameProvider.notifier).init(difficulty),
              icon: const Icon(Icons.refresh),
              label: const Text('Restart'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                ref.read(gameProvider.notifier).abandonGame();
                context.pop();
              },
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              label: const Text('Exit', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
