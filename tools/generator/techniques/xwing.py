from __future__ import annotations

from itertools import combinations

from .base import BaseTechnique, Board, Candidates, TechniqueResult, remove_values


class Technique(BaseTechnique):
    name = "xwing"
    difficulty_weight = 5

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        for value in range(1, 10):
            row_cols = {r: {c for c in range(9) if value in candidates[(r, c)]} for r in range(9)}
            row_cols = {r: cols for r, cols in row_cols.items() if len(cols) == 2}
            for rows in combinations(row_cols, 2):
                cols = set().union(*(row_cols[r] for r in rows))
                if len(cols) == 2:
                    for r in range(9):
                        if r not in rows:
                            affected = remove_values(candidates, ((r, c) for c in cols), {value})
                            if affected:
                                return TechniqueResult(True, affected, self.name)

            col_rows = {c: {r for r in range(9) if value in candidates[(r, c)]} for c in range(9)}
            col_rows = {c: rows for c, rows in col_rows.items() if len(rows) == 2}
            for cols in combinations(col_rows, 2):
                rows = set().union(*(col_rows[c] for c in cols))
                if len(rows) == 2:
                    for c in range(9):
                        if c not in cols:
                            affected = remove_values(candidates, ((r, c) for r in rows), {value})
                            if affected:
                                return TechniqueResult(True, affected, self.name)

        return TechniqueResult(False, [], self.name)
