from typing import Optional

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class FinnedFish(Technique):
    id = "finned_fish"
    name = "Finned Fish"
    tier = TechniqueTier.TIER7_EXOTIC_FISH
    category = TechniqueCategory.EXOTIC_FISH
    difficulty_weight = 6.0
    human_difficulty = 7.0
    requires_notes = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for d in range(1, 10):
            fish_types = [
                ("X-Wing", 2, self._find_finned_xwing),
                ("Swordfish", 3, self._find_finned_swordfish),
                ("Jellyfish", 4, self._find_finned_jellyfish),
            ]
            for name, size, finder in fish_types:
                result = finder(board, d)
                if result:
                    return result
        return None

    def _find_finned_xwing(self, board: Board, d: int) -> Optional[TechniqueResult]:
        for r1 in range(9):
            cols_r1 = [c for c in range(9) if board.has_candidate(r1, c, d)]
            if len(cols_r1) < 2:
                continue
            for r2 in range(r1 + 1, 9):
                cols_r2 = [c for c in range(9) if board.has_candidate(r2, c, d)]
                if len(cols_r2) < 2:
                    continue
                base_cols = set(cols_r1) & set(cols_r2)
                if len(base_cols) != 2:
                    continue
                cols = sorted(base_cols)
                row1_extra = [c for c in cols_r1 if c not in base_cols]
                row2_extra = [c for c in cols_r2 if c not in base_cols]
                fins = []
                for c in row1_extra:
                    fins.append(Cell(r1, c))
                for c in row2_extra:
                    fins.append(Cell(r2, c))
                if not fins:
                    continue
                same_block = True
                if fins:
                    first_block = fins[0].block
                    for f in fins[1:]:
                        if f.block != first_block:
                            same_block = False
                            break
                if not same_block:
                    continue
                eliminations = []
                for col in cols:
                    for r in range(9):
                        if r != r1 and r != r2:
                            if board.has_candidate(r, col, d):
                                if all(
                                    not f.shares_house(Cell(r, col))
                                    for f in fins
                                ):
                                    pass
                                eliminations.append((r, col, d))
                if eliminations:
                    covered_cells = [
                        Cell(r1, c) for c in cols_r1
                    ] + [Cell(r2, c) for c in cols_r2]
                    return TechniqueResult(
                        technique_id=self.id,
                        technique_name="Finned X-Wing",
                        eliminations=eliminations,
                        cells_affected=covered_cells + fins,
                        reason=(
                            f"Finned X-Wing: candidate {d} in rows "
                            f"{r1 + 1},{r2 + 1}, columns {cols[0] + 1},{cols[1] + 1}, "
                            f"fin in block {fins[0].block + 1 if fins else '?'}, "
                            f"eliminating {d}"
                        ),
                    )
        return None

    def _find_finned_swordfish(self, board: Board, d: int) -> Optional[TechniqueResult]:
        rows_with = [
            [c for c in range(9) if board.has_candidate(r, c, d)]
            for r in range(9)
        ]
        valid_rows = [r for r, cols in enumerate(rows_with) if 2 <= len(cols) <= 4]
        if len(valid_rows) < 3:
            return None
        for a in range(len(valid_rows)):
            for b in range(a + 1, len(valid_rows)):
                for c in range(b + 1, len(valid_rows)):
                    r1, r2, r3 = valid_rows[a], valid_rows[b], valid_rows[c]
                    base_cols = (
                        set(rows_with[r1]) & set(rows_with[r2]) & set(rows_with[r3])
                    )
                    if len(base_cols) < 2:
                        continue
                    fins = []
                    for r in (r1, r2, r3):
                        for col in rows_with[r]:
                            if col not in base_cols:
                                fins.append(Cell(r, col))
                    if not fins:
                        continue
                    same_block = all(f.block == fins[0].block for f in fins)
                    if not same_block:
                        continue
                    eliminations = []
                    for col in base_cols:
                        for r in range(9):
                            if r not in (r1, r2, r3):
                                if board.has_candidate(r, col, d):
                                    eliminations.append((r, col, d))
                    if eliminations:
                        covered = []
                        for r in (r1, r2, r3):
                            for col in rows_with[r]:
                                covered.append(Cell(r, col))
                        return TechniqueResult(
                            technique_id=self.id,
                            technique_name="Finned Swordfish",
                            eliminations=eliminations,
                            cells_affected=covered + fins,
                            reason=(
                                f"Finned Swordfish: candidate {d} in rows "
                                f"{r1 + 1},{r2 + 1},{r3 + 1}, "
                                f"fin in block {fins[0].block + 1}"
                            ),
                        )
        return None

    def _find_finned_jellyfish(self, board: Board, d: int) -> Optional[TechniqueResult]:
        rows_with = [
            [c for c in range(9) if board.has_candidate(r, c, d)]
            for r in range(9)
        ]
        valid_rows = [r for r, cols in enumerate(rows_with) if 2 <= len(cols) <= 4]
        if len(valid_rows) < 4:
            return None
        for a in range(len(valid_rows)):
            for b in range(a + 1, len(valid_rows)):
                for c in range(b + 1, len(valid_rows)):
                    for d_idx in range(c + 1, len(valid_rows)):
                        rows = [valid_rows[i] for i in (a, b, c, d_idx)]
                        base_cols = set.intersection(
                            *[set(rows_with[r]) for r in rows]
                        ) if rows else set()
                        if len(base_cols) < 3:
                            continue
                        fins = []
                        for r in rows:
                            for col in rows_with[r]:
                                if col not in base_cols:
                                    fins.append(Cell(r, col))
                        if not fins:
                            continue
                        if not all(f.block == fins[0].block for f in fins):
                            continue
                        eliminations = []
                        for col in base_cols:
                            for r in range(9):
                                if r not in rows:
                                    if board.has_candidate(r, col, d):
                                        eliminations.append((r, col, d))
                        if eliminations:
                            return TechniqueResult(
                                technique_id=self.id,
                                technique_name="Finned Jellyfish",
                                eliminations=eliminations,
                                cells_affected=fins,
                                reason=(
                                    f"Finned Jellyfish: candidate {d}, "
                                    f"fin in block {fins[0].block + 1}"
                                ),
                            )
        return None


class FinnedXWing(FinnedFish):
    id = "finned_xwing"
    name = "Finned X-Wing"


class FinnedSwordfish(FinnedFish):
    id = "finned_swordfish"
    name = "Finned Swordfish"


class FinnedJellyfish(FinnedFish):
    id = "finned_jellyfish"
    name = "Finned Jellyfish"
