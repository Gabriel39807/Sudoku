package com.sudoku.core.stats;

import com.sudoku.core.difficulty.Difficulty;
import com.sudoku.core.save.SaveManager;

public final class StatsManager {
    private final SaveManager saveManager;
    private final UnlockManager unlockManager = new UnlockManager();
    private final PlayerStats stats;
    private UnlockResult lastUnlock = UnlockResult.NONE;

    public StatsManager(SaveManager saveManager) { this.saveManager = saveManager; this.stats = saveManager.loadStats(); }
    public PlayerStats stats() { return stats; }
    public UnlockManager unlocks() { return unlockManager; }
    public UnlockResult consumeLastUnlock() { UnlockResult r = lastUnlock; lastUnlock = UnlockResult.NONE; return r; }
    public void recordWin(Difficulty difficulty, long seconds, boolean perfect) {
        DifficultyStats s = stats.get(difficulty);
        s.played++; s.wins++;
        if (perfect) s.perfect++;
        s.currentStreak++;
        s.bestStreak = Math.max(s.bestStreak, s.currentStreak);
        s.totalWinSeconds += seconds;
        s.bestSeconds = Math.min(s.bestSeconds, seconds);
        lastUnlock = unlockManager.refresh(stats);
        saveManager.saveStats(stats);
    }
    public void recordLoss(Difficulty difficulty, long seconds) {
        DifficultyStats s = stats.get(difficulty);
        s.played++;
        s.currentStreak = 0;
        lastUnlock = unlockManager.refresh(stats);
        saveManager.saveStats(stats);
    }
}
