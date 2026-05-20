from __future__ import annotations

from copy import deepcopy
from typing import Any, Dict, List

from classify_by_techniques import classify_by_techniques
from difficulty_profiles import techniques_match_profile
from difficulty_score import human_score
from human_solver import solve_human
from validator import count_solutions, solve


def to_grid(value):
    if isinstance(value, str):
        if len(value) != 81 or any(ch not in "0123456789" for ch in value):
            return None
        return [[int(value[r * 9 + c]) for c in range(9)] for r in range(9)]
    if isinstance(value, list) and len(value) == 9 and all(isinstance(row, list) and len(row) == 9 for row in value):
        return [[int(cell) for cell in row] for row in value]
    return None


def _conflicts(board):
    errors = []
    for r in range(9):
        values = [v for v in board[r] if v != 0]
        if len(values) != len(set(values)):
            errors.append(f"row {r} has conflicts")
    for c in range(9):
        values = [board[r][c] for r in range(9) if board[r][c] != 0]
        if len(values) != len(set(values)):
            errors.append(f"column {c} has conflicts")
    for br in range(0, 9, 3):
        for bc in range(0, 9, 3):
            values = [board[r][c] for r in range(br, br + 3) for c in range(bc, bc + 3) if board[r][c] != 0]
            if len(values) != len(set(values)):
                errors.append(f"box {br // 3},{bc // 3} has conflicts")
    return errors


def validate_human_profile(techniques: List[str], steps: int, difficulty: str) -> List[str]:
    errors: List[str] = []
    from difficulty_profiles import get_profile
    profile = get_profile(difficulty)
    if profile is None:
        errors.append(f"no profile found for {difficulty}")
        return errors
    forbidden = set(profile["forbidden"])
    technique_set = set(techniques)
    if technique_set & forbidden:
        errors.append(f"forbidden techniques found: {technique_set & forbidden}")
    max_steps = profile["max_steps"]
    if steps > max_steps:
        errors.append(f"steps {steps} exceeds max {max_steps} for {difficulty}")
    min_steps = profile["min_steps"]
    if steps < min_steps:
        errors.append(f"steps {steps} below min {min_steps} for {difficulty}")
    score = human_score(techniques)
    from difficulty_score import score_range_for_difficulty
    lo, hi = score_range_for_difficulty(difficulty)
    if score < lo or score > hi:
        errors.append(f"human_score {score} out of range [{lo}, {hi}] for {difficulty}")
    return errors


def validate_board(puzzle, solution=None, difficulty=None) -> Dict[str, Any]:
    errors: List[str] = []
    puzzle_grid = to_grid(puzzle)
    solution_grid = to_grid(solution) if solution is not None else None

    if puzzle_grid is None:
        return {"valid": False, "errors": ["puzzle must be 9x9 or 81 digits"]}
    if any(cell < 0 or cell > 9 for row in puzzle_grid for cell in row):
        errors.append("puzzle contains numbers outside 0..9")
    errors.extend(_conflicts(puzzle_grid))

    if errors:
        return {
            "valid": False,
            "errors": errors,
            "classification": None,
            "techniques": [],
            "steps": 0,
            "solution": None,
        }

    solved = solve(puzzle_grid)
    if solved is None:
        errors.append("solution does not exist")
    elif count_solutions(deepcopy(puzzle_grid), 2) != 1:
        errors.append("solution is not unique")

    if solution_grid is not None:
        if any(cell < 1 or cell > 9 for row in solution_grid for cell in row):
            errors.append("solution contains numbers outside 1..9")
        errors.extend(f"solution {err}" for err in _conflicts(solution_grid))
        if solved is not None and solution_grid != solved:
            errors.append("provided solution does not match solved puzzle")
        if puzzle_grid == solution_grid:
            errors.append("puzzle equals solution")
        for r in range(9):
            for c in range(9):
                if puzzle_grid[r][c] != 0 and puzzle_grid[r][c] != solution_grid[r][c]:
                    errors.append(f"preloaded value mismatch at {r},{c}")

    techniques: List[str] = []
    steps = 0
    classified = None
    score = 0

    if not errors:
        human = solve_human(puzzle_grid)
        if not human["solved"]:
            errors.append("puzzle is not human-solvable by implemented techniques")
        else:
            techniques = human["techniques"]
            steps = human["steps"]
            classified = classify_by_techniques(techniques)
            if difficulty is not None and classified != difficulty:
                errors.append(f"classification mismatch: expected {difficulty}, got {classified}")
            score = human_score(techniques)

    if not errors and difficulty is not None:
        errors.extend(validate_human_profile(techniques, steps, difficulty))

    return {
        "valid": not errors,
        "errors": errors,
        "classification": classified,
        "techniques": techniques,
        "steps": steps,
        "solution": solved,
        "human_score": score,
    }
