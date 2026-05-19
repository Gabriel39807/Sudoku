import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../stats/application/stats_provider.dart';
import '../../unlock/unlock_service.dart';
import '../domain/difficulty_model.dart';

final difficultyProvider = FutureProvider<List<DifficultyModel>>((ref) async {
  final stats = await ref.watch(statsProvider.future);
  return [
    const DifficultyModel(
      id: 'easy',
      name: 'EASY',
      description: 'Learn the basics',
      state: DifficultyState.unlocked,
    ),
    const DifficultyModel(
      id: 'intermediate',
      name: 'INTERMEDIATE',
      description: 'Think ahead',
      state: DifficultyState.unlocked,
    ),
    const DifficultyModel(
      id: 'hard',
      name: 'HARD',
      description: 'Advanced logic',
      state: DifficultyState.unlocked,
    ),
    const DifficultyModel(
      id: 'expert',
      name: 'EXPERT',
      description: 'Master challenge',
      state: DifficultyState.unlocked,
    ),
    DifficultyModel(
      id: 'evil',
      name: 'EVIL',
      description: 'Pure pain',
      state: UnlockService.isUnlocked('evil', stats)
          ? DifficultyState.unlocked
          : DifficultyState.locked,
      unlockRequirement: _progressText(stats, 'evil'),
    ),
    DifficultyModel(
      id: 'mythic',
      name: 'MYTHIC',
      description: '?????',
      state: UnlockService.isUnlocked('mythic', stats)
          ? DifficultyState.unlocked
          : DifficultyState.hidden,
      unlockRequirement: _progressText(stats, 'mythic'),
    ),
  ];
});

String _progressText(dynamic stats, String difficulty) {
  final progress = stats.unlockProgress[difficulty];
  if (progress == null) return 'Locked';
  return '${progress.current} / ${progress.required} victories';
}
