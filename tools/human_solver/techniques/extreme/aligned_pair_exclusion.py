from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class AlignedPairExclusion(Technique):
    id = "aligned_pair_exclusion"
    name = "Aligned Pair Exclusion"
    tier = TechniqueTier.TIER8_EXTREME
    category = TechniqueCategory.EXTREME
    difficulty_weight = 7.0
    human_difficulty = 8.0
    requires_notes = True
    implemented = False
    experimental = True
    status = "experimental"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        empty_cells = list(board.empty_cells())
        for a_idx in range(len(empty_cells)):
            a = empty_cells[a_idx]
            a_cands = board.get_candidates(a.row, a.col)
            if len(a_cands) < 2:
                continue
            for b_idx in range(a_idx + 1, len(empty_cells)):
                b = empty_cells[b_idx]
                if not a.shares_house(b):
                    continue
                b_cands = board.get_candidates(b.row, b.col)
                if len(b_cands) < 2:
                    continue
                if a_cands == b_cands and len(a_cands) == 2:
                    continue
                invalid_combos = set()
                for va in a_cands:
                    for vb in b_cands:
                        if va == vb and not a.shares_house(b):
                            continue
                        if self._check_combo(board, a, b, va, vb):
                            invalid_combos.add((va, vb))
                for (va, vb) in invalid_combos:
                    if len(a_cands) > 1 and va in a_cands:
                        new_a_cands = [v for v in a_cands if v != va]
                        if new_a_cands:
                            eliminations = []
                            for v_to_remove in list(a_cands):
                                if v_to_remove == va:
                                    if board.has_candidate(
                                        a.row, a.col, v_to_remove
                                    ):
                                        eliminations.append(
                                            (a.row, a.col, v_to_remove)
                                        )
                            if eliminations:
                                return TechniqueResult(
                                    technique_id=self.id,
                                    technique_name=self.name,
                                    eliminations=eliminations,
                                    cells_affected=[a, b],
                                    reason=(
                                        f"Aligned Pair Exclusion: {a.name} and "
                                        f"{b.name} cannot both be {va}",
                                    ),
                                )
        return None

    def _check_combo(self, board, a, b, va, vb):
        test = board.clone()
        test.place(a.row, a.col, va)
        test.place(b.row, b.col, vb)
        return not test.is_valid
