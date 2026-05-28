import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/sudoku_variant.dart';
import '../domain/campaign_level.dart';
import '../../onboarding/application/onboarding_provider.dart';
import '../../game/application/game_provider.dart';
import 'campaign_game_screen.dart';

class CampaignShellScreen extends ConsumerStatefulWidget {
  final int level;
  final SudokuVariant variant;
  final bool restore;

  const CampaignShellScreen({
    super.key,
    required this.level,
    required this.variant,
    this.restore = false,
  });

  @override
  ConsumerState<CampaignShellScreen> createState() => _CampaignShellScreenState();
}

class _CampaignShellScreenState extends ConsumerState<CampaignShellScreen> {
  late int _currentLevel;
  late SudokuVariant _currentVariant;
  bool _restoreConsumed = false;
  int _transitionId = 0;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.level;
    _currentVariant = widget.variant;
    _restoreConsumed = !widget.restore;
  }

  void _onContinue() {
    final notifier = ref.read(gameProvider.notifier);

    final currentLevel = notifier.campaignLevel;
    final nextLevel = currentLevel + 1;

    if (currentLevel == 5) {
      final onboarding = ref.read(onboardingProvider);
      if (!onboarding.tutorialCompleted && !onboarding.claimedRewards) {
        context.pushReplacement('/gradual-unlock');
        return;
      }
    }

    final stage = CampaignStage.fromLevel(nextLevel);
    if (nextLevel > stage.levelEnd) {
      context.go('/');
      return;
    }

    setState(() {
      _currentLevel = nextLevel;
      _currentVariant = stage.variant;
      _restoreConsumed = true;
      _transitionId++;
    });
  }

  void _onRepeat() {
    final stage = CampaignStage.fromLevel(_currentLevel);
    setState(() {
      _currentVariant = stage.variant;
      _restoreConsumed = true;
      _transitionId++;
    });
  }

  void _onHome() {
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
      child: CampaignGameScreen(
        key: ValueKey('campaign_${_currentLevel}_$_transitionId'),
        level: _currentLevel,
        variant: _currentVariant,
        restore: widget.restore && !_restoreConsumed,
        onContinue: _onContinue,
        onRepeat: _onRepeat,
        onHome: _onHome,
      ),
    );
  }
}
