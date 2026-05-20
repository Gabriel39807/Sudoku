from __future__ import annotations

from .base import BaseTechnique, Board, Candidates, TechniqueResult, place, units


class Technique(BaseTechnique):
    name = "hidden_single"
    difficulty_weight = 1

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        for unit in units():
            for value in range(1, 10):
                cells = [cell for cell in unit if value in candidates[cell]]
                if len(cells) == 1:
                    place(board, candidates, cells[0], value)
                    return TechniqueResult(True, cells, self.name)
        return TechniqueResult(False, [], self.name)
