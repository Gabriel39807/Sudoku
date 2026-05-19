import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../hint/hint_service.dart';
import '../../onboarding/difficulty_intro_service.dart';
import '../../stats/data/stats_service.dart';
import '../application/game_provider.dart';
import '../domain/game_state.dart';
import 'widgets/sudoku_board.dart';
import 'widgets/keypad_widget.dart';
import 'widgets/actions_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String difficulty;
  const GameScreen({super.key, required this.difficulty});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Delay initialization to avoid provider updates during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(gameProvider.notifier).init(widget.difficulty);
      if (!mounted) return;
      await _showDifficultyIntroIfNeeded();
    });
  }

  Future<void> _showDifficultyIntroIfNeeded() async {
    final difficulty = widget.difficulty.toLowerCase();
    final shouldShow = await DifficultyIntroService.shouldShow(difficulty);
    if (!shouldShow || !mounted) return;

    await DifficultyIntroService.markSeen(difficulty);
    await StatsService.onFirstDifficultyOpen(difficulty);

    final maxHints = HintService.maxHintsFor(difficulty);
    final hintText = maxHints < 0 ? 'Ilimitadas' : '$maxHints';
    final techniques = DifficultyIntroService.techniquesFor(difficulty);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Dificultad ${difficulty.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Max hints: $hintText'),
            const Text('Errores permitidos: 3'),
            const SizedBox(height: 12),
            const Text('Técnicas requeridas:'),
            const SizedBox(height: 6),
            for (final technique in techniques) Text('- $technique'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);

    ref.listen<GameState>(gameProvider, (previous, next) {
      if (previous?.status != GameStatus.won && next.status == GameStatus.won) {
        _showVictoryDialog();
      } else if (previous?.status != GameStatus.lost &&
          next.status == GameStatus.lost) {
        _showDefeatDialog();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      Column(
                        children: [
                          // HEADER (Height: 90)
                          SizedBox(
                            height: 90,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Difficulty Left
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DIFICULTAD',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      Text(
                                        state.difficulty,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Timer Center
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.timer_outlined,
                                        size: 16,
                                        color: Colors.white54,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(state.elapsedSeconds),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Errors & Exit Right
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'ERRORES',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white54,
                                            ),
                                          ),
                                          Text(
                                            '${state.errors} / 3',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: state.errors > 0
                                                  ? Colors.redAccent
                                                  : Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        icon: const Icon(Icons.exit_to_app),
                                        onPressed: () =>
                                            _showExitDialog(context),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // BOARD
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Center(
                                child: const SudokuBoardWidget()
                                    .animate()
                                    .fade(duration: 400.ms)
                                    .scale(begin: const Offset(0.95, 0.95)),
                              ),
                            ),
                          ),

                          // ACTIONS ROW
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: ActionsWidget(),
                          ),

                          // KEYPAD
                          const Padding(
                            padding: EdgeInsets.only(
                              bottom: 24.0,
                              left: 16.0,
                              right: 16.0,
                            ),
                            child: KeypadWidget(),
                          ),
                        ],
                      ),

                      if (state.isPaused)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'PAUSED',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                  ),
                                ).animate().fade().scale(),
                                const SizedBox(height: 40),
                                ElevatedButton.icon(
                                  onPressed: () => ref
                                      .read(gameProvider.notifier)
                                      .togglePause(),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Resume'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ref
                                        .read(gameProvider.notifier)
                                        .init(widget.difficulty);
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Restart'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: () {
                                    ref
                                        .read(gameProvider.notifier)
                                        .abandonGame();
                                    context.pop();
                                  },
                                  icon: const Icon(
                                    Icons.exit_to_app,
                                    color: Colors.redAccent,
                                  ),
                                  label: const Text(
                                    'Exit',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _showExitDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text('Leave game?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(gameProvider.notifier).abandonGame();
              context.pop(); // Go back to difficulty screen
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showVictoryDialog() async {
    final state = ref.read(gameProvider);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text(
          'VICTORY',
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Difficulty: ${state.difficulty}'),
            Text('Time: ${_formatTime(state.elapsedSeconds)}'),
            Text('Errors: ${state.errors} / 3'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Go home
            },
            child: const Text('Exit', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(gameProvider.notifier).init(widget.difficulty);
            },
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDefeatDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Text(
          'DEFEAT',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        content: const Text('You have reached the maximum number of errors.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Go home
            },
            child: const Text('Exit', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              ref.read(gameProvider.notifier).init(widget.difficulty);
            },
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
