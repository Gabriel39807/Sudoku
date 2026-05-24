from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class XYZWing(Technique):
    id = "xyzwing"
    name = "XYZ-Wing"
    tier = TechniqueTier.TIER3_WINGS_FISH
    category = TechniqueCategory.WING
    difficulty_weight = 4.5
    human_difficulty = 5.5
    requires_notes = True
    requires_bivalue = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        trivalue_cells = [
            cell for cell in board.empty_cells()
            if board.candidate_count(cell.row, cell.col) == 3
        ]
        bivalue = board.bivalue_cells()
        for pivot in trivalue_cells:
            p_cands = sorted(board.get_candidates(pivot.row, pivot.col))
            if len(p_cands) != 3:
                continue
            for w1 in bivalue:
                if w1 == pivot or not w1.shares_house(pivot):
                    continue
                w1_cands = sorted(board.get_candidates(w1.row, w1.col))
                if len(w1_cands) != 2:
                    continue
                shared = [v for v in w1_cands if v in p_cands]
                if len(shared) != 2:
                    continue
                for w2 in bivalue:
                    if w2 in (pivot, w1) or not w2.shares_house(pivot):
                        continue
                    w2_cands = sorted(board.get_candidates(w2.row, w2.col))
                    if len(w2_cands) != 2:
                        continue
                    shared2 = [v for v in w2_cands if v in p_cands]
                    if len(shared2) != 2:
                        continue
                    z = next(v for v in p_cands if v in w1_cands and v in w2_cands)
                    eliminations = []
                    for cell in board.empty_cells():
                        if cell in (pivot, w1, w2):
                            continue
                        if board.has_candidate(cell.row, cell.col, z):
                            if (cell.shares_house(pivot)
                                    and cell.shares_house(w1)
                                    and cell.shares_house(w2)):
                                eliminations.append((cell.row, cell.col, z))
                    if eliminations:
                        return TechniqueResult(
                            technique_id=self.id,
                            technique_name=self.name,
                            eliminations=eliminations,
                            cells_affected=[pivot, w1, w2],
                            reason=(
                                f"XYZ-Wing: pivot {pivot.name} ({p_cands}), "
                                f"wings {w1.name} ({w1_cands}) and "
                                f"{w2.name} ({w2_cands}), "
                                f"eliminating {z} from cells that see all three"
                            ),
                        )
        return None
