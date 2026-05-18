package com.sudoku.core.stats;

public final class DifficultyStats {
    public int played, wins, perfect, currentStreak, bestStreak;
    public long totalWinSeconds, bestSeconds = Long.MAX_VALUE;
    public float winRate() { return played == 0 ? 0f : (float) wins / played; }
    public long averageWinSeconds() { return wins == 0 ? 0 : totalWinSeconds / wins; }
}
