from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class NakedSingle(Technique):
    id = "naked_single"
    name = "Naked Single"
    tier = TechniqueTier.TIER1_BASIC
    category = TechniqueCategory.BASIC
    difficulty_weight = 0.2
    human_difficulty = 1.5
    requires_notes = True
    requires_bivalue = False
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for cell in board.empty_cells():
            cands = board.get_candidates(cell.row, cell.col)
            if len(cands) == 1:
                val = next(iter(cands))
                return TechniqueResult(
                    technique_id=self.id,
                    technique_name=self.name,
                    placements=[(cell.row, cell.col, val)],
                    cells_affected=[cell],
                    reason=(
                        f"Naked Single: {cell.name} has only one candidate {val}"
                    ),
                )
        return None
