"""Visual difficulty score based on puzzle appearance."""

from typing import List, Tuple


class VisualDifficultyScore:
    """Evaluates visual difficulty from puzzle appearance alone.

    Factors: clue count, spatial density, symmetry type, gap size, balance.
    Lower score = visually easier (more clues, symmetric, balanced).
    """

    def __init__(self, puzzle_str: str):
        self.puzzle = puzzle_str
        self.grid = self._parse(puzzle_str)
        self.clues = sum(1 for ch in puzzle_str if ch != "0")
        self._compute()

    @staticmethod
    def _parse(puzzle: str) -> List[List[int]]:
        return [[int(puzzle[r * 9 + c]) for c in range(9)] for r in range(9)]

    def _compute(self):
        clue_cells = [(r, c) for r in range(9) for c in range(9) if self.grid[r][c] != 0]

        self.clue_density = self.clues / 81

        self.symmetry_score = self._symmetry_score(clue_cells)

        self.gap_score = self._gap_score(clue_cells)

        self.balance_score = self._balance_score(clue_cells)

        self.clue_score = self._clue_component()

        self.total = self._total()

    def _symmetry_score(self, clue_cells: List[Tuple[int, int]]) -> float:
        clue_set = set(clue_cells)
        rotational = 0
        mirror_h = 0
        total = len(clue_cells)
        if total == 0:
            return 1.0

        for r, c in clue_cells:
            if (8 - r, 8 - c) in clue_set:
                rotational += 1
            if (8 - r, c) in clue_set:
                mirror_h += 1

        rot_ratio = rotational / total
        mir_ratio = mirror_h / total
        best = max(rot_ratio, mir_ratio)

        return 1.0 - best

    def _gap_score(self, clue_cells: List[Tuple[int, int]]) -> float:
        clue_set = set(clue_cells)
        max_gap = 0
        current = 0
        for r in range(9):
            for c in range(9):
                if (r, c) in clue_set:
                    if current > max_gap:
                        max_gap = current
                    current = 0
                else:
                    current += 1
            if current > max_gap:
                max_gap = current
            current = 0

        for c in range(9):
            for r in range(9):
                if (r, c) in clue_set:
                    if current > max_gap:
                        max_gap = current
                    current = 0
                else:
                    current += 1
            if current > max_gap:
                max_gap = current
            current = 0

        return max_gap / 81

    def _balance_score(self, clue_cells: List[Tuple[int, int]]) -> float:
        quadrants = [0, 0, 0, 0]
        for r, c in clue_cells:
            q = (r // 5) * 2 + (c // 5)
            if q < 4:
                quadrants[q] += 1

        total = sum(quadrants) or 1
        expected = total / 4
        deviations = sum(abs(q - expected) for q in quadrants)
        return min(1.0, deviations / total)

    def _clue_component(self) -> float:
        return 1.0 - self.clue_density

    def _total(self) -> float:
        return (
            self.clue_score * 0.40
            + self.symmetry_score * 0.20
            + self.gap_score * 0.25
            + self.balance_score * 0.15
        )

    @property
    def label(self) -> str:
        if self.total < 0.25:
            return "Very Easy"
        elif self.total < 0.40:
            return "Easy"
        elif self.total < 0.55:
            return "Medium"
        elif self.total < 0.70:
            return "Hard"
        else:
            return "Very Hard"

    @property
    def details(self) -> dict:
        return {
            "visual_score": round(self.total, 3),
            "label": self.label,
            "clues": self.clues,
            "clue_density": round(self.clue_density, 3),
            "clue_component": round(self.clue_score, 3),
            "symmetry_component": round(self.symmetry_score, 3),
            "gap_component": round(self.gap_score, 3),
            "balance_component": round(self.balance_score, 3),
        }
