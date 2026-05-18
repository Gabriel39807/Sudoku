package com.sudoku.core.game;

import java.util.LinkedHashSet;
import java.util.Set;

public final class SudokuCell {
    private int value;
    private int solution;
    private boolean fixed;
    private final Set<Integer> notes = new LinkedHashSet<>();

    public SudokuCell() {}
    public SudokuCell(int value, int solution, boolean fixed) {
        this.value = value;
        this.solution = solution;
        this.fixed = fixed;
    }
    public int value() { return value; }
    public int solution() { return solution; }
    public boolean fixed() { return fixed; }
    public Set<Integer> notes() { return notes; }
    public boolean empty() { return value == 0; }
    public void setValue(int value) { if (!fixed) { this.value = value; notes.clear(); } }
    public void restoreValue(int value) { this.value = value; }
    public void setSolution(int solution) { this.solution = solution; }
    public void setFixed(boolean fixed) { this.fixed = fixed; }
    public void toggleNote(int n) { if (!fixed && value == 0) { if (!notes.remove(n)) notes.add(n); } }
    public void clear() { if (!fixed) { value = 0; notes.clear(); } }
}
