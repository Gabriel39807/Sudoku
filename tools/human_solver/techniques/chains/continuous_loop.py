from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class ContinuousLoop(Technique):
    id = "continuous_loop"
    name = "Continuous Loop"
    tier = TechniqueTier.TIER5_CHAINS
    category = TechniqueCategory.CHAIN
    difficulty_weight = 8.0
    human_difficulty = 9.0
    requires_notes = True
    requires_coloring = True
    implemented = False
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
