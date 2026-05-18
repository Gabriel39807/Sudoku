package com.sudoku.core.ui;

import com.badlogic.gdx.graphics.Color;
import com.badlogic.gdx.graphics.Pixmap;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.BitmapFont;
import com.badlogic.gdx.scenes.scene2d.ui.Label;
import com.badlogic.gdx.scenes.scene2d.ui.Skin;
import com.badlogic.gdx.scenes.scene2d.ui.TextButton;
import com.badlogic.gdx.scenes.scene2d.ui.Window;
import com.badlogic.gdx.scenes.scene2d.utils.Drawable;
import com.badlogic.gdx.scenes.scene2d.utils.TextureRegionDrawable;
import com.badlogic.gdx.utils.Align;

public final class GameSkin {
    public static final String DRAWABLE_WHITE = "white";
    public static final String DRAWABLE_PANEL = "ui.panel";
    public static final String DRAWABLE_PANEL_ACCENT = "ui.panel.accent";
    public static final String DRAWABLE_PANEL_MYTHIC = "ui.panel.mythic";
    public static final String DRAWABLE_CELL = "ui.cell";
    public static final String DRAWABLE_CELL_ROW = "ui.cell.row";
    public static final String DRAWABLE_CELL_SELECTED = "ui.cell.selected";
    public static final String DRAWABLE_CELL_SAME = "ui.cell.same";
    public static final String DRAWABLE_CELL_ERROR = "ui.cell.error";
    public static final String DRAWABLE_LOCK_SHADE = "ui.lock.shade";
    public static final String STYLE_BUTTON_DEFAULT = "default";
    public static final String STYLE_BUTTON_ACCENT = "accent";
    public static final String STYLE_BUTTON_DANGER = "danger";
    public static final String STYLE_BUTTON_CELL = "cell";
    public static final String STYLE_LABEL_DEFAULT = "default";
    public static final String STYLE_LABEL_SECONDARY = "secondary";
    public static final String STYLE_LABEL_ACCENT = "accent";
    public static final String STYLE_LABEL_MYTHIC = "mythic";

    private static Skin instance;

    private GameSkin() {
    }

    public static Skin get() {
        if (instance == null) instance = create();
        return instance;
    }

    public static void dispose() {
        if (instance != null) {
            instance.dispose();
            instance = null;
        }
    }

    public static Drawable drawable(String name) {
        if (!get().has(name, Drawable.class)) throw new IllegalArgumentException("Drawable not registered in GameSkin: " + name);
        return get().get(name, Drawable.class);
    }

    public static Label label(String text, String style, float scale, int align) {
        Label label = new Label(text, get(), style);
        label.setFontScale(scale);
        label.setAlignment(align);
        return label;
    }

    public static Label centered(String text, String style, float scale) {
        return label(text, style, scale, Align.center);
    }

    private static Skin create() {
        Skin skin = new Skin();
        BitmapFont font = new BitmapFont();
        font.getData().markupEnabled = true;
        skin.add("default-font", font);

        Texture white = whiteTexture();
        skin.add(DRAWABLE_WHITE, white);

        registerDrawable(skin, DRAWABLE_PANEL, rounded(UIColorPalette.PANEL, UIColorPalette.BORDER, 24, 2));
        registerDrawable(skin, DRAWABLE_PANEL_ACCENT, rounded(UIColorPalette.PANEL, UIColorPalette.ACCENT, 24, 3));
        registerDrawable(skin, DRAWABLE_PANEL_MYTHIC, rounded(UIColorPalette.PANEL, UIColorPalette.MYTHIC_GOLD, 24, 3));
        registerDrawable(skin, DRAWABLE_CELL, rounded(Color.valueOf("181818"), UIColorPalette.BORDER, 10, 1));
        registerDrawable(skin, DRAWABLE_CELL_ROW, rounded(UIColorPalette.ROW_HIGHLIGHT, UIColorPalette.BORDER, 10, 1));
        registerDrawable(skin, DRAWABLE_CELL_SELECTED, rounded(UIColorPalette.ACCENT_SOFT, UIColorPalette.ACCENT, 10, 2));
        registerDrawable(skin, DRAWABLE_CELL_SAME, rounded(UIColorPalette.SAME_NUMBER, Color.valueOf("335270"), 10, 1));
        registerDrawable(skin, DRAWABLE_CELL_ERROR, rounded(Color.valueOf("3A1717"), UIColorPalette.ERROR, 10, 2));
        registerDrawable(skin, DRAWABLE_LOCK_SHADE, rounded(new Color(0f, 0f, 0f, 0.62f), new Color(0f, 0f, 0f, 0f), 18, 0));

        Drawable buttonDefault = rounded(Color.valueOf("24202E"), UIColorPalette.BORDER, 18, 2);
        Drawable buttonDefaultDown = rounded(UIColorPalette.ACCENT_SOFT, UIColorPalette.ACCENT, 18, 2);
        Drawable buttonAccent = rounded(UIColorPalette.ACCENT, UIColorPalette.ACCENT, 18, 2);
        Drawable buttonAccentDown = rounded(UIColorPalette.MYTHIC_VIOLET, UIColorPalette.MYTHIC_GOLD, 18, 2);
        Drawable buttonDanger = rounded(Color.valueOf("321B1B"), UIColorPalette.ERROR, 18, 2);
        Drawable buttonDangerDown = rounded(UIColorPalette.ERROR, UIColorPalette.ERROR, 18, 2);

        registerLabels(skin, font);
        skin.add(STYLE_BUTTON_DEFAULT, buttonStyle(font, buttonDefault, buttonDefaultDown, UIColorPalette.TEXT));
        skin.add(STYLE_BUTTON_ACCENT, buttonStyle(font, buttonAccent, buttonAccentDown, UIColorPalette.TEXT));
        skin.add(STYLE_BUTTON_DANGER, buttonStyle(font, buttonDanger, buttonDangerDown, UIColorPalette.TEXT));
        skin.add(STYLE_BUTTON_CELL, buttonStyle(font, skin.get(DRAWABLE_CELL, Drawable.class), skin.get(DRAWABLE_CELL_SELECTED, Drawable.class), UIColorPalette.TEXT));
        skin.add("default", new Window.WindowStyle(font, UIColorPalette.MYTHIC_GOLD, skin.get(DRAWABLE_PANEL_ACCENT, Drawable.class)));
        return skin;
    }

