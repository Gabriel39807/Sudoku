import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/services.dart';
import '../../../features/stats/data/stats_storage.dart';

class BoardData {
  final String id;
  final String difficulty;
  final List<int> puzzleFlat;
  final List<int> solutionFlat;
  final List<String> techniques;
  final int steps;

  const BoardData({
    required this.id,
    required this.difficulty,
    required this.puzzleFlat,
    required this.solutionFlat,
    required this.techniques,
    required this.steps,
  });
}

class BoardRepository {
  // Tabla exacta de todos los boards por dificultad
  // NO depende de AssetManifest (que puede tener URL encoding o cambiar formato entre Flutter versions).
  static const Map<String, int> _boardCount = {
    'easy':         20,
    'intermediate': 20,
    'hard':         20,
    'expert':       20,
    'evil':         20,
    'mythic':       20,
  };

  // Per-difficulty: último board seleccionado (anti-repetición inmediata)
  static final Map<String, String> _lastBoardId = {};

  // ── API pública ──────────────────────────────────────────────────────────

  static Future<BoardData> loadRandomBoard(String difficulty) async {
    final diff = difficulty.toLowerCase();
    final count = _boardCount[diff] ?? 1;

    dev.log('[BoardRepo][$diff] count=$count');

    // 1. Cargar IDs ya jugados para esta dificultad
    final played = await StatsStorage.getPlayedBoards(diff);
    dev.log('[BoardRepo][$diff] played=${played.length}');

    // 2. Construir pool de índices disponibles (1-based)
    List<int> available = List.generate(count, (i) => i + 1)
        .where((n) => !played.contains('${diff}_${n.toString().padLeft(4, '0')}'))
        .toList();

    dev.log('[BoardRepo][$diff] available=${available.length}');

    // 3. Si agotados, resetear solo esta dificultad
    if (available.isEmpty) {
      dev.log('[BoardRepo][$diff] All played — resetting');
      await StatsStorage.resetPlayedBoardsFor(diff);
      available = List.generate(count, (i) => i + 1);
    }

    // 4. Random real
    final rng = Random();
    int idx = available[rng.nextInt(available.length)];

    // 5. Anti-repetición inmediata
    final lastId = _lastBoardId[diff];
    final lastIdx = lastId != null ? _indexFromId(lastId) : null;
    if (lastIdx != null && idx == lastIdx && available.length > 1) {
      available.removeWhere((n) => n == lastIdx);
      idx = available[rng.nextInt(available.length)];
    }

    final boardId = '${diff}_${idx.toString().padLeft(4, '0')}';
    final assetPath = 'assets/boards/$diff/$boardId.json';

    dev.log('[BoardRepo][$diff] SELECTED: $boardId  PATH: $assetPath');

    // 6. Cargar y parsear JSON
    final raw = json.decode(await rootBundle.loadString(assetPath)) as Map<String, dynamic>;
    final puzzleFlat = _normalize(raw['puzzle']);
    final solutionFlat = _normalize(raw['solution']);

    dev.log('[BoardRepo][$diff] puzzle[0..9]=${puzzleFlat.take(10).toList()}');
    dev.log('[BoardRepo][$diff] solution[0..9]=${solutionFlat.take(10).toList()}');

    _lastBoardId[diff] = boardId;

    return BoardData(
      id:           raw['id'] as String? ?? boardId,
      difficulty:   diff,
      puzzleFlat:   puzzleFlat,
      solutionFlat: solutionFlat,
      techniques:   (raw['techniques'] as List?)?.map((e) => e.toString()).toList() ?? [],
      steps:        (raw['steps'] as num?)?.toInt() ?? 0,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static int? _indexFromId(String id) {
    final parts = id.split('_');
    return parts.length > 1 ? int.tryParse(parts.last) : null;
  }

  /// Acepta String de 81 chars O `List<List<int>>` anidada.
  static List<int> _normalize(dynamic raw) {
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
