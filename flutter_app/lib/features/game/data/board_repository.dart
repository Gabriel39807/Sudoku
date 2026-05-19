import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter/services.dart';

class BoardData {
  final String id;
  final String difficulty;
  final List<int> puzzleFlat;   // 81 ints, 0 = vacío
  final List<int> solutionFlat; // 81 ints
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
  // ------------------------------------------------------------------ //
  // Fallback estático garantiza al menos un tablero por dificultad      //
  // aunque AssetManifest falle o la carpeta esté vacía en el manifest.  //
  // ------------------------------------------------------------------ //
  static const Map<String, List<String>> _fallbackPaths = {
    'easy':         ['assets/boards/easy/easy_0001.json'],
    'intermediate': ['assets/boards/intermediate/intermediate_0001.json'],
    'hard':         ['assets/boards/hard/hard_0001.json'],
    'expert':       ['assets/boards/expert/expert_0001.json'],
    'evil':         ['assets/boards/evil/evil_0001.json'],
    'mythic':       ['assets/boards/mythic/mythic_0001.json'],
  };

  // ------------------------------------------------------------------ //
  // API pública principal                                               //
  // ------------------------------------------------------------------ //

  /// Carga un tablero aleatorio de [difficulty], excluyendo [playedIds].
  /// Nunca devuelve el mismo ID que [lastBoardId] si hay más opciones.
  static Future<BoardData> loadRandomBoard({
    required String difficulty,
    required Set<String> playedIds,
    String? lastBoardId,
  }) async {
    final key = difficulty.toLowerCase();
    final paths = await _resolveAssetPaths(key);

    // Parsear TODOS los tableros de la carpeta
    final allBoards = await _parseAll(paths);
    dev.log('[BoardRepository][$key] BOARD COUNT: ${allBoards.length}');

    // Filtrar jugados
    List<BoardData> available =
        allBoards.where((b) => !playedIds.contains(b.id)).toList();
    dev.log('[BoardRepository][$key] PLAYED: ${playedIds.length}  |  AVAILABLE: ${available.length}');

    // Si agotamos todos, resetear historial y volver a usar todos
    if (available.isEmpty) {
      dev.log('[BoardRepository][$key] Reset historial — todos jugados');
      available = allBoards;
    }

    // Selección aleatoria real
    final rng = Random();
    BoardData selected = available[rng.nextInt(available.length)];

    // Anti-repetición inmediata
    if (lastBoardId != null && selected.id == lastBoardId && available.length > 1) {
      available.removeWhere((b) => b.id == lastBoardId);
      selected = available[rng.nextInt(available.length)];
    }

    dev.log('[BoardRepository][$key] SELECTED: ${selected.id}');
    return selected;
  }

  // ------------------------------------------------------------------ //
  // Internals                                                           //
  // ------------------------------------------------------------------ //

  static Future<List<String>> _resolveAssetPaths(String key) async {
    dev.log('[BoardRepository] LOADING DIFFICULTY: $key');
    List<String> found = [];

    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifest = json.decode(manifestContent) as Map<String, dynamic>;
      final prefix = 'assets/boards/$key/';
      found = manifest.keys
          .where((k) => k.startsWith(prefix) && k.endsWith('.json'))
          .toList();
      dev.log('[BoardRepository] FOUND ${found.length} FILES via AssetManifest');
    } catch (e) {
      dev.log('[BoardRepository] AssetManifest ERROR: $e');
    }

    if (found.isEmpty) {
      dev.log('[BoardRepository] Usando fallback estático para "$key"');
      found = List<String>.from(_fallbackPaths[key] ?? []);
    }

    if (found.isEmpty) {
      throw Exception(
        '[BoardRepository] NO BOARDS FOUND for "$key". '
        'Asegurate de tener archivos en assets/boards/$key/ y declarados en pubspec.yaml.',
      );
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
                            ?.map((e) => e.toString())
                            .toList() ?? [],
          steps: (raw['steps'] as num?)?.toInt() ?? 0,
        ));
      } catch (e) {
        dev.log('[BoardRepository] Error parsing $path: $e');
      }
    }
    return result;
  }

  /// Convierte String de 81 chars O List anidada a `List<int>` plana.
  static List<int> _normalize(dynamic raw) {
    if (raw is String) {
      return raw.split('').map((ch) => int.tryParse(ch) ?? 0).toList();
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

  static String _idFromPath(String path) =>
      path.split('/').last.replaceAll('.json', '');
}
