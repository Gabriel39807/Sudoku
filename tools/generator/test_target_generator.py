from __future__ import annotations

import os
import sys
import unittest
from human_solver import solve_human
from validator_final import validate_board, validate_human_profile
from difficulty_profiles import PROFILES, techniques_match_profile, classify_from_profile
from difficulty_score import human_score, score_to_difficulty, score_range_for_difficulty, TECHNIQUE_WEIGHTS
from target_generator import generate_target, generate_multiple
from validator import has_unique_solution

# Higher difficulties need more removal passes to hit target techniques
_PASSES = dict(
    easy=3,
    intermediate=5,
    hard=10,
    expert=15,
    evil=12,
    mythic=20,
)


EASY_81 = "530070000600195000098000060800060003400803001700020006060000280000419005000080079"


def string_to_grid(value):
    return [[int(value[r * 9 + c]) for c in range(9)] for r in range(9)]

def _args(difficulty):
    return dict(max_solutions=1, removal_passes_per_solution=_PASSES[difficulty])


# ─── Tests: Difficulty Profiles ─────────────────────────────────

class TestProfiles(unittest.TestCase):
    def test_all_difficulties_have_profiles(self):
        for diff in ["easy", "intermediate", "hard", "expert", "evil", "mythic"]:
            self.assertIn(diff, PROFILES, f"missing profile for {diff}")

    def test_easy_profile_valid(self):
        self.assertTrue(techniques_match_profile(["naked_single", "hidden_single"], "easy"))

    def test_easy_rejects_naked_pair(self):
        self.assertFalse(techniques_match_profile(["naked_single", "naked_pair"], "easy"))

    def test_easy_rejects_xwing(self):
        self.assertFalse(techniques_match_profile(["naked_single", "xwing"], "easy"))

    def test_expert_accepts_xwing(self):
        self.assertTrue(techniques_match_profile(["naked_single", "hidden_single", "xwing"], "expert"))

    def test_expert_rejects_xywing(self):
        self.assertFalse(techniques_match_profile(["naked_single", "xywing"], "expert"))

    def test_evil_accepts_xywing(self):
        self.assertTrue(techniques_match_profile(["naked_single", "xywing"], "evil"))

    def test_evil_rejects_forcing_chain(self):
        self.assertFalse(techniques_match_profile(["naked_single", "forcing_chain"], "evil"))

    def test_mythic_accepts_forcing_chain(self):
        self.assertTrue(techniques_match_profile(["naked_single", "forcing_chain"], "mythic"))

    def test_classify_from_profile_easy(self):
        self.assertEqual(classify_from_profile(["naked_single", "hidden_single"]), "easy")

    def test_classify_from_profile_expert(self):
        self.assertEqual(classify_from_profile(["naked_single", "hidden_single", "xwing"]), "expert")

    def test_classify_from_profile_mythic(self):
        self.assertEqual(classify_from_profile(["naked_single", "forcing_chain"]), "mythic")

    def test_classify_from_profile_none(self):
        self.assertIsNone(classify_from_profile([]))

    def test_profile_has_required_and_forbidden(self):
        for diff, profile in PROFILES.items():
            self.assertIn("required", profile, f"{diff} missing required")
            self.assertIn("forbidden", profile, f"{diff} missing forbidden")
            self.assertIn("max_steps", profile, f"{diff} missing max_steps")
            self.assertIn("allowed", profile, f"{diff} missing allowed")


# ─── Tests: Difficulty Score ────────────────────────────────────

class TestScore(unittest.TestCase):
    def test_all_techniques_have_weights(self):
        expected = {
            "naked_single": 1, "hidden_single": 1,
            "naked_pair": 3, "hidden_pair": 3,
            "naked_triple": 3, "hidden_triple": 3,
            "pointing_pair": 5, "box_line_reduction": 5,
            "xwing": 10, "swordfish": 15,
            "xywing": 20, "forcing_chain": 30,
        }
        self.assertEqual(TECHNIQUE_WEIGHTS, expected)

    def test_human_score_easy(self):
        self.assertEqual(human_score(["naked_single", "hidden_single"]), 2)

    def test_human_score_expert(self):
        self.assertGreater(human_score(["naked_single", "xwing"]), 10)

    def test_human_score_no_duplicates(self):
        score = human_score(["naked_single", "naked_single", "naked_single"])
        self.assertEqual(score, 1)

    def test_score_to_difficulty_easy(self):
        self.assertEqual(score_to_difficulty(1), "easy")

    def test_score_to_difficulty_expert(self):
        self.assertEqual(score_to_difficulty(25), "expert")

    def test_score_to_difficulty_mythic(self):
        self.assertEqual(score_to_difficulty(60), "mythic")

    def test_score_range_for_difficulty(self):
        lo, hi = score_range_for_difficulty("easy")
        self.assertEqual(lo, 1)
        self.assertEqual(hi, 6)

    def test_score_range_intermediate(self):
        lo, hi = score_range_for_difficulty("intermediate")
        self.assertEqual(lo, 3)
        self.assertEqual(hi, 14)


