from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class PointingPair(Technique):
    id = "pointing_pair"
    name = "Pointing Pair"
    tier = TechniqueTier.TIER2_INTERSECTIONS
    category = TechniqueCategory.INTERSECTION
    difficulty_weight = 1.0
    human_difficulty = 3.0
    requires_notes = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for block in range(9):
            for d in range(1, 10):
                cells_with = [
                    Cell(br * 3 + r, bc * 3 + c)
                    for br, bc in [divmod(block, 3)]
                    for r in range(3)
                    for c in range(3)
                    if board.has_candidate(br * 3 + r, bc * 3 + c, d)
                ]
                if len(cells_with) == 2:
                    rows = {c.row for c in cells_with}
                    cols = {c.col for c in cells_with}
                    eliminations = []
                    if len(rows) == 1:
                        row = next(iter(rows))
                        for c in range(9):
                            if c // 3 != block % 3:
                                if board.has_candidate(row, c, d):
                                    eliminations.append((row, c, d))
                    elif len(cols) == 1:
                        col = next(iter(cols))
                        for r in range(9):
                            if r // 3 != block // 3:
                                if board.has_candidate(r, col, d):
                                    eliminations.append((r, col, d))
                    if eliminations:
                        return TechniqueResult(
                            technique_id=self.id,
                            technique_name=self.name,
                            eliminations=eliminations,
                            cells_affected=cells_with,
                            reason=(
                                f"Pointing Pair: {d} in block {block + 1} is locked "
                                f"to {'row' if len(rows) == 1 else 'col'} "
                                f"{next(iter(rows)) + 1 if len(rows) == 1 else next(iter(cols)) + 1}, "
                                f"eliminating from rest of line"
                            ),
                        )
        return None
