from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class TwinnedXYChain(Technique):
    id = "twinned_xychain"
    name = "Twinned XY-Chain"
    tier = TechniqueTier.TIER5_CHAINS
    category = TechniqueCategory.CHAIN
    difficulty_weight = 7.5
    human_difficulty = 8.5
    requires_notes = True
    requires_bivalue = True
    implemented = False
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
