package com.sudoku.core.solver;

import java.util.LinkedHashSet;
import java.util.Set;

public final class RuleEngine {
    public Set<Integer> candidates(int[][] grid, int row, int col) {
        if (grid[row][col] != 0) return Set.of();
        boolean[] used = new boolean[10];
        for (int i = 0; i < 9; i++) { used[grid[row][i]] = true; used[grid[i][col]] = true; }
        int br = row / 3 * 3, bc = col / 3 * 3;
        for (int r = br; r < br + 3; r++) for (int c = bc; c < bc + 3; c++) used[grid[r][c]] = true;
        Set<Integer> result = new LinkedHashSet<>();
        for (int n = 1; n <= 9; n++) if (!used[n]) result.add(n);
        return result;
    }
    public boolean valid(int[][] grid) {
        for (int r = 0; r < 9; r++) for (int c = 0; c < 9; c++)
            if (grid[r][c] != 0 && !validPlacement(grid, r, c, grid[r][c])) return false;
        return true;
    }
    private boolean validPlacement(int[][] grid, int row, int col, int n) {
        for (int i = 0; i < 9; i++) if ((i != col && grid[row][i] == n) || (i != row && grid[i][col] == n)) return false;
        int br = row / 3 * 3, bc = col / 3 * 3;
        for (int r = br; r < br + 3; r++) for (int c = bc; c < bc + 3; c++)
            if ((r != row || c != col) && grid[r][c] == n) return false;
        return true;
    }
}
