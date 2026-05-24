"""
Visual difficulty score tests: 10+ tests.
"""
import pytest
from tools.human_solver.visual_score import VisualDifficultyScore


def test_solved_board_low_score():
    puzzle = "216783594395264781874591326148925637632417958759638142963872415481356279527149863"
    vs = VisualDifficultyScore(puzzle)
    assert vs.total < 0.2
    assert vs.label == "Very Easy"


def test_empty_board_high_score():
    puzzle = "0" * 81
    vs = VisualDifficultyScore(puzzle)
    assert vs.total > 0.7


def test_clue_density_full():
    puzzle = "1" * 81
    vs = VisualDifficultyScore(puzzle)
    assert vs.clue_density == 1.0


def test_clue_density_empty():
    puzzle = "0" * 81
    vs = VisualDifficultyScore(puzzle)
    assert vs.clue_density == 0.0


def test_symmetry_perfect_rotational():
    cells = [0] * 81
    cells[0] = 5
    cells[80] = 3
    puzzle = "".join(str(c) for c in cells)
    vs = VisualDifficultyScore(puzzle)
    assert vs.details["symmetry_component"] == 0.0


def test_symmetry_none():
    cells = [0] * 81
    cells[0] = 5
    cells[1] = 3
    puzzle = "".join(str(c) for c in cells)
    vs = VisualDifficultyScore(puzzle)
    assert vs.details["symmetry_component"] > 0.0


def test_details_keys():
    vs = VisualDifficultyScore("0" * 81)
    d = vs.details
    assert "visual_score" in d
    assert "label" in d
    assert "clues" in d
    assert "clue_density" in d
    assert "symmetry_component" in d
    assert "gap_component" in d
    assert "balance_component" in d


class TestVisualScoreProgression:
    @pytest.mark.parametrize("clues,expected_below", [
        (60, 0.35),
        (50, 0.50),
        (40, 0.65),
        (30, 0.70),
        (24, 0.75),
    ])
    def test_fewer_clues_higher_score(self, clues, expected_below):
        puzzle = "1" * clues + "0" * (81 - clues)
        vs = VisualDifficultyScore(puzzle)
        assert vs.total < expected_below, f"{clues} clues: {vs.total} >= {expected_below}"

    def test_monotonic(self):
        scores = []
        for clues in range(20, 71, 5):
            puzzle = "1" * clues + "0" * (81 - clues)
            vs = VisualDifficultyScore(puzzle)
            scores.append(vs.total)
        for i in range(1, len(scores)):
            assert scores[i] < scores[i - 1], \
                f"Score increased at clues={20 + i * 5}: {scores[i - 1]} -> {scores[i]}"


def test_label_thresholds():
    dense = VisualDifficultyScore("1" * 60 + "0" * 21)
    assert dense.label in ("Very Easy", "Easy")

    sparse = VisualDifficultyScore("1" * 30 + "0" * 51)
    assert sparse.label not in ("Very Easy",)


def test_generated_easy_score():
    from tools.human_solver.generator import PuzzleGenerator
    g = PuzzleGenerator(seed=42)
    r = g.generate("easy", max_attempts=3)
    vs = VisualDifficultyScore(r["puzzle"])
    assert vs.label == "Very Easy"
    assert vs.details["visual_score"] < 0.25


def test_generated_mythic_score():
    from tools.human_solver.generator import PuzzleGenerator
    g = PuzzleGenerator(seed=42)
    r = g.generate("mythic", max_attempts=3)
    vs = VisualDifficultyScore(r["puzzle"])
    assert vs.label in ("Medium", "Hard", "Very Hard")
    assert vs.details["visual_score"] >= 0.25
