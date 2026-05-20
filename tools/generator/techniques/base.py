from __future__ import annotations

from itertools import combinations
from typing import Dict, Iterable, List, NamedTuple, Set, Tuple

Cell = Tuple[int, int]
Board = List[List[int]]
Candidates = Dict[Cell, Set[int]]


class TechniqueResult(NamedTuple):
    changed: bool
    affected_cells: List[Cell]
    technique: str


class BaseTechnique:
    name = "base"
    difficulty_weight = 0

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        raise NotImplementedError


def peers(r: int, c: int) -> Set[Cell]:
    result = {(r, i) for i in range(9)} | {(i, c) for i in range(9)}
    br, bc = (r // 3) * 3, (c // 3) * 3
    result |= {(rr, cc) for rr in range(br, br + 3) for cc in range(bc, bc + 3)}
    result.discard((r, c))
    return result


def units() -> List[List[Cell]]:
    rows = [[(r, c) for c in range(9)] for r in range(9)]
    cols = [[(r, c) for r in range(9)] for c in range(9)]
    boxes = [
        [(r, c) for r in range(br, br + 3) for c in range(bc, bc + 3)]
        for br in range(0, 9, 3)
        for bc in range(0, 9, 3)
    ]
    return rows + cols + boxes


def init_candidates(board: Board) -> Candidates:
    candidates: Candidates = {}
    for r in range(9):
        for c in range(9):
            if board[r][c] == 0:
                blocked = {board[rr][cc] for rr, cc in peers(r, c) if board[rr][cc] != 0}
                candidates[(r, c)] = set(range(1, 10)) - blocked
            else:
                candidates[(r, c)] = set()
    return candidates


def place(board: Board, candidates: Candidates, cell: Cell, value: int) -> None:
    r, c = cell
    board[r][c] = value
    candidates[cell] = set()
    for peer in peers(r, c):
        candidates[peer].discard(value)


def remove_values(candidates: Candidates, cells: Iterable[Cell], values: Set[int]) -> List[Cell]:
    changed: List[Cell] = []
    for cell in cells:
        before = set(candidates[cell])
        candidates[cell] -= values
        if candidates[cell] != before:
            changed.append(cell)
    return changed


def empty_count(board: Board) -> int:
    return sum(1 for row in board for value in row if value == 0)
