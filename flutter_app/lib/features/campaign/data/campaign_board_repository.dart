import 'dart:developer' as dev;
import '../../game/data/board_repository_v2.dart';
import '../domain/campaign_level.dart';
import '../domain/sudoku_variant.dart';

class CampaignBoardRepository {
  static Future<BoardData> loadBoard(int level, SudokuVariant variant) async {
    final stage = CampaignStage.fromLevel(level);
    final levelIndex = level - stage.levelStart + 1;

    dev.log('[CampaignRepo] Loading level $level (stage ${stage.datasetStage}, index $levelIndex)');

    return BoardRepositoryV2.loadCampaignBoard(stage.datasetStage, levelIndex);
  }
}
