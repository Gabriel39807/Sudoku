import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/game_state.dart';
import '../../application/game_provider.dart';

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

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          border: Border.all(color: const Color(0xFF2B2B2B), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: List.generate(9, (r) {
            return Expanded(
              child: Row(
                children: List.generate(9, (c) {
                  return Expanded(
                    child: _CellWidget(
                      cell: state.board[r][c],
                      gameState: state,
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
  final bool isInGlowRow;
  final bool isInGlowCol;
  final bool isInGlowBlock;
  final Animation<double>? glowProgress;

  const _CellWidget({
    required this.cell,
    required this.gameState,
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

    final isSameHouse = isSameRow || isSameCol || isSameBlock;

    final isSameNumber = hasSelection &&
        !selectedCell!.isEmpty &&
        selectedCell.value == cell.value;

    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = const Color(0xFF7A5FFF);
    } else if (cell.isError) {
      bgColor = Colors.red.withValues(alpha: 0.3);
    } else if (isSameNumber) {
      bgColor = Colors.blueAccent.withValues(alpha: 0.3);
    } else if (isSameHouse) {
      bgColor = Colors.white.withValues(alpha: 0.05);
    }

    final topBorder = (cell.row % 3 == 0 && cell.row != 0) ? 4.0 : 1.0;
    final leftBorder = (cell.col % 3 == 0 && cell.col != 0) ? 4.0 : 1.0;
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
            bottom: BorderSide(color: borderColor, width: 1.0),
            right: BorderSide(color: borderColor, width: 1.0),
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
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
      return GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(2),
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (i) {
          final n = i + 1;
          if (cell.notes.contains(n)) {
            return Center(
              child: Text(
                n.toString(),
                style: const TextStyle(fontSize: 8, color: Colors.white54),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      );
    }

    return const SizedBox.shrink();
  }
}
