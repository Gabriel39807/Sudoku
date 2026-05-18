package com.sudoku.core.difficulty;

public enum Difficulty {
    EASY("Easy", 99, true, true, true),
    MEDIUM("Medium", 99, true, true, true),
    HARD("Hard", 3, true, true, true),
    EXPERT("Expert", 2, true, true, true),
    EVIL("Evil", 1, true, true, false),
    MYTHIC("Mythic", 0, false, false, false);

    private final String label;
    private final int maxErrors;
    private final boolean hintsAllowed;
    private final boolean undoAllowed;
    private final boolean autoCompleteAllowed;

    Difficulty(String label, int maxErrors, boolean hintsAllowed, boolean undoAllowed, boolean autoCompleteAllowed) {
        this.label = label;
        this.maxErrors = maxErrors;
        this.hintsAllowed = hintsAllowed;
        this.undoAllowed = undoAllowed;
        this.autoCompleteAllowed = autoCompleteAllowed;
    }

    public String label() { return label; }
    public int maxErrors() { return maxErrors; }
    public boolean isPermadeath() { return this == MYTHIC; }
    public boolean hintsAllowed() { return hintsAllowed; }
    public boolean undoAllowed() { return undoAllowed; }
    public boolean autoCompleteAllowed() { return autoCompleteAllowed; }
}
