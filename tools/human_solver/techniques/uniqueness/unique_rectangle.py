from typing import Dict, List, Optional, Tuple

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class UniqueRectangle(Technique):
    id = "unique_rectangle"
    name = "Unique Rectangle"
    tier = TechniqueTier.TIER4_UNIQUENESS
    category = TechniqueCategory.UNIQUENESS
    difficulty_weight = 4.0
    human_difficulty = 5.0
    requires_notes = True
    requires_uniqueness = True
    implemented = True
    status = "implemented"

    def _get_rectangles(self, board: Board) -> List[Tuple[Cell, Cell, Cell, Cell]]:
        rects = []
        for r1 in range(8):
            for r2 in range(r1 + 1, 9):
                for c1 in range(8):
                    for c2 in range(c1 + 1, 9):
                        if (r1 // 3, c1 // 3) == (r2 // 3, c2 // 3):
                            continue
                        a = Cell(r1, c1)
                        b = Cell(r1, c2)
                        c = Cell(r2, c1)
                        d = Cell(r2, c2)
                        rects.append((a, b, c, d))
        return rects

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for a, b, c, d in self._get_rectangles(board):
            a_val = board.get_cell(a.row, a.col)
            b_val = board.get_cell(b.row, b.col)
            c_val = board.get_cell(c.row, c.col)
            d_val = board.get_cell(d.row, d.col)
            a_cands = board.get_candidates(a.row, a.col)
            b_cands = board.get_candidates(b.row, b.col)
            c_cands = board.get_candidates(c.row, c.col)
            d_cands = board.get_candidates(d.row, d.col)
            cells_vals = [a_val, b_val, c_val, d_val]
            cells_cands = [a_cands, b_cands, c_cands, d_cands]
            filled_count = sum(1 for v in cells_vals if v != 0)

            if filled_count != 2:
                continue

            filled_indices = [i for i, v in enumerate(cells_vals) if v != 0]
            empty_indices = [i for i, v in enumerate(cells_vals) if v == 0]

            if len(filled_indices) != 2:
                continue

            filled_pairs = [(cells_vals[i], cells_vals[j])
                            for i in filled_indices
                            for j in filled_indices if i < j]
            if not filled_pairs:
                continue

            f1, f2 = cells_vals[filled_indices[0]], cells_vals[filled_indices[1]]

            if f1 == f2:
                continue

            diagonal = (filled_indices[0], filled_indices[1]) in [
                (0, 3), (1, 2), (2, 1), (3, 0)
            ]

            common_candidates = None
            for idx in empty_indices:
                cands = cells_cands[idx]
                if common_candidates is None:
                    common_candidates = set(cands)
                else:
                    common_candidates &= cands

            if common_candidates is None:
                continue

            extra_candidates = [v for v in common_candidates if v != f1 and v != f2]

            if not extra_candidates:
                continue

            empty_cells = [cells_vals[i] for i in empty_indices]

            if len(extra_candidates) == 1 and diagonal:
                z = extra_candidates[0]
                eliminations = []
                empty_cell_list = [cells_vals[i] for i in empty_indices]
                empty_cells_obj = [
                    [a, b, c, d][i] for i in empty_indices
                ]
                for cell in empty_cells_obj:
                    if board.has_candidate(cell.row, cell.col, z):
                        eliminations.append((cell.row, cell.col, z))
                if eliminations:
                    return TechniqueResult(
                        technique_id=self.id,
                        technique_name=self.name + " Type 4",
                        eliminations=eliminations,
                        cells_affected=[a, b, c, d],
                        reason=(
                            f"Unique Rectangle Type 4: "
                            f"{a.name},{b.name},{c.name},{d.name} "
                            f"with {f1},{f2}, eliminating extra candidate {z} "
                            f"from {', '.join(c.name for c in empty_cells_obj)}"
                        ),
                    )

            if len(extra_candidates) >= 1 and not diagonal:
                z = extra_candidates[0]
                eliminations = []
                for cell in [a, b, c, d]:
                    cands = board.get_candidates(cell.row, cell.col)
                    if z in cands and cell.row != filled_indices[0] and cell.row != filled_indices[1]:
                        pass
                cells_list = [a, b, c, d]
                for cell in cells_list:
                    if board.get_cell(cell.row, cell.col) == 0:
                        if board.has_candidate(cell.row, cell.col, z):
                            cell_val = board.get_cell(cell.row, cell.col)
                            if cell_val == 0:
                                is_filled_cell = False
                                for fi in filled_indices:
                                    fc = cells_list[fi]
                                    if fc.row == cell.row and fc.col == cell.col:
                                        is_filled_cell = True
                                        break
                                if not is_filled_cell:
                                    eliminations.append((cell.row, cell.col, z))
                if eliminations:
                    return TechniqueResult(
                        technique_id=self.id,
                        technique_name=self.name + " Type 1",
                        eliminations=eliminations,
                        cells_affected=[a, b, c, d],
                        reason=(
                            f"Unique Rectangle Type 1: "
                            f"{a.name},{b.name},{c.name},{d.name} "
                            f"with {f1},{f2}, eliminating {z}"
                        ),
                    )

            if not diagonal and len(extra_candidates) == 2:
                z1, z2 = sorted(extra_candidates)
                type2_eliminations = []
                for idx in empty_indices:
                    cell = [a, b, c, d][idx]
                    cands = cells_cands[idx]
                    for v in cands:
                        if v not in (f1, f2) and v not in (z1, z2):
                            if board.has_candidate(cell.row, cell.col, v):
                                type2_eliminations.append((cell.row, cell.col, v))
                if type2_eliminations:
                    return TechniqueResult(
                        technique_id=self.id,
                        technique_name=self.name + " Type 2",
                        eliminations=type2_eliminations,
                        cells_affected=[a, b, c, d],
                        reason=(
                            f"Unique Rectangle Type 2: "
                            f"{a.name},{b.name},{c.name},{d.name} "
                            f"with extra candidates {z1},{z2}"
                        ),
                    )

            if len(extra_candidates) == 2:
                z1, z2 = sorted(extra_candidates)
                rect_cells = [a, b, c, d]
                for idx in empty_indices:
                    cell = rect_cells[idx]
                    cands = cells_cands[idx]
                    cell_extra = [v for v in cands if v not in (f1, f2)]
                    if len(cell_extra) == 2:
                        continue
                    if len(cell_extra) == 1:
                        z = cell_extra[0]
                        elim_type3 = []
                        for other_idx in empty_indices:
                            if other_idx == idx:
                                continue
                            other = rect_cells[other_idx]
                            board_cands = board.get_candidates(other.row, other.col)
                            if z in board_cands:
                                if board.has_candidate(other.row, other.col, z):
                                    elim_type3.append((other.row, other.col, z))
                        if elim_type3:
                            return TechniqueResult(
                                technique_id=self.id,
                                technique_name=self.name + " Type 3",
                                eliminations=elim_type3,
                                cells_affected=[a, b, c, d],
                                reason=(
                                    f"Unique Rectangle Type 3: "
                                    f"{a.name},{b.name},{c.name},{d.name}, "
                                    f"eliminating {z} from other UR cells"
                                ),
                            )

        return None
