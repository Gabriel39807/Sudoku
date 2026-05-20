from __future__ import annotations

from itertools import combinations

from .base import BaseTechnique, Board, Candidates, TechniqueResult, remove_values, units


class Technique(BaseTechnique):
    name = "naked_pair"
    difficulty_weight = 2

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        for unit in units():
            cells = [cell for cell in unit if 2 <= len(candidates[cell]) <= 2]
            for subset in combinations(cells, 2):
                values = set().union(*(candidates[cell] for cell in subset))
                if len(values) != 2:
                    continue
                affected = remove_values(candidates, (cell for cell in unit if cell not in subset), values)
                if affected:
                    return TechniqueResult(True, affected, self.name)
        return TechniqueResult(False, [], self.name)
