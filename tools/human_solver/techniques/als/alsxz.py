from typing import Dict, List, Optional, Set, Tuple

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class ALSXZ(Technique):
    id = "alsxz"
    name = "ALS-XZ"
    tier = TechniqueTier.TIER6_ALS
    category = TechniqueCategory.ALS
    difficulty_weight = 7.0
    human_difficulty = 8.0
    requires_notes = True
    requires_als = True
    implemented = True
    status = "implemented"

    def _find_als(self, board: Board) -> List[Tuple[Set[Cell], Set[int], int, str, int]]:
        als_list = []
        for ht in ("row", "col", "block"):
            for i in range(9):
                cells = board.house_cells(ht, i)
                empty = [c for c in cells if board.get_cell(c.row, c.col) == 0]
                for size in range(2, min(5, len(empty) + 1)):
                    from itertools import combinations
                    for combo in combinations(empty, size):
                        cands: Set[int] = set()
                        for c in combo:
                            cands |= board.get_candidates(c.row, c.col)
                        if len(cands) == size:
                            als_list.append((set(combo), cands, size, ht, i))
        return als_list

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        als_list = self._find_als(board)
        for a_idx in range(len(als_list)):
            a_cells, a_cands, a_size, a_ht, a_i = als_list[a_idx]
            for b_idx in range(a_idx + 1, len(als_list)):
                b_cells, b_cands, b_size, b_ht, b_i = als_list[b_idx]
                if a_cells & b_cells:
                    continue
                shared_cells = set()
                for ca in a_cells:
                    for cb in b_cells:
                        if ca.shares_house(cb):
                            shared_cells.add(ca)
                            shared_cells.add(cb)
                if not shared_cells:
                    continue
                common = a_cands & b_cands
                if len(common) != 1:
                    continue
                x = next(iter(common))
                union = a_cands | b_cands
                if len(union) != a_size + b_size + 1:
                    continue
                z_candidates = union - a_cands - b_cands
                if len(z_candidates) == 0:
                    z_candidates = union - (a_cands & b_cands)
                z_candidates = union - (a_cands & b_cands)
                if not z_candidates:
                    continue
                for z in z_candidates:
                    if z == x:
                        continue
                    eliminations = []
                    for cell in board.empty_cells():
                        if cell in a_cells or cell in b_cells:
                            continue
                        if not board.has_candidate(cell.row, cell.col, z):
                            continue
                        sees_a = any(cell.shares_house(c) for c in a_cells)
                        sees_b = any(cell.shares_house(c) for c in b_cells)
                        if sees_a and sees_b:
                            eliminations.append((cell.row, cell.col, z))
                    if eliminations:
                        return TechniqueResult(
                            technique_id=self.id,
                            technique_name=self.name,
                            eliminations=eliminations,
                            cells_affected=list(a_cells | b_cells),
                            reason=(
                                f"ALS-XZ: ALS A ({a_size} cells in {a_ht} {a_i + 1}) "
                                f"and ALS B ({b_size} cells in {b_ht} {b_i + 1}) "
                                f"share restricted common {x}, "
                                f"eliminating {z}"
                            ),
                        )
        return None
