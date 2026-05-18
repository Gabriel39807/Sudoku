package com.sudoku.core.ui;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.ScreenAdapter;
import com.badlogic.gdx.graphics.GL20;
import com.badlogic.gdx.scenes.scene2d.Stage;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.utils.viewport.FitViewport;
import com.sudoku.core.SudokuGame;

abstract class BaseScreen extends ScreenAdapter {
    protected static final float WORLD_W = Theme.WORLD_WIDTH;
    protected static final float WORLD_H = Theme.WORLD_HEIGHT;
    protected final SudokuGame game;
    protected final Stage stage = new Stage(new FitViewport(WORLD_W, WORLD_H));
    protected final Skin skin = GameSkin.get();

    BaseScreen(SudokuGame game) {
        this.game = game;
    }

    @Override public void show() {
        Gdx.input.setInputProcessor(stage);
    }

    @Override public void render(float delta) {
        Gdx.gl.glClearColor(UIColorPalette.BACKGROUND.r, UIColorPalette.BACKGROUND.g, UIColorPalette.BACKGROUND.b, 1f);
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT);
        stage.act(delta);
        stage.draw();
    }

    @Override public void resize(int width, int height) {
        stage.getViewport().update(width, height, true);
    }

    @Override public void dispose() {
        stage.dispose();
    }

    protected Label label(String text, int size) {
        Label l = new Label(text, skin);
        l.setFontScale(size / 24f);
        l.setAlignment(Align.center);
        return l;
    }

    protected Label label(String text, String style, int size) {
        Label l = new Label(text, skin, style);
        l.setFontScale(size / 24f);
        l.setAlignment(Align.center);
        return l;
    }

    protected TextButton button(String text) {
        return new RoundedButton(text, skin);
    }

    protected TextButton accentButton(String text) {
        return new RoundedButton(text, skin, "accent");
    }

    protected TextButton dangerButton(String text) {
        return new RoundedButton(text, skin, "danger");
    }
}
