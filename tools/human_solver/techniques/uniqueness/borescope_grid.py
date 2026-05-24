from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class BorescopeGrid(Technique):
    id = "borescope_grid"
    name = "Borescope Grid"
    tier = TechniqueTier.TIER4_UNIQUENESS
    category = TechniqueCategory.UNIQUENESS
    difficulty_weight = 8.0
    human_difficulty = 9.0
    requires_notes = True
    requires_uniqueness = True
    implemented = False
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
