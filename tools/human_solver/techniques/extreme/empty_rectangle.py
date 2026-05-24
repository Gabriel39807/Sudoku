from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class EmptyRectangle(Technique):
    id = "empty_rectangle"
    name = "Empty Rectangle"
    tier = TechniqueTier.TIER8_EXTREME
    category = TechniqueCategory.EXTREME
    difficulty_weight = 6.0
    human_difficulty = 7.0
    requires_notes = True
    implemented = True
    status = "implemented"

    def _find_er(self, board: Board, block: int) -> Optional[tuple]:
        br, bc = divmod(block, 3)
        cells = []
        for r in range(br * 3, br * 3 + 3):
            for c in range(bc * 3, bc * 3 + 3):
                cell = Cell(r, c)
                if board.get_cell(r, c) == 0:
                    cells.append(cell)
        if len(cells) < 4:
            return None
        for d in range(1, 10):
            has_d = [c for c in cells if board.has_candidate(c.row, c.col, d)]
            if len(has_d) < 2 or len(has_d) > 7:
                continue
            rows_with_d = {c.row for c in has_d}
            cols_with_d = {c.col for c in has_d}
            if len(rows_with_d) == 3 and len(cols_with_d) == 3:
                return (block, d, set(has_d))
        return None

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for block in range(9):
            er_info = self._find_er(board, block)
            if not er_info:
                continue
            er_block, d, er_cells = er_info
            for r in range(9):
                if r // 3 == er_block // 3:
                    continue
                cols_with_d_in_row = [
                    c for c in range(9)
                    if board.has_candidate(r, c, d)
                ]
                if len(cols_with_d_in_row) != 2:
                    continue
                c1, c2 = cols_with_d_in_row
                for col in (c1, c2):
                    if col // 3 == er_block % 3:
                        if board.has_candidate(r, col, d):
                            eliminations = []
                            for cell in board.empty_cells():
                                if cell.row == r and (cell.col == c1 or cell.col == c2):
                                    continue
                                if cell.shares_house(Cell(r, col)):
                                    if board.has_candidate(
                                        cell.row, cell.col, d
                                    ):
                                        eliminations.append(
                                            (cell.row, cell.col, d)
                                        )
                            if eliminations:
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name=self.name,
                                    eliminations=eliminations,
                                    cells_affected=list(er_cells) + [
                                        Cell(r, c1), Cell(r, c2)
                                    ],
                                    reason=(
                                        f"Empty Rectangle: block {er_block + 1} "
                                        f"has empty rectangle on {d}, "
                                        f"connected to row {r + 1}, "
                                        f"eliminating {d}"
                                    ),
                                )
        return None
