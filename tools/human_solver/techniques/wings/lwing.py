from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class LWing(Technique):
    id = "lwing"
    name = "L-Wing"
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
                if b_cands != [x, y]:
                    continue
                for branch_val in (x, y):
                    other_val = y if branch_val == x else x
                    cells_between = [
                        cell for cell in board.cells_with_candidate(branch_val)
                        if cell != a and cell != b
                        and not cell.shares_house(a)
                        and cell.shares_house(b)
                    ]
                    for mid in cells_between:
                        mid_cands = board.get_candidates(mid.row, mid.col)
                        if other_val in mid_cands:
                            eliminations = []
                            for cell in board.empty_cells():
                                if cell in (a, b, mid):
                                    continue
                                if cell.shares_house(mid) and cell.shares_house(a):
                                    if board.has_candidate(
                                        cell.row, cell.col, other_val
                                    ):
                                        eliminations.append(
                                            (cell.row, cell.col, other_val)
                                        )
                            if eliminations:
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name=self.name,
                                    eliminations=eliminations,
                                    cells_affected=[a, b, mid],
                                    reason=(
                                        f"L-Wing: {a.name} and {b.name} share {x}/{y}, "
                                        f"branching through {mid.name} on {branch_val}, "
                                        f"eliminating {other_val}"
                                    ),
                                )
        return None
