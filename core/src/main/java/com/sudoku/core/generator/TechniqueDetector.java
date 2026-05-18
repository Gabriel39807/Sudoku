package com.sudoku.core.generator;

import com.sudoku.core.solver.SolveReport;
import com.sudoku.core.solver.SudokuSolver;

public final class TechniqueDetector {
    private final SudokuSolver solver = new SudokuSolver();
    public SolveReport detect(int[][] puzzle) { return solver.solveLogically(puzzle); }
}
