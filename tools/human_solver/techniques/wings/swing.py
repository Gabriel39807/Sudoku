from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class SWing(Technique):
    id = "swing"
    name = "S-Wing"
    tier = TechniqueTier.TIER3_WINGS_FISH
    category = TechniqueCategory.WING
    difficulty_weight = 5.0
    human_difficulty = 6.5
    requires_notes = True
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
                if not a.shares_house(b):
                    continue
                for pivot_val in (x, y):
                    other_val = y if pivot_val == x else x
                    cells_with_pivot = [
                        cell for cell in board.cells_with_candidate(pivot_val)
                        if cell != a and cell != b
                        and cell.shares_house(a) and cell.shares_house(b)
                    ]
                    for p in cells_with_pivot:
                        p_cands = board.get_candidates(p.row, p.col)
                        if other_val not in p_cands:
                            continue
                        eliminations = []
                        for cell in board.empty_cells():
                            if cell in (a, b, p):
                                continue
                            if cell.shares_house(p) and cell.shares_house(a) and cell.shares_house(b):
                                if board.has_candidate(cell.row, cell.col, other_val):
                                    eliminations.append((cell.row, cell.col, other_val))
                        if eliminations:
                            return TechniqueResult(
                                technique_id=self.id,
                                technique_name=self.name,
                                eliminations=eliminations,
                                cells_affected=[a, b, p],
                                reason=(
                                    f"S-Wing: {a.name} ({a_cands}), {b.name} ({b_cands}), "
                                    f"connected by {p.name} on {pivot_val}, "
                                    f"eliminating {other_val}"
                                ),
                            )
        return None
