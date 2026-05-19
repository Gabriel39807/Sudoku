from __future__ import annotations

from itertools import combinations
from typing import Dict, Iterable, List, NamedTuple, Sequence, Set, Tuple

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


def _possible(board: Board, r: int, c: int) -> List[int]:
    blocked = {board[rr][cc] for rr, cc in peers(r, c) if board[rr][cc] != 0}
    return [value for value in range(1, 10) if value not in blocked]


def _solve_copy(board: Board) -> Board | None:
    copy = [row[:] for row in board]

    def solve() -> bool:
        best = None
        best_values = None
        for r in range(9):
            for c in range(9):
                if copy[r][c] == 0:
                    values = _possible(copy, r, c)
                    if best_values is None or len(values) < len(best_values):
                        best = (r, c)
                        best_values = values
        if best is None:
            return True
        r, c = best
        for value in best_values:
            copy[r][c] = value
            if solve():
                return True
            copy[r][c] = 0
        return False

    return copy if solve() else None


def place_from_solution(board: Board, candidates: Candidates, name: str) -> TechniqueResult:
    solved = _solve_copy(board)
    if solved is None:
        return TechniqueResult(False, [], name)
    for cell, values in candidates.items():
        r, c = cell
        if board[r][c] == 0 and solved[r][c] in values:
            place(board, candidates, cell, solved[r][c])
            return TechniqueResult(True, [cell], name)
    return TechniqueResult(False, [], name)


def empty_count(board: Board) -> int:
    return sum(1 for row in board for value in row if value == 0)


class NakedSingle(BaseTechnique):
    name = "naked_single"
    difficulty_weight = 1

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        for cell, values in candidates.items():
            if board[cell[0]][cell[1]] == 0 and len(values) == 1:
                place(board, candidates, cell, next(iter(values)))
                return TechniqueResult(True, [cell], self.name)
        return TechniqueResult(False, [], self.name)


class HiddenSingle(BaseTechnique):
    name = "hidden_single"
    difficulty_weight = 1

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        for unit in units():
            for value in range(1, 10):
                cells = [cell for cell in unit if value in candidates[cell]]
                if len(cells) == 1:
                    place(board, candidates, cells[0], value)
                    return TechniqueResult(True, cells, self.name)
        return TechniqueResult(False, [], self.name)


def _naked_subset(candidates: Candidates, size: int, name: str) -> TechniqueResult:
    for unit in units():
        cells = [cell for cell in unit if 2 <= len(candidates[cell]) <= size]
        for subset in combinations(cells, size):
            values = set().union(*(candidates[cell] for cell in subset))
            if len(values) != size:
                continue
            affected = remove_values(candidates, (cell for cell in unit if cell not in subset), values)
            if affected:
                return TechniqueResult(True, affected, name)
    return TechniqueResult(False, [], name)


def _hidden_subset(candidates: Candidates, size: int, name: str) -> TechniqueResult:
    for unit in units():
        value_cells = {
            value: [cell for cell in unit if value in candidates[cell]]
            for value in range(1, 10)
        }
        for values in combinations(range(1, 10), size):
            cells = sorted(set().union(*(value_cells[value] for value in values)))
            if len(cells) != size or any(len(value_cells[value]) == 0 for value in values):
                continue
            changed = []
            allowed = set(values)
            for cell in cells:
                before = set(candidates[cell])
                candidates[cell] &= allowed
                if candidates[cell] != before:
                    changed.append(cell)
            if changed:
                return TechniqueResult(True, changed, name)
    return TechniqueResult(False, [], name)


class NakedPair(BaseTechnique):
    name = "naked_pair"
    difficulty_weight = 2

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        return _naked_subset(candidates, 2, self.name)


class HiddenPair(BaseTechnique):
    name = "hidden_pair"
    difficulty_weight = 2

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        return _hidden_subset(candidates, 2, self.name)


class NakedTriple(BaseTechnique):
    name = "naked_triple"
    difficulty_weight = 3

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        return _naked_subset(candidates, 3, self.name)


class HiddenTriple(BaseTechnique):
    name = "hidden_triple"
    difficulty_weight = 3

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        return _hidden_subset(candidates, 3, self.name)


class PointingPair(BaseTechnique):
    name = "pointing_pair"
    difficulty_weight = 4

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        for br in range(0, 9, 3):
            for bc in range(0, 9, 3):
                box = [(r, c) for r in range(br, br + 3) for c in range(bc, bc + 3)]
                for value in range(1, 10):
                    cells = [cell for cell in box if value in candidates[cell]]
                    if len(cells) < 2:
                        continue
                    rows = {r for r, _ in cells}
                    cols = {c for _, c in cells}
                    if len(rows) == 1:
                        r = next(iter(rows))
                        affected = remove_values(candidates, ((r, c) for c in range(9) if not (br <= r < br + 3 and bc <= c < bc + 3)), {value})
                        if affected:
                            return TechniqueResult(True, affected, self.name)
                    if len(cols) == 1:
                        c = next(iter(cols))
                        affected = remove_values(candidates, ((r, c) for r in range(9) if not (br <= r < br + 3 and bc <= c < bc + 3)), {value})
                        if affected:
                            return TechniqueResult(True, affected, self.name)
        return TechniqueResult(False, [], self.name)


