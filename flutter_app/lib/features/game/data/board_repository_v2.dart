import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Unified board data — same shape used by all game modes.
class BoardData {
  final String id;
  final String difficulty;
  final List<int> puzzleFlat;
  final List<int> solutionFlat;
  final List<String> techniques;
  final int steps;
  final String checksum;
  final Map<String, dynamic> raw;

  const BoardData({
    required this.id,
    required this.difficulty,
    required this.puzzleFlat,
    required this.solutionFlat,
    this.techniques = const [],
    this.steps = 0,
    this.checksum = '',
    this.raw = const {},
  });
}

/// Unified board repository.
///
/// Responsibilities:
/// - Load boards by difficulty (easy / intermediate / … / mythic)
/// - Random selection with anti-repeat history (last 20)
/// - Daily challenge (deterministic, weighted distribution)
/// - Campaign stage loading
/// - In-memory cache (avoids re-loading same JSON within session)
class BoardRepositoryV2 {
  BoardRepositoryV2._();

  // ── Dataset sizes ─────────────────────────────────────────────────────────

  static const Map<String, int> boardCount = {
    'easy': 100,
    'intermediate': 100,
    'hard': 100,
    'expert': 500,
    'evil': 500,
    'mythic': 500,
  };

  static const List<String> allDifficulties = [
    'easy',
    'intermediate',
    'hard',
    'expert',
    'evil',
    'mythic',
  ];

  // ── History (last 20 per difficulty, in-memory) ───────────────────────────

  static final Map<String, List<String>> _history = {};
  static const int _historySize = 20;

  // ── Simple memory cache ───────────────────────────────────────────────────

  static final Map<String, BoardData> _cache = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns a board for the given [difficulty].
  static Future<BoardData> loadRandomBoard(String difficulty) async {
    final diff = difficulty.toLowerCase();
    final count = boardCount[diff] ?? 0;
    if (count == 0) throw StateError('Unknown difficulty: $diff');

    final history = _getHistory(diff);

    // build candidate indices, preferring non-recent ones
    final candidates = List.generate(count, (i) => i + 1);
    candidates.shuffle(Random());

    Object? lastErr;
    for (final idx in candidates) {
      final boardId = '${diff}_${idx.toString().padLeft(4, '0')}';
      if (history.contains(boardId)) continue;

      try {
        final board = await _loadById(diff, boardId);
        _pushHistory(diff, boardId);
        return board;
      } catch (e) {
        lastErr = e;
      }
    }

    // all candidates exhausted — try history entries as fallback
    for (final boardId in history.reversed) {
      try {
        final board = await _loadById(diff, boardId);
        _pushHistory(diff, boardId);
        return board;
      } catch (_) {}
    }

    throw StateError(
      'No valid board for $diff: ${lastErr ?? "unknown"}',
    );
  }

  /// Deterministic daily board based on UTC date.
  static Future<BoardData> loadDailyBoard(DateTime utcDate) async {
    final d = utcDate.toUtc();
    final todayKey = _dateKey(d);
    final seed = d.year * 10000 + d.month * 100 + d.day;
    final rng = Random(seed);

    final diff = _pickDailyDifficulty(rng);
    final count = boardCount[diff]!;
    final idx = rng.nextInt(count) + 1;
    final boardId = '${diff}_${idx.toString().padLeft(4, '0')}';

    try {
      final board = await _loadById(diff, boardId);
      return BoardData(
        id: 'daily_$todayKey',
        difficulty: 'daily',
        puzzleFlat: board.puzzleFlat,
        solutionFlat: board.solutionFlat,
        techniques: board.techniques,
        steps: board.steps,
        checksum: board.checksum,
        raw: board.raw,
      );
    } catch (e) {
      debugPrint('Daily board load failed ($boardId): $e — falling back to easy');
      final fallback = await loadRandomBoard('easy');
      return BoardData(
        id: 'daily_$todayKey',
        difficulty: 'daily',
        puzzleFlat: fallback.puzzleFlat,
        solutionFlat: fallback.solutionFlat,
        techniques: fallback.techniques,
        steps: fallback.steps,
        checksum: fallback.checksum,
        raw: fallback.raw,
      );
    }
  }

  /// Load a campaign board for [stage] (1‑based) and [levelIndex] (1‑based
  /// within that stage).
  static Future<BoardData> loadCampaignBoard(
    int stage,
    int levelIndex,
  ) async {
    final config = _campaignStageConfig(stage);
    final idx = levelIndex.toString().padLeft(4, '0');
    final variantName = _variantAssetName(config.variant);
    final boardId = 'campaign_${variantName}_$idx';
    final assetPath =
        'assets/boards/campaign/stage_${stage.toString().padLeft(2, '0')}/$boardId.json';

    return _loadFromAsset(assetPath, boardId: boardId, difficulty: 'campaign');
  }

  /// Look-up a specific board by difficulty and id.
  static Future<BoardData> lookupBoard(
    String difficulty,
    String boardId,
  ) async {
    return _loadById(difficulty, boardId);
  }

  /// Invalidate the in-memory cache (e.g. after a force-reload test).
  static void clearCache() {
    _cache.clear();
    _history.clear();
  }

