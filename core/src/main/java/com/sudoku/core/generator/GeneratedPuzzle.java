package com.sudoku.core.generator;

import com.sudoku.core.difficulty.Difficulty;
import com.sudoku.core.solver.SolveReport;

public final class GeneratedPuzzle {
    private final int[][] puzzle;
    private final int[][] solution;
    private final Difficulty difficulty;
    private final int score;
    private final SolveReport report;

    public GeneratedPuzzle(int[][] puzzle, int[][] solution, Difficulty difficulty, int score, SolveReport report) {
        this.puzzle = puzzle;
        this.solution = solution;
        this.difficulty = difficulty;
        this.score = score;
        this.report = report;
    }

    public int[][] puzzle() { return puzzle; }
    public int[][] solution() { return solution; }
    public Difficulty difficulty() { return difficulty; }
    public int score() { return score; }
    public SolveReport report() { return report; }
}
