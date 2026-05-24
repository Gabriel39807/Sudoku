from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class GurthSymmetry(Technique):
    id = "gurth_symmetry"
    name = "Gurth's Symmetry"
    tier = TechniqueTier.TIER4_UNIQUENESS
    category = TechniqueCategory.UNIQUENESS
    difficulty_weight = 9.0
    human_difficulty = 10.0
    requires_notes = True
    requires_uniqueness = True
    implemented = False
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
