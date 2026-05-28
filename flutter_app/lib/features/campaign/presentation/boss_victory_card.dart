import 'package:flutter/material.dart';
import 'campaign_level_complete_card.dart';

/// Legacy wrapper — delegates to [CampaignLevelCompleteCard].
/// Boss visuals are handled internally by the card based on the level.
class BossVictoryCard extends StatelessWidget {
  final int level;
  final int elapsedSeconds;
  final int mistakes;

  const BossVictoryCard({
    super.key,
    required this.level,
    required this.elapsedSeconds,
    required this.mistakes,
  });

  @override
  Widget build(BuildContext context) {
    return CampaignLevelCompleteCard(
      level: level,
      elapsedSeconds: elapsedSeconds,
      mistakes: mistakes,
    );
  }
}
