import '../../../features/game/domain/game_session_context.dart';

extension GameModeX on GameMode {
  bool get isClassic => this == GameMode.normal || this == GameMode.savedGame;
  bool get isCampaign => this == GameMode.campaign;
  bool get isDaily => this == GameMode.daily;
}

class GameResult {
  final GameMode mode;
  final String difficulty;
  final bool won;
  final int mistakes;
  final int elapsedSeconds;
  final int hintsUsed;
  final int maxCombo;
  final bool perfect;
  final bool completedWithAutocomplete;
  final int totalNoteUsage;
  final int xpEarned;
  final String? boardId;
  final int? campaignLevel;
  final int? campaignStars;
  final bool? isCampaignBoss;

  const GameResult({
    required this.mode,
    required this.difficulty,
    required this.won,
    required this.mistakes,
    required this.elapsedSeconds,
    required this.hintsUsed,
    required this.maxCombo,
    required this.perfect,
    this.completedWithAutocomplete = false,
    this.totalNoteUsage = 0,
    this.xpEarned = 0,
    this.boardId,
    this.campaignLevel,
    this.campaignStars,
    this.isCampaignBoss,
  });
}
