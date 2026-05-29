import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/campaign_level.dart';
import '../domain/campaign_progress.dart';
import '../data/campaign_storage.dart';
import '../../economy/application/wallet_provider.dart';
import '../../progression/application/progression_provider.dart';
import '../../cosmetics/application/cosmetic_inventory_provider.dart';
import '../../challenge/application/streak_provider.dart';

class CampaignReward {
  final int playerXp;
  final int tokens;
  final int gems;

  const CampaignReward({
    required this.playerXp,
    required this.tokens,
    required this.gems,
  });
}

class CampaignResult {
  final int levelsGained;
  final List<String> unlockedBgIds;
  final int stars;
  final bool isBoss;

  const CampaignResult({
    required this.levelsGained,
    required this.unlockedBgIds,
    required this.stars,
    required this.isBoss,
  });
}

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

  Future<CampaignResult> completeLevel(int level, int timeSeconds, int mistakes) async {
    final stage = CampaignStage.fromLevel(level);
    final rng = math.Random();

    final isBoss = stage.isBossLevel(level);
    final bossMult = stage.bossMultiplierForLevel(level);

    final baseReward = _rewardForStage(stage, rng);
    final stars = _computeStars(timeSeconds, mistakes, level, stage);
    final starMultiplier = switch (stars) { 1 => 1.10, 2 => 1.20, 3 => 1.40, _ => 1.0 };

    final mult = starMultiplier * (isBoss ? bossMult : 1.0);
    final finalXp = (baseReward.playerXp * mult).round();
    final finalTokens = isBoss ? (baseReward.tokens * bossMult).round() : baseReward.tokens;
    final finalGems = isBoss ? (baseReward.gems * bossMult).round() : baseReward.gems;

    final levelsGained = await ref.read(playerLevelProvider.notifier).addXp(finalXp);

    List<String> unlockedBgIds = [];
    if (levelsGained > 0) {
      final newLevel = ref.read(playerLevelProvider).level;
      unlockedBgIds = ref.read(cosmeticInventoryProvider.notifier).checkNewUnlocksAtLevel(newLevel);
    }

    await ref.read(walletProvider.notifier).addTokens(finalTokens);
    await ref.read(walletProvider.notifier).addGems(finalGems);

    final updated = state.completeLevel(level, timeSeconds, mistakes, finalXp, finalTokens, finalGems,
        overrideStars: stars);
    state = updated;
    await CampaignStorage.save(updated);
    await ref.read(streakProvider.notifier).onDailyWin();

    return CampaignResult(levelsGained: levelsGained, unlockedBgIds: unlockedBgIds, stars: stars, isBoss: isBoss);
  }

  int _computeStars(int timeSeconds, int mistakes, int level, CampaignStage stage) {
    final variant = stage.variant;
    final maxTime = switch (variant.boardSize) { 4 => 60, 6 => 180, 8 => 300, _ => 600 };
    if (stage.isBossLevel(level)) {
      return mistakes == 0 ? 3 : 1;
    }
    final noErrors = mistakes == 0;
    final timeOk = timeSeconds <= maxTime;
    if (noErrors && timeOk) return 3;
    if (noErrors || timeOk) return 2;
    return 1;
  }

  CampaignReward _rewardForStage(CampaignStage stage, math.Random rng) {
    return switch (stage) {
      CampaignStage.miniSudoku => CampaignReward(
        playerXp: 8 + rng.nextInt(8),
        tokens: 1 + rng.nextInt(2),
        gems: 3 + rng.nextInt(3),
      ),
      CampaignStage.intermediate => CampaignReward(
        playerXp: 15 + rng.nextInt(11),
        tokens: 2 + rng.nextInt(2),
        gems: 5 + rng.nextInt(3),
      ),
      CampaignStage.advanced => CampaignReward(
        playerXp: 25 + rng.nextInt(16),
        tokens: 3 + rng.nextInt(3),
        gems: 7 + rng.nextInt(3),
      ),
      CampaignStage.assisted => CampaignReward(
        playerXp: 30 + rng.nextInt(16),
        tokens: 3 + rng.nextInt(2),
        gems: 7 + rng.nextInt(3),
      ),
      CampaignStage.beginner => CampaignReward(
        playerXp: 35 + rng.nextInt(21),
        tokens: 3 + rng.nextInt(3),
        gems: 8 + rng.nextInt(3),
      ),
      CampaignStage.intermediate9 => CampaignReward(
        playerXp: 45 + rng.nextInt(21),
        tokens: 4 + rng.nextInt(3),
        gems: 10 + rng.nextInt(3),
      ),
      CampaignStage.advanced9 => CampaignReward(
        playerXp: 55 + rng.nextInt(26),
        tokens: 4 + rng.nextInt(4),
        gems: 10 + rng.nextInt(3),
      ),
      CampaignStage.expert9 => CampaignReward(
        playerXp: 65 + rng.nextInt(31),
        tokens: 5 + rng.nextInt(4),
        gems: 12 + rng.nextInt(4),
      ),
      CampaignStage.evil9 => CampaignReward(
        playerXp: 80 + rng.nextInt(36),
        tokens: 6 + rng.nextInt(5),
        gems: 15 + rng.nextInt(4),
      ),
      CampaignStage.mythic9 => CampaignReward(
        playerXp: 100 + rng.nextInt(41),
        tokens: 8 + rng.nextInt(6),
        gems: 18 + rng.nextInt(5),
      ),
    };
  }

  CampaignReward previewReward(int level) {
    final stage = CampaignStage.fromLevel(level);
    final isBoss = stage.isBossLevel(level);
    final bossMult = stage.bossMultiplierForLevel(level);
    final mult = isBoss ? bossMult : 1.0;

    return switch (stage) {
      CampaignStage.miniSudoku => CampaignReward(playerXp: (11 * mult).round(), tokens: (1 * mult).round(), gems: (4 * mult).round()),
      CampaignStage.intermediate => CampaignReward(playerXp: (20 * mult).round(), tokens: (2 * mult).round(), gems: (6 * mult).round()),
      CampaignStage.advanced => CampaignReward(playerXp: (32 * mult).round(), tokens: (4 * mult).round(), gems: (8 * mult).round()),
      CampaignStage.assisted => CampaignReward(playerXp: (38 * mult).round(), tokens: (3 * mult).round(), gems: (8 * mult).round()),
      CampaignStage.beginner => CampaignReward(playerXp: (45 * mult).round(), tokens: (4 * mult).round(), gems: (9 * mult).round()),
      CampaignStage.intermediate9 => CampaignReward(playerXp: (55 * mult).round(), tokens: (5 * mult).round(), gems: (11 * mult).round()),
      CampaignStage.advanced9 => CampaignReward(playerXp: (68 * mult).round(), tokens: (6 * mult).round(), gems: (11 * mult).round()),
      CampaignStage.expert9 => CampaignReward(playerXp: (80 * mult).round(), tokens: (7 * mult).round(), gems: (14 * mult).round()),
      CampaignStage.evil9 => CampaignReward(playerXp: (98 * mult).round(), tokens: (8 * mult).round(), gems: (17 * mult).round()),
      CampaignStage.mythic9 => CampaignReward(playerXp: (120 * mult).round(), tokens: (11 * mult).round(), gems: (20 * mult).round()),
    };
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
