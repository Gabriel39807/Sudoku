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
  /// Per-difficulty last board ID — evita repetición inmediata.
  static final Map<String, String> _lastBoardByDifficulty = {};

  static const Map<String, List<String>> _fallbackPaths = {
    'easy':         ['assets/boards/easy/easy_0001.json'],
    'intermediate': ['assets/boards/intermediate/intermediate_0001.json'],
    'hard':         ['assets/boards/hard/hard_0001.json'],
    'expert':       ['assets/boards/expert/expert_0001.json'],
    'evil':         ['assets/boards/evil/evil_0001.json'],
    'mythic':       ['assets/boards/mythic/mythic_0001.json'],
  };

  static Future<BoardData> loadRandomBoard(String difficulty) async {
    final diff = difficulty.toLowerCase();

    // 1. Resolver paths de assets
    final paths = await _resolvePaths(diff);

    // 2. Parsear todos los boards de la carpeta
    final allBoards = await _parseAll(paths);
    dev.log('[$diff] loaded ${allBoards.length}');

    // 3. Cargar IDs jugados y filtrar
    final played = await StatsStorage.getPlayedBoards(diff);
    List<BoardData> available =
        allBoards.where((b) => !played.contains(b.id)).toList();

    dev.log('[$diff] PLAYED: ${played.length}  AVAILABLE: ${available.length}');

    // 4. Si agotados, resetear sólo para esta dificultad
    if (available.isEmpty) {
      dev.log('[$diff] All played — resetting history for $diff');
      await StatsStorage.resetPlayedBoards(); // resetea todos (simplificado)
      available = allBoards;
    }

    // 5. Random real
    final rng = Random();
    BoardData selected = available[rng.nextInt(available.length)];

    // 6. Anti-repetición inmediata
    final last = _lastBoardByDifficulty[diff];
    if (last != null && selected.id == last && available.length > 1) {
      available.removeWhere((b) => b.id == last);
      selected = available[rng.nextInt(available.length)];
    }

    _lastBoardByDifficulty[diff] = selected.id;
    dev.log('[$diff] selected ${selected.id}');

    return selected;
  }

  // ── Internals ────────────────────────────────────────────────────────────

  static Future<List<String>> _resolvePaths(String diff) async {
    List<String> found = [];
    try {
      final manifest = json.decode(await rootBundle.loadString('AssetManifest.json'))
          as Map<String, dynamic>;
      final prefix = 'assets/boards/$diff/';
      found = manifest.keys
          .where((k) => k.startsWith(prefix) && k.endsWith('.json'))
          .toList();
    } catch (e) {
      dev.log('[BoardRepository] AssetManifest error: $e');
    }

    if (found.isEmpty) {
      found = List<String>.from(_fallbackPaths[diff] ?? []);
      dev.log('[BoardRepository] Using fallback for $diff');
    }

    if (found.isEmpty) {
      throw Exception('No boards found for "$diff"');
    }
    return found;
  }

  static Future<List<BoardData>> _parseAll(List<String> paths) async {
    final result = <BoardData>[];
    for (final path in paths) {
      try {
        final raw = json.decode(await rootBundle.loadString(path))
            as Map<String, dynamic>;
        result.add(BoardData(
          id:           raw['id'] as String? ?? _idFromPath(path),
          difficulty:   raw['difficulty'] as String? ?? '',
          puzzleFlat:   _normalize(raw['puzzle']),
          solutionFlat: _normalize(raw['solution']),
          techniques:   (raw['techniques'] as List?)
                            ?.map((e) => e.toString()).toList() ?? [],
          steps: (raw['steps'] as num?)?.toInt() ?? 0,
        ));
      } catch (e) {
        dev.log('[BoardRepository] Parse error $path: $e');
      }
    }
    return result;
  }

  static List<int> _normalize(dynamic raw) {
    if (raw is String) {
      return raw.split('').map((c) => int.tryParse(c) ?? 0).toList();
    }
    if (raw is List) {
      final flat = <int>[];
      for (final row in raw) {
        if (row is List) {
          for (final cell in row) { flat.add((cell as num).toInt()); }
        }
      }
      return flat;
    }
    return List.filled(81, 0);
  }

  static String _idFromPath(String path) =>
      path.split('/').last.replaceAll('.json', '');
}
