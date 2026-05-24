from typing import Optional, Set

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class NakedTriple(Technique):
    id = "naked_triple"
    name = "Naked Triple"
    tier = TechniqueTier.TIER2_INTERSECTIONS
    category = TechniqueCategory.INTERSECTION
    difficulty_weight = 2.5
    human_difficulty = 4.5
    requires_notes = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for ht in ("row", "col", "block"):
            for i in range(9):
                cells = board.house_cells(ht, i)
                empty = [c for c in cells if board.get_cell(c.row, c.col) == 0]
                if len(empty) < 3:
                    continue
                for a_idx in range(len(empty)):
                    for b_idx in range(a_idx + 1, len(empty)):
                        for c_idx in range(b_idx + 1, len(empty)):
                            trio = [empty[a_idx], empty[b_idx], empty[c_idx]]
                            union: Set[int] = set()
                            for t in trio:
                                union |= board.get_candidates(t.row, t.col)
                            if len(union) != 3:
                                continue
                            eliminations = []
                            for c in empty:
                                if c not in trio:
                                    for v in union:
                                        if board.has_candidate(c.row, c.col, v):
                                            eliminations.append((c.row, c.col, v))
                            if eliminations:
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name=self.name,
                                    eliminations=eliminations,
                                    cells_affected=trio,
                                    reason=(
                                        f"Naked Triple: cells "
                                        f"{', '.join(t.name for t in trio)} in "
                                        f"{ht} {i + 1} share candidates "
                                        f"{sorted(union)}, eliminating from rest of house"
                                    ),
                                )
        return None
