from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class MWing(Technique):
    id = "mwing"
    name = "M-Wing"
    tier = TechniqueTier.TIER3_WINGS_FISH
    category = TechniqueCategory.WING
    difficulty_weight = 5.0
    human_difficulty = 6.5
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
                if not a.shares_house(b):
                    continue
                shared_cells = [
                    cell for cell in board.cells_with_candidate(x)
                    if cell.shares_house(a) and cell.shares_house(b)
                    and cell != a and cell != b
                ]
                if shared_cells:
                    continue
                strong_links = [
                    cell
                    for cell in board.cells_with_candidate(x)
                    if board.candidate_count(cell.row, cell.col) == 2
                    and x in board.get_candidates(cell.row, cell.col)
                    and not cell.shares_house(a)
                    and not cell.shares_house(b)
                ]
                for link in strong_links:
                    eliminations = []
                    for cell in board.empty_cells():
                        if cell in (a, b, link):
                            continue
                        if cell.shares_house(link) and cell.shares_house(a):
                            if board.has_candidate(cell.row, cell.col, y):
                                eliminations.append((cell.row, cell.col, y))
                    if eliminations:
                        return TechniqueResult(
                            technique_id=self.id,
                            technique_name=self.name,
                            eliminations=eliminations,
                            cells_affected=[a, b, link],
                            reason=(
                                f"M-Wing: {a.name} and {b.name} share candidates "
                                f"{x}/{y}, with strong link on {x} through {link.name}, "
                                f"eliminating {y}"
                            ),
                        )
        return None
