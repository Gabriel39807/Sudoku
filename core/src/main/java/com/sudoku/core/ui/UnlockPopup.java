package com.sudoku.core.ui;

import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.Window;
import com.sudoku.core.stats.UnlockResult;

public final class UnlockPopup extends Window {
    public UnlockPopup(Skin skin, UnlockResult result) { this(skin, title(result), message(result)); }
    public UnlockPopup(Skin skin, UnlockResult ignored, String title, String message) { this(skin, title, message); }
    public UnlockPopup(Skin skin, String title, String message) {
        super(title, skin);
        pad(24);
        Label body = new Label(message, skin, "secondary");
        body.setFontScale(1.05f);
        add(body).width(620).pad(24);
        pack();
        setPosition(Theme.WORLD_WIDTH / 2f - getWidth() / 2f, Theme.WORLD_HEIGHT / 2f - getHeight() / 2f);
    }
    private static String title(UnlockResult r) {
        switch (r) {
            case EVIL_UNLOCKED:
                return "EVIL desbloqueado";
            case MYTHIC_UNLOCKED:
                return "MYTHIC desperto";
            default:
                return "Victoria";
        }
    }
    private static String message(UnlockResult r) {
        switch (r) {
            case EVIL_UNLOCKED:
                return "Has demostrado dominio sobre EXPERT.\nEl portal hacia EVIL se ha abierto.";
            case MYTHIC_UNLOCKED:
                return "Solo unos pocos han llegado hasta aqui.\n\nMYTHIC ha despertado.";
            default:
                return "Sudoku completado.";
        }
    }
}
