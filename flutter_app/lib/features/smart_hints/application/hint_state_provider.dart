import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/hint_type.dart';
import '../domain/hint_state_model.dart';
import '../data/hint_persistence.dart';

class HintStateNotifier extends Notifier<HintState> {
  @override
  HintState build() {
    _load();
    return const HintState();
  }

  Future<void> _load() async {
    state = await HintPersistence.load();
  }

  Future<void> markSeen(HintType type) async {
    state = state.markSeen(type);
    await HintPersistence.save(state);
  }

  Future<void> markLearned(HintType type) async {
    state = state.markLearned(type);
    await HintPersistence.save(state);
  }

  Future<void> resetAll() async {
    state = const HintState();
    await HintPersistence.save(state);
  }
}

final hintStateProvider = NotifierProvider<HintStateNotifier, HintState>(
  HintStateNotifier.new,
);