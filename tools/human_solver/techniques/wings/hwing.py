from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class HWing(Technique):
    id = "hwing"
    name = "H-Wing"
    tier = TechniqueTier.TIER3_WINGS_FISH
    category = TechniqueCategory.WING
    difficulty_weight = 5.5
    human_difficulty = 7.0
    requires_notes = True
    requires_bivalue = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        bivalue = board.bivalue_cells()
        for a in bivalue:
            a_cands = sorted(board.get_candidates(a.row, a.col))
            if len(a_cands) != 2:
                continue
            x, y = a_cands
            for b in bivalue:
                if b == a or not b.shares_house(a):
                    continue
                b_cands = sorted(board.get_candidates(b.row, b.col))
                if len(b_cands) != 2:
                    continue
                shared = [v for v in b_cands if v in a_cands]
                if len(shared) != 1:
                    continue
                z = shared[0]
                for mid in board.cells_with_candidate(z):
                    if mid in (a, b):
                        continue
                    if not (mid.shares_house(a) and mid.shares_house(b)):
                        continue
                    if board.candidate_count(mid.row, mid.col) < 2:
                        continue
                    eliminations = []
                    for cell in board.empty_cells():
                        if cell in (a, b, mid):
                            continue
                        if cell.shares_house(mid) and cell.shares_house(a) and cell.shares_house(b):
                            for v in range(1, 10):
                                if v != z and board.has_candidate(
                                    cell.row, cell.col, v
                                ):
                                    if v in a_cands and v not in b_cands:
                                        eliminations.append(
                                            (cell.row, cell.col, v)
                                        )
                    if eliminations:
                        return TechniqueResult(
                            technique_id=self.id,
                            technique_name=self.name,
                            eliminations=eliminations,
                            cells_affected=[a, b, mid],
                            reason=(
                                f"H-Wing: {a.name} ({a_cands}), {b.name} ({b_cands}), "
                                f"connected by {z} in {mid.name}, "
                                f"eliminating candidates"
                            ),
                        )
        return None
