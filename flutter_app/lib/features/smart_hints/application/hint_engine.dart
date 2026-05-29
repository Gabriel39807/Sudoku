import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/hint_type.dart';
import '../domain/smart_hint.dart';
import '../domain/hint_state_model.dart';
import 'hint_state_provider.dart';

enum HintEngineStatus { idle, showing }

class HintEngineEvent {
  final HintType type;
  final SmartHintConfig config;
  final String targetKey;
  final String message;

  const HintEngineEvent({
    required this.type,
    required this.config,
    required this.targetKey,
    required this.message,
  });
}

class HintEngine extends Notifier<HintEngineStatus> {
  Timer? _stuckTimer;
  int _undoCount = 0;
  bool _pencilUsed = false;
  int _numberCompletions = 0;

  void Function(HintEngineEvent event)? onShowHint;
  VoidCallback? onHideHint;

  @override
  HintEngineStatus build() {
    ref.onDispose(() {
      _stuckTimer?.cancel();
    });
    return HintEngineStatus.idle;
  }

  void onGameInit() {
    _undoCount = 0;
    _pencilUsed = false;
    _numberCompletions = 0;
    _stuckTimer?.cancel();
  }

  void onMistake() {
    _tryShow(HintType.erase);
  }

  void onErase() {
    final hintState = ref.read(hintStateProvider);
    if (hintState.hasSeen(HintType.erase) && !hintState.hasLearned(HintType.erase)) {
      ref.read(hintStateProvider.notifier).markLearned(HintType.erase);
      onHideHint?.call();
    }
  }

  void onUndo() {
    _undoCount++;
    if (_undoCount >= 3 && !_pencilUsed) {
      _tryShow(HintType.notes);
    }
  }

  void onPencilUsed() {
    _pencilUsed = true;
    final hintState = ref.read(hintStateProvider);
    if (hintState.hasSeen(HintType.notes) && !hintState.hasLearned(HintType.notes)) {
      ref.read(hintStateProvider.notifier).markLearned(HintType.notes);
      onHideHint?.call();
    }
  }

  void onNumberCompleted() {
    _numberCompletions++;
    if (_numberCompletions == 1) {
      _tryShow(HintType.tabMode);
    }
  }

  void onAdvancedNotesToggled() {
    final hintState = ref.read(hintStateProvider);
    if (hintState.hasSeen(HintType.advancedNotes) && !hintState.hasLearned(HintType.advancedNotes)) {
      ref.read(hintStateProvider.notifier).markLearned(HintType.advancedNotes);
      onHideHint?.call();
    }
  }

  void startStuckDetection() {
    _stuckTimer?.cancel();
    _stuckTimer = Timer(const Duration(seconds: 35), () {
      final hintState = ref.read(hintStateProvider);
      if (hintState.hasSeen(HintType.notes)) return;
      _tryShow(HintType.notes);
    });
  }

  void resetStuckTimer() {
    _stuckTimer?.cancel();
    final hintState = ref.read(hintStateProvider);
    if (hintState.hasSeen(HintType.notes)) return;
    _stuckTimer = Timer(const Duration(seconds: 35), () {
      if (ref.read(hintStateProvider).hasSeen(HintType.notes)) return;
      _tryShow(HintType.notes);
    });
  }

  void cancelStuckTimer() {
    _stuckTimer?.cancel();
  }

  void _tryShow(HintType type) {
    if (ref.read(hintEngineProvider) == HintEngineStatus.showing) return;

    final hintState = ref.read(hintStateProvider);
    final config = SmartHintConfig.all.firstWhere((c) => c.type == type);

    if (!_isEligible(config, hintState)) return;

    final targetKey = config.targetKey.first;
    final event = HintEngineEvent(
      type: type,
      config: config,
      targetKey: targetKey,
      message: config.message,
    );

    state = HintEngineStatus.showing;
    ref.read(hintStateProvider.notifier).markSeen(type);
    onShowHint?.call(event);
  }

  bool _isEligible(SmartHintConfig config, HintState hintState) {
    if (hintState.hasLearned(config.type)) return false;
    if (!config.repeatable && hintState.hasSeen(config.type)) return false;

    if (hintState.hasSeen(config.type)) {
      final lastShown = hintState.lastShownTimestamps[config.type.name];
      if (lastShown != null && config.cooldownHours > 0) {
        final elapsed = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - lastShown;
        if (elapsed < config.cooldownHours * 3600) return false;
      }
    }

    return true;
  }

  void onHintDismissed() {
    state = HintEngineStatus.idle;
  }

  void onHintComplete() {
    state = HintEngineStatus.idle;
  }
}

final hintEngineProvider = NotifierProvider<HintEngine, HintEngineStatus>(
  HintEngine.new,
);