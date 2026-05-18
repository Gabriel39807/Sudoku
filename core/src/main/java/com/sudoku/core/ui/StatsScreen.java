package com.sudoku.core.ui;

import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.sudoku.core.SudokuGame;
import com.sudoku.core.difficulty.Difficulty;
import com.sudoku.core.stats.DifficultyStats;

public final class StatsScreen extends BaseScreen {
    public StatsScreen(SudokuGame game) { super(game); }

    @Override public void show() {
        super.show();
        Table root = ResponsiveLayout.root();
        stage.addActor(root);
        root.add(label("ESTADISTICAS", 48)).padBottom(34).row();

        Table panel = new Table();
        panel.setBackground(GameSkin.drawable(GameSkin.DRAWABLE_PANEL));
        panel.pad(24);
        root.add(panel).width(940).expandY().top().row();
        for (Difficulty d : Difficulty.values()) {
            DifficultyStats s = game.statsManager().stats().get(d);
            panel.add(label(d.name(), d == Difficulty.MYTHIC ? "mythic" : "accent", 20)).width(150).left();
            panel.add(label("J " + s.played, "secondary", 17)).width(120);
            panel.add(label("V " + s.wins, "secondary", 17)).width(120);
            panel.add(label("Perfect " + s.perfect, "secondary", 17)).width(180);
            panel.add(label("Mejor " + (s.bestSeconds == Long.MAX_VALUE ? "-" : s.bestSeconds + "s"), "secondary", 17)).width(220).row();
        }

        TextButton back = button("VOLVER");
        back.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { game.setScreen(new MenuScreen(game)); }});
        root.add(back).width(360).height(70).padTop(26);
    }
}
