from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class MutantFish(Technique):
    id = "mutant_fish"
    name = "Mutant Fish"
    tier = TechniqueTier.TIER7_EXOTIC_FISH
    category = TechniqueCategory.EXOTIC_FISH
    difficulty_weight = 9.0
    human_difficulty = 9.5
    requires_notes = True
    implemented = False
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
