import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../domain/campaign_level.dart';
import '../application/campaign_provider.dart';
import 'widgets/campaign_level_tile.dart';
import 'widgets/campaign_stage_header.dart';
import 'tutorial_screen.dart';

class CampaignScreen extends ConsumerWidget {
  const CampaignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(campaignProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              'CAMPAÑA',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
            Text(
              '${progress.completedCount}/${progress.totalCount} niveles completados',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildGlobalProgress(context, progress),
          ...CampaignStage.values.map((stage) => _buildStage(context, ref, stage, progress)),
        ],
      ),
    );
  }

  Widget _buildGlobalProgress(BuildContext context, dynamic progress) {
    final total = progress.totalCount;
    final pct = total > 0 ? progress.completedCount / total : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: 600.ms,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.completedCount} / $total completados',
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildStage(BuildContext context, WidgetRef ref, CampaignStage stage, dynamic progress) {
    final start = stage.levelStart;
    final end = stage.levelEnd;
    final levels = List.generate(end - start + 1, (i) => start + i);
    final completedInStage = levels.where((l) => progress.isCompleted(l)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampaignStageHeader(
          stage: stage,
          completedInStage: completedInStage,
          totalInStage: levels.length,
        ),
        ...levels.map((level) {
          final unlocked = progress.isUnlocked(level);
          final result = progress.resultFor(level);
          final needsTutorial = stage == CampaignStage.miniSudoku && level <= 3 && result == null;

          return CampaignLevelTile(
            level: level,
            stage: stage,
            unlocked: unlocked,
            result: result,
            onTap: () => _onLevelTap(context, ref, level, stage, needsTutorial),
          );
        }),
      ],
    );
  }

  void _onLevelTap(BuildContext context, WidgetRef ref, int level, CampaignStage stage, bool needsTutorial) {
    if (needsTutorial) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TutorialScreen(
            level: level,
            variant: stage.variant,
            onComplete: () {
              Navigator.pop(context);
              context.push('/campaign-game', extra: {
                'level': level,
                'variant': stage.variant.name,
              });
            },
          ),
        ),
      );
    } else {
      context.push('/campaign-game', extra: {
        'level': level,
        'variant': stage.variant.name,
      });
    }
  }
}
