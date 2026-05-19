package com.sudoku.core.stats;

import com.sudoku.core.difficulty.Difficulty;
import java.util.HashMap;

public final class PlayerStats {
    public HashMap<Difficulty, DifficultyStats> byDifficulty = new HashMap<>();
    public boolean evilUnlocked;
    public boolean mythicUnlocked;
    public PlayerStats() { for (Difficulty d : Difficulty.values()) byDifficulty.put(d, new DifficultyStats()); }
    public DifficultyStats get(Difficulty d) {
        DifficultyStats stats = byDifficulty.get(d);
        if (stats == null) {
            stats = new DifficultyStats();
            byDifficulty.put(d, stats);
        }
        return stats;
    }
}
