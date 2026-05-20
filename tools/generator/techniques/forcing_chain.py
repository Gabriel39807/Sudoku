from __future__ import annotations

from copy import deepcopy
from typing import Dict, List, Optional, Set, Tuple

from .base import BaseTechnique, Board, Candidates, Cell, TechniqueResult, peers, units


class ForcingChainTechnique(BaseTechnique):
    """Bounded contradiction-chain eliminator.

    This is intentionally not a full Sudoku solver. It tests one candidate
    assumption at a time and propagates only deterministic consequences
    (naked singles and hidden singles). If the assumption creates a
    contradiction, the original candidate can be eliminated. For bivalue
    cells, it also supports the human forcing-chain pattern where two
    alternatives imply a common candidate elimination.
    """

    name = "forcing_chain"
    difficulty_weight = 8

    def __init__(self, max_depth: int = 32) -> None:
        self.max_depth = max_depth
        self.last_details: Dict[str, object] = {}

    def apply(self, board: Board, candidates: Candidates) -> TechniqueResult:
        self.last_details = {}
        unsolved = [cell for cell, values in candidates.items() if board[cell[0]][cell[1]] == 0 and values]

        # First: contradiction chains. If assuming a candidate deterministically
        # breaks the puzzle, that candidate is impossible.
        for cell in unsolved:
            for value in sorted(candidates[cell]):
                trial = self._run_assumption(board, candidates, cell, value)
                if trial["contradiction"]:
                    candidates[cell].discard(value)
                    self.last_details = {
                        "technique": self.name,
                        "cells": self._serialize_cells(trial["touched"] | {cell}),
                        "eliminations": [{"cell": list(cell), "value": value}],
                        "depth": trial["depth"],
                        "reason": trial["reason"],
                    }
                    return TechniqueResult(True, [cell], self.name)

        # Second: common-consequence forcing chain for bivalue cells. If every
        # alternative for a bivalue cell removes the same candidate elsewhere,
        # that common candidate can be removed in the real puzzle.
        for cell in unsolved:
            values = sorted(candidates[cell])
            if len(values) != 2:
                continue
            trials = [self._run_assumption(board, candidates, cell, value) for value in values]
            if any(trial["contradiction"] for trial in trials):
                continue
            common = set(trials[0]["eliminated"])
            for trial in trials[1:]:
                common &= set(trial["eliminated"])
            common = {
                item for item in common
                if item[0] != cell and board[item[0][0]][item[0][1]] == 0 and item[1] in candidates[item[0]]
            }
            if not common:
                continue
            target, remove_value = sorted(common, key=lambda item: (item[0][0], item[0][1], item[1]))[0]
            candidates[target].discard(remove_value)
            touched: Set[Cell] = {cell, target}
            depth = 0
            for trial in trials:
                touched |= trial["touched"]
                depth = max(depth, int(trial["depth"]))
            self.last_details = {
                "technique": self.name,
                "cells": self._serialize_cells(touched),
                "eliminations": [{"cell": list(target), "value": remove_value}],
                "depth": depth,
                "reason": "common_consequence",
            }
            return TechniqueResult(True, [target], self.name)

        return TechniqueResult(False, [], self.name)

    def _run_assumption(
        self,
        board: Board,
        candidates: Candidates,
        cell: Cell,
        value: int,
    ) -> Dict[str, object]:
        trial_board = deepcopy(board)
        trial_candidates: Candidates = {k: set(v) for k, v in candidates.items()}
        before: Candidates = {k: set(v) for k, v in candidates.items()}
        touched: Set[Cell] = set()
        reason = self._place(trial_board, trial_candidates, cell, value, touched)
        if reason is not None:
            return {
                "contradiction": True,
                "reason": reason,
                "depth": 1,
                "touched": touched,
                "eliminated": self._eliminated(before, trial_candidates),
            }

        depth = 1
        while depth <= self.max_depth:
            contradiction = self._find_contradiction(trial_board, trial_candidates)
            if contradiction is not None:
                return {
                    "contradiction": True,
                    "reason": contradiction,
                    "depth": depth,
                    "touched": touched,
                    "eliminated": self._eliminated(before, trial_candidates),
                }

            progress = False

            # Naked singles produced by the assumption.
            for next_cell, values in list(trial_candidates.items()):
                if trial_board[next_cell[0]][next_cell[1]] == 0 and len(values) == 1:
                    only = next(iter(values))
                    reason = self._place(trial_board, trial_candidates, next_cell, only, touched)
                    if reason is not None:
                        return {
                            "contradiction": True,
                            "reason": reason,
                            "depth": depth,
                            "touched": touched,
                            "eliminated": self._eliminated(before, trial_candidates),
                        }
                    progress = True
                    break
            if progress:
                depth += 1
                continue

            # Hidden singles produced by the assumption.
            hidden = self._find_hidden_single(trial_board, trial_candidates)
            if hidden is not None:
                next_cell, only = hidden
                reason = self._place(trial_board, trial_candidates, next_cell, only, touched)
                if reason is not None:
                    return {
                        "contradiction": True,
                        "reason": reason,
                        "depth": depth,
                        "touched": touched,
                        "eliminated": self._eliminated(before, trial_candidates),
                    }
                depth += 1
                continue

            return {
                "contradiction": False,
                "reason": "stable",
                "depth": depth,
                "touched": touched,
                "eliminated": self._eliminated(before, trial_candidates),
            }

        return {
            "contradiction": False,
            "reason": "max_depth",
            "depth": self.max_depth,
            "touched": touched,
            "eliminated": self._eliminated(before, trial_candidates),
        }

    def _place(
        self,
        board: Board,
        candidates: Candidates,
        cell: Cell,
        value: int,
        touched: Set[Cell],
    ) -> Optional[str]:
        r, c = cell
        existing = board[r][c]
        if existing != 0:
            return None if existing == value else f"cell {cell} already has {existing}, cannot place {value}"
        if value not in candidates[cell]:
            return f"candidate {value} not available at {cell}"

        # Conflict with already placed peers.
        for peer in peers(r, c):
            pr, pc = peer
            if board[pr][pc] == value:
                return f"peer {peer} already has {value}"

        board[r][c] = value
        candidates[cell] = set()
        touched.add(cell)
        for peer in peers(r, c):
            if value in candidates[peer]:
                candidates[peer].discard(value)
                touched.add(peer)
        return None

    def _find_contradiction(self, board: Board, candidates: Candidates) -> Optional[str]:
        for (r, c), values in candidates.items():
            if board[r][c] == 0 and not values:
                return f"cell {(r, c)} has no candidates"

        for unit in units():
            for value in range(1, 10):
                already = any(board[r][c] == value for r, c in unit)
                if already:
                    continue
                possible = [cell for cell in unit if board[cell[0]][cell[1]] == 0 and value in candidates[cell]]
                if not possible:
                    return f"unit has no place for {value}"
        return None

    def _find_hidden_single(self, board: Board, candidates: Candidates) -> Optional[Tuple[Cell, int]]:
        for unit in units():
            for value in range(1, 10):
                if any(board[r][c] == value for r, c in unit):
                    continue
                possible = [cell for cell in unit if board[cell[0]][cell[1]] == 0 and value in candidates[cell]]
                if len(possible) == 1:
                    return possible[0], value
        return None

    def _eliminated(self, before: Candidates, after: Candidates) -> Set[Tuple[Cell, int]]:
        result: Set[Tuple[Cell, int]] = set()
        for cell, values in before.items():
            for value in values - after[cell]:
                result.add((cell, value))
        return result

    def _serialize_cells(self, cells: Set[Cell]) -> List[List[int]]:
        return [list(cell) for cell in sorted(cells)]


# Backward-compatible name used by human_solver.py and tests.
Technique = ForcingChainTechnique
