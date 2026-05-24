from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class XWing(Technique):
    id = "xwing"
    name = "X-Wing"
    tier = TechniqueTier.TIER3_WINGS_FISH
    category = TechniqueCategory.FISH
    difficulty_weight = 3.0
    human_difficulty = 4.0
    requires_notes = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for d in range(1, 10):
            for r1 in range(9):
                cols_r1 = [
                    c for c in range(9)
                    if board.has_candidate(r1, c, d)
                ]
                if len(cols_r1) != 2:
                    continue
                for r2 in range(r1 + 1, 9):
                    cols_r2 = [
                        c for c in range(9)
                        if board.has_candidate(r2, c, d)
                    ]
                    if cols_r2 == cols_r1:
                        c1, c2 = cols_r1
                        eliminations = []
                        for r in range(9):
                            if r != r1 and r != r2:
                                if board.has_candidate(r, c1, d):
                                    eliminations.append((r, c1, d))
                                if board.has_candidate(r, c2, d):
                                    eliminations.append((r, c2, d))
                        if eliminations:
                            return TechniqueResult(
                                technique_id=self.id,
                                technique_name=self.name,
                                eliminations=eliminations,
                                cells_affected=[
                                    Cell(r1, c1), Cell(r1, c2),
                                    Cell(r2, c1), Cell(r2, c2),
                                ],
                                reason=(
                                    f"X-Wing: candidate {d} in rows {r1 + 1} and {r2 + 1}, "
                                    f"columns {c1 + 1} and {c2 + 1}, "
                                    f"eliminating {d} from other cells in these columns"
                                ),
                            )
        return None
