import '../../game/data/board_repository_v2.dart';

class DailyChallengeService {
  DailyChallengeService._();

  static String? _lastDifficulty;
  static String? _lastBoardId;

  /// The actual difficulty of today's board (e.g. "easy", "mythic").
  static String? get currentDifficulty => _lastDifficulty;
  /// The actual board ID of today's board.
  static String? get currentBoardId => _lastBoardId;

  /// Loads the daily challenge board deterministically based on UTC date.
  static Future<BoardData> loadDailyBoard() async {
    final board = await BoardRepositoryV2.loadDailyBoard(DateTime.now().toUtc());
    _lastDifficulty = board.raw['difficulty'] as String? ?? 'easy';
    _lastBoardId = board.id;
    return board;
  }

  static String get todayDate {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