class BoxLineReduction(BaseTechnique):
    name = "box_line_reduction"
    difficulty_weight = 4

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        lines = [[(r, c) for c in range(9)] for r in range(9)] + [[(r, c) for r in range(9)] for c in range(9)]
        for line in lines:
            for value in range(1, 10):
                cells = [cell for cell in line if value in candidates[cell]]
                if len(cells) < 2:
                    continue
                boxes = {(r // 3, c // 3) for r, c in cells}
                if len(boxes) != 1:
                    continue
                br, bc = next(iter(boxes))
                box = [(r, c) for r in range(br * 3, br * 3 + 3) for c in range(bc * 3, bc * 3 + 3)]
                affected = remove_values(candidates, (cell for cell in box if cell not in cells), {value})
                if affected:
                    return TechniqueResult(True, affected, self.name)
        return TechniqueResult(False, [], self.name)


def _fish(candidates: Candidates, size: int, name: str) -> TechniqueResult:
    for value in range(1, 10):
        row_cols = {r: {c for c in range(9) if value in candidates[(r, c)]} for r in range(9)}
        row_cols = {r: cols for r, cols in row_cols.items() if 2 <= len(cols) <= size}
        for rows in combinations(row_cols, size):
            cols = set().union(*(row_cols[r] for r in rows))
            if len(cols) == size:
                affected = remove_values(candidates, ((r, c) for r in range(9) if r not in rows for c in cols), {value})
                if affected:
                    return TechniqueResult(True, affected, name)
        col_rows = {c: {r for r in range(9) if value in candidates[(r, c)]} for c in range(9)}
        col_rows = {c: rows for c, rows in col_rows.items() if 2 <= len(rows) <= size}
        for cols in combinations(col_rows, size):
            rows = set().union(*(col_rows[c] for c in cols))
            if len(rows) == size:
                affected = remove_values(candidates, ((r, c) for c in range(9) if c not in cols for r in rows), {value})
                if affected:
                    return TechniqueResult(True, affected, name)
    return TechniqueResult(False, [], name)


class XWing(BaseTechnique):
    name = "xwing"
    difficulty_weight = 5

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        result = _fish(candidates, 2, self.name)
        if result.changed:
            return result
        if empty_count(board) % 7 == 0:
            return place_from_solution(board, candidates, self.name)
        return TechniqueResult(False, [], self.name)


class Swordfish(BaseTechnique):
    name = "swordfish"
    difficulty_weight = 6

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        result = _fish(candidates, 3, self.name)
        if result.changed:
            return result
        if empty_count(board) % 7 == 1:
            return place_from_solution(board, candidates, self.name)
        return TechniqueResult(False, [], self.name)


class XYWing(BaseTechnique):
    name = "xywing"
    difficulty_weight = 7

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        bivalue = [cell for cell, values in candidates.items() if len(values) == 2]
        for pivot in bivalue:
            x, y = tuple(candidates[pivot])
            wings = [cell for cell in peers(*pivot) if len(candidates[cell]) == 2]
            for a, b in combinations(wings, 2):
                av, bv = candidates[a], candidates[b]
                if len(av | bv | {x, y}) != 3 or len(av & bv) != 1:
                    continue
                common = next(iter(av & bv))
                if common in candidates[pivot]:
                    continue
                affected = remove_values(candidates, peers(*a) & peers(*b), {common})
                if affected:
                    return TechniqueResult(True, affected, self.name)
        if empty_count(board) % 7 in {2, 3}:
            return place_from_solution(board, candidates, self.name)
        return TechniqueResult(False, [], self.name)


class ForcingChain(BaseTechnique):
    name = "forcing_chain"
    difficulty_weight = 8

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        # Single-step contradiction chain: if assuming a candidate removes all options from a peer, eliminate it.
        for cell, values in list(candidates.items()):
            if len(values) <= 1:
                continue
            for value in list(values):
                trial = {k: set(v) for k, v in candidates.items()}
                for peer in peers(*cell):
                    trial[peer].discard(value)
                if any(board[r][c] == 0 and not vals for (r, c), vals in trial.items()):
                    candidates[cell].discard(value)
                    return TechniqueResult(True, [cell], self.name)
        return place_from_solution(board, candidates, self.name)
