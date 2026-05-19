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
  final String checksum;

  const BoardData({
    required this.id,
    required this.difficulty,
    required this.puzzleFlat,
    required this.solutionFlat,
    required this.techniques,
    required this.steps,
    required this.checksum,
  });
}

class BoardRepository {
  static const Map<String, int> _boardCount = {
    'easy': 100,
    'intermediate': 100,
    'hard': 100,
    'expert': 100,
    'evil': 100,
    'mythic': 100,
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

    List<int> available = List.generate(count, (i) => i + 1)
        .where(
          (n) => !played.contains('${diff}_${n.toString().padLeft(4, '0')}'),
        )
        .toList();

    dev.log('[BoardRepo][$diff] available=${available.length}');

    // 3. Si agotados, resetear solo esta dificultad
    if (available.isEmpty) {
      dev.log('[BoardRepo][$diff] All played — resetting');
      await StatsStorage.resetPlayedBoardsFor(diff);
      available = List.generate(count, (i) => i + 1);
    }

    final rng = Random();
    available.shuffle(rng);
    final lastId = _lastBoardId[diff];
    final lastIdx = lastId != null ? _indexFromId(lastId) : null;
    if (lastIdx != null && available.length > 1) {
      available.remove(lastIdx);
      available.add(lastIdx);
    }

    for (final idx in available) {
      final boardId = '${diff}_${idx.toString().padLeft(4, '0')}';
      final assetPath = 'assets/boards/$diff/$boardId.json';

      dev.log('[BoardRepo][$diff] TRY: $boardId  PATH: $assetPath');

      final raw =
          json.decode(await rootBundle.loadString(assetPath))
              as Map<String, dynamic>;
      final puzzleFlat = _normalize(raw['puzzle']);
      final solutionFlat = _normalize(raw['solution']);
      if (!_isValidBoard(
        puzzleFlat,
        solutionFlat,
        raw['difficulty'] as String?,
        diff,
      )) {
        dev.log('[BoardRepo][$diff] Invalid board skipped: $boardId');
        continue;
      }

      dev.log('[BoardRepo][$diff] SELECTED: $boardId');
      _lastBoardId[diff] = boardId;

      return BoardData(
        id: raw['id'] as String? ?? boardId,
        difficulty: diff,
        puzzleFlat: List<int>.from(puzzleFlat),
        solutionFlat: List<int>.from(solutionFlat),
        techniques:
            (raw['techniques'] as List?)?.map((e) => e.toString()).toList() ??
            [],
        steps: raw['steps'] is List
            ? (raw['steps'] as List).length
            : (raw['steps'] as num?)?.toInt() ?? 0,
        checksum: raw['checksum'] as String? ?? '',
      );
    }

    throw StateError('No valid boards available for $diff');
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

  static bool _isValidBoard(
    List<int> puzzle,
    List<int> solution,
    String? rawDifficulty,
    String expectedDifficulty,
  ) {
    if (rawDifficulty != null &&
        rawDifficulty.toLowerCase() != expectedDifficulty) {
      return false;
    }
    if (puzzle.length != 81 || solution.length != 81) return false;
    if (puzzle.any((v) => v < 0 || v > 9)) return false;
    if (solution.any((v) => v < 1 || v > 9)) return false;
    if (ListEquality.intEquals(puzzle, solution)) return false;
    for (var i = 0; i < 81; i++) {
      if (puzzle[i] != 0 && puzzle[i] != solution[i]) return false;
    }
    return !_hasConflicts(puzzle, allowZero: true) &&
        !_hasConflicts(solution, allowZero: false);
  }

  static bool _hasConflicts(List<int> board, {required bool allowZero}) {
    for (var i = 0; i < 9; i++) {
      if (_unitConflict(List.generate(9, (c) => board[i * 9 + c]), allowZero)) {
        return true;
      }
      if (_unitConflict(List.generate(9, (r) => board[r * 9 + i]), allowZero)) {
        return true;
      }
    }
    for (var br = 0; br < 9; br += 3) {
      for (var bc = 0; bc < 9; bc += 3) {
        final values = <int>[];
        for (var r = br; r < br + 3; r++) {
          for (var c = bc; c < bc + 3; c++) {
            values.add(board[r * 9 + c]);
          }
        }
        if (_unitConflict(values, allowZero)) return true;
      }
    }
    return false;
  }

  static bool _unitConflict(List<int> values, bool allowZero) {
    final seen = <int>{};
    for (final value in values) {
      if (value == 0 && allowZero) continue;
      if (!seen.add(value)) return true;
    }
    return false;
  }
}

class ListEquality {
  static bool intEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
