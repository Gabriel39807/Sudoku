from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class ExtendedRectangle(Technique):
    id = "extended_rectangle"
    name = "Extended Rectangle"
    tier = TechniqueTier.TIER4_UNIQUENESS
    category = TechniqueCategory.UNIQUENESS
    difficulty_weight = 7.0
    human_difficulty = 8.5
    requires_notes = True
    requires_uniqueness = True
    implemented = False
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        return None
