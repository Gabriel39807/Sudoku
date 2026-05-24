from __future__ import annotations
import time
from dataclasses import dataclass, field
from typing import Dict, List, Optional

from tools.human_solver.board import Board
from tools.human_solver.difficulty import HumanDifficultyScore
from tools.human_solver.pipeline import Pipeline
from tools.human_solver.registry import Registry


@dataclass
class BenchmarkResult:
    puzzle_name: str
    solved: bool
    steps: int = 0
    time_ms: float = 0.0
    techniques_used: Dict[str, int] = field(default_factory=dict)
    empty_before: int = 0
    empty_after: int = 0
    error: Optional[str] = None
    difficulty_score: Optional[dict] = None


class BenchmarkRunner:
    def __init__(self, registry: Optional[Registry] = None):
        self._registry = registry or Registry.instance()
        self._pipeline = Pipeline(self._registry)
        self._results: List[BenchmarkResult] = []
        self._puzzles: Dict[str, str] = {}

    def register_puzzle(self, name: str, puzzle_string: str):
        self._puzzles[name] = puzzle_string

    def register_puzzles(self, puzzles: Dict[str, str]):
        self._puzzles.update(puzzles)

    def run_all(self, max_iterations: int = 1000) -> List[BenchmarkResult]:
        self._results = []
        for name, puzzle_str in self._puzzles.items():
            result = self.run_single(name, puzzle_str, max_iterations)
            self._results.append(result)
        return self._results

    def run_single(
        self, name: str, puzzle_str: str, max_iterations: int = 1000
    ) -> BenchmarkResult:
        try:
            board = Board.from_string(puzzle_str)
        except (AssertionError, ValueError) as e:
            return BenchmarkResult(
                puzzle_name=name, solved=False, error=f"Invalid puzzle: {e}",
                empty_before=81, empty_after=81,
            )
        empty_before = board.empty_count
        start = time.perf_counter()
        try:
            solved, final_board = self._pipeline.solve(board, max_iterations)
            elapsed = (time.perf_counter() - start) * 1000
            diff_score = None
            if solved and len(self._pipeline.explainer.steps) > 0:
                diff_score = HumanDifficultyScore(
                    self._pipeline.explainer.steps
                ).details
            return BenchmarkResult(
                puzzle_name=name,
                solved=solved,
                steps=len(self._pipeline.explainer.steps),
                time_ms=round(elapsed, 2),
                techniques_used=dict(final_board.technique_counts),
                empty_before=empty_before,
                empty_after=final_board.empty_count,
                difficulty_score=diff_score,
            )
        except Exception as e:
            elapsed = (time.perf_counter() - start) * 1000
            return BenchmarkResult(
                puzzle_name=name,
                solved=False,
                time_ms=round(elapsed, 2),
                error=str(e),
                empty_before=empty_before,
                empty_after=empty_before,
            )

    @property
    def results(self) -> List[BenchmarkResult]:
        return list(self._results)

    def summary(self) -> str:
        if not self._results:
            return "No benchmark results."
        lines = []
        lines.append("=" * 70)
        lines.append("BENCHMARK SUMMARY")
        lines.append("=" * 70)
        solved_count = sum(1 for r in self._results if r.solved)
        total_time = sum(r.time_ms for r in self._results)
        lines.append(f"Puzzles: {len(self._results)} | Solved: {solved_count}")
        lines.append(f"Total time: {total_time:.0f}ms")
        lines.append("")
        for r in self._results:
            status = "+" if r.solved else "-"
            lines.append(
                f"  {status} {r.puzzle_name:25s} "
                f"steps={r.steps:3d} time={r.time_ms:8.2f}ms "
                f"empty={r.empty_before}->{r.empty_after}"
            )
            if r.error:
                lines.append(f"      ERROR: {r.error}")
        lines.append("")
        tech_totals: Dict[str, int] = {}
        for r in self._results:
            for tech_id, count in r.techniques_used.items():
                tech_totals[tech_id] = tech_totals.get(tech_id, 0) + count
        if tech_totals:
            lines.append("Technique usage across all puzzles:")
            for tech_id in sorted(tech_totals, key=lambda t: -tech_totals[t]):
                lines.append(f"  {tech_id:30s} x{tech_totals[tech_id]}")
        return "\n".join(lines)

    def to_dict(self) -> List[dict]:
        return [
            {
                "puzzle_name": r.puzzle_name,
                "solved": r.solved,
                "steps": r.steps,
                "time_ms": r.time_ms,
                "techniques_used": r.techniques_used,
                "empty_before": r.empty_before,
                "empty_after": r.empty_after,
                "error": r.error,
                "difficulty_score": r.difficulty_score,
            }
            for r in self._results
        ]
