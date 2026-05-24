import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../application/game_provider.dart';
import '../domain/game_state.dart';
import '../domain/game_session_context.dart';
import '../../progression/application/progression_provider.dart';
import '../../progression/domain/player_level.dart';
import '../../progression/domain/xp_calculator.dart';
import '../../campaign/domain/campaign_level.dart';

class VictoryScreen extends ConsumerWidget {
  final String difficulty;

  const VictoryScreen({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final playerLevel = ref.watch(playerLevelProvider);
    final isAutocomplete = state.completedWithAutocomplete;

    final victoryType = _victoryType(state);
    final accentColor = _accentColor(victoryType);
    final xpResult = XpCalculator.compute(state);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _HeaderHero(
                    victoryType: victoryType,
                    accentColor: accentColor,
                    isAutocomplete: isAutocomplete,
                    xpResult: xpResult,
                  ).animate().fade(duration: 600.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  _XpBar(
                    playerLevel: playerLevel,
                    xpResult: xpResult,
                    accentColor: accentColor,
                  ).animate().fade(delay: 200.ms, duration: 400.ms).slideX(begin: 0.1),

                  const SizedBox(height: 20),

                  _StatsGrid(state: state).animate().fade(delay: 400.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  _HeatmapSummary(
                    cellTimeMs: state.cellTimeMs,
                    session: state.session,
                    accentColor: accentColor,
                  ).animate().fade(delay: 600.ms, duration: 400.ms),

                  const SizedBox(height: 28),

                  _ActionButtons(difficulty: difficulty).animate().fade(delay: 800.ms, duration: 400.ms).slideY(begin: 0.2),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _victoryType(GameState state) {
    if (state.completedWithAutocomplete) return 'autocomplete';
    if (state.errors == 0 && state.usedHints == 0) return 'perfect';
    if (state.usedHints > 0) return 'hint';
    if (state.errors > 0) return 'fails';
    return 'victory';
  }

  Color _accentColor(String type) {
    switch (type) {
      case 'perfect': return const Color(0xFFD7B45A);
      case 'hint': return Colors.blueAccent;
      case 'fails': return Colors.orangeAccent;
      case 'autocomplete': return Colors.lightBlueAccent;
      default: return Colors.greenAccent;
    }
  }
}

// ── Header Hero ─────────────────────────────────────────────────────────────

class _HeaderHero extends StatelessWidget {
  final String victoryType;
  final Color accentColor;
  final bool isAutocomplete;
  final XpResult xpResult;

  const _HeaderHero({required this.victoryType, required this.accentColor, required this.isAutocomplete, required this.xpResult});

  @override
  Widget build(BuildContext context) {
    final icon = switch (victoryType) {
      'perfect' => Icons.auto_awesome,
      'hint' => Icons.lightbulb,
      'fails' => Icons.warning_amber,
      'autocomplete' => Icons.auto_fix_high,
      _ => Icons.celebration,
    };

    final title = switch (victoryType) {
      'perfect' => '¡VICTORIA PERFECTA!',
      'hint' => 'VICTORIA',
      'fails' => '¡SUPERADO!',
      'autocomplete' => 'COMPLETADO',
      _ => 'VICTORIA',
    };

    final subtitle = switch (victoryType) {
      'perfect' => 'Sin errores, sin pistas',
      'hint' => 'Completado con pistas',
      'fails' => '¡Lo lograste a pesar de los errores!',
      'autocomplete' => 'Completado con auto complete',
      _ => 'Sudoku resuelto',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.2),
            accentColor.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: accentColor),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: accentColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white60)),
          const SizedBox(height: 20),
          // XP breakdown
          _XpBreakdown(xpResult: xpResult, accentColor: accentColor),
        ],
      ),
    );
  }
}

// ── XP Breakdown ─────────────────────────────────────────────────────────────

class _XpBreakdown extends StatelessWidget {
  final XpResult xpResult;
  final Color accentColor;