  /// Number of boards for the given difficulty.
  static int countFor(String difficulty) =>
      boardCount[difficulty.toLowerCase()] ?? 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // DAILY DIFFICULTY DISTRIBUTION
  // ═══════════════════════════════════════════════════════════════════════════

  static final List<_WeightedDifficulty> _dailyWeights = [
    _WeightedDifficulty('easy', 57),
    _WeightedDifficulty('intermediate', 27),
    _WeightedDifficulty('hard', 11),
    _WeightedDifficulty('expert', 4),
    _WeightedDifficulty('evil', 1),
  ];

  static String _pickDailyDifficulty(Random rng) {
    // mythic: 1 day every 366
    if (rng.nextInt(366) == 0) return 'mythic';

    final total = _dailyWeights.fold(0, (s, w) => s + w.weight);
    final roll = rng.nextInt(total);
    var acc = 0;
    for (final w in _dailyWeights) {
      acc += w.weight;
      if (roll < acc) return w.difficulty;
    }
    return 'easy';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMPAIGN STAGE CONFIG
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<_CampaignStageConfig> _campaignStages = [
    _CampaignStageConfig(
      stage: 1,
      variant: 'mini_4x4',
      levelCount: 50,
      boardSize: 4,
      subgridWidth: 2,
      subgridHeight: 2,
    ),
    _CampaignStageConfig(
      stage: 2,
      variant: 'mini_6x6',
      levelCount: 75,
      boardSize: 6,
      subgridWidth: 3,
      subgridHeight: 2,
    ),
    _CampaignStageConfig(
      stage: 3,
      variant: 'mini_8x8',
      levelCount: 100,
      boardSize: 8,
      subgridWidth: 4,
      subgridHeight: 2,
    ),
  ];

  static _CampaignStageConfig _campaignStageConfig(int stage) {
    for (final c in _campaignStages) {
      if (c.stage == stage) return c;
    }
    throw StateError('Unknown campaign stage: $stage');
  }

  static int campaignLevelCount(int stage) =>
      _campaignStageConfig(stage).levelCount;

  static int campaignTotalLevels() =>
      _campaignStages.fold(0, (s, c) => s + c.levelCount);

  static String _variantAssetName(String variant) =>
      variant.replaceAll('mini_', '');

  static int campaignStageForLevel(int level) {
    var acc = 0;
    for (final c in _campaignStages) {
      acc += c.levelCount;
      if (level <= acc) return c.stage;
    }
    throw StateError('Level $level exceeds campaign total');
  }

  static int levelIndexInStage(int level) {
    var acc = 0;
    for (final c in _campaignStages) {
      if (level <= acc + c.levelCount) return level - acc;
      acc += c.levelCount;
    }
    return level - acc;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL LOADERS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<BoardData> _loadById(String diff, String boardId) async {
    final cacheKey = '$diff/$boardId';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final assetPath = 'assets/boards/$diff/$boardId.json';
    final board = await _loadFromAsset(
      assetPath,
      boardId: boardId,
      difficulty: diff,
    );
    _cache[cacheKey] = board;
    return board;
  }

  static Future<BoardData> _loadFromAsset(
    String assetPath, {
    required String boardId,
    required String difficulty,
  }) async {
    final raw = json.decode(
      await rootBundle.loadString(assetPath),
    ) as Map<String, dynamic>;

    final puzzleFlat = _normalize(raw['puzzle']);
    final solutionFlat = _normalize(raw['solution']);

    return BoardData(
      id: raw['id'] as String? ?? boardId,
      difficulty: raw['difficulty'] as String? ?? difficulty,
      puzzleFlat: List<int>.from(puzzleFlat),
      solutionFlat: List<int>.from(solutionFlat),
      techniques:
          (raw['techniques'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      steps: raw['steps'] is List
          ? (raw['steps'] as List).length
          : (raw['steps'] as num?)?.toInt() ?? 0,
      checksum: raw['checksum'] as String? ?? raw['hash'] as String? ?? '',
      raw: raw,
    );
  }

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
    return <int>[];
  }

  // ── History helpers ──────────────────────────────────────────────────────

  static List<String> _getHistory(String diff) =>
      _history.putIfAbsent(diff, () => []);

  static void _pushHistory(String diff, String boardId) {
    final h = _getHistory(diff);
    h.add(boardId);
    if (h.length > _historySize) {
      h.removeAt(0);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRIVATE MODELS
// ═════════════════════════════════════════════════════════════════════════════

class _WeightedDifficulty {
  final String difficulty;
  final int weight;
  const _WeightedDifficulty(this.difficulty, this.weight);
}

class _CampaignStageConfig {
  final int stage;
  final String variant;
  final int levelCount;
  final int boardSize;
  final int subgridWidth;
  final int subgridHeight;

  const _CampaignStageConfig({
    required this.stage,
    required this.variant,
    required this.levelCount,
    required this.boardSize,
    required this.subgridWidth,
    required this.subgridHeight,
  });
}

String _dateKey(DateTime date) {
  final d = date.toUtc();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
