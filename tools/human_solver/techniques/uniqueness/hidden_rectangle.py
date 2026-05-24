from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class HiddenRectangle(Technique):
    id = "hidden_rectangle"
    name = "Hidden Rectangle"
    tier = TechniqueTier.TIER4_UNIQUENESS
    category = TechniqueCategory.UNIQUENESS
    difficulty_weight = 5.0
    human_difficulty = 7.0
    requires_notes = True
    requires_uniqueness = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for r1 in range(8):
            for r2 in range(r1 + 1, 9):
                for c1 in range(8):
                    for c2 in range(c1 + 1, 9):
                        if (r1 // 3) == (r2 // 3) and (c1 // 3) == (c2 // 3):
                            continue
                        a, b = Cell(r1, c1), Cell(r1, c2)
                        c_cell, d = Cell(r2, c1), Cell(r2, c2)
                        cells = [a, b, c_cell, d]
                        a_placed = board.get_cell(a.row, a.col) != 0
                        b_placed = board.get_cell(b.row, b.col) != 0
                        c_placed = board.get_cell(c_cell.row, c_cell.col) != 0
                        d_placed = board.get_cell(d.row, d.col) != 0
                        placed_count = sum([a_placed, b_placed, c_placed, d_placed])
                        if placed_count != 2:
                            continue
                        placed_candidates = None
                        for cell in cells:
                            if board.get_cell(cell.row, cell.col) != 0:
                                v = board.get_cell(cell.row, cell.col)
                                if placed_candidates is None:
                                    placed_candidates = {v}
                                else:
                                    placed_candidates.add(v)
                        if placed_candidates and len(placed_candidates) != 2:
                            continue
                        if not placed_candidates:
                            continue
                        v1, v2 = sorted(placed_candidates)
                        empty_cells = [
                            c for c in cells
                            if board.get_cell(c.row, c.col) == 0
                        ]
                        for d_val in (v1, v2):
                            other_val = v2 if d_val == v1 else v1
                            shared_house = all(
                                board.has_candidate(c.row, c.col, d_val)
                                for c in empty_cells
                            )
                            if shared_house:
                                eliminations = []
                                for c in empty_cells:
                                    cands = board.get_candidates(c.row, c.col)
                                    for cand in list(cands):
                                        if cand != d_val and cand != other_val:
                                            eliminations.append(
                                                (c.row, c.col, cand)
                                            )
                                if eliminations:
                                    return TechniqueResult(
                                        technique_id=self.id,
                                        technique_name=self.name,
                                        eliminations=eliminations,
                                        cells_affected=cells,
                                        reason=(
                                            f"Hidden Rectangle: {a.name},{b.name},"
                                            f"{c_cell.name},{d.name} with {v1},{v2}, "
                                            f"eliminating extra candidates"
                                        ),
                                    )
        return None
