package com.sudoku.core.solver;

import java.util.EnumMap;
import java.util.Map;

public final class SolveReport {
    private final boolean solved;
    private final EnumMap<Technique, Integer> usage;
    public SolveReport(boolean solved, EnumMap<Technique, Integer> usage) { this.solved = solved; this.usage = usage; }
    public boolean solved() { return solved; }
    public Map<Technique, Integer> usage() { return usage; }
    public int count(Technique t) { return usage.getOrDefault(t, 0); }
}
