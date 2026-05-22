import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../game/data/board_repository.dart';

class DailyChallengeService {
  DailyChallengeService._();

  static String get todayKey {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Loads the daily challenge board deterministically based on UTC date.
  static Future<BoardData> loadDailyBoard() async {
    final seed = todayKey.hashCode;
    final rng = Random(seed);

    const difficulties = ['easy', 'intermediate', 'hard', 'expert', 'evil'];
    final diff = difficulties[rng.nextInt(difficulties.length)];
    const boardCount = 100;
    final idx = rng.nextInt(boardCount) + 1;
    final boardId = '${diff}_${idx.toString().padLeft(4, '0')}';
    final assetPath = 'assets/boards/$diff/$boardId.json';

    final raw = json.decode(await rootBundle.loadString(assetPath)) as Map<String, dynamic>;
    final puzzleFlat = _normalizeBoard(raw['puzzle']);
    final solutionFlat = _normalizeBoard(raw['solution']);

    return BoardData(
      id: 'daily_$todayKey',
      difficulty: 'daily',
      puzzleFlat: List<int>.from(puzzleFlat),
      solutionFlat: List<int>.from(solutionFlat),
      techniques: (raw['techniques'] as List?)?.map((e) => e.toString()).toList() ?? [],
      steps: raw['steps'] is List
          ? (raw['steps'] as List).length
          : (raw['steps'] as num?)?.toInt() ?? 0,
      checksum: raw['checksum'] as String? ?? '',
    );
  }

  static List<int> _normalizeBoard(dynamic raw) {
    if (raw is String) {
      return raw.split('').map((c) => int.tryParse(c) ?? 0).toList();
    }
    if (raw is List) {
      final flat = <int>[];
      for (final row in raw) {
        if (row is List) {
          for (final cell in row) {
            flat.add((cell as num).toInt());
          }
        }
      }
      return flat;
    }
    return List.filled(81, 0);
  }
}
