import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/data/board_repository_v2.dart';
import '../../stats/application/stats_provider.dart';
import '../../unlock/unlock_service.dart';
import '../domain/difficulty_model.dart';

const _subtitleMap = {
  'easy': 'Aprendiz',
  'intermediate': 'Intermedio',
  'hard': 'Avanzado',
  'expert': 'Experto',
  'evil': 'Caos',
  'mythic': 'Legendario',
};

final difficultyProvider = FutureProvider<List<DifficultyModel>>((ref) async {
  final stats = await ref.watch(statsProvider.future);
  return [
    DifficultyModel(
      id: 'easy',
      name: 'EASY',
      subtitle: _subtitleMap['easy']!,
      description: 'Learn the basics',
      state: DifficultyState.unlocked,
      totalCount: BoardRepositoryV2.boardCount['easy']!,
      completedCount: stats.playedBoardsByDifficulty['easy'] ?? 0,
    ),
    DifficultyModel(
      id: 'intermediate',
      name: 'INTERMEDIATE',
      subtitle: _subtitleMap['intermediate']!,
      description: 'Think ahead',
      state: DifficultyState.unlocked,
      totalCount: BoardRepositoryV2.boardCount['intermediate']!,
      completedCount: stats.playedBoardsByDifficulty['intermediate'] ?? 0,
    ),
    DifficultyModel(
      id: 'hard',
      name: 'HARD',
      subtitle: _subtitleMap['hard']!,
      description: 'Advanced logic',
      state: DifficultyState.unlocked,
      totalCount: BoardRepositoryV2.boardCount['hard']!,
      completedCount: stats.playedBoardsByDifficulty['hard'] ?? 0,
    ),
    DifficultyModel(
      id: 'expert',
      name: 'EXPERT',
      subtitle: _subtitleMap['expert']!,
      description: 'Master challenge',
      state: DifficultyState.unlocked,
      totalCount: BoardRepositoryV2.boardCount['expert']!,
      completedCount: stats.playedBoardsByDifficulty['expert'] ?? 0,
    ),
    DifficultyModel(
      id: 'evil',
      name: 'EVIL',
      subtitle: _subtitleMap['evil']!,
      description: 'Pure pain',
      state: UnlockService.isUnlocked('evil', stats)
          ? DifficultyState.unlocked
          : DifficultyState.locked,
      unlockRequirement: _progressText(stats, 'evil'),
      totalCount: BoardRepositoryV2.boardCount['evil']!,
      completedCount: stats.playedBoardsByDifficulty['evil'] ?? 0,
    ),
    DifficultyModel(
      id: 'mythic',
      name: 'MYTHIC',
      subtitle: UnlockService.isUnlocked('mythic', stats) ? 'Legendario' : '?????',
      description: 'Legendary challenge',
      state: UnlockService.isUnlocked('mythic', stats)
          ? DifficultyState.unlocked
          : DifficultyState.hidden,
      unlockRequirement: _progressText(stats, 'mythic'),
      totalCount: BoardRepositoryV2.boardCount['mythic']!,
      completedCount: stats.playedBoardsByDifficulty['mythic'] ?? 0,
    ),
  ];
});

String _progressText(dynamic stats, String difficulty) {
  final progress = stats.unlockProgress[difficulty];
  if (progress == null) return 'Locked';
  return '${progress.current} / ${progress.required} victories';
}
