package com.sudoku.core.game;

import com.sudoku.core.difficulty.Difficulty;

public final class GameState {
    private SudokuBoard board;
    private Difficulty difficulty;
    private GameStatus status = GameStatus.PLAYING;
    private boolean pencilMode;
    private int selectedRow = -1, selectedCol = -1, errors;
    private float elapsedSeconds;

    public GameState() {}
    public GameState(SudokuBoard board, Difficulty difficulty) { this.board = board; this.difficulty = difficulty; }
    public SudokuBoard board() { return board; }
    public Difficulty difficulty() { return difficulty; }
    public GameStatus status() { return status; }
    public boolean pencilMode() { return pencilMode; }
    public int selectedRow() { return selectedRow; }
    public int selectedCol() { return selectedCol; }
    public int errors() { return errors; }
    public long elapsedSeconds() { return (long) elapsedSeconds; }
    public void setStatus(GameStatus status) { this.status = status; }
    public void setPencilMode(boolean pencilMode) { this.pencilMode = pencilMode; }
    public void select(int row, int col) { selectedRow = row; selectedCol = col; }
    public void addError() { errors++; }
    public void setErrors(int errors) { this.errors = errors; }
    public void tick(float delta) { if (status == GameStatus.PLAYING) elapsedSeconds += delta; }
    public void setElapsedSeconds(long elapsedSeconds) { this.elapsedSeconds = elapsedSeconds; }
}
