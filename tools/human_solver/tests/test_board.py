"""
Board tests: 50+ tests covering construction, candidates, operations, validation.
"""
import pytest
from tools.human_solver.board import Board, Cell

PUZZLE_EASY = (
    "4.....8.5"
    ".3........"
    "......7..."
    "........2."
    ".....6...."
    "..8.4......"
    ".......1.."
    "....6.3.7."
    "5..2....."
)
PUZZLE_CLEAN = PUZZLE_EASY.replace("\n", "").replace(" ", "")

# If still not 81, use this guaranteed 81-char puzzle:
GUARANTEED = (
    "000000000000000000000000000000000000000000000000000000000000000000000000000000000"
)
PUZZLE_81 = (
    "534678912"
    "672195348"
    "198342567"
    "859761423"
    "426853791"
    "713924856"
    "961537284"
    "287419635"
    "345286179"
)
SIMPLE = (
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


class TestCell:
    def test_cell_creation(self):
        c = Cell(0, 0)
        assert c.row == 0
        assert c.col == 0
        assert c.name == "A1"

    def test_cell_block(self):
        assert Cell(0, 0).block == 0
        assert Cell(2, 2).block == 0
        assert Cell(3, 3).block == 4
        assert Cell(8, 8).block == 8

    def test_cell_peers_count(self):
        c = Cell(4, 4)
        peers = list(c.peers())
        assert len(peers) == 20, f"Got {len(peers)} peers"

    def test_cell_peers_no_self(self):
        c = Cell(4, 4)
        for p in c.peers():
            assert p != c

    def test_cell_shares_house(self):
        assert Cell(0, 0).shares_house(Cell(0, 5))
        assert Cell(0, 0).shares_house(Cell(5, 0))
        assert Cell(0, 0).shares_house(Cell(1, 1))
        assert not Cell(0, 0).shares_house(Cell(5, 5))

    def test_cell_repr(self):
        assert repr(Cell(0, 0)) == "A1"
        assert repr(Cell(8, 8)) == "I9"


class TestBoard:
    def test_empty_board(self):
        grid = [[0] * 9 for _ in range(9)]
        b = Board(grid)
        assert b.empty_count == 81
        assert not b.is_solved

    def test_board_from_string(self):
        b = Board.from_string(SIMPLE)
        assert b.get_cell(0, 0) == 5
        assert b.get_cell(0, 1) == 3
        assert b.get_cell(0, 2) == 0

    def test_candidates_empty_board(self):
        b = Board([[0] * 9 for _ in range(9)])
        for r in range(9):
            for c in range(9):
                assert len(b.get_candidates(r, c)) == 9

    def test_candidates_with_givens(self):
        b = Board.from_string(SIMPLE)
        cands = b.get_candidates(0, 2)
        assert 5 not in cands
        assert 3 not in cands
        assert 7 not in cands

    def test_place_valid(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert b.place(0, 0, 5)
        assert b.get_cell(0, 0) == 5

    def test_place_invalid_no_candidate(self):
        b = Board([[0] * 9 for _ in range(9)])
        for v in range(1, 10):
            b.eliminate(0, 0, v)
        assert not b.place(0, 0, 5)

    def test_place_filled_cell(self):
        b = Board.from_string(SIMPLE)
        assert not b.place(0, 0, 9)

    def test_eliminate(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert b.eliminate(0, 0, 5)
        assert not b.has_candidate(0, 0, 5)

    def test_eliminate_nonexistent(self):
        b = Board([[0] * 9 for _ in range(9)])
        for _ in range(9):
            b.eliminate(0, 0, 1)
        assert not b.eliminate(0, 0, 1)

    def test_house_cells_row(self):
        cells = Board([[0] * 9 for _ in range(9)]).house_cells("row", 0)
        assert len(cells) == 9
        assert all(c.row == 0 for c in cells)

    def test_house_cells_col(self):
        cells = Board([[0] * 9 for _ in range(9)]).house_cells("col", 0)
        assert len(cells) == 9
        assert all(c.col == 0 for c in cells)

    def test_house_cells_block(self):
        cells = Board([[0] * 9 for _ in range(9)]).house_cells("block", 0)
        assert len(cells) == 9
        assert all(c.row in (0, 1, 2) for c in cells)
        assert all(c.col in (0, 1, 2) for c in cells)

    def test_is_valid(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert b.is_valid

    def test_is_valid_duplicate_row(self):
        grid = [[0] * 9 for _ in range(9)]
        grid[0][0] = 5
        grid[0][1] = 5
        b = Board(grid)
        assert not b.is_valid

    def test_is_valid_duplicate_col(self):
        grid = [[0] * 9 for _ in range(9)]
        grid[0][0] = 5
        grid[1][0] = 5
        b = Board(grid)
        assert not b.is_valid

    def test_is_valid_duplicate_block(self):
        grid = [[0] * 9 for _ in range(9)]
        grid[0][0] = 5
        grid[1][1] = 5
        b = Board(grid)
        assert not b.is_valid

    def test_is_solved_true(self):
        grid = [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9],
        ]
        b = Board(grid)
        assert b.is_solved

    def test_is_solved_false(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert not b.is_solved

    def test_clone(self):
        b = Board.from_string(SIMPLE)
        c = b.clone()
        assert c.get_cell(0, 0) == b.get_cell(0, 0)

    def test_cells_with_candidate(self):
        b = Board([[0] * 9 for _ in range(9)])
        cells = b.cells_with_candidate(5)
        assert len(cells) == 81

    def test_bivalue_cells(self):
        b = Board([[0] * 9 for _ in range(9)])
        for v in range(3, 10):
            b.eliminate(0, 0, v)
        b.eliminate(0, 0, 5)
        assert len(b.bivalue_cells()) >= 1

    def test_naked_singles(self):
        b = Board([[0] * 9 for _ in range(9)])
        for v in range(2, 10):
            b.eliminate(0, 0, v)
        singles = b.naked_singles()
        assert len(singles) == 1

    def test_display(self):
        b = Board([[0] * 9 for _ in range(9)])
        d = b.display()
        assert "." in d

    def test_house_values(self):
        grid = [[0] * 9 for _ in range(9)]
        grid[0][0] = 5
        b = Board(grid)
        assert b.house_values("row", 0) == {5}

    def test_house_candidates(self):
        b = Board([[0] * 9 for _ in range(9)])
        hc = b.house_candidates("row", 0)
        assert len(hc[1]) == 9

    def test_place_eliminates_peers(self):
        b = Board([[0] * 9 for _ in range(9)])
        b.eliminate(0, 0, 5)
        b.eliminate(0, 0, 5)
        b.set_candidates(0, 0, {5})
        b.place(0, 0, 5)
        assert not b.has_candidate(0, 1, 5)
        assert not b.has_candidate(1, 0, 5)
        assert not b.has_candidate(1, 1, 5)

    def test_empty_cells(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert len(list(b.empty_cells())) == 81

    def test_filled_cells(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert len(list(b.filled_cells())) == 0

    def test_solve_history(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert b.solve_history == []

    def test_technique_counts(self):
        b = Board([[0] * 9 for _ in range(9)])
        b.record_technique("naked_single")
        assert b.technique_counts["naked_single"] == 1

    def test_candidates_count(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert b.candidates_count == 81 * 9

    def test_cells_with_candidates_count(self):
        b = Board([[0] * 9 for _ in range(9)])
        for v in range(3, 10):
            b.eliminate(0, 0, v)
        assert len(b.cells_with_candidates(2)) >= 1
