package com.sudoku.core.ui;

import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.InputEvent;
import com.badlogic.gdx.scenes.scene2d.ui.Container;
import com.badlogic.gdx.scenes.scene2d.ui.Image;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Stack;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.utils.ClickListener;
import com.badlogic.gdx.scenes.scene2d.utils.TextureRegionDrawable;
import com.badlogic.gdx.utils.Align;
import com.badlogic.gdx.utils.Scaling;
import com.sudoku.core.SudokuGame;
import com.sudoku.core.difficulty.Difficulty;
import com.sudoku.core.game.SudokuController;

public final class DifficultyScreen extends BaseScreen {
    public DifficultyScreen(SudokuGame game) { super(game); }

    @Override public void show() {
        super.show();
        Table root = ResponsiveLayout.root();
        stage.addActor(root);
        root.add(label("DIFICULTAD", 52)).row();
        root.add(label("Elegí tu desafío", "secondary", 24)).padTop(8).padBottom(40).row();

        Table grid = new Table();
        root.add(grid).expand().top().row();
        for (Difficulty d : Difficulty.values()) {
            grid.add(card(d)).width(300).height(360).pad(16);
            if (d.ordinal() % 3 == 2) grid.row();
        }
        com.badlogic.gdx.scenes.scene2d.ui.TextButton back = button("VOLVER");
        root.add(back).width(360).height(64).padTop(20).row();
        back.addListener(new ClickListener() {
            @Override public void clicked(InputEvent event, float x, float y) { game.setScreen(new MenuScreen(game)); }
        });
    }

    private Actor card(Difficulty d) {
        boolean unlocked = game.statsManager().unlocks().isUnlocked(game.statsManager().stats(), d);
        boolean hidden = d == Difficulty.MYTHIC && !unlocked;
        Table card = new Table();
        card.setBackground(GameSkin.drawable(d == Difficulty.MYTHIC ? GameSkin.DRAWABLE_PANEL_MYTHIC : GameSkin.DRAWABLE_PANEL));
        card.pad(18);

        Stack imageStack = new Stack();
        if (!hidden) {
            Texture texture = game.difficultyAssets().getTexture(d);
            Image image = new Image(new TextureRegionDrawable(texture));
            image.setScaling(Scaling.fit);
            imageStack.add(image);
            if (!unlocked) {
                Image shade = new Image(GameSkin.drawable(GameSkin.DRAWABLE_LOCK_SHADE));
                imageStack.add(shade);
            }
        } else {
            Label mystery = label("?????", "mythic", 38);
            mystery.setAlignment(Align.center);
            imageStack.add(mystery);
        }
        card.add(imageStack).size(220).row();
        card.add(label(hidden ? "?????" : d.name(), d == Difficulty.MYTHIC ? "mythic" : "default", 25)).padTop(16).row();
        card.add(label(statusText(hidden, unlocked), unlocked ? "secondary" : "accent", 18)).padTop(8).row();

        if (unlocked) card.addListener(new ClickListener() {
            @Override public void clicked(InputEvent event, float x, float y) {
                SudokuController c = new SudokuController(game.generator(), game.saveManager(), game.statsManager());
                c.newGame(d);
                game.setScreen(new GameScreen(game, c));
            }
        });
        else {
            Container<Label> lock = new Container<>(label("🔒", "secondary", 26));
            lock.align(Align.topRight);
            card.addActor(lock);
            lock.setFillParent(true);
        }
        return card;
    }

    private String statusText(boolean hidden, boolean unlocked) {
        if (hidden) return "oculto";
        return unlocked ? "desbloqueado" : "bloqueado";
    }
}
