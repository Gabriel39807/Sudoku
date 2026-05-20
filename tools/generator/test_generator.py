from __future__ import annotations

import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from copy import deepcopy

from classify_by_techniques import classify_by_techniques, CATEGORY, DIFFICULTY_ORDER
from export import board_to_string, export_board, puzzle_hash, SEEN_HASHES
from human_solver import solve_human, TECHNIQUE_ORDER
from techniques.base import init_candidates, place, remove_values, units
from techniques.naked_single import Technique as NakedSingle
from techniques.hidden_single import Technique as HiddenSingle
from validator import count_solutions, has_unique_solution, solve
from validator_final import to_grid, validate_board


# ─── Test boards ───────────────────────────────────────────────────

EMPTY = [[0] * 9 for _ in range(9)]

VALID_EASY = (
    "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
)

SOLUTION_EASY = (
    "534678912672195348198342567859761423426853791713924856961537284287419635345286179"
)

INVALID_ROW = (
    "110000000000000000000000000000000000000000000000000000000000000000000000000000000"
)

INVALID_COL = (
    "100000000100000000000000000000000000000000000000000000000000000000000000000000000"
)

INVALID_BOX = (
    "100000000010000000000000000000000000000000000000000000000000000000000000000000000"
)


def string_to_grid(value):
    return [[int(value[r * 9 + c]) for c in range(9)] for r in range(9)]


# ─── Tests: Solver ─────────────────────────────────────────────────

class TestSolver(unittest.TestCase):
    def test_solve_valid_puzzle(self):
        grid = string_to_grid(VALID_EASY)
        result = solve(grid)
        self.assertIsNotNone(result)

    def test_has_unique_solution(self):
        grid = string_to_grid(VALID_EASY)
        self.assertTrue(has_unique_solution(grid))

    def test_empty_board_solution(self):
        grid = deepcopy(EMPTY)
        result = solve(grid)
        self.assertIsNotNone(result)

    def test_count_solutions_unique(self):
        grid = string_to_grid(VALID_EASY)
        self.assertEqual(count_solutions(deepcopy(grid), 2), 1)

    def test_full_board_is_valid(self):
        grid = string_to_grid(SOLUTION_EASY)
        result = solve(grid)
        self.assertIsNotNone(result)


# ─── Tests: Human Solver ──────────────────────────────────────────

class TestHumanSolver(unittest.TestCase):
    def test_solves_easy_puzzle(self):
        grid = string_to_grid(VALID_EASY)
        result = solve_human(grid)
        self.assertTrue(result["solved"])
        self.assertIn("techniques", result)
        self.assertGreater(result["steps"], 0)

    def test_techniques_are_real(self):
        grid = string_to_grid(VALID_EASY)
        result = solve_human(grid)
        for technique in result["techniques"]:
            self.assertIn(technique, CATEGORY, f"{technique} not in CATEGORY mapping")

    def test_easy_only_uses_easy_techniques(self):
        grid = string_to_grid(VALID_EASY)
        result = solve_human(grid)
        classified = classify_by_techniques(result["techniques"])
        self.assertIn(classified, ("easy",))

    def test_human_solver_empty(self):
        grid = deepcopy(EMPTY)
        result = solve_human(grid)
        self.assertFalse(result["solved"], "human solver cant solve empty board without guessing")

    def test_technique_order_contains_all(self):
        names = [t.name for t in TECHNIQUE_ORDER]
        expected = [
            "naked_single", "hidden_single", "naked_pair", "hidden_pair",
            "naked_triple", "hidden_triple", "pointing_pair", "box_line_reduction",
            "xwing", "swordfish", "xywing", "forcing_chain",
        ]
        self.assertEqual(names, expected)


# ─── Tests: Validator ──────────────────────────────────────────────

class TestValidator(unittest.TestCase):
    def test_validate_valid_puzzle(self):
        result = validate_board(VALID_EASY, SOLUTION_EASY, "easy")
        self.assertTrue(result["valid"], f"errors: {result['errors']}")

    def test_validate_rejects_row_conflict(self):
        result = validate_board(INVALID_ROW)
        self.assertFalse(result["valid"])
        self.assertTrue(any("row" in e for e in result["errors"]))

    def test_validate_rejects_col_conflict(self):
        result = validate_board(INVALID_COL)
        self.assertFalse(result["valid"])
        self.assertTrue(any("column" in e for e in result["errors"]))

    def test_validate_rejects_box_conflict(self):
        result = validate_board(INVALID_BOX)
        self.assertFalse(result["valid"])
        self.assertTrue(any("box" in e for e in result["errors"]))

    def test_validate_rejects_preloaded_mismatch(self):
        puzzle = "100000000" + "0" * 72
        solution = "2" + "1" * 80
        result = validate_board(puzzle, solution, "easy")
        self.assertFalse(result["valid"])
        self.assertTrue(any("preloaded value mismatch" in e for e in result["errors"]))

    def test_validate_empty_has_no_unique_solution(self):
        result = validate_board(EMPTY)
        self.assertFalse(result["valid"])
        self.assertTrue(any("not unique" in e for e in result["errors"]))


# ─── Tests: Classification ─────────────────────────────────────────

