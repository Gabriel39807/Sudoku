import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalSavedGame {
  final String difficulty;
  final String boardId;
  final List<int> initialBoard;
  final List<int> currentBoard;
  final List<int> solution;
  final Set<int> fixedCells;
  final Map<int, Set<int>> notes;
  final int mistakes;
  final int elapsedSeconds;
  final int hintsUsed;
  final int retries;
  final int continuesUsed;
  final int remainingHints;
  final int correctStreak;
  final int maxCombo;
  final int totalMoves;
  final int correctMoves;
  final int noteUsageCount;
  final bool advancedNotesEnabled;
  final bool advancedNotesUnlockedForRun;
  final Map<int, int> cellTimeMs;
  final Map<int, Set<int>>? manualNotes;
  final bool completedWithAutocomplete;
  final int autoCompleteUsed;
  final DateTime savedAt;

  const GlobalSavedGame({
    required this.difficulty,
    required this.boardId,
    required this.initialBoard,
    required this.currentBoard,
    required this.solution,
    required this.fixedCells,
    required this.notes,
    required this.mistakes,
    required this.elapsedSeconds,
    required this.hintsUsed,
    required this.retries,
    required this.continuesUsed,
    required this.remainingHints,
    required this.correctStreak,
    required this.maxCombo,
    required this.totalMoves,
    required this.correctMoves,
    required this.noteUsageCount,
    required this.advancedNotesEnabled,
    required this.advancedNotesUnlockedForRun,
    required this.cellTimeMs,
    this.manualNotes,
    required this.completedWithAutocomplete,
    required this.autoCompleteUsed,
    required this.savedAt,
  });

  int get completionPercent {
    final empty = currentBoard.where((v) => v == 0).length;
    return ((81 - empty) * 100 / 81).round();
  }

  Map<String, dynamic> toJson() => {
    'difficulty': difficulty,
    'boardId': boardId,
    'initialBoard': initialBoard,
    'currentBoard': currentBoard,
    'solution': solution,
    'fixedCells': fixedCells.toList(),
    'notes': notes.map((k, v) => MapEntry(k.toString(), v.toList())),
    'mistakes': mistakes,
    'elapsedSeconds': elapsedSeconds,
    'hintsUsed': hintsUsed,
    'retries': retries,
    'continuesUsed': continuesUsed,
    'remainingHints': remainingHints,
    'correctStreak': correctStreak,
    'maxCombo': maxCombo,
    'totalMoves': totalMoves,
    'correctMoves': correctMoves,
    'noteUsageCount': noteUsageCount,
    'advancedNotesEnabled': advancedNotesEnabled,
    'advancedNotesUnlockedForRun': advancedNotesUnlockedForRun,
    'cellTimeMs': cellTimeMs.map((k, v) => MapEntry(k.toString(), v)),
    'manualNotes': manualNotes?.map((k, v) => MapEntry(k.toString(), v.toList())),
    'completedWithAutocomplete': completedWithAutocomplete,
    'autoCompleteUsed': autoCompleteUsed,
    'savedAt': savedAt.toIso8601String(),
  };

  factory GlobalSavedGame.fromJson(Map<String, dynamic> json) {
    return GlobalSavedGame(
      difficulty: json['difficulty'] as String,
      boardId: json['boardId'] as String,
      initialBoard: (json['initialBoard'] as List).cast<int>(),
      currentBoard: (json['currentBoard'] as List).cast<int>(),
      solution: (json['solution'] as List).cast<int>(),
      fixedCells: Set<int>.from((json['fixedCells'] as List).cast<int>()),
      notes: (json['notes'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), Set<int>.from((v as List).cast<int>())),
      ),
      mistakes: json['mistakes'] as int,
      elapsedSeconds: json['elapsedSeconds'] as int,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      retries: json['retries'] as int? ?? 0,
      continuesUsed: json['continuesUsed'] as int? ?? 0,
      remainingHints: json['remainingHints'] as int? ?? 3,
      correctStreak: json['correctStreak'] as int? ?? 0,
      maxCombo: json['maxCombo'] as int? ?? 0,
      totalMoves: json['totalMoves'] as int? ?? 0,
      correctMoves: json['correctMoves'] as int? ?? 0,
      noteUsageCount: json['noteUsageCount'] as int? ?? 0,
      advancedNotesEnabled: json['advancedNotesEnabled'] as bool? ?? false,
      advancedNotesUnlockedForRun: json['advancedNotesUnlockedForRun'] as bool? ?? false,
      cellTimeMs: (json['cellTimeMs'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(int.parse(k), v as int)),
      manualNotes: (json['manualNotes'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(int.parse(k), Set<int>.from((v as List).cast<int>()))),
      completedWithAutocomplete: json['completedWithAutocomplete'] as bool? ?? false,
      autoCompleteUsed: json['autoCompleteUsed'] as int? ?? 0,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

class GlobalSaveStorage {
  static const _key = 'global_manual_save';

  static Future<GlobalSavedGame?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return GlobalSavedGame.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  static Future<void> save(GlobalSavedGame game) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(game.toJson()));
  }

  static Future<bool> exists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  static Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final globalSavedGameProvider = FutureProvider<GlobalSavedGame?>((ref) {
  return GlobalSaveStorage.load();
});