  const _XpBreakdown({required this.xpResult, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final items = <_BreakdownLine>[
      _BreakdownLine('${xpResult.difficulty.toUpperCase()} — Base', '', xpResult.base),
    ];

    if (xpResult.perfectBonus > 0) {
      items.add(_BreakdownLine('Perfect Victory', '+40%', xpResult.perfectBonus));
    }
    if (xpResult.flawlessBonus > 0) {
      items.add(_BreakdownLine('Flawless+', '+25%', xpResult.flawlessBonus));
    }
    if (xpResult.speedBonus > 0) {
      items.add(_BreakdownLine('Velocidad', '', xpResult.speedBonus));
    }
    if (xpResult.comboBonus > 0) {
      items.add(_BreakdownLine('Combo', '', xpResult.comboBonus));
    }
    if (xpResult.completionBonus > 0) {
      items.add(_BreakdownLine('Finalización', '', xpResult.completionBonus));
    }
    if (xpResult.hintPenalty > 0) {
      items.add(_BreakdownLine('Pistas', '-${(xpResult.hintsUsed * 15)}%', -xpResult.hintPenalty));
    }
    if (xpResult.failPenalty > 0) {
      items.add(_BreakdownLine('Errores', '-20%', -xpResult.failPenalty));
    }
    if (xpResult.autoCompletePenalty > 0) {
      items.add(_BreakdownLine('Auto Complete', '-35%', -xpResult.autoCompletePenalty));
    }

    items.add(_BreakdownLine('', '', 0, isDivider: true));
    items.add(_BreakdownLine(
      'TOTAL XP',
      xpResult.capped ? 'CAP ${xpResult.maxCap}' : '',
      xpResult.total,
      isTotal: true,
      accentColor: accentColor,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items.map((line) => _buildLine(line)).toList(),
    );
  }

  Widget _buildLine(_BreakdownLine line) {
    if (line.isDivider) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: Colors.white12, height: 1),
      );
    }

    final color = line.isTotal
        ? line.accentColor ?? Colors.white
        : line.amount >= 0
            ? Colors.white70
            : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(line.label, style: TextStyle(fontSize: 12, color: color, fontWeight: line.isTotal ? FontWeight.bold : FontWeight.normal)),
          if (line.tag.isNotEmpty)
            Text(line.tag,
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.5))),
          const Spacer(),
          Text(
            line.amount >= 0 ? '+${line.amount} XP' : '${line.amount} XP',
            style: TextStyle(fontSize: 13, color: color, fontWeight: line.isTotal ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}

class _BreakdownLine {
  final String label;
  final String tag;
  final int amount;
  final bool isDivider;
  final bool isTotal;
  final Color? accentColor;

  const _BreakdownLine(this.label, this.tag, this.amount,
      {this.isDivider = false, this.isTotal = false, this.accentColor});
}

// ── XP Bar ─────────────────────────────────────────────────────────────────

class _XpBar extends StatelessWidget {
  final PlayerLevel playerLevel;
  final XpResult xpResult;
  final Color accentColor;

  const _XpBar({required this.playerLevel, required this.xpResult, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NIVEL ${playerLevel.level}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2)),
                  Text(playerLevel.title,
                      style: TextStyle(fontSize: 11, color: accentColor.withValues(alpha: 0.7))),
                ],
              ),
              Text('+${xpResult.total} XP',
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: playerLevel.progress),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('${playerLevel.currentXp} / ${playerLevel.xpForNext} XP',
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }
}