class TestClassification(unittest.TestCase):
    def test_easy_classification(self):
        self.assertEqual(classify_by_techniques(["naked_single", "hidden_single"]), "easy")

    def test_intermediate_classification(self):
        self.assertEqual(classify_by_techniques(["hidden_single", "naked_pair"]), "intermediate")

    def test_hard_classification(self):
        self.assertEqual(classify_by_techniques(["pointing_pair"]), "hard")

    def test_expert_classification(self):
        self.assertEqual(classify_by_techniques(["xwing"]), "expert")

    def test_evil_classification(self):
        self.assertEqual(classify_by_techniques(["xywing"]), "evil")

    def test_mythic_classification(self):
        self.assertEqual(classify_by_techniques(["forcing_chain"]), "mythic")

    def test_rejects_unknown_technique(self):
        self.assertEqual(classify_by_techniques(["unknown_technique"]), None)

    def test_hard_with_xwing_becomes_expert(self):
        self.assertEqual(classify_by_techniques(["pointing_pair", "xwing"]), "expert")

    def test_all_categories_mapped(self):
        expected = {
            "naked_single": "easy", "hidden_single": "easy",
            "naked_pair": "intermediate", "hidden_pair": "intermediate",
            "naked_triple": "intermediate", "hidden_triple": "intermediate",
            "pointing_pair": "hard", "box_line_reduction": "hard",
            "xwing": "expert", "swordfish": "expert",
            "xywing": "evil", "forcing_chain": "mythic",
        }
        self.assertEqual(CATEGORY, expected)


# ─── Tests: Duplicates ─────────────────────────────────────────────

class TestDuplicates(unittest.TestCase):
    def setUp(self):
        SEEN_HASHES.clear()

    def test_same_puzzle_rejected(self):
        grid = string_to_grid(VALID_EASY)
        export_board("test_001", "easy", grid, grid)
        with self.assertRaises(ValueError):
            export_board("test_002", "easy", grid, grid)

    def test_different_puzzles_accepted(self):
        grid1 = string_to_grid(VALID_EASY)
        grid2 = string_to_grid(VALID_EASY.replace("5", "9", 1))
        export_board("test_001", "easy", grid1, grid1)
        export_board("test_002", "easy", grid2, grid2)

    def test_hash_differs_for_different_boards(self):
        grid1 = string_to_grid(VALID_EASY)
        grid2 = string_to_grid(INVALID_ROW)
        self.assertNotEqual(puzzle_hash(grid1), puzzle_hash(grid2))

    def test_hash_consistent(self):
        g1 = string_to_grid(VALID_EASY)
        g2 = string_to_grid(VALID_EASY)
        self.assertEqual(puzzle_hash(g1), puzzle_hash(g2))


# ─── Tests: Export ─────────────────────────────────────────────────

class TestExport(unittest.TestCase):
    def setUp(self):
        SEEN_HASHES.clear()

    def test_export_contains_hash(self):
        grid = string_to_grid(VALID_EASY)
        data = export_board("test_export", "easy", grid, grid)
        self.assertIn("hash", data)
        self.assertIn("id", data)
        self.assertIn("difficulty", data)
        self.assertIn("puzzle", data)
        self.assertIn("solution", data)
        self.assertIn("techniques", data)
        self.assertIn("steps", data)

    def test_export_no_checksum_field(self):
        grid = string_to_grid(VALID_EASY)
        data = export_board("test_no_cs", "easy", grid, grid)
        self.assertNotIn("checksum", data)

    def test_export_hash_is_sha256(self):
        grid = string_to_grid(VALID_EASY)
        data = export_board("test_hash", "easy", grid, grid)
        self.assertEqual(len(data["hash"]), 64)

    def test_board_to_string(self):
        grid = string_to_grid(VALID_EASY)
        result = board_to_string(grid)
        self.assertEqual(len(result), 81)
        self.assertEqual(result, VALID_EASY)


# ─── Tests: to_grid ────────────────────────────────────────────────

class TestToGrid(unittest.TestCase):
    def test_string_81_chars(self):
        result = to_grid(VALID_EASY)
        self.assertIsNotNone(result)
        self.assertEqual(len(result), 9)
        self.assertEqual(len(result[0]), 9)

    def test_string_wrong_length(self):
        self.assertIsNone(to_grid("123"))

    def test_string_invalid_chars(self):
        self.assertIsNone(to_grid("a" + "0" * 80))

    def test_list_9x9(self):
        grid = [[0] * 9 for _ in range(9)]
        result = to_grid(grid)
        self.assertIsNotNone(result)

    def test_invalid_type(self):
        self.assertIsNone(to_grid(123))

    def test_none_input(self):
        self.assertIsNone(to_grid(None))


# ─── Tests: Technique helpers ──────────────────────────────────────

class TestTechniqueHelpers(unittest.TestCase):
    def test_init_candidates_empty(self):
        board = [[0] * 9 for _ in range(9)]
        cands = init_candidates(board)
        for r in range(9):
            for c in range(9):
                self.assertEqual(cands[(r, c)], set(range(1, 10)))

    def test_init_candidates_full(self):
        grid = string_to_grid(SOLUTION_EASY)
        cands = init_candidates(grid)
        for r in range(9):
            for c in range(9):
                self.assertEqual(cands[(r, c)], set())

    def test_place_updates_candidates(self):
        board = [[0] * 9 for _ in range(9)]
        cands = init_candidates(board)
        place(board, cands, (0, 0), 5)
        self.assertEqual(board[0][0], 5)
        self.assertEqual(cands[(0, 0)], set())
        self.assertNotIn(5, cands[(0, 1)])

    def test_remove_values(self):
        board = [[0] * 9 for _ in range(9)]
        cands = init_candidates(board)
        changed = remove_values(cands, [(0, 0)], {1, 2, 3})
        self.assertEqual(len(changed), 1)
        self.assertEqual(cands[(0, 0)], set(range(4, 10)))

    def test_units_count(self):
        all_units = units()
        self.assertEqual(len(all_units), 27)


# ─── Run ───────────────────────────────────────────────────────────

if __name__ == "__main__":
    unittest.main(verbosity=2)
