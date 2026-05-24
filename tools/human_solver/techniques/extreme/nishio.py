from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class Nishio(Technique):
    id = "nishio"
    name = "Nishio"
    tier = TechniqueTier.TIER8_EXTREME
    category = TechniqueCategory.FORCING_CHAIN
    difficulty_weight = 8.0
    human_difficulty = 9.0
    requires_notes = True
    implemented = False
    experimental = True
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        from tools.human_solver.techniques.extreme.forcing_chains import (
            ForcingChains,
        )
        fc = ForcingChains()
        test = board.clone()
        contradiction = fc._contradiction_forcing(board)
        if contradiction:
            return contradiction
        return None