// ── Stats Grid ──────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final GameState state;
  const _StatsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final accuracy =
        state.totalMoves == 0 ? 1.0 : state.correctMoves / state.totalMoves;
    final avgSpeed = state.elapsedSeconds == 0
        ? 0.0
        : (81 - (state.session?.currentBoard.where((v) => v == 0).length ?? 0)) /
            state.elapsedSeconds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RESULTADO',
              style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white54)),
          const SizedBox(height: 12),
          _statRow('Tiempo total', _fmtTime(state.elapsedSeconds)),
          _statRow('Precisión', '${(accuracy * 100).toStringAsFixed(1)}%'),
          _statRow('Errores', '${state.errors}'),
          _statRow('Pistas usadas', '${state.usedHints}'),
          _statRow('Racha máxima', '${state.maxCombo}'),
          _statRow('Auto Complete', state.completedWithAutocomplete ? 'Sí' : 'No'),
          _statRow('Celdas completadas',
              '${81 - (state.session?.currentBoard.where((v) => v == 0).length ?? 0)}'),
          _statRow('Velocidad promedio', '${avgSpeed.toStringAsFixed(2)} celdas/s'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _fmtTime(int seconds) {
    if (seconds <= 0) return '-';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

// ── Board Dimension-Aware Heatmap Summary ─────────────────────────────────────

class BoardDimensionAwareHeatmap extends StatelessWidget {
  final Map<int, int> cellTimeMs;
  final dynamic session;
  final Color accentColor;

  const BoardDimensionAwareHeatmap(
      {required this.cellTimeMs, required this.session, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    if (cellTimeMs.isEmpty) return const SizedBox.shrink();

    final config = session?.config;
    final boardSize = config?.boardSize ?? 9;
    final totalCells = boardSize * boardSize;

    if (totalCells <= 0 || totalCells > 81) {
      return const SizedBox.shrink();
    }

    final maxTime = cellTimeMs.values.reduce((a, b) => a > b ? a : b);
    final errorIndices = <int>{};
    if (session != null) {
      for (var i = 0; i < totalCells; i++) {
        if (i < session.currentBoard.length &&
            session.currentBoard[i] != 0 &&
            i < session.solution.length &&
            session.currentBoard[i] != session.solution[i]) {
          errorIndices.add(i);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('HEATMAP',
                  style:
                      TextStyle(fontSize: 12, letterSpacing: 2, color: accentColor)),
              const Spacer(),
              _legendDot(Colors.greenAccent, 'Rápido'),
              const SizedBox(width: 8),
              _legendDot(Colors.orangeAccent, 'Lento'),
              const SizedBox(width: 8),
              _legendDot(Colors.redAccent, 'Error'),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: boardSize,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
            children: List.generate(totalCells, (i) {
              final timeMs = cellTimeMs[i] ?? 0;
              final hasError = errorIndices.contains(i);
              final intensity = maxTime > 0 ? timeMs / maxTime : 0.0;

              Color color;
              if (hasError) {
                color = Colors.redAccent.withValues(alpha: 0.4);
              } else if (intensity > 0.7) {
                color = Colors.orangeAccent.withValues(alpha: intensity * 0.5);
              } else if (intensity > 0.3) {
                color = Colors.amber.withValues(alpha: intensity * 0.4);
              } else {
                color =
                    Colors.greenAccent.withValues(alpha: 0.1 + intensity * 0.3);
              }

              return Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  border: hasError
                      ? Border.all(color: Colors.redAccent.withValues(alpha: 0.6))
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
      ],
    );
  }
}

// ── Old Heatmap — now delegates to BoardDimensionAwareHeatmap ─────────────────

class _HeatmapSummary extends StatelessWidget {
  final Map<int, int> cellTimeMs;
  final dynamic session;
  final Color accentColor;

  const _HeatmapSummary(
      {required this.cellTimeMs, required this.session, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return BoardDimensionAwareHeatmap(
      cellTimeMs: cellTimeMs,
      session: session,
      accentColor: accentColor,
    );
  }
}

// ── Action Buttons ─────────────────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final String difficulty;
  const _ActionButtons({required this.difficulty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final ctx = notifier.currentContext;
    final isCampaign = ctx?.mode == GameMode.campaign;
    final isDaily = ctx?.mode == GameMode.daily;
    final isCampaignOrDaily = isCampaign || isDaily;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('REPLAY',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            onPressed: () {
              notifier.restartCurrentBoard();
              if (isCampaign) {
                final level = ctx!.progress!;
                final variant = CampaignStage.fromLevel(level).variant.name;
                context.pushReplacement('/campaign-game', extra: {'level': level, 'variant': variant});
              } else {
                context.pushReplacement('/game', extra: difficulty);
              }
            },
          ),
        ),
        if (!isCampaignOrDaily) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.skip_next, size: 18),
              label: const Text('SIGUIENTE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
              ),
              onPressed: () {
                context.pushReplacement('/game', extra: difficulty);
              },
            ),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.menu, size: 18),
            label: Text(isCampaign ? 'CAMPAÑA' : 'MENÚ',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            onPressed: () {
              if (isCampaignOrDaily) {
                context.pop();
                context.pop();
              } else {
                context.pop();
                context.pop();
              }
            },
          ),
        ),
      ],
    );
  }
}
