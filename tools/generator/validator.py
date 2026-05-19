from __future__ import annotations

from copy import deepcopy
from typing import List, Optional, Tuple

Board = List[List[int]]


def find_empty(board: Board) -> Optional[Tuple[int, int]]:
    best = None
    best_values = None
    for r in range(9):
        for c in range(9):
            if board[r][c] == 0:
                values = possible_values(board, r, c)
                if best_values is None or len(values) < len(best_values):
                    best = (r, c)
                    best_values = values
    return best


def possible_values(board: Board, r: int, c: int):
    used = set(board[r]) | {board[i][c] for i in range(9)}
    br, bc = (r // 3) * 3, (c // 3) * 3
    used |= {board[rr][cc] for rr in range(br, br + 3) for cc in range(bc, bc + 3)}
    return [value for value in range(1, 10) if value not in used]


def solve_backtracking(board: Board) -> bool:
    empty = find_empty(board)
    if empty is None:
        return True
    r, c = empty
    for value in possible_values(board, r, c):
        board[r][c] = value
        if solve_backtracking(board):
            return True
        board[r][c] = 0
    return False


def count_solutions(board: Board, limit: int = 2) -> int:
    empty = find_empty(board)
    if empty is None:
        return 1
    r, c = empty
    total = 0
    for value in possible_values(board, r, c):
        board[r][c] = value
        total += count_solutions(board, limit)
        board[r][c] = 0
        if total >= limit:
            return total
    return total


def has_unique_solution(board: Board) -> bool:
    return count_solutions(deepcopy(board), 2) == 1


def solve(board: Board) -> Optional[Board]:
    copy = deepcopy(board)
    return copy if solve_backtracking(copy) else None
