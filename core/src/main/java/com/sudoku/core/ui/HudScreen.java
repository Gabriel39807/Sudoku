package com.sudoku.core.ui;

import com.badlogic.gdx.scenes.scene2d.ui.Image;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.utils.Scaling;
import com.sudoku.core.SudokuGame;
import com.sudoku.core.game.SudokuController;

public final class HudScreen extends Table {
    public HudScreen(SudokuGame game, SudokuController controller, Skin skin, Label timer, Label errors) {
        setBackground(GameSkin.drawable(controller.state().difficulty().name().equals("MYTHIC") ? GameSkin.DRAWABLE_PANEL_MYTHIC : GameSkin.DRAWABLE_PANEL));
        pad(18);
        Image icon = new Image(game.difficultyAssets().getTexture(controller.state().difficulty()));
        icon.setScaling(Scaling.fit);
        add(icon).size(104).padRight(22);

        Table text = new Table();
        text.add(GameSkin.label(controller.state().difficulty().name(), GameSkin.STYLE_LABEL_DEFAULT, 1.25f, Align.left)).left().row();
        text.add(GameSkin.label("Classic Journey", GameSkin.STYLE_LABEL_SECONDARY, 0.85f, Align.left)).left();
        add(text).expandX().left();
        add(timer).width(210).right().padRight(22);
        add(errors).width(210).right();
    }
}
