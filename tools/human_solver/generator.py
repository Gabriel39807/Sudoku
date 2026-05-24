"""Puzzle generator using human pipeline as validator.

Pipeline: solved grid → remove cell(s) → human solver → uniqueness → visual profile → accept
"""

from __future__ import annotations
import random
from typing import Dict, List, Optional, Tuple

from tools.human_solver.board import Board
from tools.human_solver.difficulty import HumanDifficultyScore
from tools.human_solver.pipeline import Pipeline
from tools.human_solver.uniqueness import has_unique_solution
from tools.human_solver.visual_profiles import get_profile, VisualProfile


def _rotational_pair(r: int, c: int) -> Tuple[int, int]:
    """180-degree rotational symmetry partner."""
    return (8 - r, 8 - c)


def _mirror_h_pair(r: int, c: int) -> Tuple[int, int]:
    """Horizontal mirror symmetry partner."""
    return (8 - r, c)


def _mirror_v_pair(r: int, c: int) -> Tuple[int, int]:
    """Vertical mirror symmetry partner."""
    return (r, 8 - c)


def _build_cell_groups(mode: str) -> List[List[Tuple[int, int]]]:
    """Build cell groups for removal based on symmetry mode."""
    all_cells = [(r, c) for r in range(9) for c in range(9)]
    used = set()
    groups = []

    fn = None
    if mode == "rotational":
        fn = _rotational_pair
    elif mode == "mirror":
        fn = _mirror_h_pair
    else:
        return [[cell] for cell in all_cells]

    for r, c in all_cells:
        if (r, c) in used:
            continue
        pr, pc = fn(r, c)
        if (pr, pc) == (r, c):
            groups.append([(r, c)])
            used.add((r, c))
        else:
            groups.append([(r, c), (pr, pc)])
            used.add((r, c))
            used.add((pr, pc))

    return groups


class PuzzleGenerator:
    def __init__(self, seed: Optional[int] = None):
        if seed is not None:
            random.seed(seed)
        self._pipeline = Pipeline()

    def generate_solved(self) -> Board:
        """Generate a fully solved board using backtracking."""
        grid = [[0] * 9 for _ in range(9)]
        for i in range(0, 9, 3):
            nums = list(range(1, 10))
            random.shuffle(nums)
            for r in range(3):
                for c in range(3):
                    grid[i + r][i + c] = nums.pop()
        self._backtrack_solve(grid)
        return Board(grid)

    def _backtrack_solve(self, grid: List[List[int]]) -> bool:
        best = None
        best_vals = None
        for r in range(9):
            for c in range(9):
                if grid[r][c] == 0:
                    vals = [v for v in range(1, 10) if self._is_valid(grid, r, c, v)]
                    if best_vals is None or len(vals) < len(best_vals):
                        best = (r, c)
                        best_vals = vals
        if best is None:
            return True
        r, c = best
        random.shuffle(best_vals)
        for v in best_vals:
            grid[r][c] = v
            if self._backtrack_solve(grid):
                return True
            grid[r][c] = 0
        return False

    @staticmethod
    def _is_valid(grid: List[List[int]], r: int, c: int, val: int) -> bool:
        for i in range(9):
            if grid[r][i] == val or grid[i][c] == val:
                return False
        br, bc = r // 3 * 3, c // 3 * 3
        for i in range(3):
            for j in range(3):
                if grid[br + i][bc + j] == val:
                    return False
        return True

    def _score_puzzle(self, puzzle_str: str) -> Optional[dict]:
        b = Board.from_string(puzzle_str)
        solved, _ = self._pipeline.solve(b)
        if not solved:
            return None
        return HumanDifficultyScore(self._pipeline.explainer.steps).details

    def _attempt_remove(
        self, grid: List[List[int]], profile: VisualProfile, groups: List[List[Tuple[int, int]]]
    ) -> Optional[int]:
        """Try removing cell groups one by one, validating each step.

        Returns final clue count, or None if no valid puzzle found.
        """
        removed = 0

        for group in groups:
            values = [grid[r][c] for r, c in group]

            for r, c in group:
                grid[r][c] = 0

            puzzle_str = "".join(str(grid[r][c]) for r in range(9) for c in range(9))

            score = self._score_puzzle(puzzle_str)
            valid = score is not None and has_unique_solution(puzzle_str)

            if not valid:
                for (r, c), val in zip(group, values):
                    grid[r][c] = val
                continue

            removed += len(group)
            clues = 81 - removed

            if clues <= profile.min_clues:
                return clues

        return 81 - removed

    def generate(
        self,
        difficulty: str = "easy",
        max_attempts: int = 20,
    ) -> Optional[Dict]:
        profile = get_profile(difficulty)

        for attempt in range(max_attempts):
            solved = self.generate_solved()
            solution_str = "".join(
                str(solved.get_cell(r, c)) for r in range(9) for c in range(9)
            )
            grid = [[solved.get_cell(r, c) for c in range(9)] for r in range(9)]

            groups = _build_cell_groups(profile.symmetry_mode)
            random.shuffle(groups)

            clues = self._attempt_remove(grid, profile, groups)
            if clues is None:
                continue

            if not profile.clues_in_range(clues):
                continue

            puzzle_str = "".join(str(grid[r][c]) for r in range(9) for c in range(9))
            score = self._score_puzzle(puzzle_str)
            if score is None:
                continue
            if score["tier_max"] > profile.max_tier:
                continue

            return {
                "puzzle": puzzle_str,
                "solution": solution_str,
                "difficulty": difficulty,
                "difficulty_label": profile.label,
                "difficulty_score": score["total_score"],
                "tier_max": score["tier_max"],
                "clues": clues,
                "fill_percent": round(clues / 81 * 100, 1),
                "symmetry": profile.symmetry_mode,
                "attempts": attempt + 1,
                "technique_breakdown": score["technique_breakdown"],
            }

        return None

    def validate_puzzle(self, puzzle_str: str) -> Dict:
        b = Board.from_string(puzzle_str)
        if not b.is_valid:
            return {"valid": False, "solved": False, "error": "Invalid puzzle"}
        score = self._score_puzzle(puzzle_str)
        unique = has_unique_solution(puzzle_str)
        return {
            "valid": True,
            "solved": score is not None,
            "unique": unique,
            "clues": 81 - b.empty_count,
            "difficulty_score": score,
        }
