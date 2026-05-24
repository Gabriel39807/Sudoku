from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class PatternOverlay(Technique):
    id = "pattern_overlay"
    name = "Pattern Overlay Method"
    tier = TechniqueTier.TIER8_EXTREME
    category = TechniqueCategory.PATTERN_OVERLAY
    difficulty_weight = 7.5
    human_difficulty = 8.0
    requires_notes = True
    implemented = False
    experimental = True
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for d in range(1, 10):
            cells = board.cells_with_candidate(d)
            if len(cells) == 0:
                continue
            placements = []
            for cell in cells:
                test = board.clone()
                if test.place(cell.row, cell.col, d):
                    conflicts = False
                    for v in range(1, 10):
                        if v == d:
                            continue
                        other_cells = test.cells_with_candidate(v)
                        if not other_cells:
                            continue
                        if not self._can_place_all(test, v):
                            conflicts = True
                            break
                    if not conflicts:
                        placements.append(cell)
            if len(placements) == 1:
                cell = placements[0]
                return TechniqueResult(
                    technique_id=self.id,
                    technique_name=self.name,
                    placements=[(cell.row, cell.col, d)],
                    cells_affected=[cell],
                    reason=(
                        f"Pattern Overlay: {d} must be in {cell.name} "
                        f"as it is the only cell where a valid template exists"
                    ),
                )
        return None

    def _can_place_all(self, board: Board, d: int) -> bool:
        cells = board.cells_with_candidate(d)
        if not cells:
            return True
        if len(cells) == 0:
            return True
        for cell in cells:
            test = board.clone()
            if test.place(cell.row, cell.col, d):
                remaining = test.cells_with_candidate(d)
                if not remaining or self._can_place_all(test, d):
                    return True
        return False
