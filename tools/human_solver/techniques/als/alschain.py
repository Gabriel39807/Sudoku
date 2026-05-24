from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class ALSChain(Technique):
    id = "alschain"
    name = "ALS Chain"
    tier = TechniqueTier.TIER6_ALS
    category = TechniqueCategory.ALS
    difficulty_weight = 9.0
    human_difficulty = 10.0
    requires_notes = True
    requires_als = True
    implemented = False
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
