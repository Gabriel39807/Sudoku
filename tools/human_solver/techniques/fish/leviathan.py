from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class Leviathan(Technique):
    id = "leviathan"
    name = "Leviathan"
    tier = TechniqueTier.TIER7_EXOTIC_FISH
    category = TechniqueCategory.EXOTIC_FISH
    difficulty_weight = 9.5
    human_difficulty = 10.0
    requires_notes = True
    implemented = False
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
