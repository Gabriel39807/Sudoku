from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class WWing(Technique):
    id = "wwing"
    name = "W-Wing"
    tier = TechniqueTier.TIER3_WINGS_FISH
    category = TechniqueCategory.WING
    difficulty_weight = 4.5
    human_difficulty = 5.5
    requires_notes = True
    requires_bivalue = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        bivalue = board.bivalue_cells()
        for a_idx in range(len(bivalue)):
            a = bivalue[a_idx]
            a_cands = board.get_candidates(a.row, a.col)
            for b_idx in range(a_idx + 1, len(bivalue)):
                b = bivalue[b_idx]
                b_cands = board.get_candidates(b.row, b.col)
                if a_cands != b_cands:
                    continue
                if a.shares_house(b):
                    continue
                vals = sorted(a_cands)
                for d in vals:
                    cells_with_d = board.cells_with_candidate(d)
                    connectors = [
                        cell for cell in cells_with_d
                        if cell != a and cell != b
                        and cell.shares_house(a) and cell.shares_house(b)
                    ]
                    for conn in connectors:
                        if conn.shares_house(a) and conn.shares_house(b):
                            elim_val = next(v for v in vals if v != d)
                            eliminations = []
                            for cell in board.empty_cells():
                                if cell in (a, b, conn):
                                    continue
                                if cell.shares_house(a) and cell.shares_house(b):
                                    if board.has_candidate(
                                        cell.row, cell.col, elim_val
                                    ):
                                        eliminations.append(
                                            (cell.row, cell.col, elim_val)
                                        )
                            if eliminations:
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name=self.name,
                                    eliminations=eliminations,
                                    cells_affected=[a, b, conn],
                                    reason=(
                                        f"W-Wing: {a.name} and {b.name} share "
                                        f"candidates {vals}, connected by {d} in "
                                        f"{conn.name}, eliminating {elim_val}"
                                    ),
                                )
        return None
