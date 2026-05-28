import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../game/application/game_provider.dart';
import '../../game/presentation/widgets/sudoku_board.dart';
import '../../game/presentation/widgets/keypad_widget.dart';
import '../../game/presentation/widgets/actions_widget.dart';
import '../domain/sudoku_variant.dart';
import '../application/campaign_provider.dart';
import '../../onboarding/application/onboarding_provider.dart';
import '../../onboarding/presentation/tutorial_overlay.dart';
import '../../../shared/widgets/game_modal_card.dart';
import 'campaign_level_complete_card.dart';

class CampaignGameScreen extends ConsumerStatefulWidget {
  final int level;
  final SudokuVariant variant;
  final bool restore;
  final VoidCallback? onContinue;
  final VoidCallback? onRepeat;
  final VoidCallback? onHome;

  const CampaignGameScreen({
    super.key,
    required this.level,
    required this.variant,
    this.restore = false,
    this.onContinue,
    this.onRepeat,
    this.onHome,
  });

  @override
  ConsumerState<CampaignGameScreen> createState() => _CampaignGameScreenState();
}

class _CampaignGameScreenState extends ConsumerState<CampaignGameScreen> {
  StreamSubscription<bool>? _gameOverSub;
  bool _levelComplete = false;
  bool _isDefeat = false;
  int _elapsedAtWin = 0;
  int _mistakesAtWin = 0;
  bool _showTutorial = false;
  bool _dismissingTutorial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.restore) {
        ref.read(gameProvider.notifier).restoreCampaign();
      } else {
        ref.read(gameProvider.notifier).initCampaign(widget.level, widget.variant);
        ref.read(campaignProvider.notifier).startRun(widget.level);
        // Show tutorial overlay for levels 1-5 (only if not already completed)
        if (widget.level <= 5 && !widget.restore) {
          final onboarding = ref.read(onboardingProvider);
          if (!onboarding.tutorialCompleted) {
            setState(() => _showTutorial = true);
            Future.delayed(6.seconds, () {
              if (mounted) setState(() {
                _showTutorial = false;
                _dismissingTutorial = false;
              });
            });
          }
        }
      }
      _listenToGameOver();
    });
  }

  void _listenToGameOver() {
    _gameOverSub?.cancel();
    _gameOverSub = ref.read(gameProvider.notifier).gameOverEvent.listen((won) {
      if (!mounted) return;
      if (won) {
        final gameState = ref.read(gameProvider);
        setState(() {
          _levelComplete = true;
          _isDefeat = false;
          _elapsedAtWin = gameState.elapsedSeconds;
          _mistakesAtWin = gameState.errors;
        });
      } else {
        setState(() {
          _levelComplete = true;
          _isDefeat = true;
          _elapsedAtWin = 0; // Not relevant for defeat but required
          _mistakesAtWin = 0; // Not relevant for defeat but required
        });
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
    final state = ref.watch(gameProvider);
    final showTimer = widget.level > 25;

    return Scaffold(
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1)),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.session == null
                      ? (state.errorMessage != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                                    const SizedBox(height: 16),
                                    Text(state.errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white54, fontSize: 14)),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () => widget.onHome?.call(),
                                      child: const Text('VOLVER AL INICIO'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink())
                      : Stack(
                      children: [
                        Column(
                          children: [
                            _CampaignHeader(
                              level: widget.level,
                              variant: widget.variant,
                              showTimer: showTimer,
                              elapsed: state.elapsedSeconds,
                              onExit: () => _showExitDialog(context),
                            ),
                            _CampaignStatsBar(
                              stats: state.sessionStats,
                              errors: state.errors,
                              maxErrors: state.sessionStats.remainingCells,
                            ),
                            Expanded(
                              flex: 58,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: const SudokuBoardWidget().animate().fade(duration: 400.ms).scale(begin: Offset(0.95, 0.95)),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 42,
                              child: Column(
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
                            ),
                          ],
                        ),
                        if (state.isPaused) _CampaignPauseOverlay(level: widget.level),
                        if (_levelComplete)
                           CampaignLevelCompleteCard(
                              level: widget.level,
                              elapsedSeconds: _elapsedAtWin,
                              mistakes: _mistakesAtWin,
                              victory: !_isDefeat,
                              forcedStars: _isDefeat ? 0 : null,
                              showNext: !_isDefeat,
                              showPlatinum: !_isDefeat,
                              defeatMode: _isDefeat,
                              onContinue: _onContinue,
                              onRepeat: _onRepeat,
                              onHome: _onHome,
                            ),
                        if ((_showTutorial || _dismissingTutorial) && TutorialOverlay.lessons.containsKey(widget.level))
                          AnimatedOpacity(
                            opacity: _dismissingTutorial ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: TutorialOverlay(
                              level: widget.level,
                              onDismiss: () {
                                if (!_dismissingTutorial) {
                                  setState(() => _dismissingTutorial = true);
                                  Future.delayed(const Duration(milliseconds: 200), () {
                                    if (mounted) setState(() {
                                      _showTutorial = false;
                                      _dismissingTutorial = false;
                                    });
                                  });
                                }
                              },
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _onContinue() {
    if (!mounted) return;
    setState(() {
      _levelComplete = false;
      _isDefeat = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(gameProvider.notifier);
      notifier.finishSession();
      notifier.startLoading();
      widget.onContinue?.call();
    });
  }

  void _onRepeat() {
    if (!mounted) return;
    setState(() {
      _levelComplete = false;
      _isDefeat = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(gameProvider.notifier);
      notifier.finishSession();
      notifier.startLoading();
      widget.onRepeat?.call();
    });
  }

  void _onHome() {
    if (!mounted) return;
    setState(() {
      _levelComplete = false;
      _isDefeat = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(gameProvider.notifier).finishSession();
      widget.onHome?.call();
    });
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => GameModalCard(
        onClose: () => Navigator.pop(ctx, false),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.exit_to_app, size: 40, color: Colors.white54),
              const SizedBox(height: 16),
              const Text('SALIR DEL NIVEL',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              const Text('Perderás el progreso de este nivel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white54)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('SALIR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
                  child: const Text('SEGUIR JUGANDO', style: TextStyle(fontSize: 13, color: Colors.white54)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true && mounted) {
      ref.read(gameProvider.notifier).abandonGame();
      ref.read(campaignProvider.notifier).clearRun();
      widget.onHome?.call();
    }
  }

}

class _CampaignHeader extends StatelessWidget {
  final int level;
  final SudokuVariant variant;
  final bool showTimer;
  final int elapsed;
  final VoidCallback onExit;

  const _CampaignHeader({
    required this.level, required this.variant, required this.showTimer,
    required this.elapsed, required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
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
                Text('CAMPAÑA · NIVEL $level',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${variant.boardSize}x${variant.boardSize}',
                    style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
            Row(
              children: [
                if (showTimer) ...[
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(_fmtTime(elapsed),
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  const SizedBox(width: 16),
                ],
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
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _CampaignStatsBar extends StatelessWidget {
  final dynamic stats;
  final int errors;
  final int maxErrors;

  const _CampaignStatsBar({required this.stats, required this.errors, required this.maxErrors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _pill( '◻ ${stats.remainingCells}'),
          _pill('✕ ${stats.errors}'),
          if (stats.currentCombo > 1) _pill('🔥 x${stats.currentCombo}', color: Colors.orangeAccent),
          _pill('🎯 ${(stats.accuracy * 100).toStringAsFixed(0)}%'),
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

class _CampaignPauseOverlay extends ConsumerWidget {
  final int level;
  const _CampaignPauseOverlay({required this.level});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: GameModalCard(
          onClose: () => ref.read(gameProvider.notifier).togglePause(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pause, size: 48, color: Colors.white54),
                const SizedBox(height: 16),
                Text('NIVEL $level PAUSADO',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => ref.read(gameProvider.notifier).togglePause(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('CONTINUAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
