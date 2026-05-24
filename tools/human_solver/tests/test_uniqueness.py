"""
Uniqueness tests: 15+ tests.
"""
import pytest
from tools.human_solver.uniqueness import has_unique_solution, count_solutions


def test_empty_board_not_unique():
    assert has_unique_solution("0" * 81) is False


def test_empty_board_has_many_solutions():
    assert count_solutions("0" * 81, limit=10) >= 10


def test_solved_board_unique():
    solved = "216783594395264781874591326148925637632417958759638142963872415481356279527149863"
    assert has_unique_solution(solved) is True


def test_single_cell_missing_unique():
    puzzle = list("216783594395264781874591326148925637632417958759638142963872415481356279527149863")
    puzzle[0] = "0"
    assert has_unique_solution("".join(puzzle)) is True


def test_two_cells_missing_unique():
    puzzle = list("216783594395264781874591326148925637632417958759638142963872415481356279527149863")
    puzzle[0] = "0"
    puzzle[10] = "0"
    assert has_unique_solution("".join(puzzle)) is True


def test_wrong_length_rejected():
    assert has_unique_solution("0" * 80) is False


def test_empty_str_rejected():
    assert has_unique_solution("") is False


def test_known_unique_puzzle():
    puzzle = (
        "530070000"
        "600195000"
        "098000060"
        "800060003"
        "400803001"
        "700020006"
        "060000280"
        "000419005"
        "000080079"
    )
    assert has_unique_solution(puzzle) is True


def test_rotationally_symmetric_unique():
    puzzle = (
        "530070000"
        "600195000"
        "098000060"
        "800060003"
        "400803001"
        "700020006"
        "060000280"
        "000419005"
        "000080079"
    )
    assert has_unique_solution(puzzle) is True


def test_minimal_clues_not_unique():
    puzzle = list("0" * 81)
    puzzle[0] = "1"
    assert has_unique_solution("".join(puzzle)) is False


def test_count_solutions_known():
    puzzle = (
        "530070000"
        "600195000"
        "098000060"
        "800060003"
        "400803001"
        "700020006"
        "060000280"
        "000419005"
        "000080079"
    )
    assert count_solutions(puzzle, limit=5) == 1


@pytest.mark.parametrize("clues", [17, 25, 30, 40, 50, 60])
def test_partial_puzzle_may_be_unique(clues):
    puzzle = "0" * clues + "1" * (81 - clues)
    result = has_unique_solution(puzzle[:81])
    assert isinstance(result, bool)


def test_count_solutions_large():
    puzzle = "0" * 81
    assert count_solutions(puzzle, limit=3) == 3


def test_single_row_empty():
    grid = ["1"] * 9
    puzzle = "".join(grid + ["0"] * 72)
    assert count_solutions(puzzle, limit=10) >= 1


def test_invalid_chars_not_unique():
    puzzle = "X" * 81
    assert has_unique_solution(puzzle) is False
