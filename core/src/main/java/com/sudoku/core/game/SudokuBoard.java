package com.sudoku.core.game;

public final class SudokuBoard {
    public static final int SIZE = 9;
    private final SudokuCell[][] cells = new SudokuCell[SIZE][SIZE];

    public SudokuBoard() {
        for (int r = 0; r < SIZE; r++) for (int c = 0; c < SIZE; c++) cells[r][c] = new SudokuCell();
    }
    public SudokuCell cell(int row, int col) { validate(row, col); return cells[row][col]; }
    public boolean isSolved() {
        for (int r = 0; r < SIZE; r++) for (int c = 0; c < SIZE; c++)
            if (cells[r][c].value() != cells[r][c].solution()) return false;
        return true;
    }
    public boolean sameHouse(int r1, int c1, int r2, int c2) {
        return r1 == r2 || c1 == c2 || (r1 / 3 == r2 / 3 && c1 / 3 == c2 / 3);
    }
    public int[][] values() {
        int[][] out = new int[SIZE][SIZE];
        for (int r = 0; r < SIZE; r++) for (int c = 0; c < SIZE; c++) out[r][c] = cells[r][c].value();
        return out;
    }
    public int[][] solutions() {
        int[][] out = new int[SIZE][SIZE];
        for (int r = 0; r < SIZE; r++) for (int c = 0; c < SIZE; c++) out[r][c] = cells[r][c].solution();
        return out;
    }
    public static SudokuBoard from(int[][] puzzle, int[][] solution) {
        SudokuBoard b = new SudokuBoard();
        for (int r = 0; r < SIZE; r++) for (int c = 0; c < SIZE; c++) {
            int v = puzzle[r][c];
            SudokuCell cell = b.cell(r, c);
            cell.setSolution(solution[r][c]);
            cell.restoreValue(v);
            cell.setFixed(v != 0);
        }
        return b;
    }
    private void validate(int row, int col) {
        if (row < 0 || row >= SIZE || col < 0 || col >= SIZE) throw new IllegalArgumentException("Cell outside 9x9 board");
    }
}
