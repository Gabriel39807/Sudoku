package com.sudoku.core.ui;

import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;

public final class RoundedButton extends TextButton {
    public RoundedButton(String text, Skin skin) {
        this(text, skin, "default");
    }

    public RoundedButton(String text, Skin skin, String styleName) {
        super(text, skin, styleName);
        getLabel().setFontScale(1.15f);
        pad(8f, 20f, 8f, 20f);
    }
}
