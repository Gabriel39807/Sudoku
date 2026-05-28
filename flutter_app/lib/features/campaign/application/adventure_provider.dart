import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/adventure_content.dart';
import '../domain/campaign_level.dart';
import '../data/adventure_storage.dart';
import '../../economy/application/wallet_provider.dart';
import 'campaign_provider.dart';

class AdventureState {
  final WorldMissionProgress missions;
  final Map<String, WorldChest> chests;
  final FragmentProgress fragments;
  final PerfectStreak streak;
  final CodexProgress codex;
  final Set<String> mentorSeen;
  final Set<String> tutorialsSeen;
  final WorldCompletionProgress worldCompletion;

  const AdventureState({
    this.missions = const WorldMissionProgress(),
    this.chests = const {},
    this.fragments = const FragmentProgress(),
    this.streak = const PerfectStreak(),
    this.codex = const CodexProgress(),
    this.mentorSeen = const {},
    this.tutorialsSeen = const {},
    this.worldCompletion = const WorldCompletionProgress(),
  });

  AdventureState copyWith({
    WorldMissionProgress? missions,
    Map<String, WorldChest>? chests,
    FragmentProgress? fragments,
    PerfectStreak? streak,
    CodexProgress? codex,
    Set<String>? mentorSeen,
    Set<String>? tutorialsSeen,
    WorldCompletionProgress? worldCompletion,
  }) => AdventureState(
    missions: missions ?? this.missions,
    chests: chests ?? this.chests,
    fragments: fragments ?? this.fragments,
    streak: streak ?? this.streak,
    codex: codex ?? this.codex,
    mentorSeen: mentorSeen ?? this.mentorSeen,
    tutorialsSeen: tutorialsSeen ?? this.tutorialsSeen,
    worldCompletion: worldCompletion ?? this.worldCompletion,
  );
}

