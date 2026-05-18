package com.sudoku.core.stats;

import com.sudoku.core.difficulty.Difficulty;

public final class UnlockManager {
    public boolean isUnlocked(PlayerStats stats, Difficulty difficulty) {
        switch (difficulty) {
            case EASY:
            case MEDIUM:
            case HARD:
            case EXPERT:
                return true;
            case EVIL:
                return stats.evilUnlocked;
            case MYTHIC:
                return stats.mythicUnlocked;
            default:
                throw new IllegalArgumentException("Unsupported difficulty: " + difficulty);
        }
    }
    public UnlockResult refresh(PlayerStats stats) {
        boolean evilBefore = stats.evilUnlocked, mythicBefore = stats.mythicUnlocked;
        DifficultyStats expert = stats.get(Difficulty.EXPERT);
        if (expert.wins >= 10 && expert.perfect >= 3 && expert.winRate() >= 0.70f) stats.evilUnlocked = true;
        DifficultyStats evil = stats.get(Difficulty.EVIL);
        if (evil.wins >= 20 && evil.perfect >= 10 && evil.currentStreak >= 5) stats.mythicUnlocked = true;
        if (!evilBefore && stats.evilUnlocked) return UnlockResult.EVIL_UNLOCKED;
        if (!mythicBefore && stats.mythicUnlocked) return UnlockResult.MYTHIC_UNLOCKED;
        return UnlockResult.NONE;
    }
}
