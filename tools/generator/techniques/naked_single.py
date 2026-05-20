from __future__ import annotations

from .base import BaseTechnique, Board, Candidates, TechniqueResult, place


class Technique(BaseTechnique):
    name = "naked_single"
    difficulty_weight = 1

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        for cell, values in candidates.items():
            if board[cell[0]][cell[1]] == 0 and len(values) == 1:
                place(board, candidates, cell, next(iter(values)))
                return TechniqueResult(True, [cell], self.name)
        return TechniqueResult(False, [], self.name)
