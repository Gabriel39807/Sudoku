import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../domain/campaign_level.dart';
import '../../game/application/game_provider.dart';
import '../../../ui/currency/currency_widget.dart';
import '../../../ui/currency/currency_type.dart';

class CampaignLevelCompleteCard extends ConsumerStatefulWidget {
  final int level;
  final int elapsedSeconds;
  final int mistakes;

  const CampaignLevelCompleteCard({
    super.key,
    required this.level,
    required this.elapsedSeconds,
    required this.mistakes,
  });

  @override
  ConsumerState<CampaignLevelCompleteCard> createState() => _CampaignLevelCompleteCardState();
}

class _CampaignLevelCompleteCardState extends ConsumerState<CampaignLevelCompleteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  int get _stars {
    final stage = CampaignStage.fromLevel(widget.level);
    final variant = stage.variant;
    final maxTime = switch (variant.boardSize) { 4 => 60, 6 => 180, 8 => 300, _ => 600 };
    var stars = 3;
    if (widget.mistakes > 0) stars--;
    if (widget.elapsedSeconds > maxTime) stars--;
    return stars.clamp(1, 3);
  }

  @override
  Widget build(BuildContext context) {
    final stage = CampaignStage.fromLevel(widget.level);
    final variant = stage.variant;
    final nextLevel = widget.level + 1;
    final isLast = nextLevel > stage.levelEnd;
    final canContinue = !isLast;

    return Material(
      color: Colors.black87,
      child: Center(
        child: FadeTransition(
          opacity: _animCtrl,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 5),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stars
                    _StarsRow(stars: _stars),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      '¡NIVEL ${widget.level} COMPLETADO!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${variant.boardSize}x${variant.boardSize}',
                      style: const TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                    const SizedBox(height: 24),
                    // Rewards row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RewardChip(type: CurrencyType.souls, amount: 1).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.3),
                        const SizedBox(width: 16),
                        RewardChip(type: CurrencyType.tokens, amount: 1).animate().fade(delay: 300.ms, duration: 400.ms).slideY(begin: 0.3),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Stats
                    _statLine('Tiempo', _fmtTime(widget.elapsedSeconds)),
                    _statLine('Errores', '${widget.mistakes}'),
                    const SizedBox(height: 28),
                    // CONTINUE button
                    if (canContinue)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 8,
                          ),
                          child: const Text('CONTINUAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                        ),
                      ),
                    if (!canContinue) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onHome,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 8,
                          ),
                          child: const Text('¡STAGE COMPLETO!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onRepeat,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Text('REPETIR', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onHome,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Text('HOME', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onContinue() {
    if (!mounted) return;
    ref.read(gameProvider.notifier).abandonGame();
    final nextLevel = widget.level + 1;
    final stage = CampaignStage.fromLevel(nextLevel);
    context.pushReplacement('/campaign-game', extra: {'level': nextLevel, 'variant': stage.variant.name});
  }

  void _onRepeat() {
    if (!mounted) return;
    ref.read(gameProvider.notifier).abandonGame();
    final stage = CampaignStage.fromLevel(widget.level);
    context.pushReplacement('/campaign-game', extra: {'level': widget.level, 'variant': stage.variant.name});
  }

  void _onHome() {
    if (!mounted) return;
    ref.read(gameProvider.notifier).abandonGame();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _fmtTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _statLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white54)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  final int stars;
  const _StarsRow({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            size: 36,
            color: filled ? Colors.amber : Colors.white24,
          ).animate().scale(
            delay: (i * 150).ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
        );
      }),
    );
  }
}

class RewardChip extends StatelessWidget {
  final CurrencyType type;
  final int amount;
  const RewardChip({super.key, required this.type, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: CurrencyWidget(type: type, amount: amount, size: 18, showLabel: true),
    );
  }
}
