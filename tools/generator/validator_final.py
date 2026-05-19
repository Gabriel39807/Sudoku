from __future__ import annotations

from copy import deepcopy
from typing import Dict, List

from classify_by_techniques import classify_by_techniques
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


def validate_board(puzzle, solution=None, difficulty=None) -> Dict[str, object]:
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
            "steps": [],
            "solution": None,
        }

    solved = solve(puzzle_grid)
    if solved is None:
        errors.append("solution does not exist")
    if count_solutions(deepcopy(puzzle_grid), 2) != 1:
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

    human = solve_human(puzzle_grid)
    if not human["solved"]:
        errors.append("puzzle is not human-solvable by implemented techniques")

    classified = classify_by_techniques(human["techniques"])
    if difficulty is not None and classified != difficulty:
        errors.append(f"classification mismatch: expected {difficulty}, got {classified}")

    return {
        "valid": not errors,
        "errors": errors,
        "classification": classified,
        "techniques": human["techniques"],
        "steps": human["steps"],
        "solution": solved,
    }
