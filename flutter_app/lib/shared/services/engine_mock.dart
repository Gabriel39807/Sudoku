import 'package:flutter/foundation.dart';
import '../../features/difficulty/domain/difficulty_model.dart';

class EngineMock {
  // This is a temporary interface to connect to the Java core_engine later.
  // It simulates what the engine will provide via MethodChannels or JNI.

  Future<List<DifficultyModel>> getDifficulties() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      DifficultyModel(id: 'EASY', name: 'EASY', description: 'Learn the basics', state: DifficultyState.unlocked),
      DifficultyModel(id: 'INTERMEDIATE', name: 'INTERMEDIATE', description: 'Think ahead', state: DifficultyState.unlocked),
      DifficultyModel(id: 'HARD', name: 'HARD', description: 'Advanced logic', state: DifficultyState.unlocked),
      DifficultyModel(id: 'EXPERT', name: 'EXPERT', description: 'Master challenge', state: DifficultyState.unlocked),
      DifficultyModel(id: 'EVIL', name: 'EVIL', description: 'Pure pain', state: DifficultyState.locked, unlockRequirement: 'Win 10 Expert games'),
      DifficultyModel(id: 'MYTHIC', name: 'MYTHIC', description: '?????', state: DifficultyState.hidden, unlockRequirement: 'Perfect Evil streak'),
    ];
  }

  Future<void> generateGame(String difficulty) async {
    // Simulate generation delay
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Game generated for difficulty: $difficulty');
  }

  Future<bool> solveGame(List<List<int>> board) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true; // Simulate solved
  }

  Future<void> saveProgress(Map<String, dynamic> state) async {
    debugPrint('Progress saved to core_engine');
  }

  Future<Map<String, dynamic>> loadProgress() async {
    return {}; // Simulate empty/no progress
  }
}

final engineMock = EngineMock();
