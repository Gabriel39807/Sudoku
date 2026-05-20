from __future__ import annotations

from itertools import combinations

from .base import BaseTechnique, Board, Candidates, TechniqueResult, units


class Technique(BaseTechnique):
    name = "hidden_pair"
    difficulty_weight = 2

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        for unit in units():
            value_cells = {
                value: [cell for cell in unit if value in candidates[cell]]
                for value in range(1, 10)
            }
            for values in combinations(range(1, 10), 2):
                cells = sorted(set().union(*(value_cells[value] for value in values)))
                if len(cells) != 2 or any(len(value_cells[value]) == 0 for value in values):
                    continue
                changed = []
                allowed = set(values)
                for cell in cells:
                    before = set(candidates[cell])
                    candidates[cell] &= allowed
                    if candidates[cell] != before:
                        changed.append(cell)
                if changed:
                    return TechniqueResult(True, changed, self.name)
        return TechniqueResult(False, [], self.name)