    private static void registerLabels(Skin skin, BitmapFont font) {
        skin.add(STYLE_LABEL_DEFAULT, new Label.LabelStyle(font, UIColorPalette.TEXT));
        skin.add(STYLE_LABEL_SECONDARY, new Label.LabelStyle(font, UIColorPalette.SECONDARY));
        skin.add(STYLE_LABEL_ACCENT, new Label.LabelStyle(font, UIColorPalette.ACCENT));
        skin.add(STYLE_LABEL_MYTHIC, new Label.LabelStyle(font, UIColorPalette.MYTHIC_GOLD));
    }

    private static TextButton.TextButtonStyle buttonStyle(BitmapFont font, Drawable up, Drawable down, Color fontColor) {
        TextButton.TextButtonStyle style = new TextButton.TextButtonStyle(up, down, down, font);
        style.fontColor = fontColor;
        style.downFontColor = UIColorPalette.TEXT;
        style.checkedFontColor = UIColorPalette.TEXT;
        return style;
    }

    private static Texture whiteTexture() {
        Pixmap pixmap = new Pixmap(1, 1, Pixmap.Format.RGBA8888);
        pixmap.setColor(Color.WHITE);
        pixmap.fill();
        Texture texture = new Texture(pixmap);
        pixmap.dispose();
        return texture;
    }

    private static void registerDrawable(Skin skin, String name, Drawable drawable) {
        skin.add(name, drawable, Drawable.class);
    }

    private static Drawable rounded(Color fill, Color border, int radius, int borderWidth) {
        int w = 96, h = 96;
        Pixmap pixmap = new Pixmap(w, h, Pixmap.Format.RGBA8888);
        pixmap.setBlending(Pixmap.Blending.SourceOver);
        pixmap.setColor(0f, 0f, 0f, 0f);
        pixmap.fill();
        fillRoundRect(pixmap, 0, 0, w, h, radius, border);
        if (borderWidth > 0) {
            fillRoundRect(pixmap, borderWidth, borderWidth, w - borderWidth * 2, h - borderWidth * 2, Math.max(1, radius - borderWidth), fill);
        } else {
            fillRoundRect(pixmap, 0, 0, w, h, radius, fill);
        }
        Texture texture = new Texture(pixmap);
        pixmap.dispose();
        TextureRegionDrawable drawable = new TextureRegionDrawable(texture);
        drawable.setMinWidth(24f);
        drawable.setMinHeight(24f);
        drawable.setLeftWidth(radius);
        drawable.setRightWidth(radius);
        drawable.setTopHeight(radius);
        drawable.setBottomHeight(radius);
        return drawable;
    }

    private static void fillRoundRect(Pixmap p, int x, int y, int w, int h, int r, Color color) {
        p.setColor(color);
        p.fillRectangle(x + r, y, w - r * 2, h);
        p.fillRectangle(x, y + r, w, h - r * 2);
        p.fillCircle(x + r, y + r, r);
        p.fillCircle(x + w - r - 1, y + r, r);
        p.fillCircle(x + r, y + h - r - 1, r);
        p.fillCircle(x + w - r - 1, y + h - r - 1, r);
    }
}
