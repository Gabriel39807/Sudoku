package com.sudoku.core.save;

import com.sudoku.core.difficulty.Difficulty;
import com.sudoku.core.game.GameState;
import com.sudoku.core.game.SudokuBoard;
import com.sudoku.core.game.SudokuCell;
import java.util.ArrayList;

public final class GameSaveData {
    public Difficulty difficulty;
    public int errors;
    public long elapsedSeconds;
    public int[][] values;
    public int[][] solutions;
    public boolean[][] fixed;
    public ArrayList<Integer>[][] notes;

    @SuppressWarnings("unchecked")
    public static GameSaveData from(GameState state) {
        GameSaveData d = new GameSaveData();
        d.difficulty = state.difficulty();
        d.errors = state.errors();
        d.elapsedSeconds = state.elapsedSeconds();
        d.values = state.board().values();
        d.solutions = state.board().solutions();
        d.fixed = new boolean[9][9];
        d.notes = new ArrayList[9][9];
        for (int r = 0; r < 9; r++) for (int c = 0; c < 9; c++) {
            SudokuCell cell = state.board().cell(r, c);
            d.fixed[r][c] = cell.fixed();
            d.notes[r][c] = new ArrayList<>(cell.notes());
        }
        return d;
    }
    public GameState toState() {
        SudokuBoard board = SudokuBoard.from(values, solutions);
        for (int r = 0; r < 9; r++) for (int c = 0; c < 9; c++) {
            board.cell(r, c).setFixed(fixed[r][c]);
            if (notes != null && notes[r][c] != null) for (Integer n : notes[r][c]) board.cell(r, c).toggleNote(n);
        }
        GameState state = new GameState(board, difficulty);
        state.setErrors(errors);
        state.setElapsedSeconds(elapsedSeconds);
        return state;
    }
}
