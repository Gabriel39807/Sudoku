package com.sudoku.core.ui;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.badlogic.gdx.scenes.scene2d.utils.Drawable;
import com.sudoku.core.SudokuGame;
import com.sudoku.core.game.GameState;
import com.sudoku.core.game.GameStatus;
import com.sudoku.core.game.SudokuCell;
import com.sudoku.core.game.SudokuController;
import com.sudoku.core.stats.UnlockResult;
import java.util.Locale;

public final class GameScreen extends BaseScreen {
    private final SudokuController controller;
    private final Table boardTable = new Table();
    private final Label timer;
    private final Label errors;

    public GameScreen(SudokuGame game, SudokuController controller) {
        super(game);
        this.controller = controller;
        this.timer = label("00:00", "accent", 25);
        this.errors = label("", "secondary", 21);
    }

    @Override public void show() {
        super.show();
        Table root = ResponsiveLayout.root();
        root.pad(28);
        stage.addActor(root);
        root.add(new HudScreen(game, controller, skin, timer, errors)).width(1010).height(150).padBottom(28).row();
        root.add(boardTable).size(ResponsiveLayout.boardSize()).padBottom(28).row();
        buildBoard();

        Table numbers = new Table();
        for (int n = 1; n <= 9; n++) {
            final int value = n;
            TextButton b = accentButton(String.valueOf(n));
            b.getLabel().setFontScale(1.35f);
            b.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { controller.input(value); refresh(); }});
            numbers.add(b).size(140, 78).pad(6);
            if (n % 3 == 0) numbers.row();
        }
        root.add(numbers).padBottom(18).row();

        Table actions = new Table();
        TextButton pencil = button("PENCIL"), erase = button("BORRAR"), pause = button("PAUSA"), restart = dangerButton("REINICIAR");
        pencil.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { controller.togglePencil(); refresh(); }});
        erase.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { controller.erase(); refresh(); }});
        pause.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) {
            if (controller.state().status() == GameStatus.PAUSED) controller.resumePause(); else controller.pause();
            refresh();
        }});
        restart.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { controller.newGame(controller.state().difficulty()); refresh(); }});
        actions.add(pencil).width(230).height(70).pad(6);
        actions.add(erase).width(230).height(70).pad(6);
        actions.add(pause).width(230).height(70).pad(6);
        actions.add(restart).width(230).height(70).pad(6);
        root.add(actions).row();
        refresh();
    }

    private void buildBoard() {
        boardTable.clear();
        boardTable.setBackground(GameSkin.drawable(GameSkin.DRAWABLE_PANEL));
        boardTable.pad(14);
        float size = (ResponsiveLayout.boardSize() - 28f) / 9f;
        for (int r = 0; r < 9; r++) {
            for (int c = 0; c < 9; c++) {
                final int rr = r, cc = c;
                TextButton cell = new RoundedButton("", skin, "cell");
                cell.getLabel().setFontScale(1.4f);
                cell.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { controller.select(rr, cc); refresh(); }});
                boardTable.add(cell)
                    .size(size)
                    .pad(c % 3 == 2 ? 5 : 1, r % 3 == 2 ? 5 : 1, 1, 1);
            }
            boardTable.row();
        }
    }

    private void refresh() {
        int i = 0;
        GameState s = controller.state();
        int selectedValue = selectedValue(s);
        for (Actor actor : boardTable.getChildren()) {
            int r = i / 9, c = i % 9;
            TextButton button = (TextButton) actor;
            SudokuCell cell = s.board().cell(r, c);
            button.setText(cell.value() == 0 ? notes(cell) : String.valueOf(cell.value()));
            button.getStyle().up = cellBackground(s, cell, r, c, selectedValue);
            button.getStyle().down = GameSkin.drawable(GameSkin.DRAWABLE_CELL_SELECTED);
            button.getStyle().checked = GameSkin.drawable(GameSkin.DRAWABLE_CELL_SELECTED);
            button.getLabel().setColor(cellTextColor(cell));
            i++;
        }
        timer.setText(formatTime(s.elapsedSeconds()));
        errors.setText(String.format(
            Locale.ROOT,
            "ERRORES %d/%s",
            s.errors(),
            s.difficulty().isPermadeath() ? "PERMADEATH" : String.valueOf(s.difficulty().maxErrors())));
        if (s.status() == GameStatus.WON) stage.addActor(new UnlockPopup(skin, game.statsManager().consumeLastUnlock()));
        if (s.status() == GameStatus.LOST) stage.addActor(new UnlockPopup(skin, UnlockResult.NONE, "Derrota", "Volvé más fuerte."));
    }

    private Drawable cellBackground(GameState s, SudokuCell cell, int row, int col, int selectedValue) {
        if (cell.value() != 0 && cell.value() != cell.solution()) return GameSkin.drawable(GameSkin.DRAWABLE_CELL_ERROR);
        if (row == s.selectedRow() && col == s.selectedCol()) return GameSkin.drawable(GameSkin.DRAWABLE_CELL_SELECTED);
        if (selectedValue != 0 && cell.value() == selectedValue) return GameSkin.drawable(GameSkin.DRAWABLE_CELL_SAME);
        if (s.selectedRow() >= 0 && s.board().sameHouse(s.selectedRow(), s.selectedCol(), row, col)) return GameSkin.drawable(GameSkin.DRAWABLE_CELL_ROW);
        return GameSkin.drawable(GameSkin.DRAWABLE_CELL);
    }

    private Color cellTextColor(SudokuCell cell) {
        if (cell.value() != 0 && cell.value() != cell.solution()) return UIColorPalette.ERROR;
        if (cell.fixed()) return UIColorPalette.MYTHIC_GOLD;
        if (cell.value() == 0) return UIColorPalette.SECONDARY;
        return UIColorPalette.TEXT;
    }

    private int selectedValue(GameState state) {
        if (state.selectedRow() < 0 || state.selectedCol() < 0) return 0;
        return state.board().cell(state.selectedRow(), state.selectedCol()).value();
    }

    private String notes(SudokuCell c) {
        return c.notes().isEmpty() ? "" : c.notes().toString().replaceAll("[\\[\\], ]", "");
    }

    private String formatTime(long totalSeconds) {
        long minutes = totalSeconds / 60;
        long seconds = totalSeconds % 60;
        return String.format(Locale.ROOT, "%02d:%02d", minutes, seconds);
    }

    @Override public void render(float delta) {
        controller.update(delta);
        refresh();
        super.render(delta);
    }
}