# ─── Tests: Target Generator ────────────────────────────────────

class TestTargetGenerator(unittest.TestCase):
    def test_generate_target_easy(self):
        board = generate_target("easy", **_args("easy"))
        self.assertIsNotNone(board, "should generate easy board")
        self.assertIn("puzzle", board)
        self.assertIn("solution", board)
        self.assertIn("techniques", board)
        self.assertGreater(board["steps"], 0)

    def test_generated_board_has_unique_solution(self):
        board = generate_target("easy", **_args("easy"))
        self.assertIsNotNone(board)
        self.assertTrue(has_unique_solution(board["puzzle"]))

    def test_generated_board_is_solvable_by_human(self):
        board = generate_target("easy", **_args("easy"))
        self.assertIsNotNone(board)
        human = solve_human(board["puzzle"])
        self.assertTrue(human["solved"])

    def test_generated_techniques_match_profile(self):
        board = generate_target("easy", **_args("easy"))
        self.assertIsNotNone(board)
        self.assertTrue(techniques_match_profile(board["techniques"], "easy"))

    def test_generate_target_intermediate(self):
        board = generate_target("intermediate", **_args("intermediate"))
        self.assertIsNotNone(board, "should generate intermediate board")

    def test_generate_target_hard(self):
        board = generate_target("hard", **_args("hard"))
        self.assertIsNotNone(board, "should generate hard board")

    def test_generate_target_expert(self):
        board = generate_target("expert", **_args("expert"))
        self.assertIsNotNone(board, "should generate expert board")

    def test_generate_target_evil(self):
        board = generate_target("evil", **_args("evil"))
        self.assertIsNotNone(board, "should generate evil board")

    def test_generate_target_mythic(self):
        board = generate_target("mythic", **_args("mythic"))
        self.assertIsNotNone(board, "should generate mythic board")

    def test_generate_target_invalid_difficulty(self):
        board = generate_target("invalid_difficulty")
        self.assertIsNone(board)

    def test_generate_target_has_removed_cells(self):
        board = generate_target("easy", **_args("easy"))
        self.assertIsNotNone(board)
        self.assertGreaterEqual(board["removed"], 20)

    def test_generated_puzzle_differs_from_solution(self):
        board = generate_target("easy", **_args("easy"))
        self.assertIsNotNone(board)
        puzzle_str = "".join(str(v) for row in board["puzzle"] for v in row)
        sol_str = "".join(str(v) for row in board["solution"] for v in row)
        self.assertNotEqual(puzzle_str, sol_str)

    def test_generate_multiple_returns_list(self):
        boards = generate_multiple("easy", count=3, max_solutions_per_board=1, removal_passes_per_solution=_PASSES["easy"])
        self.assertEqual(len(boards), 3)

    def test_generate_multiple_no_duplicates(self):
        boards = generate_multiple("easy", count=3, max_solutions_per_board=1, removal_passes_per_solution=_PASSES["easy"])
        hashes = []
        for b in boards:
            from export import puzzle_hash
            hashes.append(puzzle_hash(b["puzzle"]))
        self.assertEqual(len(hashes), len(set(hashes)))

    def test_generated_techniques_have_human_score(self):
        board = generate_target("easy", **_args("easy"))
        self.assertIsNotNone(board)
        score = human_score(board["techniques"])
        self.assertGreater(score, 0)


# ─── Tests: Validate Human Profile ──────────────────────────────

class TestValidateHumanProfile(unittest.TestCase):
    def test_easy_profile_passes(self):
        errors = validate_human_profile(["naked_single", "hidden_single"], 10, "easy")
        self.assertEqual(errors, [])

    def test_easy_with_xwing_fails(self):
        errors = validate_human_profile(["naked_single", "xwing"], 10, "easy")
        self.assertTrue(len(errors) > 0)

    def test_expert_with_xywing_fails(self):
        errors = validate_human_profile(["naked_single", "xywing"], 10, "expert")
        self.assertTrue(len(errors) > 0)

    def test_evil_with_forcing_chain_fails(self):
        errors = validate_human_profile(["naked_single", "forcing_chain"], 10, "evil")
        self.assertTrue(len(errors) > 0)

    def test_mythic_with_forcing_chain_passes(self):
        errors = validate_human_profile(["naked_single", "forcing_chain"], 10, "mythic")
        self.assertEqual(errors, [])

    def test_too_many_steps_fails(self):
        errors = validate_human_profile(["naked_single", "hidden_single"], 999, "easy")
        self.assertTrue(any("steps" in e for e in errors))


# ─── Verify old tests still pass ────────────────────────────────

class TestBackwardCompatibility(unittest.TestCase):
    def test_validator_still_works(self):
        result = validate_board(EASY_81)
        self.assertIn("valid", result)
        self.assertIn("human_score", result)

    def test_validate_human_profile_returns_list(self):
        result = validate_human_profile(["naked_single"], 5, "easy")
        self.assertIsInstance(result, list)


if __name__ == "__main__":
    unittest.main(verbosity=2)
