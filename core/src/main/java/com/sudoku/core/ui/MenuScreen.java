package com.sudoku.core.ui;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.sudoku.core.SudokuGame;
import com.sudoku.core.game.SudokuController;

public final class MenuScreen extends BaseScreen {
    public MenuScreen(SudokuGame game) { super(game); }

    @Override public void show() {
        super.show();
        Table root = ResponsiveLayout.root();
        stage.addActor(root);

        root.add().expandY().row();
        Label title = label("SUDOKU", "default", 64);
        Label subtitle = label("Classic Journey", "secondary", 28);
        root.add(title).row();
        root.add(subtitle).padTop(10).padBottom(96).row();

        TextButton play = accentButton("JUGAR");
        TextButton stats = button("ESTADISTICAS");
        TextButton settings = button("CONFIGURACION");
        TextButton exit = dangerButton("SALIR");

        ResponsiveLayout.menuButton(root.add(play)).row();
        ResponsiveLayout.menuButton(root.add(stats)).row();
        ResponsiveLayout.menuButton(root.add(settings)).row();
        ResponsiveLayout.menuButton(root.add(exit)).row();
        root.add().height(96).row();
        root.add().expandY();

        play.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) {
            SudokuController c = new SudokuController(game.generator(), game.saveManager(), game.statsManager());
            if (c.resumeSavedGame()) game.setScreen(new GameScreen(game, c));
            else game.setScreen(new DifficultyScreen(game));
        }});
        stats.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { game.setScreen(new StatsScreen(game)); }});
        settings.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { game.setScreen(new SettingsScreen(game)); }});
        exit.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { Gdx.app.exit(); }});
    }
}
