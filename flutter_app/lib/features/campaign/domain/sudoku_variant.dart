enum SudokuVariant {
  mini4,
  mini6,
  mini8,
  normal9;

  BoardConfig get config => switch (this) {
    SudokuVariant.mini4 => BoardConfig.mini4,
    SudokuVariant.mini6 => BoardConfig.mini6,
    SudokuVariant.mini8 => BoardConfig.mini8,
    SudokuVariant.normal9 => BoardConfig.normal9,
  };

  int get totalCells => config.totalCells;
  int get boardSize => config.boardSize;

  static SudokuVariant fromLevel(int level) {
    if (level <= 50) return SudokuVariant.mini4;
    if (level <= 125) return SudokuVariant.mini6;
    return SudokuVariant.mini8;
  }
}

class BoardConfig {
  final int boardSize;
  final int subgridWidth;
  final int subgridHeight;
  final int digits;

  const BoardConfig({
    required this.boardSize,
    required this.subgridWidth,
    required this.subgridHeight,
    required this.digits,
  });

  int get totalCells => boardSize * boardSize;
  int get blocksPerRow => boardSize ~/ subgridWidth;
  int get blocksPerCol => boardSize ~/ subgridHeight;
  int get totalBlocks => blocksPerRow * blocksPerCol;

  int index(int row, int col) => row * boardSize + col;
  int rowOf(int idx) => idx ~/ boardSize;
  int colOf(int idx) => idx % boardSize;
  int blockRowOf(int row) => row ~/ subgridHeight;
  int blockColOf(int col) => col ~/ subgridWidth;
  int blockOf(int row, int col) => blockRowOf(row) * blocksPerRow + blockColOf(col);

  static const mini4 = BoardConfig(
    boardSize: 4,
    subgridWidth: 2,
    subgridHeight: 2,
    digits: 4,
  );

  static const mini6 = BoardConfig(
    boardSize: 6,
    subgridWidth: 2,
    subgridHeight: 3,
    digits: 6,
  );

  static const mini8 = BoardConfig(
    boardSize: 8,
    subgridWidth: 2,
    subgridHeight: 4,
    digits: 8,
  );

  static const normal9 = BoardConfig(
    boardSize: 9,
    subgridWidth: 3,
    subgridHeight: 3,
    digits: 9,
  );
}
