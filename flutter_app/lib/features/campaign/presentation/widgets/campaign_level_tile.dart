import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/campaign_level.dart';
import '../../domain/campaign_progress.dart';

class CampaignLevelTile extends StatelessWidget {
  final int level;
  final CampaignStage stage;
  final bool unlocked;
  final CampaignLevelResult? result;
  final VoidCallback onTap;

  const CampaignLevelTile({
    super.key,
    required this.level,
    required this.stage,
    required this.unlocked,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = result?.completed ?? false;
    final stars = result?.stars ?? 0;
    final isFirstInStage = level == stage.levelStart;

    final color = completed
        ? Colors.greenAccent
        : unlocked
            ? Theme.of(context).primaryColor
            : Colors.white24;

    return Padding(
      padding: EdgeInsets.only(top: isFirstInStage ? 24 : 8, left: 16, right: 16),
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked ? color.withValues(alpha: 0.4) : Colors.white10,
            ),
            color: completed
                ? Colors.greenAccent.withValues(alpha: 0.06)
                : unlocked
                    ? color.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.02),
          ),
          child: Row(
            children: [
              _buildStarBadge(stars, completed, color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'NIVEL $level',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: unlocked ? Colors.white : Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(completed, result),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              if (completed)
                const Icon(Icons.check_circle, size: 20, color: Colors.greenAccent),
              if (!unlocked)
                const Icon(Icons.lock, size: 18, color: Colors.white24),
              if (unlocked && !completed)
                Icon(Icons.play_arrow, size: 20, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarBadge(int stars, bool completed, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed
            ? Colors.greenAccent.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.1),
        border: Border.all(
          color: completed ? Colors.greenAccent.withValues(alpha: 0.3) : color.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: completed
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => Text(
                  i < stars ? '⭐' : '☆',
                  style: const TextStyle(fontSize: 9),
                )),
              )
            : Text(
                level.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: unlocked ? Colors.white : Colors.white24,
                ),
              ),
      ),
    );
  }

  String _subtitle(bool completed, CampaignLevelResult? result) {
    if (completed && result != null) {
      final timeStr = _fmtTime(result.bestTimeSeconds);
      return '$timeStr · ${result.bestMistakes} errores · ${result.attempts} intentos';
    }
    if (result == null) return 'Sin jugar';
    return '${result.attempts} intentos';
  }

  String _fmtTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}
