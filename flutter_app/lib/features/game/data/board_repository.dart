import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/services.dart';

class BoardRepository {
  // Fallback estático: garantiza que siempre hay al menos un tablero por dificultad
  // aunque AssetManifest falle o la lista esté vacía.
  static const Map<String, List<String>> _fallbackBoards = {
    'easy': ['assets/boards/easy/easy_0001.json'],
    'intermediate': ['assets/boards/intermediate/intermediate_0001.json'],
    'hard': ['assets/boards/hard/hard_0001.json'],
    'expert': ['assets/boards/expert/expert_0001.json'],
    'evil': ['assets/boards/evil/evil_0001.json'],
    'mythic': ['assets/boards/mythic/mythic_0001.json'],
  };

  static Future<List<String>> getAvailableBoards(String difficulty) async {
    final key = difficulty.toLowerCase();
    dev.log('[BoardRepository] LOADING DIFFICULTY: $key');

    List<String> found = [];

    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final path = 'assets/boards/$key/';
      found = manifestMap.keys
          .where((k) => k.startsWith(path) && k.endsWith('.json'))
          .toList();
      dev.log('[BoardRepository] FOUND ${found.length} FILES via AssetManifest');
    } catch (e) {
      dev.log('[BoardRepository] AssetManifest ERROR: $e — switching to fallback');
    }

    // Si el manifest no devolvió nada, intentar el fallback estático
    if (found.isEmpty) {
      dev.log('[BoardRepository] AssetManifest returned empty, using fallback for "$key"');
      found = List<String>.from(_fallbackBoards[key] ?? []);
      dev.log('[BoardRepository] FALLBACK FOUND ${found.length} FILES');
    }

    if (found.isEmpty) {
      throw Exception(
        '[BoardRepository] NO BOARDS FOUND for difficulty "$key". '
        'Check that assets/boards/$key/ contains at least one .json file '
        'and is declared in pubspec.yaml.',
      );
    }

    return found;
  }

  /// Carga un JSON de tablero y lo normaliza independientemente del formato:
  ///   Formato A: `{ "puzzle": "530070...", "solution": "534678..." }` — string de 81 chars
  ///   Formato B: `{ "puzzle": [[...]], "solution": [[...]] }` — List anidado de int
  static Future<Map<String, dynamic>> loadBoard(String assetPath) async {
    dev.log('[BoardRepository] SELECTED FILE: $assetPath');
    final jsonString = await rootBundle.loadString(assetPath);
    final raw = json.decode(jsonString) as Map<String, dynamic>;

    final boardId = raw['id'] as String? ?? assetPath.split('/').last.replaceAll('.json', '');
    final diff = raw['difficulty'] as String? ?? '';

    final puzzleRaw = raw['puzzle'];
    final solutionRaw = raw['solution'];

    dev.log('[BoardRepository] BOARD ID: $boardId | DIFFICULTY: $diff | JSON TYPE: ${puzzleRaw.runtimeType}');

    final puzzleFlat = _normalize(puzzleRaw);
    final solutionFlat = _normalize(solutionRaw);

    return {
      'id': boardId,
      'difficulty': diff,
      'techniques': raw['techniques'] ?? [],
      'steps': raw['steps'] ?? 0,
      'puzzleFlat': puzzleFlat,   // List<int> de 81 elementos
      'solutionFlat': solutionFlat,
    };
  }

  /// Convierte cualquier formato a `List<int>` de 81 posiciones.
  static List<int> _normalize(dynamic raw) {
    if (raw is String) {
      // Formato A: "530070000..."
      return raw.split('').map((ch) => int.tryParse(ch) ?? 0).toList();
    }
    if (raw is List) {
      // Formato B: [[5,3,0,...], [...], ...]
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
    // Fallback vacío (no debería ocurrir)
    return List.filled(81, 0);
  }
}
