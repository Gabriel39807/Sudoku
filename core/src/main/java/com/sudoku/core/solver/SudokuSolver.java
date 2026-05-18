package com.sudoku.core.solver;

import java.util.ArrayList;
import java.util.Collections;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

public final class SudokuSolver {
    private final RuleEngine rules = new RuleEngine();

    public SolveReport solveLogically(int[][] puzzle) {
        int[][] grid = copy(puzzle);
        EnumMap<Technique, Integer> usage = new EnumMap<>(Technique.class);
        boolean progress;
        do {
            progress = applySingles(grid, usage);
            detectTechniqueSignals(grid, usage);
        } while (progress && !solved(grid));
        return new SolveReport(solved(grid), usage);
    }

    public int countSolutions(int[][] puzzle, int limit) { return count(copy(puzzle), limit, 0); }
    public boolean solveBruteforce(int[][] puzzle) { return fill(puzzle, 0); }

    private boolean applySingles(int[][] grid, EnumMap<Technique, Integer> usage) {
        boolean progress = false;
        for (int r = 0; r < 9; r++) for (int c = 0; c < 9; c++) if (grid[r][c] == 0) {
            Set<Integer> cand = rules.candidates(grid, r, c);
            if (cand.size() == 1) { grid[r][c] = cand.iterator().next(); inc(usage, Technique.NAKED_SINGLE); progress = true; }
            else {
                Integer hidden = hiddenSingle(grid, r, c, cand);
                if (hidden != null) { grid[r][c] = hidden; inc(usage, Technique.HIDDEN_SINGLE); progress = true; }
            }
        }
        return progress;
    }

    /**
     * MVP detector: techniques are detected from candidate topology, not empty-cell count.
     * Full eliminator implementations can replace this class without changing generator/UI contracts.
     */
    private void detectTechniqueSignals(int[][] grid, EnumMap<Technique, Integer> usage) {
        int pairSignals = 0, tripleSignals = 0, sparseRows = 0;
        for (int r = 0; r < 9; r++) {
            Map<Set<Integer>, Integer> seen = new HashMap<>();
            int unresolved = 0;
            for (int c = 0; c < 9; c++) {
                Set<Integer> s = rules.candidates(grid, r, c);
                if (!s.isEmpty()) unresolved++;
                if (s.size() == 2 || s.size() == 3) seen.merge(s, 1, Integer::sum);
            }
            if (unresolved >= 6) sparseRows++;
            for (Map.Entry<Set<Integer>, Integer> e : seen.entrySet()) {
                if (e.getKey().size() == 2 && e.getValue() >= 2) pairSignals++;
                if (e.getKey().size() == 3 && e.getValue() >= 3) tripleSignals++;
            }
        }
        if (pairSignals > 0) inc(usage, Technique.NAKED_PAIR);
        if (tripleSignals > 0) inc(usage, Technique.TRIPLE);
        if (pairSignals >= 2) inc(usage, Technique.POINTING_PAIR);
        if (pairSignals >= 4) inc(usage, Technique.X_WING);
        if (pairSignals >= 6 && tripleSignals >= 1) inc(usage, Technique.SWORDFISH);
        if (sparseRows >= 5 && pairSignals >= 5) inc(usage, Technique.XY_WING);
        if (sparseRows >= 7 && pairSignals >= 7) inc(usage, Technique.FORCING_CHAIN);
    }

    private Integer hiddenSingle(int[][] grid, int row, int col, Set<Integer> cand) {
        for (int n : cand) if (uniqueInRow(grid, row, col, n) || uniqueInCol(grid, row, col, n) || uniqueInBox(grid, row, col, n)) return n;
        return null;
    }
    private boolean uniqueInRow(int[][] g, int row, int col, int n) {
        for (int c = 0; c < 9; c++) if (c != col && g[row][c] == 0 && rules.candidates(g, row, c).contains(n)) return false;
        return true;
    }
    private boolean uniqueInCol(int[][] g, int row, int col, int n) {
        for (int r = 0; r < 9; r++) if (r != row && g[r][col] == 0 && rules.candidates(g, r, col).contains(n)) return false;
        return true;
    }
    private boolean uniqueInBox(int[][] g, int row, int col, int n) {
        int br = row / 3 * 3, bc = col / 3 * 3;
        for (int r = br; r < br + 3; r++) for (int c = bc; c < bc + 3; c++)
            if ((r != row || c != col) && g[r][c] == 0 && rules.candidates(g, r, c).contains(n)) return false;
        return true;
    }
    private boolean solved(int[][] g) {
        for (int[] row : g) for (int v : row) if (v == 0) return false;
        return rules.valid(g);
    }
    private int count(int[][] g, int limit, int pos) {
        if (limit <= 0) return 0;
        while (pos < 81 && g[pos / 9][pos % 9] != 0) pos++;
        if (pos == 81) return 1;
        int total = 0, r = pos / 9, c = pos % 9;
        for (int n : shuffled()) if (rules.candidates(g, r, c).contains(n)) {
            g[r][c] = n;
            total += count(g, limit - total, pos + 1);
            g[r][c] = 0;
            if (total >= limit) return total;
        }
        return total;
    }
    private boolean fill(int[][] g, int pos) {
        while (pos < 81 && g[pos / 9][pos % 9] != 0) pos++;
        if (pos == 81) return true;
        int r = pos / 9, c = pos % 9;
        for (int n : shuffled()) if (rules.candidates(g, r, c).contains(n)) {
            g[r][c] = n;
            if (fill(g, pos + 1)) return true;
            g[r][c] = 0;
        }
        return false;
    }
    private List<Integer> shuffled() {
        List<Integer> n = new ArrayList<>();
        for (int i = 1; i <= 9; i++) n.add(i);
        Collections.shuffle(n);
        return n;
    }
    private int[][] copy(int[][] in) {
        int[][] out = new int[9][9];
        for (int r = 0; r < 9; r++) System.arraycopy(in[r], 0, out[r], 0, 9);
        return out;
    }
    private void inc(EnumMap<Technique, Integer> usage, Technique t) { usage.merge(t, 1, Integer::sum); }
}
