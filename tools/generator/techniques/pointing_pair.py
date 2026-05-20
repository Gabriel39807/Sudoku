from __future__ import annotations

from .base import BaseTechnique, Board, Candidates, TechniqueResult, remove_values


class Technique(BaseTechnique):
    name = "pointing_pair"
    difficulty_weight = 4

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        for br in range(0, 9, 3):
            for bc in range(0, 9, 3):
                box = [(r, c) for r in range(br, br + 3) for c in range(bc, bc + 3)]
                for value in range(1, 10):
                    cells = [cell for cell in box if value in candidates[cell]]
                    if len(cells) < 2:
                        continue
                    rows = {r for r, _ in cells}
                    cols = {c for _, c in cells}
                    if len(rows) == 1:
                        r = next(iter(rows))
                        affected = remove_values(
                            candidates,
                            ((r, c) for c in range(9) if not (br <= r < br + 3 and bc <= c < bc + 3)),
                            {value},
                        )
                        if affected:
                            return TechniqueResult(True, affected, self.name)
                    if len(cols) == 1:
                        c = next(iter(cols))
                        affected = remove_values(
                            candidates,
                            ((r, c) for r in range(9) if not (br <= r < br + 3 and bc <= c < bc + 3)),
                            {value},
                        )
                        if affected:
                            return TechniqueResult(True, affected, self.name)
        return TechniqueResult(False, [], self.name)
