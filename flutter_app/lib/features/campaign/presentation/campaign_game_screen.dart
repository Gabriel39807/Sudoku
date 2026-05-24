import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../game/application/game_provider.dart';
import '../../game/presentation/widgets/sudoku_board.dart';
import '../../game/presentation/widgets/keypad_widget.dart';
import '../../game/presentation/widgets/actions_widget.dart';
import '../domain/sudoku_variant.dart';
import '../application/campaign_provider.dart';
import '../../../shared/widgets/game_modal_card.dart';
import 'campaign_level_complete_card.dart';

class CampaignGameScreen extends ConsumerStatefulWidget {
  final int level;
  final SudokuVariant variant;

  const CampaignGameScreen({
    super.key,
    required this.level,
    required this.variant,
  });

  @override
  ConsumerState<CampaignGameScreen> createState() => _CampaignGameScreenState();
}

class _CampaignGameScreenState extends ConsumerState<CampaignGameScreen> {
  StreamSubscription<bool>? _gameOverSub;
  bool _levelComplete = false;
  int _elapsedAtWin = 0;
  int _mistakesAtWin = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).initCampaign(widget.level, widget.variant);
      ref.read(campaignProvider.notifier).startRun(widget.level);
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
          _elapsedAtWin = gameState.elapsedSeconds;
          _mistakesAtWin = gameState.errors;
        });
      } else {
        _showDefeat();
      }
    });
  }

  void _showDefeat() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameModalCard(
        onClose: () {},
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sentiment_dissatisfied, size: 56, color: Colors.redAccent)
                  .animate().fade().scale(begin: Offset(0, 0), curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              const Text('DERROTA',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('Nivel ${widget.level} · ¡Intentalo de nuevo!',
                  style: const TextStyle(fontSize: 14, color: Colors.white54)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(gameProvider.notifier).restartCurrentBoard();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('REINTENTAR',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('VOLVER', style: TextStyle(fontSize: 13, color: Colors.white54)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              child: state.isLoading || state.session == null
                  ? const Center(child: CircularProgressIndicator())
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
      context.pop();
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
