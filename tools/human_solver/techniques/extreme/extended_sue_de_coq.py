from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class ExtendedSueDeCoq(Technique):
    id = "extended_sue_de_coq"
    name = "Extended Sue de Coq"
    tier = TechniqueTier.TIER8_EXTREME
    category = TechniqueCategory.EXTREME
    difficulty_weight = 8.5
    human_difficulty = 9.5
    requires_notes = True
    requires_als = True
    implemented = False
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
