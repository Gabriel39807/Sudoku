from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class HiddenSingle(Technique):
    id = "hidden_single"
    name = "Hidden Single"
    tier = TechniqueTier.TIER1_BASIC
    category = TechniqueCategory.BASIC
    difficulty_weight = 0.3
    human_difficulty = 2.0
    requires_notes = True
    requires_bivalue = False
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for ht in ("row", "col", "block"):
            for i in range(9):
                hc = board.house_candidates(ht, i)
                for d, cells in hc.items():
                    if len(cells) == 1:
                        cell = cells[0]
                        if board.get_cell(cell.row, cell.col) == 0:
                            return TechniqueResult(
                                technique_id=self.id,
                                technique_name=self.name,
                                placements=[(cell.row, cell.col, d)],
                                cells_affected=[cell],
                                reason=(
                                    f"Hidden Single: {d} appears only in {cell.name} "
                                    f"in {ht} {i + 1}"
                                ),
                            )
        return None
