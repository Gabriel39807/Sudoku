from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class BUG(Technique):
    id = "bug"
    name = "BUG"
    tier = TechniqueTier.TIER4_UNIQUENESS
    category = TechniqueCategory.UNIQUENESS
    difficulty_weight = 5.0
    human_difficulty = 6.0
    requires_notes = True
    requires_uniqueness = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        bivalue_count = len(
            [c for c in board.empty_cells()
             if board.candidate_count(c.row, c.col) == 2]
        )
        trivalue_count = len(
            [c for c in board.empty_cells()
             if board.candidate_count(c.row, c.col) >= 3]
        )
        empty_count = board.empty_count

        if trivalue_count > 1:
            return None
        if bivalue_count + trivalue_count != empty_count:
            return None

        for cell in board.empty_cells():
            cands = board.get_candidates(cell.row, cell.col)
            if len(cands) >= 3:
                for ht in ("row", "col", "block"):
                    i = (
                        cell.row if ht == "row"
                        else cell.col if ht == "col"
                        else cell.block
                    )
                    hc = board.house_candidates(ht, i)
                    for d in list(cands):
                        if len(hc.get(d, [])) == 1:
                            continue
                        extra = [v for v in cands if v != d]
                        if len(extra) == 1:
                            elim_val = extra[0]
                            if board.has_candidate(
                                cell.row, cell.col, elim_val
                            ):
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name="BUG+1",
                                    placements=[(cell.row, cell.col, d)],
                                    eliminations=[
                                        (cell.row, cell.col, elim_val)
                                    ],
                                    cells_affected=[cell],
                                    reason=(
                                        f"BUG+1: all remaining cells are bivalue "
                                        f"except {cell.name} with candidates "
                                        f"{sorted(cands)}, must place {d} "
                                        f"to avoid deadly pattern"
                                    ),
                                )
                        if len(extra) == 2:
                            eliminations = []
                            for e in extra:
                                if board.has_candidate(
                                    cell.row, cell.col, e
                                ):
                                    eliminations.append(
                                        (cell.row, cell.col, e)
                                    )
                            if eliminations:
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name="BUG+2",
                                    eliminations=eliminations,
                                    cells_affected=[cell],
                                    reason=(
                                        f"BUG+2: {cell.name} with candidates "
                                        f"{sorted(cands)}, eliminating extra candidates"
                                    ),
                                )
        return None
