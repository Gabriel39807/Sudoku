#!/usr/bin/env python3
"""Export solver trace to JSON for visual replay."""
import sys, os, json
from typing import Optional

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from human_solver.board import Board
from human_solver.pipeline import Pipeline
from human_solver.explainer import Explainer


def export_trace(
    puzzle_string: str,
    output_path: Optional[str] = None,
    max_iterations: int = 200,
) -> dict:
    p = Pipeline()
    b = Board.from_string(puzzle_string)
    solved, final = p.solve(b, max_iterations)
    trace = p.explainer.to_replay()
    trace["metadata"]["puzzle"] = puzzle_string
    trace["metadata"]["solved"] = solved

    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(trace, f, indent=2, ensure_ascii=False)
        print(f"Trace saved to: {output_path}")

    return trace
