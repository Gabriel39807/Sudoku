"""Mini 8x8 Sudoku engine — 2x4 blocks, tiered technique solver (5 tiers)."""

import random
from typing import Dict, List, Optional, Set, Tuple

N = 8
BOX_ROWS = 2
BOX_COLS = 4
CELLS = 64


class Mini8x8Board:
    def __init__(self, grid: Optional[List[List[int]]] = None):
        self.grid = grid or [[0] * N for _ in range(N)]
        self._cands: Optional[List[List[Set[int]]]] = None

    @classmethod
    def from_string(cls, s: str) -> "Mini8x8Board":
        if len(s) != CELLS:
            raise ValueError(f"Expected {CELLS} chars, got {len(s)}")
        grid = [[int(s[r * N + c]) for c in range(N)] for r in range(N)]
        return cls(grid)

    def to_string(self) -> str:
        return "".join(str(self.grid[r][c]) for r in range(N) for c in range(N))

    def get_cell(self, r: int, c: int) -> int:
        return self.grid[r][c]

    def set_cell(self, r: int, c: int, val: int):
        self.grid[r][c] = val
        if self._cands is not None:
            self._cands[r][c] = set()
            for i in range(N):
                self._cands[r][i].discard(val)
                self._cands[i][c].discard(val)
            br = (r // BOX_ROWS) * BOX_ROWS
            bc = (c // BOX_COLS) * BOX_COLS
            for i in range(BOX_ROWS):
                for j in range(BOX_COLS):
                    self._cands[br + i][bc + j].discard(val)

    def candidates(self, r: int, c: int) -> Set[int]:
        if self._cands is None:
            self._init_cands()
        return self._cands[r][c]

    def eliminate(self, r: int, c: int, val: int) -> bool:
        if self._cands is None:
            self._init_cands()
        if val in self._cands[r][c]:
            self._cands[r][c].discard(val)
            return True
        return False

    def _init_cands(self):
        self._cands = [[set() for _ in range(N)] for _ in range(N)]
        for r in range(N):
            for c in range(N):
                if self.grid[r][c] == 0:
                    self._cands[r][c] = self._compute_cell_cands(r, c)

    def _compute_cell_cands(self, r: int, c: int) -> Set[int]:
        used: Set[int] = set()
        for i in range(N):
            if self.grid[r][i]:
                used.add(self.grid[r][i])
            if self.grid[i][c]:
                used.add(self.grid[i][c])
        br = (r // BOX_ROWS) * BOX_ROWS
        bc = (c // BOX_COLS) * BOX_COLS
        for i in range(BOX_ROWS):
            for j in range(BOX_COLS):
                if self.grid[br + i][bc + j]:
                    used.add(self.grid[br + i][bc + j])
        return {v for v in range(1, N + 1) if v not in used}

    def reset_cands(self):
        self._cands = None

    def clone(self) -> "Mini8x8Board":
        new = Mini8x8Board([row[:] for row in self.grid])
        if self._cands is not None:
            new._cands = [[set(c) for c in row] for row in self._cands]
        return new

    def is_solved(self) -> bool:
        return all(self.grid[r][c] != 0 for r in range(N) for c in range(N))

    def is_valid(self) -> bool:
        for r in range(N):
            vals = [self.grid[r][c] for c in range(N) if self.grid[r][c] != 0]
            if len(vals) != len(set(vals)):
                return False
        for c in range(N):
            vals = [self.grid[r][c] for r in range(N) if self.grid[r][c] != 0]
            if len(vals) != len(set(vals)):
                return False
        for br in range(0, N, BOX_ROWS):
            for bc in range(0, N, BOX_COLS):
                vals = []
                for i in range(BOX_ROWS):
                    for j in range(BOX_COLS):
                        if self.grid[br + i][bc + j] != 0:
                            vals.append(self.grid[br + i][bc + j])
                if len(vals) != len(set(vals)):
                    return False
        return True


class Mini8x8TechniqueSolver:
    """Tiered solver for 8x8. Returns (solved, max_tier_used)."""

    TECHNIQUES = [
        (1, "naked_single"),
        (1, "hidden_single"),
        (2, "pointing_pair"),
        (2, "pointing_triple"),
        (2, "box_line_reduction"),
        (3, "naked_pair"),
        (3, "hidden_pair"),
        (3, "naked_triple"),
        (4, "hidden_triple"),
        (4, "naked_quad"),
        (5, "hidden_quad"),
        (5, "xwing"),
    ]

    @staticmethod
    def solve(board: "Mini8x8Board") -> Tuple[bool, int]:
        b = board.clone()
        b._init_cands()
        max_tier = 0
        changed = True
        while changed and not b.is_solved():
            changed = False
            for tier, name in Mini8x8TechniqueSolver.TECHNIQUES:
                fn = getattr(Mini8x8TechniqueSolver, f"_{name}")
                if fn(b):
                    changed = True
                    if tier > max_tier:
                        max_tier = tier
                    break
            if not changed:
                break
        return b.is_solved(), max_tier

    @staticmethod
    def solve_with_limit(board: "Mini8x8Board", max_tier: int) -> bool:
        b = board.clone()
        b._init_cands()
        changed = True
        while changed and not b.is_solved():
            changed = False
            for tier, name in Mini8x8TechniqueSolver.TECHNIQUES:
                if tier > max_tier:
                    continue
                fn = getattr(Mini8x8TechniqueSolver, f"_{name}")
                if fn(b):
                    changed = True
                    break
            if not changed:
                break
        return b.is_solved()

    # Tier 1

    @staticmethod
    def _naked_single(board: Mini8x8Board) -> bool:
        for r in range(N):
            for c in range(N):
                if board.grid[r][c] == 0:
                    cands = board.candidates(r, c)
                    if len(cands) == 1:
                        board.set_cell(r, c, cands.pop())
                        return True
        return False

    @staticmethod
    def _hidden_single(board: Mini8x8Board) -> bool:
        for r in range(N):
            for val in range(1, N + 1):
                cells = [(r, c) for c in range(N) if board.grid[r][c] == 0 and val in board.candidates(r, c)]
                if len(cells) == 1:
                    board.set_cell(cells[0][0], cells[0][1], val)
                    return True
        for c in range(N):
            for val in range(1, N + 1):
                cells = [(r, c) for r in range(N) if board.grid[r][c] == 0 and val in board.candidates(r, c)]
                if len(cells) == 1:
                    board.set_cell(cells[0][0], cells[0][1], val)
                    return True
        for br in range(0, N, BOX_ROWS):
            for bc in range(0, N, BOX_COLS):
                for val in range(1, N + 1):
                    cells = []
                    for i in range(BOX_ROWS):
                        for j in range(BOX_COLS):
                            r, c = br + i, bc + j
                            if board.grid[r][c] == 0 and val in board.candidates(r, c):
                                cells.append((r, c))
                    if len(cells) == 1:
                        board.set_cell(cells[0][0], cells[0][1], val)
                        return True
        return False

    # Tier 2

    @staticmethod
    def _pointing_pair(board: Mini8x8Board) -> bool:
        for br in range(0, N, BOX_ROWS):
            for bc in range(0, N, BOX_COLS):
                for val in range(1, N + 1):
                    block_cells = []
                    for i in range(BOX_ROWS):
                        for j in range(BOX_COLS):
                            r, c = br + i, bc + j
                            if board.grid[r][c] == 0 and val in board.candidates(r, c):
                                block_cells.append((r, c))
                    if len(block_cells) != 2:
                        continue
                    rows = {r for r, c in block_cells}
                    cols = {c for r, c in block_cells}
                    if len(rows) == 1:
                        r = rows.pop()
                        changed = False
                        for c2 in range(N):
                            if board.grid[r][c2] == 0 and (r, c2) not in block_cells:
                                if board.eliminate(r, c2, val):
                                    changed = True
                        if changed:
                            return True
                    if len(cols) == 1:
                        c = cols.pop()
                        changed = False
                        for r2 in range(N):
                            if board.grid[r2][c] == 0 and (r2, c) not in block_cells:
                                if board.eliminate(r2, c, val):
                                    changed = True
                        if changed:
                            return True
        return False

    @staticmethod
    def _pointing_triple(board: Mini8x8Board) -> bool:
        for br in range(0, N, BOX_ROWS):
            for bc in range(0, N, BOX_COLS):
                for val in range(1, N + 1):
                    block_cells = []
                    for i in range(BOX_ROWS):
                        for j in range(BOX_COLS):
                            r, c = br + i, bc + j
                            if board.grid[r][c] == 0 and val in board.candidates(r, c):
                                block_cells.append((r, c))
                    if len(block_cells) not in (3, 4):
                        continue
                    rows = {r for r, c in block_cells}
                    cols = {c for r, c in block_cells}
                    if len(rows) == 1:
                        r = rows.pop()
                        changed = False
                        for c2 in range(N):
                            if board.grid[r][c2] == 0 and (r, c2) not in block_cells:
                                if board.eliminate(r, c2, val):
                                    changed = True
                        if changed:
                            return True
                    if len(cols) == 1:
                        c = cols.pop()
                        changed = False
                        for r2 in range(N):
                            if board.grid[r2][c] == 0 and (r2, c) not in block_cells:
                                if board.eliminate(r2, c, val):
                                    changed = True
                        if changed:
                            return True
        return False

    @staticmethod
    def _box_line_reduction(board: Mini8x8Board) -> bool:
        for val in range(1, N + 1):
            for r in range(N):
                in_block_cols: Set[int] = set()
                block_br = (r // BOX_ROWS) * BOX_ROWS
                for bc in range(0, N, BOX_COLS):
                    for c in range(bc, bc + BOX_COLS):
                        if board.grid[r][c] == 0 and val in board.candidates(r, c):
                            in_block_cols.add(bc)
                if len(in_block_cols) == 1:
                    bc = in_block_cols.pop()
                    changed = False
                    for i in range(BOX_ROWS):
                        ri = block_br + i
                        if ri == r:
                            continue
                        for c in range(bc, bc + BOX_COLS):
                            if board.grid[ri][c] == 0 and val in board.candidates(ri, c):
                                if board.eliminate(ri, c, val):
                                    changed = True
                    if changed:
                        return True
            for c in range(N):
                in_block_rows: Set[int] = set()
                block_bc = (c // BOX_COLS) * BOX_COLS
                for br in range(0, N, BOX_ROWS):
                    for r in range(br, br + BOX_ROWS):
                        if board.grid[r][c] == 0 and val in board.candidates(r, c):
                            in_block_rows.add(br)
                if len(in_block_rows) == 1:
                    br = in_block_rows.pop()
                    changed = False
                    for j in range(BOX_COLS):
                        cj = block_bc + j
                        if cj == c:
                            continue
                        for r in range(br, br + BOX_ROWS):
                            if board.grid[r][cj] == 0 and val in board.candidates(r, cj):
                                if board.eliminate(r, cj, val):
                                    changed = True
                    if changed:
                        return True
        return False

    # Tier 3

    @staticmethod
    def _naked_pair(board: Mini8x8Board) -> bool:
        houses = Mini8x8TechniqueSolver._houses()
        for cells in houses:
            pair_cells = [(r, c) for r, c in cells if board.grid[r][c] == 0 and len(board.candidates(r, c)) == 2]
            for i in range(len(pair_cells)):
                for j in range(i + 1, len(pair_cells)):
                    r1, c1 = pair_cells[i]
                    r2, c2 = pair_cells[j]
                    if board.candidates(r1, c1) == board.candidates(r2, c2):
                        vals = board.candidates(r1, c1)
                        changed = False
                        for r, c in cells:
                            if (r, c) in ((r1, c1), (r2, c2)):
                                continue
                            if board.grid[r][c] == 0:
                                for v in vals:
                                    if board.eliminate(r, c, v):
                                        changed = True
                        if changed:
                            return True
        return False

    @staticmethod
    def _hidden_pair(board: Mini8x8Board) -> bool:
        houses = Mini8x8TechniqueSolver._houses()
        for cells in houses:
            for va in range(1, N + 1):
                cells_va = [(r, c) for r, c in cells if board.grid[r][c] == 0 and va in board.candidates(r, c)]
                if len(cells_va) != 2:
                    continue
                for vb in range(va + 1, N + 1):
                    cells_vb = [(r, c) for r, c in cells if board.grid[r][c] == 0 and vb in board.candidates(r, c)]
                    if set(cells_va) == set(cells_vb):
                        changed = False
                        for r, c in cells_va:
                            for v in list(board.candidates(r, c)):
                                if v != va and v != vb:
                                    if board.eliminate(r, c, v):
                                        changed = True
                        if changed:
                            return True
        return False

    @staticmethod
    def _naked_triple(board: Mini8x8Board) -> bool:
        houses = Mini8x8TechniqueSolver._houses()
        for cells in houses:
            tc = [(r, c) for r, c in cells if board.grid[r][c] == 0 and 2 <= len(board.candidates(r, c)) <= 3]
            if len(tc) < 3:
                continue
            for i in range(len(tc)):
                for j in range(i + 1, len(tc)):
                    for k in range(j + 1, len(tc)):
                        r1, c1 = tc[i]; r2, c2 = tc[j]; r3, c3 = tc[k]
                        union = board.candidates(r1, c1) | board.candidates(r2, c2) | board.candidates(r3, c3)
                        if len(union) == 3:
                            changed = False
                            for r, c in cells:
                                if (r, c) in ((r1, c1), (r2, c2), (r3, c3)):
                                    continue
                                if board.grid[r][c] == 0:
                                    for v in union:
                                        if board.eliminate(r, c, v):
                                            changed = True
                            if changed:
                                return True
        return False

    # Tier 4

    @staticmethod
    def _hidden_triple(board: Mini8x8Board) -> bool:
        houses = Mini8x8TechniqueSolver._houses()
        for cells in houses:
            for va in range(1, N + 1):
                cells_a = {(r, c) for r, c in cells if board.grid[r][c] == 0 and va in board.candidates(r, c)}
                if not cells_a:
                    continue
                for vb in range(va + 1, N + 1):
                    cells_b = {(r, c) for r, c in cells if board.grid[r][c] == 0 and vb in board.candidates(r, c)}
                    union = cells_a | cells_b
                    if len(union) > 3:
                        continue
                    for vc in range(vb + 1, N + 1):
                        cells_c = {(r, c) for r, c in cells if board.grid[r][c] == 0 and vc in board.candidates(r, c)}
                        full = union | cells_c
                        if len(full) != 3:
                            continue
                        vals_set = {va, vb, vc}
                        changed = False
                        for r, c in full:
                            for v in list(board.candidates(r, c)):
                                if v not in vals_set:
                                    if board.eliminate(r, c, v):
                                        changed = True
                        if changed:
                            return True
        return False

    @staticmethod
    def _naked_quad(board: Mini8x8Board) -> bool:
        houses = Mini8x8TechniqueSolver._houses()
        for cells in houses:
            qc = [(r, c) for r, c in cells if board.grid[r][c] == 0 and 2 <= len(board.candidates(r, c)) <= 4]
            if len(qc) < 4:
                continue
            for i in range(len(qc)):
                for j in range(i + 1, len(qc)):
                    for k in range(j + 1, len(qc)):
                        for m in range(k + 1, len(qc)):
                            cells4 = [qc[i], qc[j], qc[k], qc[m]]
                            union: Set[int] = set()
                            for r, c in cells4:
                                union |= board.candidates(r, c)
                            if len(union) == 4:
                                changed = False
                                for r, c in cells:
                                    if (r, c) in cells4:
                                        continue
                                    if board.grid[r][c] == 0:
                                        for v in union:
                                            if board.eliminate(r, c, v):
                                                changed = True
                                if changed:
                                    return True
        return False

    # Tier 5

    @staticmethod
    def _hidden_quad(board: Mini8x8Board) -> bool:
        houses = Mini8x8TechniqueSolver._houses()
        for cells in houses:
            present: Dict[int, Set[Tuple[int, int]]] = {}
            for v in range(1, N + 1):
                s = {(r, c) for r, c in cells if board.grid[r][c] == 0 and v in board.candidates(r, c)}
                if s:
                    present[v] = s
            for va in range(1, N + 1):
                if va not in present or len(present[va]) > 4:
                    continue
                for vb in range(va + 1, N + 1):
                    if vb not in present:
                        continue
                    u2 = present[va] | present[vb]
                    if len(u2) > 4:
                        continue
                    for vc in range(vb + 1, N + 1):
                        if vc not in present:
                            continue
                        u3 = u2 | present[vc]
                        if len(u3) > 4:
                            continue
                        for vd in range(vc + 1, N + 1):
                            if vd not in present:
                                continue
                            u4 = u3 | present[vd]
                            if len(u4) != 4:
                                continue
                            vals_set = {va, vb, vc, vd}
                            changed = False
                            for r, c in u4:
                                for v in list(board.candidates(r, c)):
                                    if v not in vals_set:
                                        if board.eliminate(r, c, v):
                                            changed = True
                            if changed:
                                return True
        return False

    @staticmethod
    def _xwing(board: Mini8x8Board) -> bool:
        for val in range(1, N + 1):
            for r1 in range(N):
                cols_r1 = [c for c in range(N) if board.grid[r1][c] == 0 and val in board.candidates(r1, c)]
                if len(cols_r1) != 2:
                    continue
                for r2 in range(r1 + 1, N):
                    cols_r2 = [c for c in range(N) if board.grid[r2][c] == 0 and val in board.candidates(r2, c)]
                    if len(cols_r2) != 2 or set(cols_r1) != set(cols_r2):
                        continue
                    c1, c2 = cols_r1
                    changed = False
                    for r in range(N):
                        if r in (r1, r2):
                            continue
                        if board.grid[r][c1] == 0 and val in board.candidates(r, c1):
                            if board.eliminate(r, c1, val):
                                changed = True
                        if board.grid[r][c2] == 0 and val in board.candidates(r, c2):
                            if board.eliminate(r, c2, val):
                                changed = True
                    if changed:
                        return True
            for c1 in range(N):
                rows_c1 = [r for r in range(N) if board.grid[r][c1] == 0 and val in board.candidates(r, c1)]
                if len(rows_c1) != 2:
                    continue
                for c2 in range(c1 + 1, N):
                    rows_c2 = [r for r in range(N) if board.grid[r][c2] == 0 and val in board.candidates(r, c2)]
                    if len(rows_c2) != 2 or set(rows_c1) != set(rows_c2):
                        continue
                    r1, r2 = rows_c1
                    changed = False
                    for c in range(N):
                        if c in (c1, c2):
                            continue
                        if board.grid[r1][c] == 0 and val in board.candidates(r1, c):
                            if board.eliminate(r1, c, val):
                                changed = True
                        if board.grid[r2][c] == 0 and val in board.candidates(r2, c):
                            if board.eliminate(r2, c, val):
                                changed = True
                    if changed:
                        return True
        return False

    @staticmethod
    def _houses() -> List[List[Tuple[int, int]]]:
        result = []
        for r in range(N):
            result.append([(r, c) for c in range(N)])
        for c in range(N):
            result.append([(r, c) for r in range(N)])
        for br in range(0, N, BOX_ROWS):
            for bc in range(0, N, BOX_COLS):
                result.append([(br + i, bc + j) for i in range(BOX_ROWS) for j in range(BOX_COLS)])
        return result


class Mini8x8BacktrackSolver:
    """Backtracking solver for uniqueness and generation."""

    @staticmethod
    def solve(board: Mini8x8Board) -> Optional[Mini8x8Board]:
        b = board.clone()
        if Mini8x8BacktrackSolver._backtrack(b.grid):
            return b
        return None

    @staticmethod
    def _backtrack(grid: List[List[int]], shuffle: bool = True) -> bool:
        best = None
        best_vals = None
        for r in range(N):
            for c in range(N):
                if grid[r][c] == 0:
                    vals = Mini8x8BacktrackSolver._valid_values(grid, r, c)
                    if not vals:
                        return False
                    if best_vals is None or len(vals) < len(best_vals):
                        best = (r, c)
                        best_vals = vals[:]
        if best is None:
            return True
        r, c = best
        if shuffle:
            random.shuffle(best_vals)
        for v in best_vals:
            grid[r][c] = v
            if Mini8x8BacktrackSolver._backtrack(grid, shuffle):
                return True
            grid[r][c] = 0
        return False

    @staticmethod
    def _valid_values(grid: List[List[int]], r: int, c: int) -> List[int]:
        used: Set[int] = set()
        for i in range(N):
            if grid[r][i]:
                used.add(grid[r][i])
            if grid[i][c]:
                used.add(grid[i][c])
        br = (r // BOX_ROWS) * BOX_ROWS
        bc = (c // BOX_COLS) * BOX_COLS
        for i in range(BOX_ROWS):
            for j in range(BOX_COLS):
                if grid[br + i][bc + j]:
                    used.add(grid[br + i][bc + j])
        return [v for v in range(1, N + 1) if v not in used]

    @staticmethod
    def count_solutions(board: Mini8x8Board, limit: int = 2) -> int:
        grid = [row[:] for row in board.grid]
        return Mini8x8BacktrackSolver._count(grid, limit)

    @staticmethod
    def _count(grid: List[List[int]], limit: int) -> int:
        best = None
        best_vals = None
        for r in range(N):
            for c in range(N):
                if grid[r][c] == 0:
                    vals = Mini8x8BacktrackSolver._valid_values(grid, r, c)
                    if best_vals is None or len(vals) < len(best_vals):
                        best = (r, c)
                        best_vals = vals
        if best is None:
            return 1
        r, c = best
        count = 0
        for v in best_vals:
            grid[r][c] = v
            count += Mini8x8BacktrackSolver._count(grid, limit - count)
            grid[r][c] = 0
            if count >= limit:
                return count
        return count

    @staticmethod
    def has_unique_solution(board: Mini8x8Board) -> bool:
        return Mini8x8BacktrackSolver.count_solutions(board, limit=2) == 1


class Mini8x8Generator:
    """Generate mini 8x8 puzzles with technique tier constraints."""

    def __init__(self, seed: Optional[int] = None):
        if seed is not None:
            random.seed(seed)

    def generate_solved(self) -> Mini8x8Board:
        grid = [[0] * N for _ in range(N)]
        Mini8x8BacktrackSolver._backtrack(grid)
        return Mini8x8Board(grid)

    def generate(self, min_clues: int, max_clues: int, max_tier: int, max_attempts: int = 30) -> Optional[Dict]:
        for _ in range(max_attempts):
            solved = self.generate_solved()
            solution = solved.to_string()
            grid = [row[:] for row in solved.grid]

            cells = [(r, c) for r in range(N) for c in range(N)]
            random.shuffle(cells)
            removed = 0

            for r, c in cells:
                val = grid[r][c]
                grid[r][c] = 0
                board = Mini8x8Board(grid)
                clues_if_removed = CELLS - removed - 1

                tech_ok = Mini8x8TechniqueSolver.solve_with_limit(board, max_tier)
                unique = Mini8x8BacktrackSolver.has_unique_solution(board)

                if tech_ok and unique and clues_if_removed >= min_clues:
                    removed += 1
                else:
                    grid[r][c] = val

            clues = CELLS - removed
            if clues < min_clues or clues > max_clues:
                continue

            board = Mini8x8Board(grid)
            if not Mini8x8BacktrackSolver.has_unique_solution(board):
                continue

            return {
                "puzzle": board.to_string(),
                "solution": solution,
                "clues": clues,
                "variant": "mini_8x8",
            }

        return None


TIER_DEFINITIONS = {
    1: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle"],
    2: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
        "PointingPair", "PointingTriple", "BoxLineReduction"],
    3: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
        "PointingPair", "PointingTriple", "BoxLineReduction",
        "NakedPair", "HiddenPair", "NakedTriple"],
    4: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
        "PointingPair", "PointingTriple", "BoxLineReduction",
        "NakedPair", "HiddenPair", "NakedTriple",
        "HiddenTriple", "NakedQuad"],
    5: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
        "PointingPair", "PointingTriple", "BoxLineReduction",
        "NakedPair", "HiddenPair", "NakedTriple",
        "HiddenTriple", "NakedQuad",
        "HiddenQuad", "XWing"],
}


LEVEL_DESIGNS = [
    {"start": 1, "end": 20, "min_clues": 34, "max_clues": 38, "max_tier": 1,
     "label": "Foundation", "chapter": 1},
    {"start": 21, "end": 40, "min_clues": 30, "max_clues": 34, "max_tier": 2,
     "label": "Intersections", "chapter": 2},
    {"start": 41, "end": 65, "min_clues": 26, "max_clues": 30, "max_tier": 3,
     "label": "Structures", "chapter": 3},
    {"start": 66, "end": 85, "min_clues": 24, "max_clues": 26, "max_tier": 4,
     "label": "Advanced Intro", "chapter": 4},
    {"start": 86, "end": 100, "min_clues": 22, "max_clues": 24, "max_tier": 5,
     "label": "Advanced Intro", "chapter": 4},
]


def generate_stage3(output_dir: str, seed: int = 42) -> List[Dict]:
    import json, os
    gen = Mini8x8Generator(seed=seed)
    results = []
    for design in LEVEL_DESIGNS:
        for idx in range(design["start"], design["end"] + 1):
            level_id = f"campaign_8x8_{idx:04d}"
            result = gen.generate(
                min_clues=design["min_clues"],
                max_clues=design["max_clues"],
                max_tier=design["max_tier"],
                max_attempts=40,
            )
            if result is None:
                print(f"  FAILED {level_id}")
                continue
            result["level_id"] = level_id
            result["stage"] = 3
            result["chapter"] = design["label"]
            result["level_index"] = idx
            result["difficulty"] = design["label"]
            result["tier_max"] = design["max_tier"]
            result["techniques"] = TIER_DEFINITIONS[design["max_tier"]]
            result["visual_score"] = round(result["clues"] / CELLS, 3)
            result["human_score"] = result["tier_max"]
            result["tutorial"] = idx <= 3
            result["economy"] = {
                "coins": idx * 8,
                "souls": max(1, idx // 8),
                "perfect_bonus": 15,
                "combo_bonus": 8,
                "chapter_reward": design["chapter"] * 50,
            }
            result["stars"] = {
                "clear": 1,
                "perfect": 2,
                "fast_clear": 3,
            }
            results.append(result)
            os.makedirs(output_dir, exist_ok=True)
            path = os.path.join(output_dir, f"{level_id}.json")
            with open(path, "w") as f:
                json.dump(result, f, indent=2)
            print(f"  {level_id}: clues={result['clues']} tier={result['tier_max']}")
    return results
