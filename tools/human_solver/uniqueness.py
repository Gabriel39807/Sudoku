"""Uniqueness checker — verifies exactly 1 solution exists."""

from typing import List, Optional, Tuple


def _grid_from_string(puzzle: str) -> List[List[int]]:
    grid = [[0] * 9 for _ in range(9)]
    for i, ch in enumerate(puzzle):
        if ch.isdigit():
            grid[i // 9][i % 9] = int(ch)
    return grid


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


def _find_best(grid: List[List[int]]) -> Optional[Tuple[int, int, List[int]]]:
    best = None
    best_vals = None
    for r in range(9):
        for c in range(9):
            if grid[r][c] == 0:
                vals = [v for v in range(1, 10) if _is_valid(grid, r, c, v)]
                if not vals:
                    return None
                if best_vals is None or len(vals) < len(best_vals):
                    best = (r, c)
                    best_vals = vals
    if best is None:
        return None
    r, c = best
    return r, c, best_vals


def _count_solutions(grid: List[List[int]], limit: int = 2) -> int:
    found = _find_best(grid)
    if found is None:
        return 1
    r, c, vals = found
    count = 0
    for v in vals:
        grid[r][c] = v
        count += _count_solutions(grid, limit - count)
        grid[r][c] = 0
        if count >= limit:
            return count
    return count


def has_unique_solution(puzzle: str) -> bool:
    if len(puzzle) != 81:
        return False
    grid = _grid_from_string(puzzle)
    return _count_solutions(grid, limit=2) == 1


def count_solutions(puzzle: str, limit: int = 100) -> int:
    grid = _grid_from_string(puzzle)
    return _count_solutions(grid, limit=limit)
