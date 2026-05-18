package com.sudoku.core.ui;

import com.badlogic.gdx.scenes.scene2d.Actor;
import com.badlogic.gdx.scenes.scene2d.ui.Table;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.utils.ChangeListener;
import com.sudoku.core.SudokuGame;

public final class SettingsScreen extends BaseScreen {
    public SettingsScreen(SudokuGame game) { super(game); }

    @Override public void show() {
        super.show();
        Table root = ResponsiveLayout.root();
        stage.addActor(root);
        root.add(label("CONFIGURACION", 48)).padBottom(34).row();

        Table panel = new Table();
        panel.setBackground(GameSkin.drawable(GameSkin.DRAWABLE_PANEL));
        panel.pad(42);
        root.add(panel).width(840).height(360).row();
        panel.add(label("Opciones visuales, audio, idioma y accesibilidad van acá.", "secondary", 22)).row();
        panel.add(label("TODO: mantener esto fuera del dominio Sudoku.", "accent", 18)).padTop(24).row();

        TextButton back = button("VOLVER");
        back.addListener(new ChangeListener() { @Override public void changed(ChangeEvent e, Actor a) { game.setScreen(new MenuScreen(game)); }});
        root.add(back).width(360).height(70).padTop(34);
    }
}
