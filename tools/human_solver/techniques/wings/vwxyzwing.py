from typing import Optional, Set

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class VWXYZWing(Technique):
    id = "vwxyzwing"
    name = "VWXYZ-Wing"
    tier = TechniqueTier.TIER3_WINGS_FISH
    category = TechniqueCategory.WING
    difficulty_weight = 7.0
    human_difficulty = 8.5
    requires_notes = True
    requires_bivalue = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        quadvalue = [
            cell for cell in board.empty_cells()
            if board.candidate_count(cell.row, cell.col) == 4
        ]
        bivalue_cells = board.bivalue_cells()
        for pivot in quadvalue:
            p_cands = board.get_candidates(pivot.row, pivot.col)
            wings = []
            for w in bivalue_cells:
                if w == pivot:
                    continue
                w_cands = board.get_candidates(w.row, w.col)
                if w_cands.issubset(p_cands) and len(w_cands) == 2:
                    wings.append(w)
            if len(wings) < 4:
                continue
            from itertools import combinations
            for combo in combinations(wings, 4):
                union: Set[int] = set()
                all_cells = [pivot] + list(combo)
                for c in all_cells:
                    union |= board.get_candidates(c.row, c.col)
                if len(union) != 5:
                    continue
                z_candidates = union - p_cands
                if len(z_candidates) != 1:
                    continue
                z = next(iter(z_candidates))
                eliminations = []
                for cell in board.empty_cells():
                    if cell in all_cells:
                        continue
                    if board.has_candidate(cell.row, cell.col, z):
                        if all(cell.shares_house(c) for c in all_cells):
                            eliminations.append((cell.row, cell.col, z))
                if eliminations:
                    return TechniqueResult(
                        technique_id=self.id,
                        technique_name=self.name,
                        eliminations=eliminations,
                        cells_affected=all_cells,
                        reason=(
                            f"VWXYZ-Wing: pivot {pivot.name} ({sorted(p_cands)}), "
                            f"wings {', '.join(w.name for w in combo)}, "
                            f"eliminating {z}"
                        ),
                    )
        return None
