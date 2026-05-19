package com.sudoku.core.ui;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.ui.Container;
import com.badlogic.gdx.scenes.scene2d.ui.Image;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Stack;
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
        root.pad(24);
        stage.addActor(root);
        TextButton exitTop = dangerButton("SALIR");
        exitTop.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { showExitConfirmation(); }});
        root.add(new HudScreen(game, controller, timer, errors, exitTop)).width(1010).height(150).padBottom(24).row();
        root.add(boardTable).size(ResponsiveLayout.boardSize()).padBottom(24).row();
        buildBoard();

        Table numbers = new Table();
        for (int n = 1; n <= 9; n++) {
            final int value = n;
            TextButton b = accentButton(String.valueOf(n));
            b.getLabel().setFontScale(1.55f);
            b.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { controller.input(value); refresh(); }});
            numbers.add(b).size(180, 82).pad(7);
            if (n % 3 == 0) numbers.row();
        }
        root.add(numbers).padBottom(14).row();

        Table actions = new Table();
        TextButton pencil = button("PENCIL"), erase = button("BORRAR"), pause = button("PAUSA"), exit = dangerButton("SALIR");
        pencil.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { controller.togglePencil(); refresh(); }});
        erase.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { controller.erase(); refresh(); }});
        pause.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) {
            if (controller.state().status() == GameStatus.PAUSED) controller.resumePause(); else controller.pause();
            refresh();
        }});
        exit.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { showExitConfirmation(); }});
        actions.add(pencil).width(230).height(76).pad(6);
        actions.add(erase).width(230).height(76).pad(6);
        actions.add(pause).width(230).height(76).pad(6);
        actions.add(exit).width(230).height(76).pad(6);
        root.add(actions).row();
        refresh();
    }

    private void buildBoard() {
        boardTable.clear();
        boardTable.setBackground(GameSkin.drawable(GameSkin.DRAWABLE_PANEL));
        boardTable.pad(16);
        float size = Math.max(Theme.MIN_DESKTOP_CELL, (ResponsiveLayout.boardSize() - 32f) / 9f);
        for (int r = 0; r < 9; r++) {
            for (int c = 0; c < 9; c++) {
                final int rr = r, cc = c;
                TextButton cell = new RoundedButton("", skin, "cell");
                cell.setStyle(new TextButton.TextButtonStyle(cell.getStyle()));
                cell.getLabel().setFontScale(1.55f);
                cell.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { controller.select(rr, cc); refresh(); }});
                boardTable.add(cell)
                    .size(size)
                    .pad(c % 3 == 2 ? 6 : 1, r % 3 == 2 ? 6 : 1, 1, 1);
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

    private void showExitConfirmation() {
        final Stack overlay = new Stack();
        overlay.setFillParent(true);
        overlay.add(new Image(GameSkin.drawable(GameSkin.DRAWABLE_DIALOG_SHADE)));

        Table dialog = new Table();
        dialog.setBackground(GameSkin.drawable(GameSkin.DRAWABLE_PANEL_ACCENT));
        dialog.pad(34);
        dialog.add(label("Tienes una partida en progreso", "default", 30)).width(650).padBottom(28).row();
        Table buttons = new Table();
        TextButton cancel = button("Cancelar");
        TextButton exit = dangerButton("Salir");
        buttons.add(cancel).width(250).height(76).pad(8);
        buttons.add(exit).width(250).height(76).pad(8);
        dialog.add(buttons).row();

        Container<Table> centered = new Container<>(dialog);
        centered.center();
        overlay.add(centered);
        stage.addActor(overlay);

        cancel.addListener(new ChangeListener() { @Override public void changed(ChangeEvent event, Actor actor) { overlay.remove(); }});
        exit.addListener(new ChangeListener() { @Override public void changed(ChangeEvent event, Actor actor) {
            controller.saveProgress();
            game.setScreen(new DifficultyScreen(game));
        }});
    }

    @Override public void render(float delta) {
        controller.update(delta);
        refresh();
        super.render(delta);
    }
}
