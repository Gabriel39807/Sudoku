package com.sudoku.core.generator;

import com.sudoku.core.difficulty.Difficulty;
import com.sudoku.core.solver.SolveReport;
import com.sudoku.core.solver.Technique;

public final class DifficultyAnalyzer {
    public int score(SolveReport r) {
        int singles = r.count(Technique.NAKED_SINGLE) + r.count(Technique.HIDDEN_SINGLE);
        int pairs = r.count(Technique.NAKED_PAIR) + r.count(Technique.HIDDEN_PAIR);
        return singles + pairs * 2 + r.count(Technique.X_WING) * 5 + r.count(Technique.SWORDFISH) * 8 + r.count(Technique.FORCING_CHAIN) * 12;
    }
    public Difficulty classify(SolveReport r) {
        if (r.count(Technique.FORCING_CHAIN) > 0 && r.count(Technique.XY_WING) > 0) return Difficulty.MYTHIC;
        if (r.count(Technique.XY_WING) > 0 || r.count(Technique.FORCING_CHAIN) > 0) return Difficulty.EVIL;
        if (r.count(Technique.X_WING) > 0 || r.count(Technique.SWORDFISH) > 0) return Difficulty.EXPERT;
        if (r.count(Technique.POINTING_PAIR) > 0 || r.count(Technique.BOX_REDUCTION) > 0 || r.count(Technique.INTERSECTION) > 0) return Difficulty.HARD;
        if (r.count(Technique.NAKED_PAIR) > 0 || r.count(Technique.HIDDEN_PAIR) > 0 || r.count(Technique.TRIPLE) > 0) return Difficulty.MEDIUM;
        return Difficulty.EASY;
    }
    public boolean matches(Difficulty target, SolveReport r) { return classify(r).ordinal() >= target.ordinal(); }
}
