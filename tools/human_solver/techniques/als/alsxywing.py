from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class ALSXYWing(Technique):
    id = "alsxywing"
    name = "ALS-XY-Wing"
    tier = TechniqueTier.TIER6_ALS
    category = TechniqueCategory.ALS
    difficulty_weight = 8.0
    human_difficulty = 9.0
    requires_notes = True
    requires_als = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
