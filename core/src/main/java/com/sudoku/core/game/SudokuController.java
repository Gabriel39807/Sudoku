package com.sudoku.core.game;

import com.sudoku.core.difficulty.Difficulty;
import com.sudoku.core.generator.GeneratedPuzzle;
import com.sudoku.core.generator.SudokuGenerator;
import com.sudoku.core.save.SaveManager;
import com.sudoku.core.stats.StatsManager;

public final class SudokuController {
    private final SudokuGenerator generator;
    private final SaveManager saveManager;
    private final StatsManager statsManager;
    private GameState state;

    public SudokuController(SudokuGenerator generator, SaveManager saveManager, StatsManager statsManager) {
        this.generator = generator; this.saveManager = saveManager; this.statsManager = statsManager;
    }
    public GameState state() { return state; }
    public void newGame(Difficulty difficulty) {
        GeneratedPuzzle p = generator.generate(difficulty);
        state = new GameState(SudokuBoard.from(p.puzzle(), p.solution()), difficulty);
        saveManager.saveGame(state);
    }
    public boolean resumeSavedGame() { state = saveManager.loadGame(); return state != null; }
    public void select(int row, int col) { if (playing()) state.select(row, col); }
    public void togglePencil() { if (playing()) state.setPencilMode(!state.pencilMode()); }
    public void erase() { if (playing() && selected()) { state.board().cell(state.selectedRow(), state.selectedCol()).clear(); saveManager.saveGame(state); } }
    public void pause() { if (state != null && state.status() == GameStatus.PLAYING) { state.setStatus(GameStatus.PAUSED); saveManager.saveGame(state); } }
    public void resumePause() { if (state != null && state.status() == GameStatus.PAUSED) state.setStatus(GameStatus.PLAYING); }
    public void input(int value) {
        if (!playing() || !selected() || value < 1 || value > 9) return;
        SudokuCell cell = state.board().cell(state.selectedRow(), state.selectedCol());
        if (cell.fixed()) return;
        if (state.pencilMode()) { cell.toggleNote(value); saveManager.saveGame(state); return; }
        cell.setValue(value);
        if (value != cell.solution()) {
            state.addError();
            if (state.difficulty().isPermadeath() || state.errors() > state.difficulty().maxErrors()) lose();
        } else if (state.board().isSolved()) win();
        saveManager.saveGame(state);
    }
    public void update(float delta) { if (playing()) state.tick(delta); }
    private void win() {
        state.setStatus(GameStatus.WON);
        statsManager.recordWin(state.difficulty(), state.elapsedSeconds(), state.errors() == 0);
        saveManager.clearGame();
    }
    private void lose() {
        state.setStatus(GameStatus.LOST);
        statsManager.recordLoss(state.difficulty(), state.elapsedSeconds());
        saveManager.clearGame();
    }
    private boolean selected() { return state.selectedRow() >= 0 && state.selectedCol() >= 0; }
    private boolean playing() { return state != null && state.status() == GameStatus.PLAYING; }
}
