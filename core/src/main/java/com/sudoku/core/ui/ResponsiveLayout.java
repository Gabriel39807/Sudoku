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
        return Math.min(Theme.WORLD_WIDTH - 88f, 900f);
    }

    public static <T extends Actor> Cell<T> menuButton(Cell<T> cell) {
        return cell
                .width(0.7f * 540f)
                .height(70f)
                .pad(10f);
    }
}
