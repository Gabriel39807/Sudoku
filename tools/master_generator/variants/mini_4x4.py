"""Mini 4x4 Sudoku engine — 2x2 blocks, tiered technique solver."""

import random
from copy import deepcopy
from typing import Dict, List, Optional, Set, Tuple


N = 4
BOX = 2
CELLS = 16


class MiniBoard:
    def __init__(self, grid: Optional[List[List[int]]] = None):
        self.grid = grid or [[0] * N for _ in range(N)]

    @classmethod
    def from_string(cls, s: str) -> "MiniBoard":
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

    def clone(self) -> "MiniBoard":
        return MiniBoard([row[:] for row in self.grid])

    @property
    def empty_cells(self) -> List[Tuple[int, int]]:
        return [(r, c) for r in range(N) for c in range(N) if self.grid[r][c] == 0]

    @property
    def clues(self) -> int:
        return CELLS - len(self.empty_cells)

    def candidates(self, r: int, c: int) -> Set[int]:
        if self.grid[r][c] != 0:
            return set()
        used = set()
        for i in range(N):
            if self.grid[r][i] != 0:
                used.add(self.grid[r][i])
            if self.grid[i][c] != 0:
                used.add(self.grid[i][c])
        br, bc = (r // BOX) * BOX, (c // BOX) * BOX
        for i in range(BOX):
            for j in range(BOX):
                if self.grid[br + i][bc + j] != 0:
                    used.add(self.grid[br + i][bc + j])
        return {v for v in range(1, N + 1) if v not in used}

    def is_solved(self) -> bool:
        return len(self.empty_cells) == 0

    def is_valid(self) -> bool:
        for r in range(N):
            vals = [self.grid[r][c] for c in range(N) if self.grid[r][c] != 0]
            if len(vals) != len(set(vals)):
                return False
        for c in range(N):
            vals = [self.grid[r][c] for r in range(N) if self.grid[r][c] != 0]
            if len(vals) != len(set(vals)):
                return False
        for br in range(0, N, BOX):
            for bc in range(0, N, BOX):
                vals = []
                for i in range(BOX):
                    for j in range(BOX):
                        if self.grid[br + i][bc + j] != 0:
                            vals.append(self.grid[br + i][bc + j])
                if len(vals) != len(set(vals)):
                    return False
        return True


class MiniTechniqueSolver:
    """Tiered solver for 4x4. Returns (solved, max_tier_used)."""

    @staticmethod
    def solve(board: MiniBoard) -> Tuple[bool, int]:
        b = board.clone()
        max_tier = 0
        changed = True
        while changed and not b.is_solved():
            changed = False
            for cell, tier, func in [
                ("naked_single", 1, MiniTechniqueSolver._naked_single),
                ("hidden_single", 2, MiniTechniqueSolver._hidden_single),
                ("pointing", 3, MiniTechniqueSolver._pointing),
            ]:
                if func(b):
                    changed = True
                    if tier > max_tier:
                        max_tier = tier
                    break
            if not changed:
                break
        return b.is_solved(), max_tier

    @staticmethod
    def solve_with_limit(board: MiniBoard, max_tier: int) -> bool:
        b = board.clone()
        changed = True
        while changed and not b.is_solved():
            changed = False
            for tier, func in [
                (1, MiniTechniqueSolver._naked_single),
                (2, MiniTechniqueSolver._hidden_single),
                (3, MiniTechniqueSolver._pointing),
            ]:
                if tier > max_tier:
                    continue
                if func(b):
                    changed = True
                    break
            if not changed:
                break
        return b.is_solved()

    @staticmethod
    def _naked_single(board: MiniBoard) -> bool:
        for r in range(N):
            for c in range(N):
                if board.grid[r][c] == 0:
                    cands = board.candidates(r, c)
                    if len(cands) == 1:
                        board.set_cell(r, c, cands.pop())
                        return True
        return False

    @staticmethod
    def _hidden_single(board: MiniBoard) -> bool:
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
        for br in range(0, N, BOX):
            for bc in range(0, N, BOX):
                for val in range(1, N + 1):
                    cells = []
                    for i in range(BOX):
                        for j in range(BOX):
                            r, c = br + i, bc + j
                            if board.grid[r][c] == 0 and val in board.candidates(r, c):
                                cells.append((r, c))
                    if len(cells) == 1:
                        board.set_cell(cells[0][0], cells[0][1], val)
                        return True
        return False

    @staticmethod
    def _pointing(board: MiniBoard) -> bool:
        for br in range(0, N, BOX):
            for bc in range(0, N, BOX):
                for val in range(1, N + 1):
                    block_cells = []
                    for i in range(BOX):
                        for j in range(BOX):
                            r, c = br + i, bc + j
                            if board.grid[r][c] == 0 and val in board.candidates(r, c):
                                block_cells.append((r, c))
                    if not block_cells:
                        continue
                    rows = {r for r, c in block_cells}
                    cols = {c for r, c in block_cells}
                    if len(rows) == 1:
                        r = rows.pop()
                        eliminated = False
                        for c2 in range(N):
                            if board.grid[r][c2] == 0 and val in board.candidates(r, c2) and (r, c2) not in block_cells:
                                board.candidates  # triggers recompute
                                eliminated = True
                        if eliminated:
                            return True
                    if len(cols) == 1:
                        c = cols.pop()
                        eliminated = False
                        for r2 in range(N):
                            if board.grid[r2][c] == 0 and val in board.candidates(r2, c) and (r2, c) not in block_cells:
                                eliminated = True
                        if eliminated:
                            return True
        return False


class MiniBacktrackSolver:
    """Backtracking solver for uniqueness and generation."""

    @staticmethod
    def solve(board: MiniBoard) -> Optional[MiniBoard]:
        b = board.clone()
        if MiniBacktrackSolver._backtrack(b.grid):
            return b
        return None

    @staticmethod
    def _backtrack(grid: List[List[int]], shuffle: bool = True) -> bool:
        best = None
        best_vals = None
        for r in range(N):
            for c in range(N):
                if grid[r][c] == 0:
                    vals = MiniBacktrackSolver._valid_values(grid, r, c)
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
            if MiniBacktrackSolver._backtrack(grid, shuffle):
                return True
            grid[r][c] = 0
        return False

    @staticmethod
    def _valid_values(grid: List[List[int]], r: int, c: int) -> List[int]:
        used = set()
        for i in range(N):
            if grid[r][i]:
                used.add(grid[r][i])
            if grid[i][c]:
                used.add(grid[i][c])
        br, bc = (r // BOX) * BOX, (c // BOX) * BOX
        for i in range(BOX):
            for j in range(BOX):
                if grid[br + i][bc + j]:
                    used.add(grid[br + i][bc + j])
        return [v for v in range(1, N + 1) if v not in used]

    @staticmethod
    def count_solutions(board: MiniBoard, limit: int = 2) -> int:
        grid = [row[:] for row in board.grid]
        return MiniBacktrackSolver._count(grid, limit)

    @staticmethod
    def _count(grid: List[List[int]], limit: int) -> int:
        best = None
        best_vals = None
        for r in range(N):
            for c in range(N):
                if grid[r][c] == 0:
                    vals = MiniBacktrackSolver._valid_values(grid, r, c)
                    if best_vals is None or len(vals) < len(best_vals):
                        best = (r, c)
                        best_vals = vals
        if best is None:
            return 1
        r, c = best
        count = 0
        for v in best_vals:
            grid[r][c] = v
            count += MiniBacktrackSolver._count(grid, limit - count)
            grid[r][c] = 0
            if count >= limit:
                return count
        return count

    @staticmethod
    def has_unique_solution(board: MiniBoard) -> bool:
        return MiniBacktrackSolver.count_solutions(board, limit=2) == 1


class Mini4x4Generator:
    """Generate mini 4x4 puzzles with technique tier constraints."""

    def __init__(self, seed: Optional[int] = None):
        if seed is not None:
            random.seed(seed)

    def generate_solved(self) -> MiniBoard:
        grid = [[0] * N for _ in range(N)]
        MiniBacktrackSolver._backtrack(grid)
        return MiniBoard(grid)

    def generate(self, min_clues: int, max_clues: int, max_tier: int, max_attempts: int = 50) -> Optional[Dict]:
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
                board = MiniBoard(grid)
                clues_if_removed = CELLS - removed - 1

                tech_ok = MiniTechniqueSolver.solve_with_limit(board, max_tier)
                unique = MiniBacktrackSolver.has_unique_solution(board)

                if tech_ok and unique and clues_if_removed >= min_clues:
                    removed += 1
                else:
                    grid[r][c] = val

            clues = CELLS - removed
            if clues < min_clues or clues > max_clues:
                continue

            board = MiniBoard(grid)
            if not MiniBacktrackSolver.has_unique_solution(board):
                continue

            _, tech_tier = MiniTechniqueSolver.solve(board)

            return {
                "puzzle": board.to_string(),
                "solution": solution,
                "clues": clues,
                "tier_max": tech_tier,
                "variant": "mini_4x4",
            }

        return None


TIER_DEFINITIONS = {
    1: ["LastBlank", "FullHouse", "NakedSingle"],
    2: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle"],
    3: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle", "Pointing"],
}


LEVEL_DESIGNS = [
    {"start": 1, "end": 10, "min_clues": 12, "max_clues": 14, "max_tier": 1, "label": "Guided Intro"},
    {"start": 11, "end": 20, "min_clues": 10, "max_clues": 12, "max_tier": 2, "label": "Hidden Discovery"},
    {"start": 21, "end": 35, "min_clues": 8, "max_clues": 10, "max_tier": 3, "label": "Pointing Practice"},
    {"start": 36, "end": 50, "min_clues": 7, "max_clues": 8, "max_tier": 3, "label": "Mini Challenge"},
]


def generate_stage1(output_dir: str, seed: int = 42) -> List[Dict]:
    import os, json
    gen = Mini4x4Generator(seed=seed)
    results = []
    for design in LEVEL_DESIGNS:
        for idx in range(design["start"], design["end"] + 1):
            level_id = f"campaign_4x4_{idx:04d}"
            result = gen.generate(
                min_clues=design["min_clues"],
                max_clues=design["max_clues"],
                max_tier=design["max_tier"],
                max_attempts=100,
            )
            if result is None:
                print(f"  FAILED {level_id}")
                continue
            result["level_id"] = level_id
            result["stage"] = 1
            result["level_index"] = idx
            result["difficulty"] = design["label"]
            result["techniques"] = TIER_DEFINITIONS[design["max_tier"]]
            result["visual_score"] = round(result["clues"] / CELLS, 3)
            result["human_score"] = result["tier_max"]
            result["ui"] = {
                "stars": 0,
                "perfect": False,
                "coins": 0,
                "souls": 0,
                "first_clear": False,
            }
            results.append(result)
            os.makedirs(output_dir, exist_ok=True)
            path = os.path.join(output_dir, f"{level_id}.json")
            with open(path, "w") as f:
                json.dump(result, f, indent=2)
            print(f"  {level_id}: clues={result['clues']} tier={result['tier_max']}")
    return results
