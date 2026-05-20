from __future__ import annotations

from .base import BaseTechnique, Board, Candidates, TechniqueResult, remove_values


class Technique(BaseTechnique):
    name = "box_line_reduction"
    difficulty_weight = 4

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        lines = [[(r, c) for c in range(9)] for r in range(9)] + [[(r, c) for r in range(9)] for c in range(9)]
        for line in lines:
            for value in range(1, 10):
                cells = [cell for cell in line if value in candidates[cell]]
                if len(cells) < 2:
                    continue
                boxes = {(r // 3, c // 3) for r, c in cells}
                if len(boxes) != 1:
                    continue
                br, bc = next(iter(boxes))
                box = [(r, c) for r in range(br * 3, br * 3 + 3) for c in range(bc * 3, bc * 3 + 3)]
                affected = remove_values(candidates, (cell for cell in box if cell not in cells), {value})
                if affected:
                    return TechniqueResult(True, affected, self.name)
        return TechniqueResult(False, [], self.name)
