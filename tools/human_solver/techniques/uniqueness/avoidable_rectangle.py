from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class AvoidableRectangle(Technique):
    id = "avoidable_rectangle"
    name = "Avoidable Rectangle"
    tier = TechniqueTier.TIER4_UNIQUENESS
    category = TechniqueCategory.UNIQUENESS
    difficulty_weight = 5.5
    human_difficulty = 7.5
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
                        vals = [
                            board.get_cell(c.row, c.col) for c in cells
                        ]
                        filled = [(i, v) for i, v in enumerate(vals) if v != 0]
                        if len(filled) != 3:
                            continue
                        filled_vals = [v for _, v in filled]
                        if len(set(filled_vals)) != 2:
                            continue
                        v1, v2 = sorted(set(filled_vals))
                        empty_idx = next(i for i, v in enumerate(vals) if v == 0)
                        empty_cell = cells[empty_idx]
                        empty_cands = board.get_candidates(
                            empty_cell.row, empty_cell.col
                        )
                        uncommon = [v for v in empty_cands if v not in (v1, v2)]
                        if uncommon:
                            eliminations = []
                            for v in list(empty_cands):
                                if v not in (v1, v2):
                                    if board.has_candidate(
                                        empty_cell.row, empty_cell.col, v
                                    ):
                                        eliminations.append(
                                            (empty_cell.row, empty_cell.col, v)
                                        )
                            if eliminations:
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name=self.name,
                                    eliminations=eliminations,
                                    cells_affected=cells,
                                    reason=(
                                        f"Avoidable Rectangle: "
                                        f"{a.name},{b.name},{c_cell.name},{d.name} "
                                        f"with {v1},{v2}, avoiding deadly pattern"
                                    ),
                                )
        return None
