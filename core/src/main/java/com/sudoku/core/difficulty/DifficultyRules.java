package com.sudoku.core.difficulty;

public interface DifficultyRules {
    Difficulty difficulty();
    default int maxErrors() { return difficulty().maxErrors(); }
    default boolean isDefeat(int errors) {
        return difficulty().isPermadeath() ? errors >= 1 : errors > maxErrors();
    }
    default boolean hintsAllowed() { return difficulty().hintsAllowed(); }
    default boolean undoAllowed() { return difficulty().undoAllowed(); }
}
