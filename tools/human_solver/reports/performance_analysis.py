#!/usr/bin/env python3
"""Performance analysis: time per technique, steps, frequency."""
import sys, os, time

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from human_solver.board import Board
from human_solver.pipeline import Pipeline
from human_solver.tests.famous_puzzles import FAMOUS_PUZZLES

SIMPLE = (
    "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
)


def main():
    print("=" * 70)
    print("PERFORMANCE ANALYSIS")
    print("=" * 70)

    print("\n--- Solver timing per puzzle ---")
    valid = []
    for name, s in FAMOUS_PUZZLES.items():
        cleaned = s.replace(".", "0").replace(" ", "").replace("\n", "").replace("\r", "")
        if len(cleaned) == 81:
            valid.append((name, cleaned))

    for name, s in valid:
        p = Pipeline()
        b = Board.from_string(s)
        start = time.perf_counter()
        solved, final = p.solve(b, max_iterations=200)
        elapsed = (time.perf_counter() - start) * 1000

        tech_breakdown = {}
        for step in p.explainer.steps:
            tid = step["technique_id"]
            tech_breakdown[tid] = tech_breakdown.get(tid, 0) + 1

        steps = len(p.explainer.steps)
        status = "OK" if solved else "PARTIAL" if final.empty_count < b.empty_count else "FAIL"
        print(f"\n  {status} {name}")
        print(f"      Time: {elapsed:.1f}ms  Steps: {steps}")
        if tech_breakdown:
            top = sorted(tech_breakdown.items(), key=lambda x: -x[1])[:5]
            print(f"      Top techniques: {', '.join(f'{t} x{c}' for t, c in top)}")

    print("\n" + "=" * 70)
    print("Done.")


if __name__ == "__main__":
    main()
