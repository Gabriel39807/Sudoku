from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class HiddenTriple(Technique):
    id = "hidden_triple"
    name = "Hidden Triple"
    tier = TechniqueTier.TIER2_INTERSECTIONS
    category = TechniqueCategory.INTERSECTION
    difficulty_weight = 3.0
    human_difficulty = 5.0
    requires_notes = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for ht in ("row", "col", "block"):
            for i in range(9):
                hc = board.house_candidates(ht, i)
                candidates = [d for d in range(1, 10) if hc.get(d, [])]
                if len(candidates) < 3:
                    continue
                for a in range(len(candidates)):
                    for b in range(a + 1, len(candidates)):
                        for c in range(b + 1, len(candidates)):
                            d1, d2, d3 = candidates[a], candidates[b], candidates[c]
                            cells_union = set(hc[d1]) | set(hc[d2]) | set(hc[d3])
                            if len(cells_union) != 3:
                                continue
                            cells = list(cells_union)
                            eliminations = []
                            for cell in cells:
                                cands = board.get_candidates(cell.row, cell.col)
                                for v in list(cands):
                                    if v not in (d1, d2, d3):
                                        eliminations.append((cell.row, cell.col, v))
                            if eliminations:
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name=self.name,
                                    eliminations=eliminations,
                                    cells_affected=cells,
                                    reason=(
                                        f"Hidden Triple: {d1},{d2},{d3} appear only in "
                                        f"{', '.join(c.name for c in cells)} in "
                                        f"{ht} {i + 1}, eliminating other candidates"
                                    ),
                                )
        return None
