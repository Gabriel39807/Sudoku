from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class Jellyfish(Technique):
    id = "jellyfish"
    name = "Jellyfish"
    tier = TechniqueTier.TIER3_WINGS_FISH
    category = TechniqueCategory.FISH
    difficulty_weight = 7.0
    human_difficulty = 8.0
    requires_notes = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for d in range(1, 10):
            rows_with = [
                [c for c in range(9) if board.has_candidate(r, c, d)]
                for r in range(9)
            ]
            valid_rows = [r for r, cols in enumerate(rows_with) if 2 <= len(cols) <= 4]
            if len(valid_rows) < 4:
                continue
            for a in range(len(valid_rows)):
                for b in range(a + 1, len(valid_rows)):
                    for c in range(b + 1, len(valid_rows)):
                        for d_idx in range(c + 1, len(valid_rows)):
                            r1, r2, r3, r4 = (
                                valid_rows[a], valid_rows[b],
                                valid_rows[c], valid_rows[d_idx],
                            )
                            cols_union = set(
                                rows_with[r1] + rows_with[r2]
                                + rows_with[r3] + rows_with[r4]
                            )
                            if len(cols_union) != 4:
                                continue
                            cols = list(cols_union)
                            eliminations = []
                            for col in cols:
                                for r in range(9):
                                    if r not in (r1, r2, r3, r4):
                                        if board.has_candidate(r, col, d):
                                            eliminations.append((r, col, d))
                            if eliminations:
                                affected = []
                                for r in (r1, r2, r3, r4):
                                    for col in rows_with[r]:
                                        affected.append(Cell(r, col))
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name=self.name,
                                    eliminations=eliminations,
                                    cells_affected=affected,
                                    reason=(
                                        f"Jellyfish: candidate {d} in rows "
                                        f"{r1 + 1}, {r2 + 1}, {r3 + 1}, {r4 + 1} "
                                        f"and columns {', '.join(str(col + 1) for col in cols)}, "
                                        f"eliminating {d} from other cells in these columns"
                                    ),
                                )
        return None