class AdventureNotifier extends Notifier<AdventureState> {
  @override
  AdventureState build() {
    _load();
    return const AdventureState();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AdventureStorage.loadMissions(),
      AdventureStorage.loadChests(),
      AdventureStorage.loadFragments(),
      AdventureStorage.loadStreak(),
      AdventureStorage.loadCodex(),
      AdventureStorage.loadMentorSeen(),
      AdventureStorage.loadTutorialsSeen(),
      AdventureStorage.loadWorldCompletion(),
    ]);
    state = AdventureState(
      missions: results[0] as WorldMissionProgress,
      chests: results[1] as Map<String, WorldChest>,
      fragments: results[2] as FragmentProgress,
      streak: results[3] as PerfectStreak,
      codex: results[4] as CodexProgress,
      mentorSeen: results[5] as Set<String>,
      tutorialsSeen: results[6] as Set<String>,
      worldCompletion: results[7] as WorldCompletionProgress,
    );
  }

  // ── Missions ──────────────────────────────────────────────────────────

  Future<void> advanceMission(CampaignStage stage, String missionId, int amount) async {
    final current = state.missions.get(missionId);
    final updated = state.missions.copyWith(
      progress: {...state.missions.progress, missionId: current + amount},
    );
    state = state.copyWith(missions: updated);
    await AdventureStorage.saveMissions(updated);

    // Check completion
    final missions = worldMissionsForStage(stage);
    final mission = missions.where((m) => m.id == missionId).firstOrNull;
    if (mission != null && (current + amount) >= mission.target && !state.missions.isCompleted(missionId)) {
      await _completeMission(stage, mission);
    }
  }

  Future<void> _completeMission(CampaignStage stage, WorldMission mission) async {
    final updated = state.missions.copyWith(
      completed: {...state.missions.completed, mission.id},
    );
    await ref.read(walletProvider.notifier).addTokens(mission.tokensReward);
    await ref.read(walletProvider.notifier).addSouls(mission.soulsReward);
    if (mission.cosmeticRewardId != null) {
      // Future: unlock cosmetic
    }
    state = state.copyWith(missions: updated);
    await AdventureStorage.saveMissions(updated);
  }

  // ── Chests ────────────────────────────────────────────────────────────

  Future<ChestReward> claimChest(String chestId) async {
    final chest = state.chests[chestId];
    if (chest == null || chest.claimed) return const ChestReward();
    final stage = CampaignStage.fromLevel(chest.level);
    final reward = chest.generateReward(stage.datasetStage);
    final claimed = chest.claim();

    await ref.read(walletProvider.notifier).addTokens(reward.tokens);
    await ref.read(walletProvider.notifier).addSouls(reward.souls);
    if (reward.hints > 0) {
      // Future: add hints to inventory
    }
    if (reward.advancedNotes > 0) {
      // Future: add advanced notes to inventory
    }
    if (reward.spins > 0) {
      // Future: add spins
    }

    final updated = {...state.chests, chestId: claimed};
    state = state.copyWith(chests: updated);
    await AdventureStorage.saveChests(updated);
    return reward;
  }

  void initChestsForStage(CampaignStage stage) {
    final existing = chestsForStage(stage);
    var updated = {...state.chests};
    for (final chest in existing) {
      if (!updated.containsKey(chest.id)) {
        updated[chest.id] = chest;
      }
    }
    if (updated.length != state.chests.length) {
      state = state.copyWith(chests: updated);
      AdventureStorage.saveChests(updated);
    }
  }

  // ── Fragments ─────────────────────────────────────────────────────────

  Future<void> collectFragment(String stageKey, int index) async {
    if (state.fragments.hasCollected(stageKey, index)) return;
    final updated = state.fragments.collect(stageKey, index);
    state = state.copyWith(fragments: updated);
    await AdventureStorage.saveFragments(updated);

    if (updated.collectedIn(stageKey) >= FragmentProgress.totalPerStage) {
      await ref.read(walletProvider.notifier).addSouls(50);
    }
  }

  // ── Streak ────────────────────────────────────────────────────────────

  Future<void> recordGameResult(bool won, bool noMistakes) async {
    if (!won) {
      state = state.copyWith(streak: const PerfectStreak());
      await AdventureStorage.saveStreak(state.streak);
      return;
    }
    final updated = state.streak.recordWin(noMistakes);
    state = state.copyWith(streak: updated);
    await AdventureStorage.saveStreak(updated);

    // Streak bonuses at 10, 25, 50
    if (updated.currentStreak == 10 || updated.currentStreak == 25 || updated.currentStreak == 50) {
      final bonusSouls = updated.currentStreak * 2;
      final bonusTokens = updated.currentStreak;
      await ref.read(walletProvider.notifier).addSouls(bonusSouls);
      await ref.read(walletProvider.notifier).addTokens(bonusTokens);
    }
  }

  // ── Codex ─────────────────────────────────────────────────────────────

  Future<void> discoverTechnique(String techniqueId) async {
    if (state.codex.hasSeen(techniqueId)) return;
    final updated = state.codex.markSeen(techniqueId);
    state = state.copyWith(codex: updated);
    await AdventureStorage.saveCodex(updated);
  }

  List<CodexEntry> get unlockedCodexEntries {
    final entries = CodexEntry.registry;
    final currentLevel = ref.read(campaignProvider).currentLevel;
    return entries.where((e) => e.unlockLevel <= currentLevel).toList();
  }

  // ── Mentor ───────────────────────────────────────────────────────────

  MentorMessage? mentorMessageForLevel(int level) {
    final notSeen = mentorMessages.where((m) => m.triggerLevel == level && !state.mentorSeen.contains(m.id));
    return notSeen.isEmpty ? null : notSeen.first;
  }

  Future<void> dismissMentor(String id) async {
    final updated = {...state.mentorSeen, id};
    state = state.copyWith(mentorSeen: updated);
    await AdventureStorage.saveMentorSeen(updated);
  }

  // ── Tutorials ─────────────────────────────────────────────────────────

  bool hasSeenTutorial(String techniqueId) => state.tutorialsSeen.contains(techniqueId);

  Future<void> markTutorialSeen(String techniqueId) async {
    final updated = {...state.tutorialsSeen, techniqueId};
    state = state.copyWith(tutorialsSeen: updated);
    await AdventureStorage.saveTutorialsSeen(updated);
  }

  // ── World Completion ───────────────────────────────────────────────────

  bool isWorldCleared(int stage) => state.worldCompletion.isCleared(stage);

  Future<void> markWorldCleared(int stage) async {
    final updated = state.worldCompletion.markCleared(stage);
    state = state.copyWith(worldCompletion: updated);
    await AdventureStorage.saveWorldCompletion(updated);
  }

  // ── Biome ─────────────────────────────────────────────────────────────

  BiomeConfig biomeForStage(CampaignStage stage) => BiomeConfig.forStageNum(stage.datasetStage);

  Future<void> resetAll() async {
    await Future.wait([
      AdventureStorage.saveMissions(const WorldMissionProgress()),
      AdventureStorage.saveChests({}),
      AdventureStorage.saveFragments(const FragmentProgress()),
      AdventureStorage.saveStreak(const PerfectStreak()),
      AdventureStorage.saveCodex(const CodexProgress()),
      AdventureStorage.saveMentorSeen({}),
      AdventureStorage.saveTutorialsSeen({}),
      AdventureStorage.saveWorldCompletion(const WorldCompletionProgress()),
    ]);
    state = const AdventureState();
  }
}

final adventureProvider = NotifierProvider<AdventureNotifier, AdventureState>(
  AdventureNotifier.new,
);
