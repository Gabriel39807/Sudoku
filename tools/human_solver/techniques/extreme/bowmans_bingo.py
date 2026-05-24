from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class BowmansBingo(Technique):
    id = "bowmans_bingo"
    name = "Bowman's Bingo"
    tier = TechniqueTier.TIER8_EXTREME
    category = TechniqueCategory.FORCING_CHAIN
    difficulty_weight = 8.5
    human_difficulty = 9.5
    requires_notes = True
    implemented = False
    experimental = True
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for cell in list(board.empty_cells())[:3]:
            cands = board.get_candidates(cell.row, cell.col)
            for v in cands:
                test = board.clone()
                test.place(cell.row, cell.col, v)
                from tools.human_solver.techniques.extreme.forcing_chains import (
                    ForcingChains,
                )
                fc = ForcingChains()
                changed = True
                while changed:
                    changed = False
                    for c2 in list(test.empty_cells()):
                        c2_cands = test.get_candidates(c2.row, c2.col)
                        if len(c2_cands) == 1:
                            c2v = next(iter(c2_cands))
                            test.place(c2.row, c2.col, c2v)
                            changed = True
                if test.is_valid:
                    for c2 in test.empty_cells():
                        for c2v in list(test.get_candidates(c2.row, c2.col)):
                            test2 = test.clone()
                            test2.place(c2.row, c2.col, c2v)
                            changed2 = True
                            while changed2 and test2.is_valid:
                                changed2 = False
                                for c3 in test2.empty_cells():
                                    c3_cands = test2.get_candidates(c3.row, c3.col)
                                    if len(c3_cands) == 1:
                                        c3v = next(iter(c3_cands))
                                        test2.place(c3.row, c3.col, c3v)
                                        changed2 = True
                            if not test2.is_valid:
                                if test.has_candidate(c2.row, c2.col, c2v):
                                    return TechniqueResult(
                                        technique_id=self.id,
                                        technique_name=self.name,
                                        eliminations=[(c2.row, c2.col, c2v)],
                                        cells_affected=[cell, c2],
                                        reason=(
                                            f"Bowman's Bingo: assuming "
                                            f"{cell.name}={v}, then "
                                            f"{c2.name}={c2v} leads to "
                                            f"invalid board"
                                        ),
                                    )
        return None
