from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class LastBlankCell(Technique):
    id = "last_blank_cell"
    name = "Last Blank Cell"
    tier = TechniqueTier.TIER1_BASIC
    category = TechniqueCategory.BASIC
    difficulty_weight = 0.1
    human_difficulty = 1.0
    requires_notes = False
    requires_bivalue = False
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for ht in ("row", "col", "block"):
            for i in range(9):
                cells = board.house_cells(ht, i)
                empty = [c for c in cells if board.get_cell(c.row, c.col) == 0]
                if len(empty) == 1:
                    cell = empty[0]
                    values = board.house_values(ht, i)
                    missing = next(v for v in range(1, 10) if v not in values)
                    return TechniqueResult(
                        technique_id=self.id,
                        technique_name=self.name,
                        placements=[(cell.row, cell.col, missing)],
                        cells_affected=[cell],
                        reason=(
                            f"Last Blank Cell: only empty cell in {ht} {i + 1} is "
                            f"{cell.name}, must be {missing}"
                        ),
                    )
        return None
