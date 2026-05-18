package com.sudoku.core.generator;

import com.sudoku.core.difficulty.Difficulty;
import com.sudoku.core.solver.SolveReport;
import com.sudoku.core.solver.SudokuSolver;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class SudokuGenerator {
    private final SudokuSolver solver = new SudokuSolver();
    private final DifficultyAnalyzer analyzer = new DifficultyAnalyzer();

    public GeneratedPuzzle generate(Difficulty target) {
        int[][] solution = new int[9][9];
        solver.solveBruteforce(solution);
        int[][] puzzle = copy(solution);
        List<Integer> positions = new ArrayList<>();
        for (int i = 0; i < 81; i++) positions.add(i);
        Collections.shuffle(positions);
        SolveReport bestReport = solver.solveLogically(puzzle);
        for (int pos : positions) {
            int r = pos / 9, c = pos % 9, previous = puzzle[r][c];
            puzzle[r][c] = 0;
            if (solver.countSolutions(puzzle, 2) != 1) { puzzle[r][c] = previous; continue; }
            SolveReport report = solver.solveLogically(puzzle);
            if (!report.solved()) { puzzle[r][c] = previous; continue; }
            bestReport = report;
            if (analyzer.matches(target, report) && analyzer.score(report) >= minScore(target)) break;
        }
        return new GeneratedPuzzle(puzzle, solution, target, analyzer.score(bestReport), bestReport);
    }
    private int minScore(Difficulty d) {
        switch (d) {
            case EASY:
                return 12;
            case MEDIUM:
                return 24;
            case HARD:
                return 36;
            case EXPERT:
                return 52;
            case EVIL:
                return 72;
            case MYTHIC:
                return 96;
            default:
                throw new IllegalArgumentException("Unsupported difficulty: " + d);
        }
    }
    private int[][] copy(int[][] in) {
        int[][] out = new int[9][9];
        for (int r = 0; r < 9; r++) System.arraycopy(in[r], 0, out[r], 0, 9);
        return out;
    }
}
