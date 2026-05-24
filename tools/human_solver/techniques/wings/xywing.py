from typing import List, Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class XYWing(Technique):
    id = "xywing"
    name = "XY-Wing"
    tier = TechniqueTier.TIER3_WINGS_FISH
    category = TechniqueCategory.WING
    difficulty_weight = 4.0
    human_difficulty = 5.0
    requires_notes = True
    requires_bivalue = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        bivalue = board.bivalue_cells()
        for pivot in bivalue:
            p_cands = sorted(board.get_candidates(pivot.row, pivot.col))
            if len(p_cands) != 2:
                continue
            p, q = p_cands[0], p_cands[1]
            for w1 in bivalue:
                if w1 == pivot or not w1.shares_house(pivot):
                    continue
                w1_cands = sorted(board.get_candidates(w1.row, w1.col))
                if len(w1_cands) != 2:
                    continue
                if w1_cands == [p, q]:
                    continue
                if p not in w1_cands and q not in w1_cands:
                    continue
                for w2 in bivalue:
                    if w2 in (pivot, w1) or not w2.shares_house(pivot):
                        continue
                    if not w1.shares_house(w2):
                        continue
                    w2_cands = sorted(board.get_candidates(w2.row, w2.col))
                    if len(w2_cands) != 2:
                        continue
                    if w2_cands == [p, q]:
                        continue
                    if p not in w2_cands and q not in w2_cands:
                        continue
                    all_vals = set(p_cands + w1_cands + w2_cands)
                    if len(all_vals) != 3:
                        continue
                    if p in w1_cands and p in w2_cands:
                        continue
                    if q in w1_cands and q in w2_cands:
                        continue
                    z = next(v for v in all_vals if v != p and v != q)
                    eliminations = []
                    for cell in board.empty_cells():
                        if cell == pivot or cell == w1 or cell == w2:
                            continue
                        if board.has_candidate(cell.row, cell.col, z):
                            if cell.shares_house(w1) and cell.shares_house(w2):
                                eliminations.append((cell.row, cell.col, z))
                    if eliminations:
                        return TechniqueResult(
                            technique_id=self.id,
                            technique_name=self.name,
                            eliminations=eliminations,
                            cells_affected=[pivot, w1, w2],
                            reason=(
                                f"XY-Wing: pivot {pivot.name} ({p}/{q}), "
                                f"wings {w1.name} ({sorted(w1_cands)}) and "
                                f"{w2.name} ({sorted(w2_cands)}), "
                                f"eliminating {z} from cells that see both wings"
                            ),
                        )
        return None
