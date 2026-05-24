from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class BoxLineReduction(Technique):
    id = "box_line_reduction"
    name = "Box-Line Reduction"
    tier = TechniqueTier.TIER2_INTERSECTIONS
    category = TechniqueCategory.INTERSECTION
    difficulty_weight = 1.3
    human_difficulty = 3.5
    requires_notes = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for line_type in ("row", "col"):
            for i in range(9):
                for d in range(1, 10):
                    cells_with = []
                    for cell in board.house_cells(line_type, i):
                        if board.has_candidate(cell.row, cell.col, d):
                            cells_with.append(cell)
                    if len(cells_with) <= 3 and len(cells_with) >= 2:
                        blocks = {c.block for c in cells_with}
                        if len(blocks) == 1:
                            block = next(iter(blocks))
                            eliminations = []
                            br, bc = divmod(block, 3)
                            for r in range(br * 3, br * 3 + 3):
                                for c in range(bc * 3, bc * 3 + 3):
                                    if (line_type == "row" and r != i) or (
                                        line_type == "col" and c != i
                                    ):
                                        if board.has_candidate(r, c, d):
                                            eliminations.append((r, c, d))
                            if eliminations:
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name=self.name,
                                    eliminations=eliminations,
                                    cells_affected=cells_with,
                                    reason=(
                                        f"Box-Line Reduction: {d} restricted to "
                                        f"{line_type} {i + 1} within block {block + 1}, "
                                        f"eliminating from rest of block"
                                    ),
                                )
        return None
