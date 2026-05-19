package com.sudoku.core.ui;

import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.ui.Cell;
import com.badlogic.gdx.scenes.scene2d.ui.Table;

public final class ResponsiveLayout {
    private ResponsiveLayout() {
    }

    public static Table root() {
        Table table = new Table();
        table.setFillParent(true);
        table.pad(Theme.SCREEN_PAD);
        return table;
    }

    public static float boardSize() {
        float target = Theme.WORLD_WIDTH * Theme.BOARD_WIDTH_RATIO;
        float minimum = Theme.MIN_DESKTOP_CELL * 9f;
        return Math.max(minimum, target);
    }

    public static <T extends Actor> Cell<T> menuButton(Cell<T> cell) {
        return cell
                .width(0.7f * 540f)
                .height(70f)
                .pad(10f);
    }
}
