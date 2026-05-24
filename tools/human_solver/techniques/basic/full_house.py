from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class FullHouse(Technique):
    id = "full_house"
    name = "Full House"
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
                values = set()
                empty_cell = None
                all_filled = True
                for c in cells:
                    v = board.get_cell(c.row, c.col)
                    if v == 0:
                        if empty_cell is None:
                            empty_cell = c
                        else:
                            all_filled = False
                            break
                    else:
                        values.add(v)
                if empty_cell is not None and all_filled:
                    missing = next(v for v in range(1, 10) if v not in values)
                    return TechniqueResult(
                        technique_id=self.id,
                        technique_name=self.name,
                        placements=[(empty_cell.row, empty_cell.col, missing)],
                        cells_affected=[empty_cell],
                        reason=(
                            f"Full House: {empty_cell.name} is the only empty cell "
                            f"in {ht} {i + 1}, must be {missing}"
                        ),
                    )
        return None
