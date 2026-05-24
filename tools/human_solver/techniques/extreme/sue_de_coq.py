from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class SueDeCoq(Technique):
    id = "sue_de_coq"
    name = "Sue de Coq"
    tier = TechniqueTier.TIER8_EXTREME
    category = TechniqueCategory.EXTREME
    difficulty_weight = 7.5
    human_difficulty = 8.5
    requires_notes = True
    requires_als = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
