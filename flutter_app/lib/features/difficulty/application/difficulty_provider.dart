import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/difficulty_model.dart';
import '../../../shared/services/engine_mock.dart';

final difficultyProvider = FutureProvider<List<DifficultyModel>>((ref) async {
  return engineMock.getDifficulties();
});
