package com.sudoku.core.ui;

import com.badlogic.gdx.scenes.scene2d.ui.Image;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.utils.Scaling;
import com.sudoku.core.SudokuGame;
import com.sudoku.core.game.SudokuController;

public final class HudScreen extends Table {
    public HudScreen(SudokuGame game, SudokuController controller, Label timer, Label errors, TextButton exitButton) {
        setBackground(GameSkin.drawable(controller.state().difficulty().name().equals("MYTHIC") ? GameSkin.DRAWABLE_PANEL_MYTHIC : GameSkin.DRAWABLE_PANEL));
        pad(16);
        Image icon = new Image(game.difficultyAssets().getTexture(controller.state().difficulty()));
        icon.setScaling(Scaling.fit);
        add(icon).size(118).padRight(22);

        Table text = new Table();
        text.add(GameSkin.label(controller.state().difficulty().name(), GameSkin.STYLE_LABEL_DEFAULT, 1.28f, Align.left)).left().row();
        text.add(GameSkin.label("Classic Journey", GameSkin.STYLE_LABEL_SECONDARY, 0.92f, Align.left)).left();
        add(text).expandX().left();
        add(timer).width(165).right().padRight(16);
        add(errors).width(230).right().padRight(16);
        add(exitButton).width(150).height(68).right();
    }
}
