from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class HiddenPair(Technique):
    id = "hidden_pair"
    name = "Hidden Pair"
    tier = TechniqueTier.TIER2_INTERSECTIONS
    category = TechniqueCategory.INTERSECTION
    difficulty_weight = 2.0
    human_difficulty = 4.0
    requires_notes = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for ht in ("row", "col", "block"):
            for i in range(9):
                hc = board.house_candidates(ht, i)
                candidates_two = [
                    d for d in range(1, 10) if len(hc.get(d, [])) == 2
                ]
                for a_idx in range(len(candidates_two)):
                    a = candidates_two[a_idx]
                    a_cells = set(hc[a])
                    for b_idx in range(a_idx + 1, len(candidates_two)):
                        b = candidates_two[b_idx]
                        b_cells = set(hc[b])
                        if a_cells == b_cells and len(a_cells) == 2:
                            cells = list(a_cells)
                            eliminations = []
                            for c in cells:
                                cands = board.get_candidates(c.row, c.col)
                                for v in cands:
                                    if v != a and v != b:
                                        eliminations.append((c.row, c.col, v))
                            if eliminations:
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name=self.name,
                                    eliminations=eliminations,
                                    cells_affected=cells,
                                    reason=(
                                        f"Hidden Pair: {a} and {b} appear only in "
                                        f"{cells[0].name} and {cells[1].name} in "
                                        f"{ht} {i + 1}, eliminating other candidates"
                                    ),
                                )
        return None
