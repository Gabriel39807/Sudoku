from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class NakedPair(Technique):
    id = "naked_pair"
    name = "Naked Pair"
    tier = TechniqueTier.TIER2_INTERSECTIONS
    category = TechniqueCategory.INTERSECTION
    difficulty_weight = 1.5
    human_difficulty = 3.0
    requires_notes = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for ht in ("row", "col", "block"):
            for i in range(9):
                cells = board.house_cells(ht, i)
                empty_cells = [c for c in cells if board.get_cell(c.row, c.col) == 0]
                for a_idx in range(len(empty_cells)):
                    a = empty_cells[a_idx]
                    a_cands = board.get_candidates(a.row, a.col)
                    if len(a_cands) != 2:
                        continue
                    for b_idx in range(a_idx + 1, len(empty_cells)):
                        b = empty_cells[b_idx]
                        b_cands = board.get_candidates(b.row, b.col)
                        if b_cands != a_cands:
                            continue
                        eliminations = []
                        for c in empty_cells:
                            if c != a and c != b:
                                for v in a_cands:
                                    if board.has_candidate(c.row, c.col, v):
                                        eliminations.append((c.row, c.col, v))
                        if eliminations:
                            vals = sorted(a_cands)
                            return TechniqueResult(
                                technique_id=self.id,
                                technique_name=self.name,
                                eliminations=eliminations,
                                cells_affected=[a, b],
                                reason=(
                                    f"Naked Pair: cells {a.name} and {b.name} in "
                                    f"{ht} {i + 1} share candidates {vals}, "
                                    f"eliminating {vals} from rest of house"
                                ),
                            )
        return None
