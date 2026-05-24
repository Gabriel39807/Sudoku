import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/campaign_level.dart';
import '../domain/campaign_progress.dart';
import '../data/campaign_storage.dart';

class CampaignNotifier extends Notifier<CampaignProgress> {
  @override
  CampaignProgress build() {
    _load();
    return const CampaignProgress();
  }

  Future<void> _load() async {
    final progress = await CampaignStorage.load();
    state = progress;
  }

  Future<void> startRun(int level) async {
    if (state.activeRunLevel == level) return;
    final updated = state.copyWith(activeRunLevel: level);
    state = updated;
    await CampaignStorage.save(updated);
  }

  Future<void> clearRun() async {
    if (state.activeRunLevel == 0) return;
    final updated = state.copyWith(activeRunLevel: 0);
    state = updated;
    await CampaignStorage.save(updated);
  }

  Future<void> completeLevel(int level, int timeSeconds, int mistakes) async {
    final updated = state.completeLevel(level, timeSeconds, mistakes);
    state = updated;
    await CampaignStorage.save(updated);
  }

  Future<void> reset() async {
    await CampaignStorage.reset();
    state = const CampaignProgress();
  }

  bool isLevelUnlocked(int level) => state.isUnlocked(level);
  bool isLevelCompleted(int level) => state.isCompleted(level);
  CampaignLevelResult? resultFor(int level) => state.resultFor(level);

  CampaignStage get currentStage => state.currentStage ?? CampaignStage.miniSudoku;
}

final campaignProvider = NotifierProvider<CampaignNotifier, CampaignProgress>(
  CampaignNotifier.new,
);
