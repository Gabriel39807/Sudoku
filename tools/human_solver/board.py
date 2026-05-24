from __future__ import annotations
from copy import deepcopy
from dataclasses import dataclass, field
from typing import Dict, Iterator, List, Optional, Set, Tuple

DIGITS = set(range(1, 10))
ROWS = "ABCDEFGHI"


@dataclass(frozen=True)
class Cell:
    row: int
    col: int

    def __post_init__(self):
        assert 0 <= self.row < 9, f"Invalid row: {self.row}"
        assert 0 <= self.col < 9, f"Invalid col: {self.col}"

    @property
    def block(self) -> int:
        return (self.row // 3) * 3 + (self.col // 3)

    @property
    def block_row(self) -> int:
        return self.row // 3

    @property
    def block_col(self) -> int:
        return self.col // 3

    @property
    def row_name(self) -> str:
        return ROWS[self.row]

    @property
    def col_name(self) -> str:
        return str(self.col + 1)

    @property
    def name(self) -> str:
        return f"{self.row_name}{self.col_name}"

    def shares_house(self, other: Cell) -> bool:
        return (
            self.row == other.row
            or self.col == other.col
            or self.block == other.block
        )

    def peers(self) -> Iterator[Cell]:
        seen = set()
        for c in range(9):
            if c != self.col:
                cell = Cell(self.row, c)
                if cell not in seen:
                    seen.add(cell)
                    yield cell
        for r in range(9):
            if r != self.row:
                cell = Cell(r, self.col)
                if cell not in seen:
                    seen.add(cell)
                    yield cell
        br, bc = self.block_row, self.block_col
        for r in range(br * 3, br * 3 + 3):
            for c in range(bc * 3, bc * 3 + 3):
                if r != self.row or c != self.col:
                    cell = Cell(r, c)
                    if cell not in seen:
                        seen.add(cell)
                        yield cell

    def __repr__(self) -> str:
        return self.name


@dataclass
class Candidate:
    cell: Cell
    value: int

    def __repr__(self) -> str:
        return f"{self.cell.name}={self.value}"


class Board:
    def __init__(self, grid: List[List[int]]):
        assert len(grid) == 9, f"Expected 9 rows, got {len(grid)}"
        for row in grid:
            assert len(row) == 9, f"Expected 9 cols, got {len(row)}"

        self._grid: List[List[int]] = deepcopy(grid)
        self._candidates: Dict[Cell, Set[int]] = {}

        for r in range(9):
            for c in range(9):
                cell = Cell(r, c)
                if self._grid[r][c] == 0:
                    self._candidates[cell] = set(range(1, 10))
                else:
                    self._candidates[cell] = set()

        self._init_candidates()
        self._history: List[dict] = []
        self._technique_counts: Dict[str, int] = {}

    def _init_candidates(self):
        for r in range(9):
            for c in range(9):
                cell = Cell(r, c)
                if self._grid[r][c] != 0:
                    val = self._grid[r][c]
                    for peer in cell.peers():
                        if peer in self._candidates and val in self._candidates[peer]:
                            self._candidates[peer].discard(val)

    def clone(self) -> Board:
        return deepcopy(self)

    @property
    def grid(self) -> List[List[int]]:
        return deepcopy(self._grid)

    def get_cell(self, row: int, col: int) -> int:
        return self._grid[row][col]

    def get_candidates(self, row: int, col: int) -> Set[int]:
        return set(self._candidates.get(Cell(row, col), set()))

    def cells(self) -> Iterator[Cell]:
        for r in range(9):
            for c in range(9):
                yield Cell(r, c)

    def empty_cells(self) -> Iterator[Cell]:
        for r in range(9):
            for c in range(9):
                if self._grid[r][c] == 0:
                    yield Cell(r, c)

    def filled_cells(self) -> Iterator[Cell]:
        for r in range(9):
            for c in range(9):
                if self._grid[r][c] != 0:
                    yield Cell(r, c)

    def house_cells(self, house_type: str, index: int) -> List[Cell]:
        if house_type == "row":
            return [Cell(index, c) for c in range(9)]
        elif house_type == "col":
            return [Cell(r, index) for r in range(9)]
        elif house_type == "block":
            br, bc = divmod(index, 3)
            return [Cell(br * 3 + r, bc * 3 + c) for r in range(3) for c in range(3)]
        raise ValueError(f"Unknown house type: {house_type}")

    def house_values(self, house_type: str, index: int) -> Set[int]:
        return {
            self._grid[cell.row][cell.col]
            for cell in self.house_cells(house_type, index)
            if self._grid[cell.row][cell.col] != 0
        }

    def house_candidates(self, house_type: str, index: int) -> Dict[int, List[Cell]]:
        result: Dict[int, List[Cell]] = {d: [] for d in range(1, 10)}
        for cell in self.house_cells(house_type, index):
            if self._grid[cell.row][cell.col] == 0:
                for d in self._candidates.get(cell, set()):
                    result[d].append(cell)
        return result

    def place(self, row: int, col: int, value: int) -> bool:
        cell = Cell(row, col)
        if self._grid[row][col] != 0:
            return False
        if value not in self._candidates.get(cell, set()):
            return False

        self._grid[row][col] = value
        self._candidates[cell] = set()

        for peer in cell.peers():
            if peer in self._candidates and value in self._candidates[peer]:
                self._candidates[peer].discard(value)

        return True

    def eliminate(self, row: int, col: int, value: int) -> bool:
        cell = Cell(row, col)
        if cell not in self._candidates:
            return False
        if value not in self._candidates[cell]:
            return False
        self._candidates[cell].discard(value)
        return True

    def set_candidates(self, row: int, col: int, candidates: Set[int]):
        cell = Cell(row, col)
        if cell in self._candidates:
            self._candidates[cell] = set(candidates)

    def has_candidate(self, row: int, col: int, value: int) -> bool:
        cell = Cell(row, col)
        return cell in self._candidates and value in self._candidates[cell]

    def candidate_count(self, row: int, col: int) -> int:
        return len(self._candidates.get(Cell(row, col), set()))

    @property
    def is_solved(self) -> bool:
        if any(0 in row for row in self._grid):
            return False
        for i in range(9):
            vals = set(self._grid[i])
            if len(vals) != 9:
                return False
            vals = {self._grid[r][i] for r in range(9)}
            if len(vals) != 9:
                return False
        for b in range(9):
            br, bc = divmod(b, 3)
            vals = set()
            for r in range(br * 3, br * 3 + 3):
                for c in range(bc * 3, bc * 3 + 3):
                    vals.add(self._grid[r][c])
            if len(vals) != 9:
                return False
        return True

    @property
    def is_valid(self) -> bool:
        for r in range(9):
            vals = [v for v in self._grid[r] if v != 0]
            if len(vals) != len(set(vals)):
                return False
        for c in range(9):
            vals = [self._grid[r][c] for r in range(9) if self._grid[r][c] != 0]
            if len(vals) != len(set(vals)):
                return False
        for b in range(9):
            br, bc = divmod(b, 3)
            vals = []
            for r in range(br * 3, br * 3 + 3):
                for c in range(bc * 3, bc * 3 + 3):
                    if self._grid[r][c] != 0:
                        vals.append(self._grid[r][c])
            if len(vals) != len(set(vals)):
                return False
        return True

    @property
    def empty_count(self) -> int:
        return sum(1 for row in self._grid for v in row if v == 0)

    @property
    def candidates_count(self) -> int:
        return sum(len(cands) for cands in self._candidates.values())

    def cells_with_candidate(self, value: int) -> List[Cell]:
        return [
            cell
            for cell, cands in self._candidates.items()
            if value in cands
        ]

    def cells_with_candidates(self, count: int) -> List[Cell]:
        return [
            cell
            for cell, cands in self._candidates.items()
            if len(cands) == count
        ]

    def bivalue_cells(self) -> List[Cell]:
        return self.cells_with_candidates(2)

    def naked_singles(self) -> List[Cell]:
        return self.cells_with_candidates(1)

    def hidden_singles(self) -> List[TechniqueResult]:
        results: List[TechniqueResult] = []
        for ht in ("row", "col", "block"):
            for i in range(9):
                hc = self.house_candidates(ht, i)
                for d, cells in hc.items():
                    if len(cells) == 1:
                        cell = cells[0]
                        if self._grid[cell.row][cell.col] == 0:
                            results.append(
                                TechniqueResult(
                                    technique_id="hidden_single",
                                    placements=[(cell.row, cell.col, d)],
                                    eliminations=[],
                                    cells_affected=[cell],
                                    reason=f"Hidden Single: {d} appears only in {cell.name} in {ht} {i + 1}",
                                )
                            )
        return results

    def record_step(self, step: dict):
        self._history.append(step)

    def record_technique(self, tech_id: str):
        self._technique_counts[tech_id] = self._technique_counts.get(tech_id, 0) + 1

    @property
    def solve_history(self) -> List[dict]:
        return list(self._history)

    @property
    def technique_counts(self) -> Dict[str, int]:
        return dict(self._technique_counts)

    def display(self) -> str:
        lines = []
        for r in range(9):
            if r > 0 and r % 3 == 0:
                lines.append("------+-------+------")
            row_parts = []
            for c in range(9):
                if c > 0 and c % 3 == 0:
                    row_parts.append("|")
                val = self._grid[r][c]
                row_parts.append(str(val) if val != 0 else ".")
            lines.append(" ".join(row_parts))
        return "\n".join(lines)

    def to_snapshot(self) -> str:
        return self.display()

    def __repr__(self) -> str:
        return self.display()

    @staticmethod
    def from_string(s: str) -> Board:
        cleaned = s.replace(".", "0").replace(" ", "").replace("\n", "").replace("\r", "")
        assert len(cleaned) == 81, f"Expected 81 chars, got {len(cleaned)}"
        grid = [[int(cleaned[r * 9 + c]) for c in range(9)] for r in range(9)]
        return Board(grid)
