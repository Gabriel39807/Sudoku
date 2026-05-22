import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/game_state.dart';
import '../../application/game_provider.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../cosmetics/domain/frame_skin.dart';
import '../../../cosmetics/application/cosmetic_inventory_provider.dart';
import '../../../settings/application/settings_provider.dart';

class SudokuBoardWidget extends ConsumerStatefulWidget {
  const SudokuBoardWidget({super.key});

  @override
  ConsumerState<SudokuBoardWidget> createState() => _SudokuBoardWidgetState();
}

class _SudokuBoardWidgetState extends ConsumerState<SudokuBoardWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _glowController;
  int _glowRow = -1;
  int _glowCol = -1;
  int _glowBlock = -1;
  StreamSubscription<int>? _rowSub;
  StreamSubscription<int>? _colSub;
  StreamSubscription<int>? _blockSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(gameProvider.notifier);
      _rowSub = notifier.rowCompleted.listen((r) => _triggerGlow(row: r));
      _colSub = notifier.colCompleted.listen((c) => _triggerGlow(col: c));
      _blockSub = notifier.blockCompleted.listen((b) => _triggerGlow(block: b));
    });
  }

  @override
  void dispose() {
    _rowSub?.cancel();
    _colSub?.cancel();
    _blockSub?.cancel();
    _glowController?.dispose();
    super.dispose();
  }

  void _triggerGlow({int? row, int? col, int? block}) {
    _glowController?.dispose();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    setState(() {
      _glowRow = row ?? -1;
      _glowCol = col ?? -1;
      _glowBlock = block ?? -1;
    });
    _glowController!.forward().then((_) {
      if (mounted) {
        setState(() {
          _glowRow = -1;
          _glowCol = -1;
          _glowBlock = -1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final cosmetics = ref.watch(cosmeticsProvider);
    final inventory = ref.watch(cosmeticInventoryProvider);
    final settings = ref.watch(settingsProvider);

    final bgPath = inventory.equippedAssetPath ?? cosmetics.selectedTheme.backgroundPath;

    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final boardSize = (shortest * 0.89).clamp(320.0, 520.0);
    final cellSize = boardSize / 9;
    final frameThickness = (boardSize * 0.07).clamp(24.0, 48.0);
    final cornerSize = frameThickness * 1.3;

    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                bgPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          _buildFrame(cosmetics.selectedFrame, frameThickness, cornerSize),
          Padding(
            padding: EdgeInsets.all(frameThickness),
            child:           _buildGrid(state, cellSize, settings.boardAnimations),
          ),
        ],
      ),
    );
  }

  Widget _buildFrame(FrameSkin frame, double ft, double cs) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildSides(frame, ft),
        _buildCorners(frame, cs),
        _buildOrnaments(frame, ft),
      ],
    );
  }

  Widget _buildSides(FrameSkin frame, double ft) {
    return Stack(
      children: [
        Positioned(top: 0, left: ft, right: ft, child: Image.asset(frame.edges.top, height: ft, fit: BoxFit.fill)),
        Positioned(bottom: 0, left: ft, right: ft, child: Image.asset(frame.edges.bottom, height: ft, fit: BoxFit.fill)),
        Positioned(left: 0, top: ft, bottom: ft, child: Image.asset(frame.edges.left, width: ft, fit: BoxFit.fill)),
        Positioned(right: 0, top: ft, bottom: ft, child: Image.asset(frame.edges.right, width: ft, fit: BoxFit.fill)),
      ],
    );
  }

  Widget _buildCorners(FrameSkin frame, double cs) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(top: 0, left: 0, child: Image.asset(frame.corners.tl, width: cs, height: cs)),
        Positioned(top: 0, right: 0, child: Image.asset(frame.corners.tr, width: cs, height: cs)),
        Positioned(bottom: 0, left: 0, child: Image.asset(frame.corners.bl, width: cs, height: cs)),
        Positioned(bottom: 0, right: 0, child: Image.asset(frame.corners.br, width: cs, height: cs)),
      ],
    );
  }

  Widget _buildOrnaments(FrameSkin frame, double ft) {
    return Stack(
      children: [
        Positioned(top: 0, left: 0, right: 0, child: Center(child: Image.asset(frame.decorations.topCenter, width: ft, height: ft))),
        Positioned(bottom: 0, left: 0, right: 0, child: Center(child: Image.asset(frame.decorations.bottomCenter, width: ft, height: ft))),
        Positioned(left: 0, top: 0, bottom: 0, child: Center(child: Image.asset(frame.decorations.leftCenter, width: ft, height: ft))),
        Positioned(right: 0, top: 0, bottom: 0, child: Center(child: Image.asset(frame.decorations.rightCenter, width: ft, height: ft))),
      ],
    );
  }

  Widget _buildGrid(GameState state, double cellSize, bool boardAnimations) {
    final thick = cellSize * 0.08;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2B2B2B), width: thick),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(
          children: List.generate(9, (r) {
            return Expanded(
              child: Row(
                children: List.generate(9, (c) {
                  return Expanded(
                    child: _CellWidget(
                      cell: state.board[r][c],
                      gameState: state,
                      cellSize: cellSize,
                      boardAnimations: boardAnimations,
                      isInGlowRow: r == _glowRow,
                      isInGlowCol: c == _glowCol,
                      isInGlowBlock: (r ~/ 3) * 3 + (c ~/ 3) == _glowBlock,
                      glowProgress: _glowController?.drive(
                        CurveTween(curve: Curves.easeOut),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _CellWidget extends ConsumerWidget {
  final SudokuCell cell;
  final GameState gameState;
  final double cellSize;
  final bool boardAnimations;
  final bool isInGlowRow;
  final bool isInGlowCol;
  final bool isInGlowBlock;
  final Animation<double>? glowProgress;

  const _CellWidget({
    required this.cell,
    required this.gameState,
    required this.cellSize,
    required this.boardAnimations,
    this.isInGlowRow = false,
    this.isInGlowCol = false,
    this.isInGlowBlock = false,
    this.glowProgress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = gameState.selectedRow == cell.row &&
        gameState.selectedCol == cell.col;

    final hasSelection =
        gameState.selectedRow != null && gameState.selectedCol != null;
    final selectedCell = hasSelection
        ? gameState.board[gameState.selectedRow!][gameState.selectedCol!]
        : null;

    final isSameRow = hasSelection && gameState.selectedRow == cell.row;
    final isSameCol = hasSelection && gameState.selectedCol == cell.col;
    final isSameBlock = hasSelection &&
        (gameState.selectedRow! ~/ 3) == (cell.row ~/ 3) &&
        (gameState.selectedCol! ~/ 3) == (cell.col ~/ 3);

    final lockNum = gameState.lockedNumber;
    final isSameNumber = lockNum != null
        ? (cell.value != 0 && lockNum == cell.value)
        : (hasSelection && !selectedCell!.isEmpty && selectedCell.value == cell.value);

    final settings = ref.watch(settingsProvider);

    bool shouldHighlightHouse = false;
    if (settings.highlightSameNumbers) {
      if (isSameRow || isSameCol) {
        shouldHighlightHouse = true;
      } else if (isSameBlock && settings.highlightRegion) {
        shouldHighlightHouse = true;
      }
    }

    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = const Color(0xFF7A5FFF);
    } else if (cell.isError) {
      bgColor = Colors.red.withValues(alpha: 0.3);
    } else if (settings.highlightSameNumbers && isSameNumber) {
      bgColor = Colors.blueAccent.withValues(alpha: 0.3);
    } else if (shouldHighlightHouse) {
      bgColor = Colors.white.withValues(alpha: 0.05);
    }

    final thick = cellSize * 0.05;
    final thin = cellSize * 0.02;

    final topBorder = (cell.row % 3 == 0 && cell.row != 0) ? thick : thin;
    final leftBorder = (cell.col % 3 == 0 && cell.col != 0) ? thick : thin;
    final borderColor = const Color(0xFF2B2B2B);

    final glowOpacity = glowProgress?.value ?? 0.0;
    final hasGlow = (isInGlowRow || isInGlowCol || isInGlowBlock) &&
        glowOpacity > 0 &&
        cell.value != 0 &&
        !cell.isError;

    Color? glowColor;
    if (hasGlow) {
      glowColor = Color.lerp(
        Colors.transparent,
        const Color(0xFF7A5FFF).withValues(alpha: 0.3),
        glowOpacity * (1 - glowOpacity),
      );
    }

    return GestureDetector(
      onTap: () =>
          ref.read(gameProvider.notifier).selectCell(cell.row, cell.col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: glowColor ?? bgColor,
          border: Border(
            top: BorderSide(color: borderColor, width: topBorder),
            left: BorderSide(color: borderColor, width: leftBorder),
            bottom: BorderSide(color: borderColor, width: thin),
            right: BorderSide(color: borderColor, width: thin),
          ),
        ),
        child: Center(
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (cell.value != 0) {
      return Text(
        cell.value.toString(),
        style: TextStyle(
          fontSize: cellSize * 0.62,
          color: cell.isError
              ? Colors.redAccent
              : cell.isFixed
                  ? Colors.white
                  : const Color(0xFFBCA6FF),
          fontWeight: cell.isFixed ? FontWeight.bold : FontWeight.w500,
        ),
      );
    }

    if (cell.notes.isNotEmpty) {
      final selectedNumber = gameState.lockedNumber;
      return GridView.count(
        crossAxisCount: 3,
        padding: EdgeInsets.all(cellSize * 0.05),
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (i) {
          final n = i + 1;
          if (cell.notes.contains(n)) {
            final isConflict = cell.noteConflict;
            final isHighlighted = selectedNumber == n;
            final noteWidget = Center(
              child: Text(
                n.toString(),
                style: TextStyle(
                  fontSize: cellSize * 0.18,
                  color: isHighlighted
                      ? const Color(0xFFBCA6FF)
                      : isConflict
                          ? Colors.redAccent
                          : Colors.white70,
                  fontWeight:
                      isHighlighted || isConflict ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
            if (boardAnimations) {
              return noteWidget
                  .animate(target: isHighlighted ? 1 : 0)
                  .scaleXY(begin: 1.0, end: 1.1, duration: 150.ms, curve: Curves.easeOut);
            }
            return noteWidget;
          }
          return const SizedBox.shrink();
        }),
      );
    }

    return const SizedBox.shrink();
  }
}
