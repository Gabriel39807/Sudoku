import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../domain/campaign_level.dart';
import '../domain/adventure_content.dart';
import '../domain/campaign_progress.dart';
import '../application/campaign_provider.dart';
import '../application/adventure_provider.dart';
import 'tutorial_screen.dart';
import 'chest_modal.dart';
import 'world_background.dart';
import 'codex_unlock_screen.dart';
import 'world_completion_screen.dart';

class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiCtrl;
  late ScrollController _scrollCtrl;
  final _levelKeys = <int, GlobalKey>{};
  int _showStreakAnimation = 0;
  MentorMessage? _mentorMessage;
  int _visibleStageNum = 1;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final stage in CampaignStage.values) {
        ref.read(adventureProvider.notifier).initChestsForStage(stage);
      }
      // Delay checks so AdventureState finishes loading async data
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _checkMentor();
        _checkWorldCompletion();
        _checkCodexUnlocks();
      });
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _checkWorldCompletion() {
    final progress = ref.read(campaignProvider);
    final ad = ref.read(adventureProvider);
    for (final stage in CampaignStage.values) {
      final levels = List.generate(stage.levelCount, (i) => stage.levelStart + i);
      final completed = levels.where((l) => progress.isCompleted(l)).length;
      if (completed >= stage.levelCount && !ad.worldCompletion.isCleared(stage.datasetStage)) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showWorldCleared(stage);
        });
        break;
      }
    }
  }

  void _checkCodexUnlocks() {
    final lvl = ref.read(campaignProvider).currentLevel;
    final codex = ref.read(adventureProvider).codex;
    for (final entry in CodexEntry.registry) {
      if (entry.unlockLevel <= lvl && !codex.hasSeen(entry.techniqueId)) {
        ref.read(adventureProvider.notifier).discoverTechnique(entry.techniqueId);
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => CodexUnlockScreen(
              entry: entry,
              totalSeen: codex.seenTechniques.length + 1,
            ),
          );
        }
        break;
      }
    }
  }

  void _showWorldCleared(CampaignStage stage) {
    final biome = BiomeConfig.forStageNum(stage.datasetStage);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorldCompletionScreen(
          biome: biome,
          stageNum: stage.datasetStage,
          tokensReward: stage.datasetStage * 10,
          soulsReward: stage.datasetStage * 5,
        ),
      ),
    ).then((_) {
      ref.read(adventureProvider.notifier).markWorldCleared(stage.datasetStage);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(campaignProvider);
    final adventure = ref.watch(adventureProvider);

    return Scaffold(
      body: Stack(
        children: [
          // World ambient background (changes per visible biome section)
          WorldBackground(
            key: ValueKey('bg_$_visibleStageNum'),
            stageNum: _visibleStageNum,
            scrollCtrl: _scrollCtrl,
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [Colors.amber, Colors.orange, Colors.yellow, Colors.white],
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 5,
              gravity: 0.1,
            ),
          ),
          // Main scrollable map
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification && _scrollCtrl.hasClients) {
                final offset = _scrollCtrl.offset + 200;
                final sectionHeight = 180.0;
                final idx = (offset / sectionHeight).floor().clamp(0, CampaignStage.values.length - 1);
                final newStage = CampaignStage.values[idx].datasetStage;
                if (newStage != _visibleStageNum) {
                  setState(() => _visibleStageNum = newStage);
                }
              }
              return true;
            },
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                // Top header
                SliverToBoxAdapter(
                  child: _MapHeader(
                    completed: progress.completedCount,
                    total: CampaignStage.totalLevels,
                    streak: adventure.streak.currentStreak,
                    onCodex: () => context.push('/campaign/codex'),
                    onMissions: () => _showMissionSummary(context, progress, adventure),
                  ),
                ),
                // Biome sections
                ...CampaignStage.values.map((stage) => _BiomeSection(
                  key: ValueKey(stage.name),
                  stage: stage,
                  progress: progress,
                  adventure: adventure,
                  levelKeys: _levelKeys,
                  confettiCtrl: _confettiCtrl,
                  onLevelTap: (level) => _onLevelTap(context, level, stage, progress),
                  onChestTap: (chest) => _onChestTap(context, chest),
                )),
                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          // Continue button (ALWAYS visible — either next or continue)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _ContinueButton(
              level: progress.hasActiveRun ? progress.activeRunLevel : progress.currentLevel,
              onTap: () {
                final targetLevel = progress.hasActiveRun ? progress.activeRunLevel : progress.currentLevel;
                final stage = CampaignStage.fromLevel(targetLevel);
                context.push('/campaign-game', extra: {'level': targetLevel, 'variant': stage.variant.name});
              },
            ).animate().fade().slideY(begin: 1),
          ),
          // Perfect streak banner
          if (_showStreakAnimation > 0)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: _StreakBanner(streak: _showStreakAnimation)
                  .animate().fade(duration: 2.seconds).slideY(begin: -1, curve: Curves.easeOutBack)
                  .then(delay: 3.seconds)
                  .fadeOut()
                  .callback(callback: (_) => setState(() => _showStreakAnimation = 0)),
            ),
          // Mentor message
          if (_mentorMessage != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _MentorBubble(
                message: _mentorMessage!,
                onDismiss: () {
                  ref.read(adventureProvider.notifier).dismissMentor(_mentorMessage!.id);
                  setState(() => _mentorMessage = null);
                },
              ).animate().fade().slideY(begin: 0.5),
            ),
        ],
      ),
    );
  }

  void _checkMentor() {
    final lvl = ref.read(campaignProvider).currentLevel;
    final msg = ref.read(adventureProvider.notifier).mentorMessageForLevel(lvl);
    if (msg != null && _mentorMessage == null) {
      setState(() => _mentorMessage = msg);
    }
  }

  void _onLevelTap(BuildContext context, int level, CampaignStage stage, CampaignProgress progress) {
    if (!progress.isUnlocked(level)) return;
    final result = progress.resultFor(level);
    final needsTutorial = stage == CampaignStage.miniSudoku && level <= 3 && result == null;

    if (needsTutorial) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TutorialScreen(
            level: level,
            variant: stage.variant,
            onComplete: () {
              Navigator.pop(context);
              context.push('/campaign-game', extra: {'level': level, 'variant': stage.variant.name});
            },
          ),
        ),
      );
    } else {
      context.push('/campaign-game', extra: {'level': level, 'variant': stage.variant.name});
    }
  }

  void _onChestTap(BuildContext context, WorldChest chest) async {
    if (chest.claimed) return;
    final reward = await ref.read(adventureProvider.notifier).claimChest(chest.id);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChestOpenModal(chest: chest, reward: reward),
    );
    _confettiCtrl.play();
  }

  void _showMissionSummary(BuildContext context, CampaignProgress progress, AdventureState adventure) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MissionSheet(
        adventure: adventure,
        currentLevel: progress.currentLevel,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Map Header
// ═══════════════════════════════════════════════════════════════════════════

class _MapHeader extends StatelessWidget {
  final int completed;
  final int total;
  final int streak;
  final VoidCallback onCodex;
  final VoidCallback onMissions;

  const _MapHeader({
    required this.completed,
    required this.total,
    required this.streak,
    required this.onCodex,
    required this.onMissions,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? completed / total : 0.0;
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('MAPA MUNDIAL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 4, color: Colors.white)),
              ),
              _HeaderButton(icon: Icons.menu_book_outlined, label: 'Codex', onTap: onCodex),
              const SizedBox(width: 8),
              _HeaderButton(icon: Icons.flag_outlined, label: 'Metas', onTap: onMissions),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: 800.ms,
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(val >= 1.0 ? Colors.greenAccent : Colors.amber),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('$completed / $total completados',
                  style: const TextStyle(fontSize: 11, color: Colors.white54)),
              const Spacer(),
              if (streak >= 2)
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 14, color: Colors.orangeAccent),
                    const SizedBox(width: 4),
                    Text('$streak racha perfecta',
                        style: const TextStyle(fontSize: 11, color: Colors.orangeAccent)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Biome Section
// ═══════════════════════════════════════════════════════════════════════════

class _BiomeSection extends ConsumerWidget {
  final CampaignStage stage;
  final CampaignProgress progress;
  final AdventureState adventure;
  final Map<int, GlobalKey> levelKeys;
  final ConfettiController confettiCtrl;
  final void Function(int level) onLevelTap;
  final void Function(WorldChest chest) onChestTap;

  const _BiomeSection({
    super.key,
    required this.stage,
    required this.progress,
    required this.adventure,
    required this.levelKeys,
    required this.confettiCtrl,
    required this.onLevelTap,
    required this.onChestTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biome = BiomeConfig.forStageNum(stage.datasetStage);
    final levels = List.generate(stage.levelCount, (i) => stage.levelStart + i);
    final completedInStage = levels.where((l) => progress.isCompleted(l)).length;
    final progressPct = stage.levelCount > 0 ? completedInStage / stage.levelCount : 0.0;
    final isComplete = completedInStage >= stage.levelCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(biome.primaryColor).withValues(alpha: 0.3),
            Color(biome.secondaryColor).withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(
          color: Color(biome.accentColor).withValues(alpha: isComplete ? 0.5 : 0.2),
          width: isComplete ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Biome header
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Color(biome.accentColor).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(biome.icon, style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(biome.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          Text(biome.subtitle,
                              style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        ],
                      ),
                    ),
                    Text('$completedInStage/${stage.levelCount}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                            color: isComplete ? Colors.greenAccent : Colors.white70)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progressPct),
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(isComplete ? Colors.greenAccent : Color(biome.accentColor)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Level nodes
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: levels.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.arrow_forward_ios, size: 8, color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    itemBuilder: (_, i) {
                      final level = levels[i];
                      final result = progress.resultFor(level);
                      final unlocked = progress.isUnlocked(level);
                      final completed = result?.completed ?? false;
                      final isBoss = stage.isBossLevel(level);
                      final chest = adventure.chests.values.where((c) => c.level == level).firstOrNull;
                      final isCurrent = level == progress.currentLevel;
                      final stars = result?.stars ?? 0;

                      return _LevelNode(
                        level: level,
                        unlocked: unlocked,
                        completed: completed,
                        isBoss: isBoss,
                        isCurrent: isCurrent,
                        stars: stars,
                        isPlatinum: result?.isPlatinum ?? false,
                        biome: biome,
                        hasChest: chest != null && !chest.claimed,
                        chestColor: chest?.type == ChestType.boss ? Colors.amber : Colors.cyan,
                        onTap: () {
                          if (chest != null && !chest.claimed) {
                            onChestTap(chest);
                          } else if (unlocked) {
                            onLevelTap(level);
                          }
                        },
                      );
                    },
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

// ═══════════════════════════════════════════════════════════════════════════
// Medal icon for level nodes
// ═══════════════════════════════════════════════════════════════════════════

class _MedalIcon extends StatelessWidget {
  final int stars;
  final bool isPlatinum;
  final double size;

  const _MedalIcon({required this.stars, required this.isPlatinum, required this.size});

  Color get _color {
    if (isPlatinum) return const Color(0xFFE5E4E2);
    return switch (stars) { 1 => const Color(0xFFCD7F32), 2 => const Color(0xFFC0C0C0), _ => const Color(0xFFFFD700) };
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.emoji_events, size: size.clamp(10, 18), color: _color);
    if (!isPlatinum) return icon;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1),
        ],
      ),
      child: icon,
    );
  }
}

// Level Node
// ═══════════════════════════════════════════════════════════════════════════

class _LevelNode extends StatelessWidget {
  final int level;
  final bool unlocked;
  final bool completed;
  final bool isBoss;
  final bool isCurrent;
  final int stars;
  final bool isPlatinum;
  final BiomeConfig biome;
  final bool hasChest;
  final Color chestColor;
  final VoidCallback onTap;

  const _LevelNode({
    required this.level,
    required this.unlocked,
    required this.completed,
    required this.isBoss,
    required this.isCurrent,
    required this.stars,
    this.isPlatinum = false,
    required this.biome,
    required this.hasChest,
    required this.chestColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = isBoss ? 72.0 : 56.0;
    final color = completed
        ? Colors.greenAccent
        : isCurrent
            ? Colors.amber
            : unlocked
                ? Color(biome.accentColor)
                : Colors.white24;

    return GestureDetector(
      onTap: unlocked || hasChest ? onTap : null,
      child: AnimatedContainer(
        duration: 300.ms,
        width: size,
        height: size,
        margin: EdgeInsets.only(top: isBoss ? 0 : 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasChest
              ? chestColor.withValues(alpha: 0.2)
              : completed
                  ? Colors.greenAccent.withValues(alpha: 0.15)
                  : color.withValues(alpha: unlocked ? 0.1 : 0.03),
          border: Border.all(
            color: hasChest
                ? chestColor.withValues(alpha: 0.6)
                : isCurrent
                    ? Colors.amber.withValues(alpha: 0.8)
                    : color.withValues(alpha: unlocked ? 0.4 : 0.1),
            width: isCurrent ? 2.5 : (hasChest ? 2 : 1.5),
          ),
          boxShadow: isCurrent || hasChest
              ? [BoxShadow(color: (hasChest ? chestColor : Colors.amber).withValues(alpha: 0.3), blurRadius: 12)]
              : null,
        ),
        child: hasChest
            ? Icon(Icons.inventory_2_outlined, size: size * 0.4, color: chestColor)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(level.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isBoss ? 13 : 11,
                        color: unlocked ? Colors.white : Colors.white38,
                      )),
                  if (completed && stars > 0) ...[
                    const SizedBox(height: 2),
                    _MedalIcon(stars: stars, isPlatinum: isPlatinum, size: size * 0.22),
                  ],
                  if (isBoss)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.whatshot, size: size * 0.2, color: Colors.orange.shade300),
                    ),
                ],
              ),
      ).animate(
        target: isCurrent ? 1 : 0,
      ).shake(duration: 2.seconds, delay: 1.seconds),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Continue Button (enhanced)
// ═══════════════════════════════════════════════════════════════════════════

class _ContinueButton extends ConsumerWidget {
  final int level;
  final VoidCallback onTap;
  const _ContinueButton({required this.level, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = CampaignStage.fromLevel(level);
    final biome = BiomeConfig.forStageNum(stage.datasetStage);
    final progress = ref.watch(campaignProvider);
    final result = progress.resultFor(level);
    final stars = result?.stars ?? 0;
    final isBoss = stage.isBossLevel(level);
    final isActiveRun = progress.hasActiveRun;
    final completedHere = progress.completedCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isBoss
                ? [Colors.deepOrange.shade800, Colors.red.shade900]
                : [Color(biome.accentColor).withValues(alpha: 0.8), Color(biome.primaryColor).withValues(alpha: 0.6)],
          ),
          boxShadow: [
            BoxShadow(
              color: (isBoss ? Colors.deepOrange : Color(biome.accentColor)).withValues(alpha: 0.4),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: Icon(
                isActiveRun ? Icons.play_arrow : Icons.arrow_forward,
                color: Colors.white, size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(biome.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(biome.name, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      if (isBoss) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.whatshot, size: 12, color: Colors.orange.shade300),
                        Text(' BOSS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade300)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActiveRun ? 'CONTINUAR NIVEL $level' : 'SIGUIENTE NIVEL $level',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 1, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (stars > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(stars.clamp(0, 3), (_) =>
                  const Text('⭐', style: TextStyle(fontSize: 10)),
                ),
              ),
            if (completedHere > 0) ...[
              const SizedBox(width: 8),
              Text('$completedHere/875', style: const TextStyle(fontSize: 10, color: Colors.white38)),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Streak Banner
// ═══════════════════════════════════════════════════════════════════════════

class _StreakBanner extends StatelessWidget {
  final int streak;
  const _StreakBanner({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.orange.shade800, Colors.red.shade800]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 24)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$streak RACHA PERFECTA',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 2)),
                Text('¡Seguí así!',
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mentor Bubble (NPC with avatar)
// ═══════════════════════════════════════════════════════════════════════════

class _MentorBubble extends StatefulWidget {
  final MentorMessage message;
  final VoidCallback onDismiss;
  const _MentorBubble({required this.message, required this.onDismiss});

  @override
  State<_MentorBubble> createState() => _MentorBubbleState();
}

class _MentorBubbleState extends State<_MentorBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final float = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut).value;
        return Transform.translate(
          offset: Offset(0, -2 * float),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1A237E).withValues(alpha: 0.95), const Color(0xFF0D1442).withValues(alpha: 0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)]),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                          blurRadius: 8 + float * 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🧙', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text('Mentor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade300, letterSpacing: 1)),
                            const Spacer(),
                            if (widget.message.techniqueId != null)
                              Text('★ Técnica', style: TextStyle(fontSize: 8, color: Colors.cyan.shade300)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(widget.message.message,
                            style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white38),
                    onPressed: widget.onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mission Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _MissionSheet extends StatelessWidget {
  final AdventureState adventure;
  final int currentLevel;
  const _MissionSheet({required this.adventure, required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    final stage = CampaignStage.fromLevel(currentLevel);
    final missions = worldMissionsForStage(stage);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 16),
          Text('METAS · ${stage.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2, color: Colors.white)),
          const SizedBox(height: 16),
          ...missions.map((m) {
            final completed = adventure.missions.isCompleted(m.id);
            final current = adventure.missions.get(m.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: completed ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: completed ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(
                    completed ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: completed ? Colors.greenAccent : Colors.white38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: completed ? Colors.greenAccent : Colors.white,
                            )),
                        Text(m.description,
                            style: const TextStyle(fontSize: 11, color: Colors.white54)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: (current / m.target).clamp(0.0, 1.0),
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(completed ? Colors.greenAccent : Colors.amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (completed)
                    Row(
                      children: [
                        if (m.tokensReward > 0) ...[
                          const SizedBox(width: 4),
                          Text('+${m.tokensReward}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                        if (m.soulsReward > 0) ...[
                          const SizedBox(width: 4),
                          Text('+${m.soulsReward}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                        ],
                      ],
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
