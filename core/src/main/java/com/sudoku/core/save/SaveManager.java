package com.sudoku.core.save;

import com.badlogic.gdx.Gdx;
import com.badlogic.gdx.files.FileHandle;
import com.badlogic.gdx.utils.Json;
import com.sudoku.core.game.GameState;
import com.sudoku.core.stats.PlayerStats;

public final class SaveManager {
    private static final String GAME_FILE = "save/current-game.json";
    private static final String STATS_FILE = "save/stats.json";
    private final Json json = new Json();

    public void saveGame(GameState state) {
        if (state != null) file(GAME_FILE).writeString(json.prettyPrint(GameSaveData.from(state)), false, "UTF-8");
    }
    public GameState loadGame() {
        FileHandle f = file(GAME_FILE);
        return f.exists() ? json.fromJson(GameSaveData.class, f.readString("UTF-8")).toState() : null;
    }
    public void clearGame() {
        FileHandle f = file(GAME_FILE);
        if (f.exists()) f.delete();
    }
    public PlayerStats loadStats() {
        FileHandle f = file(STATS_FILE);
        return f.exists() ? json.fromJson(PlayerStats.class, f.readString("UTF-8")) : new PlayerStats();
    }
    public void saveStats(PlayerStats stats) { file(STATS_FILE).writeString(json.prettyPrint(stats), false, "UTF-8"); }
    private FileHandle file(String path) { return Gdx.files.local(path); }
}
