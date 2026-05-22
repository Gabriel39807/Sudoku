import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../game/data/save/global_saved_game.dart';
import '../../../shared/widgets/saved_game_conflict_dialog.dart';
import '../application/difficulty_provider.dart';
import 'widgets/difficulty_card.dart';

class DifficultyScreen extends ConsumerWidget {
  const DifficultyScreen({super.key});

  Future<void> _onDifficultyTap(
    BuildContext context,
    WidgetRef ref,
    String diff,
    GlobalSavedGame? savedGame,
  ) async {
    if (savedGame != null && savedGame.difficulty != diff) {
      final action = await showSavedGameConflictDialog(context, savedGame, diff);
      if (!context.mounted) return;

      if (action == null) return; // cancel
      if (action == false) {
        // start new
        await GlobalSaveStorage.delete();
        ref.invalidate(globalSavedGameProvider);
      }
      // action == true: continue saved game — falls through to push
    }
    if (context.mounted) context.push('/game', extra: diff);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficultiesAsync = ref.watch(difficultyProvider);
    final savedGameAsync = ref.watch(globalSavedGameProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              'SELECT DIFFICULTY',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
            Text(
              'Choose your challenge',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
      body: difficultiesAsync.when(
        data: (difficulties) {
          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 1;
              if (constraints.maxWidth > 600) {
                crossAxisCount = 2;
              }

              final savedGame = savedGameAsync.asData?.value;

              final children = <Widget>[];

              if (savedGame != null) {
                children.add(_ContinueCard(savedGame: savedGame));
              }

              children.add(
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      mainAxisExtent: 240,
                    ),
                    itemCount: difficulties.length,
                    itemBuilder: (context, index) {
                      final model = difficulties[index];
                      return DifficultyCard(
                        model: model,
                        onTap: () => _onDifficultyTap(context, ref, model.id, savedGame),
                      ).animate().fade(delay: (100 * index).ms).slideY(begin: 0.2);
                    },
                  ),
                ),
              );

              return Column(
                children: children,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  final GlobalSavedGame savedGame;
  const _ContinueCard({required this.savedGame});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = savedGame.elapsedSeconds ~/ 3600;
    final m = (savedGame.elapsedSeconds % 3600) ~/ 60;
    final s = savedGame.elapsedSeconds % 60;
    final timeStr =
        h > 0
            ? '${h}h ${m}m'
            : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: InkWell(
        onTap: () {
          context.push('/game', extra: savedGame.difficulty);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade600, width: 1.5),
            color: Colors.amber.withValues(alpha: 0.08),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.amberAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CONTINUAR PARTIDA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.amber.shade200,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${savedGame.difficulty.toUpperCase()} · ${savedGame.completionPercent}% · $timeStr · ${savedGame.mistakes} errores',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.amberAccent),
            ],
          ),
        ),
      ),
    );
  }
}
