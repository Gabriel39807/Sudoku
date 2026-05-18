package com.sudoku.core.ui.assets;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.assets.AssetManager;
import com.badlogic.gdx.graphics.Texture;
import com.badlogic.gdx.graphics.g2d.TextureAtlas;
import com.sudoku.core.difficulty.Difficulty;
import java.util.EnumMap;

public final class DifficultyAssetManager implements AutoCloseable {
    private static final String BASE = "textures/difficulty/";
    private final AssetManager assets = new AssetManager();
    private final EnumMap<Difficulty, String> paths = new EnumMap<>(Difficulty.class);

    public DifficultyAssetManager() {
        for (Difficulty d : Difficulty.values()) paths.put(d, BASE + "difficulty_" + d.name().toLowerCase() + ".png");
    }
    public void queue() {
        for (String path : paths.values()) assets.load(path, Texture.class);
        if (Gdx.files.internal("atlas/game.atlas").exists()) assets.load("atlas/game.atlas", TextureAtlas.class);
    }
    public void finishLoading() {
        assets.finishLoading();
        for (String path : paths.values()) assets.get(path, Texture.class).setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear);
    }
    public Texture getTexture(Difficulty difficulty) { return assets.get(paths.get(difficulty), Texture.class); }
    public boolean hasAtlas() { return assets.isLoaded("atlas/game.atlas", TextureAtlas.class); }
    public TextureAtlas atlas() { return hasAtlas() ? assets.get("atlas/game.atlas", TextureAtlas.class) : null; }
    @Override public void close() { assets.dispose(); }
}
