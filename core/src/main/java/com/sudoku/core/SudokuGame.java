package com.sudoku.core;

import com.badlogic.gdx.Game;
import com.sudoku.core.generator.SudokuGenerator;
import com.sudoku.core.save.SaveManager;
import com.sudoku.core.stats.StatsManager;
import com.sudoku.core.ui.GameSkin;
import com.sudoku.core.ui.MenuScreen;
import com.sudoku.core.ui.assets.DifficultyAssetManager;

public final class SudokuGame extends Game {
    private DifficultyAssetManager difficultyAssets;
    private SaveManager saveManager;
    private StatsManager statsManager;
    private SudokuGenerator generator;

    @Override public void create() {
        difficultyAssets = new DifficultyAssetManager();
        difficultyAssets.queue();
        difficultyAssets.finishLoading();
        saveManager = new SaveManager();
        statsManager = new StatsManager(saveManager);
        generator = new SudokuGenerator();
        setScreen(new MenuScreen(this));
    }
    public DifficultyAssetManager difficultyAssets() { return difficultyAssets; }
    public SaveManager saveManager() { return saveManager; }
    public StatsManager statsManager() { return statsManager; }
    public SudokuGenerator generator() { return generator; }
    @Override public void dispose() {
        super.dispose();
        if (difficultyAssets != null) difficultyAssets.close();
        GameSkin.dispose();
    }
    // TODO campaign: add a campaign-map flow before free play without changing SudokuController.
    // TODO economy/events/skins/store: add new application services; keep classic Sudoku domain pure.
}
