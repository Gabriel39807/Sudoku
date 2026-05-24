from typing import Optional, Set

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class WXYZWing(Technique):
    id = "wxyzwing"
    name = "WXYZ-Wing"
    tier = TechniqueTier.TIER3_WINGS_FISH
    category = TechniqueCategory.WING
    difficulty_weight = 6.0
    human_difficulty = 7.5
    requires_notes = True
    requires_bivalue = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        trivalue = [
            cell for cell in board.empty_cells()
            if board.candidate_count(cell.row, cell.col) == 3
        ]
        bivalue = board.bivalue_cells()
        for pivot in trivalue:
            p_cands = board.get_candidates(pivot.row, pivot.col)
            for w1 in bivalue:
                if w1 == pivot or not w1.shares_house(pivot):
                    continue
                w1_cands = board.get_candidates(w1.row, w1.col)
                if not w1_cands.issubset(p_cands):
                    continue
                for w2 in bivalue:
                    if w2 in (pivot, w1):
                        continue
                    if not (w2.shares_house(w1) or w2.shares_house(pivot)):
                        continue
                    if w1.shares_house(pivot) and w2.shares_house(pivot):
                        if not w1.shares_house(w2):
                            continue
                    w2_cands = board.get_candidates(w2.row, w2.col)
                    if not w2_cands.issubset(p_cands):
                        continue
                    for w3 in bivalue:
                        if w3 in (pivot, w1, w2):
                            continue
                        if not (w3.shares_house(pivot) or w3.shares_house(w1) or w3.shares_house(w2)):
                            continue
                        w3_cands = board.get_candidates(w3.row, w3.col)
                        if not w3_cands.issubset(p_cands):
                            continue
                        union: Set[int] = set()
                        for c in (pivot, w1, w2, w3):
                            union |= board.get_candidates(c.row, c.col)
                        if len(union) != 4:
                            continue
                        z_candidates = union - p_cands
                        if len(z_candidates) != 1:
                            continue
                        z = next(iter(z_candidates))
                        eliminations = []
                        for cell in board.empty_cells():
                            if cell in (pivot, w1, w2, w3):
                                continue
                            if board.has_candidate(cell.row, cell.col, z):
                                if all(cell.shares_house(c) for c in (pivot, w1, w2, w3)):
                                    eliminations.append((cell.row, cell.col, z))
                        if eliminations:
                            return TechniqueResult(
                                technique_id=self.id,
                                technique_name=self.name,
                                eliminations=eliminations,
                                cells_affected=[pivot, w1, w2, w3],
                                reason=(
                                    f"WXYZ-Wing: pivot {pivot.name} ({sorted(p_cands)}), "
                                    f"wings {w1.name}, {w2.name}, {w3.name}, "
                                    f"eliminating {z}"
                                ),
                            )
        return None
