from __future__ import annotations

from itertools import combinations

from .base import BaseTechnique, Board, Candidates, TechniqueResult, peers, remove_values


class Technique(BaseTechnique):
    name = "xywing"
    difficulty_weight = 7

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        bivalue = [cell for cell, values in candidates.items() if len(values) == 2]
        for pivot in bivalue:
            x, y = tuple(candidates[pivot])
            wings = [cell for cell in peers(*pivot) if len(candidates[cell]) == 2]
            for a, b in combinations(wings, 2):
                av, bv = candidates[a], candidates[b]
                if len(av | bv | {x, y}) != 3 or len(av & bv) != 1:
                    continue
                common = next(iter(av & bv))
                if common in candidates[pivot]:
                    continue
                affected = remove_values(candidates, peers(*a) & peers(*b), {common})
                if affected:
                    return TechniqueResult(True, affected, self.name)
        return TechniqueResult(False, [], self.name)
