from __future__ import annotations

from itertools import combinations

from .base import BaseTechnique, Board, Candidates, TechniqueResult, remove_values, units


class Technique(BaseTechnique):
    name = "naked_triple"
    difficulty_weight = 3

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        for unit in units():
            cells = [cell for cell in unit if 2 <= len(candidates[cell]) <= 3]
            for subset in combinations(cells, 3):
                values = set().union(*(candidates[cell] for cell in subset))
                if len(values) != 3:
                    continue
                affected = remove_values(candidates, (cell for cell in unit if cell not in subset), values)
                if affected:
                    return TechniqueResult(True, affected, self.name)
        return TechniqueResult(False, [], self.name)
