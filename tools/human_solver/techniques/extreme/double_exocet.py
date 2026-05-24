from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class DoubleExocet(Technique):
    id = "double_exocet"
    name = "Double Exocet"
    tier = TechniqueTier.TIER8_EXTREME
    category = TechniqueCategory.EXTREME
    difficulty_weight = 10.0
    human_difficulty = 10.0
    requires_notes = True
    requires_als = True
    implemented = False
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
