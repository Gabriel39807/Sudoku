"""
Variant registry tests.
"""
import pytest
import os
import json
import pytest
from tools.master_generator.variants import VariantRegistry, VARIANTS
from tools.master_generator.variants.mini_4x4 import (
    Mini4x4Generator,
    MiniBacktrackSolver as Mini4x4BTS,
    MiniTechniqueSolver as Mini4x4TS,
    MiniBoard,
)
from tools.master_generator.variants.mini_6x6 import (
    Mini6x6Generator,
    Mini6x6BacktrackSolver,
    Mini6x6TechniqueSolver,
    Mini6x6Board,
)
from tools.master_generator.variants.mini_8x8 import (
    Mini8x8Generator,
    Mini8x8BacktrackSolver,
    Mini8x8TechniqueSolver,
    Mini8x8Board,
    TIER_DEFINITIONS as TIER_DEFS_8,
)


class TestVariantRegistry:
    def test_get_classic(self):
        v = VariantRegistry.get("classic_9x9")
        assert v.id == "classic_9x9"
        assert v.status == "active"

    def test_list_contains_all(self):
        ids = VariantRegistry.list()
        assert "classic_9x9" in ids
        assert "mini_4x4" in ids
        assert "killer" in ids

    def test_get_unknown_raises(self):
        with pytest.raises(ValueError):
            VariantRegistry.get("nonexistent")

    def test_active_only(self):
        active = VariantRegistry.active()
        for v in active:
            assert v.status == "active"
        ids = [v.id for v in active]
        assert "classic_9x9" in ids
        assert "killer" not in ids

    def test_by_status_future(self):
        future = VariantRegistry.by_status("future")
        for v in future:
            assert v.status == "future"

    def test_by_tag_mini(self):
        mini = VariantRegistry.by_tag("mini")
        ids = [v.id for v in mini]
        assert "mini_4x4" in ids
        assert "mini_6x6" in ids
        assert "mini_8x8" in ids

    def test_by_tag_campaign(self):
        campaign = VariantRegistry.by_tag("campaign")
        assert len(campaign) >= 1

    def test_by_tag_variant(self):
        variants = VariantRegistry.by_tag("variant")
        assert len(variants) >= 3  # killer, x, windoku, jigsaw


class TestVariants:
    def test_all_have_ids(self):
        for v in VARIANTS:
            assert len(v.id) > 0

    def test_all_have_status(self):
        for v in VARIANTS:
            assert v.status in ("active", "registered", "future")

    def test_future_require_solver(self):
        for v in VariantRegistry.by_status("future"):
            assert len(v.requires) > 0

    def test_registered_variants(self):
        reg = VariantRegistry.by_status("registered")
        ids = [v.id for v in reg]
        assert "mini_4x4" in ids
        assert "campaign_progressive" in ids

    def test_mini_sizes(self):
        mini = VariantRegistry.by_tag("mini")
        for v in mini:
            assert v.cells < 81


class TestMini4x4Generator:
    def test_generate_solved_valid(self):
        gen = Mini4x4Generator(seed=42)
        board = gen.generate_solved()
        assert board.is_solved()
        assert board.is_valid()

    def test_generate_different_seeds(self):
        b1 = Mini4x4Generator(seed=1).generate_solved()
        b2 = Mini4x4Generator(seed=2).generate_solved()
        assert b1.to_string() != b2.to_string()

    def test_generate_within_clue_range(self):
        gen = Mini4x4Generator(seed=99)
        for _ in range(5):
            r = gen.generate(min_clues=10, max_clues=12, max_tier=1, max_attempts=20)
            assert r is not None, "generate returned None"
            assert 10 <= r["clues"] <= 12, "clues=%d not in [10,12]" % r["clues"]
            assert r["tier_max"] == 1

    def test_generate_tier_2(self):
        gen = Mini4x4Generator(seed=7)
        r = gen.generate(min_clues=6, max_clues=8, max_tier=2, max_attempts=30)
        assert r is not None
        assert r["tier_max"] <= 2

    def test_generate_all_unique(self):
        gen = Mini4x4Generator(seed=42)
        puzzles = set()
        for _ in range(10):
            r = gen.generate(min_clues=7, max_clues=8, max_tier=1, max_attempts=20)
            assert r is not None
            assert r["puzzle"] not in puzzles, "duplicate puzzle generated"
            puzzles.add(r["puzzle"])

    def test_mini_backtrack_solver(self):
        board = MiniBoard([[0] * 4 for _ in range(4)])
        solved = Mini4x4BTS.solve(board)
        assert solved.is_solved()
        assert solved.is_valid()

    def test_mini_technique_solver_naked_single(self):
        gen = Mini4x4Generator(seed=5)
        r = gen.generate(min_clues=12, max_clues=12, max_tier=1, max_attempts=10)
        assert r is not None
        board = MiniBoard.from_string(r["puzzle"])
        ok, tier = Mini4x4TS.solve(board)
        assert ok, "puzzle not solvable"
        assert tier == 1


class TestCampaignStage1:
    CAMPAIGN_DIR = os.path.join(
        os.path.dirname(__file__), "..", "..", "..",
        "assets", "boards", "campaign", "stage_01",
    )

    def test_all_files_exist(self):
        assert os.path.isdir(self.CAMPAIGN_DIR), "stage_01 dir missing"
        files = [f for f in os.listdir(self.CAMPAIGN_DIR) if f.endswith(".json")]
        assert len(files) == 50, "expected 50 files, got %d" % len(files)

    def _load_puzzles(self):
        files = sorted(
            f for f in os.listdir(self.CAMPAIGN_DIR) if f.endswith(".json")
        )
        return [json.load(open(os.path.join(self.CAMPAIGN_DIR, f))) for f in files]

    def test_all_levels_unique_solution(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            board = MiniBoard.from_string(p["puzzle"])
            assert Mini4x4BTS.has_unique_solution(board), (
                "%s has multiple solutions" % p["level_id"]
            )

    def test_all_levels_solvable_with_required_tier(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            board = MiniBoard.from_string(p["puzzle"])
            ok, tier = Mini4x4TS.solve(board)
            assert ok, "%s not solvable" % p["level_id"]
            assert tier <= p["tier_max"], (
                "%s requires tier %d, max is %d" % (p["level_id"], tier, p["tier_max"])
            )

    def test_solution_matches(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            board = MiniBoard.from_string(p["puzzle"])
            solved = Mini4x4BTS.solve(board)
            assert solved.to_string() == p["solution"], (
                "%s solution mismatch" % p["level_id"]
            )

    def test_clue_ranges_by_difficulty(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            idx = p["level_index"]
            clues = p["clues"]
            if idx <= 10:
                assert clues >= 12, "levels 1-10 min 12 clues, got %d" % clues
            elif idx <= 20:
                assert 10 <= clues <= 12, "levels 11-20 10-12 clues, got %d" % clues
            elif idx <= 35:
                assert 8 <= clues <= 10, "levels 21-35 8-10 clues, got %d" % clues
            else:
                assert 7 <= clues <= 8, "levels 36-50 7-8 clues, got %d" % clues

    def test_all_tier_1(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            assert p["tier_max"] == 1, "%s tier_max=%d" % (p["level_id"], p["tier_max"])

    def test_valid_json_format(self):
        puzzles = self._load_puzzles()
        required = {"puzzle", "solution", "clues", "tier_max", "variant", "level_id", "stage", "level_index", "difficulty", "techniques"}
        for p in puzzles:
            missing = required - set(p.keys())
            assert not missing, "%s missing keys: %s" % (p["level_id"], missing)
            assert len(p["puzzle"]) == 16, "%s puzzle len=%d" % (p["level_id"], len(p["puzzle"]))
            assert len(p["solution"]) == 16, "%s solution len=%d" % (p["level_id"], len(p["solution"]))
            assert p["variant"] == "mini_4x4"
            assert p["stage"] == 1


CAMPAIGN_2_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "campaign", "stage_02",
)


class TestMini6x6Generator:
    def test_generate_solved_valid(self):
        gen = Mini6x6Generator(seed=42)
        board = gen.generate_solved()
        assert board.is_solved()
        assert board.is_valid()

    def test_generate_different_seeds(self):
        b1 = Mini6x6Generator(seed=1).generate_solved()
        b2 = Mini6x6Generator(seed=2).generate_solved()
        assert b1.to_string() != b2.to_string()

    def test_generate_within_clue_range(self):
        gen = Mini6x6Generator(seed=99)
        for _ in range(3):
            r = gen.generate(min_clues=16, max_clues=18, max_tier=2, max_attempts=20)
            assert r is not None
            assert 16 <= r["clues"] <= 18

    def test_generate_tier_3(self):
        gen = Mini6x6Generator(seed=7)
        r = gen.generate(min_clues=14, max_clues=14, max_tier=3, max_attempts=20)
        assert r is not None
        assert r["clues"] == 14

    def test_generate_tier_4(self):
        gen = Mini6x6Generator(seed=13)
        r = gen.generate(min_clues=12, max_clues=12, max_tier=4, max_attempts=20)
        assert r is not None
        assert r["clues"] == 12

    def test_generate_all_unique_6x6(self):
        gen = Mini6x6Generator(seed=42)
        puzzles = set()
        for _ in range(10):
            r = gen.generate(min_clues=12, max_clues=14, max_tier=4, max_attempts=20)
            assert r is not None
            assert r["puzzle"] not in puzzles
            puzzles.add(r["puzzle"])

    def test_backtrack_solver_6x6_empty(self):
        board = Mini6x6Board([[0] * 6 for _ in range(6)])
        solved = Mini6x6BacktrackSolver.solve(board)
        assert solved is not None
        assert solved.is_solved()
        assert solved.is_valid()

    def test_backtrack_solver_6x6_string_roundtrip(self):
        gen = Mini6x6Generator(seed=5)
        r = gen.generate(min_clues=16, max_clues=18, max_tier=2, max_attempts=20)
        assert r is not None
        board = Mini6x6Board.from_string(r["puzzle"])
        solved = Mini6x6BacktrackSolver.solve(board)
        assert solved.to_string() == r["solution"]

    def test_technique_solver_solves_level_4(self):
        gen = Mini6x6Generator(seed=42)
        r = gen.generate(min_clues=12, max_clues=14, max_tier=4, max_attempts=30)
        assert r is not None
        board = Mini6x6Board.from_string(r["puzzle"])
        ok, _ = Mini6x6TechniqueSolver.solve(board)
        assert ok

    def test_candidates_properly_tracked(self):
        # 6x6 = 36 chars: first row 1-6, rest zeros
        board = Mini6x6Board.from_string("123456000000000000000000000000000000")
        # Cell (0,0)=1 should have no candidates
        assert len(board.candidates(0, 0)) == 0
        # Cell (1,0) should not have 1 in candidates (same col)
        assert 1 not in board.candidates(1, 0)
        # Cell (0,5) should not have 1 in candidates (same row)
        assert 6 not in board.candidates(0, 5)

    def test_eliminate_persists(self):
        board = Mini6x6Board.from_string("0" * 36)
        cands_before = board.candidates(0, 0)
        assert 1 in cands_before
        assert board.eliminate(0, 0, 1)
        assert 1 not in board.candidates(0, 0)

    def test_clone_independent(self):
        board = Mini6x6Board.from_string("100000" + "0" * 30)
        clone = board.clone()
        clone.set_cell(0, 1, 2)
        assert board.get_cell(0, 1) == 0, "clone modified original"
        assert clone.get_cell(0, 1) == 2


class TestCampaignStage2:
    CAMPAIGN_DIR = os.path.join(
        os.path.dirname(__file__), "..", "..", "..",
        "assets", "boards", "campaign", "stage_02",
    )

    def test_all_files_exist(self):
        assert os.path.isdir(self.CAMPAIGN_DIR), "stage_02 dir missing"
        files = [f for f in os.listdir(self.CAMPAIGN_DIR) if f.endswith(".json")]
        assert len(files) == 75, "expected 75 files, got %d" % len(files)

    def _load_puzzles(self):
        files = sorted(
            f for f in os.listdir(self.CAMPAIGN_DIR) if f.endswith(".json")
        )
        return [json.load(open(os.path.join(self.CAMPAIGN_DIR, f))) for f in files]

    def test_all_levels_unique_solution(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            board = Mini6x6Board.from_string(p["puzzle"])
            assert Mini6x6BacktrackSolver.has_unique_solution(board), (
                "%s has multiple solutions" % p["level_id"]
            )

    def test_all_levels_solvable(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            board = Mini6x6Board.from_string(p["puzzle"])
            ok, _ = Mini6x6TechniqueSolver.solve(board)
            assert ok, "%s not solvable" % p["level_id"]

    def test_solution_matches(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            board = Mini6x6Board.from_string(p["puzzle"])
            solved = Mini6x6BacktrackSolver.solve(board)
            assert solved.to_string() == p["solution"], (
                "%s solution mismatch" % p["level_id"]
            )

    def test_clue_ranges_by_chapter(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            idx = p["level_index"]
            clues = p["clues"]
            if idx <= 15:
                assert 18 <= clues <= 22, "1-15: 18-22 clues, got %d" % clues
            elif idx <= 35:
                assert 16 <= clues <= 18, "16-35: 16-18 clues, got %d" % clues
            elif idx <= 55:
                assert 14 <= clues <= 16, "36-55: 14-16 clues, got %d" % clues
            else:
                assert 12 <= clues <= 14, "56-75: 12-14 clues, got %d" % clues

    def test_tier_progression(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            idx = p["level_index"]
            tier = p["tier_max"]
            if idx <= 15:
                assert tier == 1, "1-15 tier=1, got %d" % tier
            elif idx <= 35:
                assert tier == 2, "16-35 tier=2, got %d" % tier
            elif idx <= 55:
                assert tier == 3, "36-55 tier=3, got %d" % tier
            else:
                assert tier == 4, "56-75 tier=4, got %d" % tier

    def test_all_mini_6x6_variant(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            assert p["variant"] == "mini_6x6", "%s variant=%s" % (p["level_id"], p.get("variant"))

    def test_stage_is_2(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            assert p["stage"] == 2, "%s stage=%d" % (p["level_id"], p.get("stage"))

    def test_economy_metadata_present(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            assert "economy" in p, "%s missing economy" % p["level_id"]
            for key in ("coins", "souls", "perfect_bonus", "streak_bonus"):
                assert key in p["economy"], "%s economy missing %s" % (p["level_id"], key)

    def test_stars_metadata_present(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            assert "stars" in p, "%s missing stars" % p["level_id"]
            for key in ("clear", "perfect", "fast_clear"):
                assert key in p["stars"], "%s stars missing %s" % (p["level_id"], key)

    def test_valid_json_format(self):
        puzzles = self._load_puzzles()
        required = {
            "puzzle", "solution", "clues", "tier_max", "variant",
            "level_id", "stage", "chapter", "level_index",
            "difficulty", "techniques", "visual_score", "human_score",
            "tutorial", "economy", "stars",
        }
        for p in puzzles:
            missing = required - set(p.keys())
            assert not missing, "%s missing: %s" % (p["level_id"], missing)
            assert len(p["puzzle"]) == 36, "%s puzzle len=%d" % (p["level_id"], len(p["puzzle"]))
            assert len(p["solution"]) == 36, "%s solution len=%d" % (p["level_id"], len(p["solution"]))
            assert p["variant"] == "mini_6x6"
            assert p["stage"] == 2

    def test_tutorial_first_three(self):
        puzzles = self._load_puzzles()
        for p in puzzles:
            if p["level_index"] <= 3:
                assert p["tutorial"] is True, "%s should be tutorial" % p["level_id"]
            else:
                assert p["tutorial"] is False, "%s should not be tutorial" % p["level_id"]

    def test_no_fish_wings_chains(self):
        puzzles = self._load_puzzles()
        forbidden = {"Fish", "Wings", "Chains", "ALS", "Uniqueness", "Advanced"}
        for p in puzzles:
            for tech in p.get("techniques", []):
                for f in forbidden:
                    assert f.lower() not in tech.lower(), (
                        "%s has forbidden technique %s" % (p["level_id"], tech)
                    )

    def test_technique_count_by_tier(self):
        puzzles = self._load_puzzles()
        from tools.master_generator.variants.mini_6x6 import TIER_DEFINITIONS
        for p in puzzles:
            tier = p["tier_max"]
            expected = set(TIER_DEFINITIONS[tier])
            actual = set(p.get("techniques", []))
            assert actual == expected, (
                "%s tier=%d techniques mismatch:\n  expected=%s\n  actual=%s" % (
                    p["level_id"], tier, sorted(expected), sorted(actual)
                )
            )

    def test_level_ids_sequential(self):
        puzzles = sorted(self._load_puzzles(), key=lambda x: x["level_index"])
        for i, p in enumerate(puzzles, 1):
            assert p["level_index"] == i, "expected index %d, got %d" % (i, p["level_index"])
            expected_id = "campaign_6x6_%04d" % i
            assert p["level_id"] == expected_id, "expected %s, got %s" % (expected_id, p["level_id"])


CAMPAIGN_3_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "campaign", "stage_03",
)


class TestMini8x8Generator:
    def test_generate_solved_valid(self):
        gen = Mini8x8Generator(seed=42)
        board = gen.generate_solved()
        assert board.is_solved()
        assert board.is_valid()

    def test_generate_different_seeds(self):
        b1 = Mini8x8Generator(seed=1).generate_solved()
        b2 = Mini8x8Generator(seed=2).generate_solved()
        assert b1.to_string() != b2.to_string()

    def test_generate_all_tiers(self):
        gen = Mini8x8Generator(seed=99)
        for clues, tier in [(34, 1), (30, 2), (26, 3), (24, 4), (22, 5)]:
            r = gen.generate(min_clues=clues, max_clues=clues, max_tier=tier, max_attempts=15)
            assert r is not None, "Tier %d failed" % tier
            assert r["clues"] == clues

    def test_backtrack_solver_empty(self):
        board = Mini8x8Board([[0] * 8 for _ in range(8)])
        solved = Mini8x8BacktrackSolver.solve(board)
        assert solved is not None
        assert solved.is_solved()
        assert solved.is_valid()

    def test_backtrack_roundtrip(self):
        gen = Mini8x8Generator(seed=5)
        r = gen.generate(min_clues=30, max_clues=30, max_tier=2, max_attempts=15)
        assert r is not None
        board = Mini8x8Board.from_string(r["puzzle"])
        solved = Mini8x8BacktrackSolver.solve(board)
        assert solved.to_string() == r["solution"]

    def test_technique_solver_tier5(self):
        gen = Mini8x8Generator(seed=42)
        r = gen.generate(min_clues=22, max_clues=22, max_tier=5, max_attempts=20)
        assert r is not None
        board = Mini8x8Board.from_string(r["puzzle"])
        ok, _ = Mini8x8TechniqueSolver.solve(board)
        assert ok

    def test_candidates_8x8(self):
        s = "12345678" + "0" * 56
        board = Mini8x8Board.from_string(s)
        assert len(board.candidates(0, 0)) == 0
        assert 1 not in board.candidates(1, 0)
        assert 8 not in board.candidates(0, 7)

    def test_eliminate_persists_8x8(self):
        board = Mini8x8Board([([0] * 8) for _ in range(8)])
        assert 1 in board.candidates(0, 0)
        assert board.eliminate(0, 0, 1)
        assert 1 not in board.candidates(0, 0)

    def test_clone_independent_8x8(self):
        s = "10000000" + "0" * 56
        board = Mini8x8Board.from_string(s)
        clone = board.clone()
        clone.set_cell(0, 1, 2)
        assert board.get_cell(0, 1) == 0
        assert clone.get_cell(0, 1) == 2

    def test_generate_no_duplicates_8x8(self):
        gen = Mini8x8Generator(seed=42)
        puzzles = set()
        for _ in range(5):
            r = gen.generate(min_clues=26, max_clues=30, max_tier=3, max_attempts=15)
            assert r is not None
            assert r["puzzle"] not in puzzles
            puzzles.add(r["puzzle"])


class TestCampaignStage3:
    CAMPAIGN_DIR = CAMPAIGN_3_DIR

    def test_all_files_exist(self):
        assert os.path.isdir(self.CAMPAIGN_DIR)
        files = [f for f in os.listdir(self.CAMPAIGN_DIR) if f.endswith(".json")]
        assert len(files) == 100, "expected 100 files, got %d" % len(files)

    def _load_puzzles(self):
        files = sorted(f for f in os.listdir(self.CAMPAIGN_DIR) if f.endswith(".json"))
        return [json.load(open(os.path.join(self.CAMPAIGN_DIR, f))) for f in files]

    def test_unique_solution(self):
        for p in self._load_puzzles():
            board = Mini8x8Board.from_string(p["puzzle"])
            assert Mini8x8BacktrackSolver.has_unique_solution(board), (
                "%s multiple solutions" % p["level_id"]
            )

    def test_solvable(self):
        for p in self._load_puzzles():
            board = Mini8x8Board.from_string(p["puzzle"])
            ok, _ = Mini8x8TechniqueSolver.solve(board)
            assert ok, "%s not solvable" % p["level_id"]

    def test_solution_matches(self):
        for p in self._load_puzzles():
            board = Mini8x8Board.from_string(p["puzzle"])
            solved = Mini8x8BacktrackSolver.solve(board)
            assert solved.to_string() == p["solution"], (
                "%s solution mismatch" % p["level_id"]
            )

    def test_clue_ranges_by_chapter(self):
        for p in self._load_puzzles():
            idx = p["level_index"]
            clues = p["clues"]
            if idx <= 20:
                assert 34 <= clues <= 38, "1-20: 34-38 clues, got %d" % clues
            elif idx <= 40:
                assert 30 <= clues <= 34, "21-40: 30-34 clues, got %d" % clues
            elif idx <= 65:
                assert 26 <= clues <= 30, "41-65: 26-30 clues, got %d" % clues
            elif idx <= 85:
                assert 24 <= clues <= 26, "66-85: 24-26 clues, got %d" % clues
            else:
                assert 22 <= clues <= 24, "86-100: 22-24 clues, got %d" % clues

    def test_tier_progression(self):
        for p in self._load_puzzles():
            idx = p["level_index"]
            t = p["tier_max"]
            if idx <= 20:
                assert t == 1, "1-20 tier=1, got %d" % t
            elif idx <= 40:
                assert t == 2, "21-40 tier=2, got %d" % t
            elif idx <= 65:
                assert t == 3, "41-65 tier=3, got %d" % t
            elif idx <= 85:
                assert t == 4, "66-85 tier=4, got %d" % t
            else:
                assert t == 5, "86-100 tier=5, got %d" % t

    def test_variant_mini_8x8(self):
        for p in self._load_puzzles():
            assert p["variant"] == "mini_8x8", "%s variant=%s" % (p["level_id"], p.get("variant"))

    def test_stage_is_3(self):
        for p in self._load_puzzles():
            assert p["stage"] == 3

    def test_economy_metadata(self):
        for p in self._load_puzzles():
            e = p.get("economy", {})
            for key in ("coins", "souls", "perfect_bonus", "combo_bonus", "chapter_reward"):
                assert key in e, "%s missing %s" % (p["level_id"], key)

    def test_stars_metadata(self):
        for p in self._load_puzzles():
            s = p.get("stars", {})
            for key in ("clear", "perfect", "fast_clear"):
                assert key in s

    def test_valid_json_format(self):
        required = {
            "puzzle", "solution", "clues", "tier_max", "variant",
            "level_id", "stage", "chapter", "level_index",
            "difficulty", "techniques", "visual_score", "human_score",
            "tutorial", "economy", "stars",
        }
        for p in self._load_puzzles():
            missing = required - set(p.keys())
            assert not missing, "%s missing: %s" % (p["level_id"], missing)
            assert len(p["puzzle"]) == 64, "puzzle len=%d" % len(p["puzzle"])
            assert len(p["solution"]) == 64, "solution len=%d" % len(p["solution"])
            assert p["variant"] == "mini_8x8"
            assert p["stage"] == 3

    def test_tutorial_first_three(self):
        for p in self._load_puzzles():
            if p["level_index"] <= 3:
                assert p["tutorial"] is True
            else:
                assert p["tutorial"] is False

    def test_no_forbidden_techniques(self):
        forbidden = {"XYWing", "Swordfish", "Chains", "ALS", "Uniqueness", "ExoticFish"}
        for p in self._load_puzzles():
            for tech in p.get("techniques", []):
                for f in forbidden:
                    assert f.lower() not in tech.lower(), (
                        "%s has %s" % (p["level_id"], tech)
                    )

    def test_technique_count_by_tier(self):
        for p in self._load_puzzles():
            tier = p["tier_max"]
            expected = set(TIER_DEFS_8[tier])
            actual = set(p.get("techniques", []))
            assert actual == expected, "%s tier=%d mismatch" % (p["level_id"], tier)

    def test_level_ids_sequential(self):
        puzzles = sorted(self._load_puzzles(), key=lambda x: x["level_index"])
        for i, p in enumerate(puzzles, 1):
            assert p["level_index"] == i, "index %d != %d" % (p["level_index"], i)
            assert p["level_id"] == "campaign_8x8_%04d" % i

    def test_visual_score_correct(self):
        for p in self._load_puzzles():
            expected = round(p["clues"] / 64, 3)
            assert p["visual_score"] == expected, "%s visual_score %.3f != %.3f" % (
                p["level_id"], p["visual_score"], expected
            )

    def test_chapter_assignment(self):
        for p in self._load_puzzles():
            idx = p["level_index"]
            ch = p["chapter"]
            if idx <= 20:
                assert ch == "Foundation"
            elif idx <= 40:
                assert ch == "Intersections"
            else:
                assert ch == "Structures" or ch == "Advanced Intro"


# ── Easy Dataset Tests ─────────────────────────────────────────────────────

EASY_DIR = "assets/boards/easy"


class TestEasyGenerator:
    def test_generate_solved_valid(self):
        from tools.master_generator.variants.easy_9x9 import Easy9x9Generator
        gen = Easy9x9Generator(seed=42)
        solved = gen.generate_solved()
        assert len(solved) == 81
        assert all(c in "123456789" for c in solved)

    def test_generate_one_tramo1(self):
        from tools.master_generator.variants.easy_9x9 import (
            Easy9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Easy9x9Generator(seed=42)
        t = TRAMO_CONFIG[0]
        r = gen.generate_one(t["clues"], t["tech_ids"], max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["clues"] == 65
        assert len(r["puzzle"]) == 81
        assert len(r["solution"]) == 81

    def test_generate_one_tramo4(self):
        from tools.master_generator.variants.easy_9x9 import (
            Easy9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Easy9x9Generator(seed=42)
        t = TRAMO_CONFIG[3]
        r = gen.generate_one(t["clues"], t["tech_ids"], max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["clues"] == 60
        assert len(r["puzzle"]) == 81

    def test_tramo_config_consistent(self):
        from tools.master_generator.variants.easy_9x9 import TRAMO_CONFIG
        assert len(TRAMO_CONFIG) == 4
        for t in TRAMO_CONFIG:
            assert t["start"] < t["end"]
            assert 44 <= t["clues"] <= 81
            assert len(t["tech_ids"]) >= 3
            assert len(t["techniques"]) >= 3
            assert 1 <= t["tier_max"] <= 8
            assert t["est_minutes"] > 0

    def test_forbidden_techniques_not_in_allowed(self):
        from tools.master_generator.variants.easy_9x9 import (
            TRAMO_CONFIG, FORBIDDEN_TECH_IDS
        )
        for t in TRAMO_CONFIG:
            overlap = t["tech_ids"] & FORBIDDEN_TECH_IDS
            assert len(overlap) == 0, f"Tramo {t['start']} has forbidden: {overlap}"

    def test_make_board_entry_format(self):
        from tools.master_generator.variants.easy_9x9 import (
            TRAMO_CONFIG, _make_board_entry
        )
        gen_result = {
            "puzzle": "123456789" * 9,
            "solution": "987654321" * 9,
            "clues": 65,
            "fill_percent": 80.2,
            "symmetry": "rotational",
            "steps": 10,
            "technique_history": [],
        }
        entry = _make_board_entry(1, gen_result, TRAMO_CONFIG[0])
        assert entry["id"] == "easy_0001"
        assert entry["difficulty"] == "easy"
        assert entry["clues"] == 65
        assert len(entry["hash"]) == 16
        assert entry["hash"] == entry["checksum"]
        assert entry["human_score"] == 1
        assert entry["tier_max"] == 1


class TestEasyDataset:
    def test_all_files_exist(self):
        assert os.path.isdir(EASY_DIR)
        files = [f for f in os.listdir(EASY_DIR) if f.endswith(".json")]
        assert len(files) == 1000, f"Expected 1000, got {len(files)}"

    def test_file_names(self):
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            assert os.path.exists(path), f"Missing: easy_{i:04d}.json"

    def test_valid_json_format(self):
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert isinstance(data, dict)
            assert "id" in data
            assert "puzzle" in data
            assert "solution" in data
            assert "difficulty" in data

    def test_difficulty_field(self):
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["difficulty"] == "easy", f"{data['id']}: {data['difficulty']}"

    def test_id_matches_filename(self):
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["id"] == f"easy_{i:04d}", f"{data['id']} != easy_{i:04d}"

    def test_puzzle_length(self):
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert len(data["puzzle"]) == 81, f"{data['id']}: puzzle len={len(data['puzzle'])}"
            assert len(data["solution"]) == 81, f"{data['id']}: solution len={len(data['solution'])}"

    def test_clue_ranges(self):
        from tools.master_generator.variants.easy_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(EASY_DIR, f"easy_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert data["clues"] == t["clues"], (
                    f"{data['id']}: expected {t['clues']} clues, got {data['clues']}"
                )

    def test_tramo_techniques_match(self):
        from tools.master_generator.variants.easy_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(EASY_DIR, f"easy_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert set(data["techniques"]) == set(t["techniques"]), (
                    f"{data['id']}: expected {t['techniques']}, got {data['techniques']}"
                )

    def test_tier_matches_tramo(self):
        from tools.master_generator.variants.easy_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(EASY_DIR, f"easy_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert data["tier_max"] == t["tier_max"], (
                    f"{data['id']}: expected tier {t['tier_max']}, got {data['tier_max']}"
                )

    def test_no_duplicate_hashes(self):
        hashes = set()
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            h = data["hash"]
            assert h not in hashes, f"Duplicate hash {h} at easy_{i:04d}"
            hashes.add(h)

    def test_hash_integrity(self):
        import hashlib
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            expected = hashlib.sha256(data["puzzle"].encode()).hexdigest()[:16]
            assert data["hash"] == expected, f"{data['id']}: hash mismatch"

    def test_hash_equals_checksum(self):
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["hash"] == data["checksum"], f"{data['id']}: hash != checksum"

    def test_symmetry_field(self):
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["symmetry"] == "rotational", f"{data['id']}: {data['symmetry']}"

    def test_no_forbidden_techniques(self):
        from tools.master_generator.variants.easy_9x9 import FORBIDDEN_TECH_IDS, TRAMO_CONFIG
        all_allowed = set()
        for t in TRAMO_CONFIG:
            all_allowed |= t["tech_ids"]
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            # Check that only tramo-appropriate techniques are in the techniques list
            # We can't verify from just the techniques list, but we can check
            # that no forbidden ID is referenced
            for tech in data["techniques"]:
                # Convert human name to ID format for checking
                tid = tech.lower().replace(" ", "_")
                assert tid not in FORBIDDEN_TECH_IDS, (
                    f"{data['id']}: forbidden technique {tech} listed"
                )

    def test_economy_metadata_present(self):
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "human_score" in data
            assert "visual_score" in data
            assert "tier_max" in data
            assert "estimated_time_minutes" in data
            assert "level_index" in data

    def test_tramo_1_only_three_techniques(self):
        for i in range(1, 251):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert len(data["techniques"]) == 3, f"{data['id']}: {data['techniques']}"
            assert "NakedSingle" in data["techniques"]
            assert "FullHouse" in data["techniques"]
            assert "LastBlank" in data["techniques"]

    def test_tramo_2_adds_hidden_single(self):
        for i in range(251, 501):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "HiddenSingle" in data["techniques"], f"{data['id']} missing HiddenSingle"
            assert len(data["techniques"]) == 4, f"{data['id']}: {data['techniques']}"

    def test_tramo_3_adds_pointing(self):
        for i in range(501, 751):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "PointingPair" in data["techniques"]
            assert "PointingTriple" in data["techniques"]
            assert len(data["techniques"]) == 6

    def test_tramo_4_adds_box_line(self):
        for i in range(751, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "BoxLineReduction" in data["techniques"]
            assert len(data["techniques"]) == 7


class TestEasyBoardLoopback:
    """Verifies selector → dataset connection (simulated)."""

    def test_board_repository_path_pattern(self):
        """Verify Flutter BoardRepository path pattern works."""
        for i in [1, 250, 251, 500, 501, 750, 751, 1000]:
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            assert os.path.exists(path), f"Path pattern failed: {path}"

    def test_board_has_difficulty_for_validation(self):
        """Flutter _isValidBoard checks rawDifficulty == expectedDifficulty."""
        for i in [1, 500, 1000]:
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["difficulty"] == "easy"
            # Simulate _isValidBoard
            puzzle = data["puzzle"]
            solution = data["solution"]
            assert len(puzzle) == 81
            assert len(solution) == 81
            assert all(c in "0123456789" for c in puzzle)
            assert all(c in "123456789" for c in solution)

    def test_puzzle_values_subset_of_solution(self):
        """Verify puzzle givens are subset of solution."""
        for i in range(1, 1001, 50):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            puzzle = data["puzzle"]
            solution = data["solution"]
            for pi, si in zip(puzzle, solution):
                if pi != "0":
                    assert pi == si, f"{data['id']}: given {pi} != solution {si}"

    def test_no_conflicts(self):
        """Verify no row/col/block conflicts."""
        for i in range(1, 1001, 50):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            puzzle = data["puzzle"]
            solution = data["solution"]
            for board_str, name in [(puzzle, "puzzle"), (solution, "solution")]:
                board = [int(c) if c != "0" else 0 for c in board_str]
                for r in range(9):
                    vals = [board[r * 9 + c] for c in range(9) if board[r * 9 + c] != 0]
                    assert len(vals) == len(set(vals)), f"{data['id']} {name} row {r} conflict"
                for c in range(9):
                    vals = [board[r * 9 + c] for r in range(9) if board[r * 9 + c] != 0]
                    assert len(vals) == len(set(vals)), f"{data['id']} {name} col {c} conflict"
                for br in range(0, 9, 3):
                    for bc in range(0, 9, 3):
                        vals = []
                        for r in range(3):
                            for c in range(3):
                                v = board[(br + r) * 9 + (bc + c)]
                                if v != 0:
                                    vals.append(v)
                        assert len(vals) == len(set(vals)), f"{data['id']} {name} block {br},{bc} conflict"


class TestEasySelectorConnection:
    """Tests for the selector → dataset → board routing fix."""

    def test_easy_count_1000_in_dart_code(self):
        """Verification point: BoardRepository._boardCount['easy'] must be 1000."""
        # This is verified by checking the Dart file
        dart_path = "flutter_app/lib/features/game/data/board_repository.dart"
        with open(dart_path) as f:
            content = f.read()
        assert "'easy': 1000" in content, "BoardRepository easy count not updated to 1000"

    def test_easy_total_count_1000_in_difficulty_provider(self):
        """Verification point: difficulty_provider._boardTotalCount['easy'] must be 1000."""
        dart_path = "flutter_app/lib/features/difficulty/application/difficulty_provider.dart"
        with open(dart_path) as f:
            content = f.read()
        assert "'easy': 1000" in content, "Difficulty provider easy count not updated to 1000"

    def test_easy_dir_declared_in_pubspec(self):
        """Verify pubspec.yaml includes assets/boards/easy/."""
        pubspec_path = "flutter_app/pubspec.yaml"
        with open(pubspec_path) as f:
            content = f.read()
        assert "assets/boards/easy/" in content, "easy board dir not in pubspec"

    def test_all_have_difficulty_for_selector(self):
        """Every board has the 'difficulty' field needed for selector validation."""
        for i in range(1, 1001):
            path = os.path.join(EASY_DIR, f"easy_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "difficulty" in data, f"easy_{i:04d} missing difficulty field"


# ── Intermediate Dataset Tests ─────────────────────────────────────────────

INT_DIR = "assets/boards/intermediate"


class TestIntermediateGenerator:
    def test_generate_solved_valid(self):
        from tools.master_generator.variants.intermediate_9x9 import Intermediate9x9Generator
        gen = Intermediate9x9Generator(seed=42)
        solved = gen.generate_solved()
        assert len(solved) == 81
        assert all(c in "123456789" for c in solved)

    def test_generate_one_tramo1(self):
        from tools.master_generator.variants.intermediate_9x9 import (
            Intermediate9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Intermediate9x9Generator(seed=42)
        t = TRAMO_CONFIG[0]
        r = gen.generate_one(t["clues"], t["tech_ids"], max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["clues"] == 58
        assert len(r["puzzle"]) == 81

    def test_generate_one_tramo4(self):
        from tools.master_generator.variants.intermediate_9x9 import (
            Intermediate9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Intermediate9x9Generator(seed=42)
        t = TRAMO_CONFIG[3]
        r = gen.generate_one(t["clues"], t["tech_ids"], max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["clues"] == 54

    def test_generate_mirror_symmetry(self):
        from tools.master_generator.variants.intermediate_9x9 import (
            Intermediate9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Intermediate9x9Generator(seed=42)
        t = TRAMO_CONFIG[0]
        r = gen.generate_one(t["clues"], t["tech_ids"], sym_type="mirror", max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["symmetry"] == "mirror"

    def test_tramo_config_consistent(self):
        from tools.master_generator.variants.intermediate_9x9 import TRAMO_CONFIG
        assert len(TRAMO_CONFIG) == 4
        for t in TRAMO_CONFIG:
            assert t["start"] < t["end"]
            assert 44 <= t["clues"] <= 81
            assert len(t["tech_ids"]) >= 4
            assert 1 <= t["tier_max"] <= 8
            assert t["est_minutes"] > 0

    def test_forbidden_techniques_not_in_allowed(self):
        from tools.master_generator.variants.intermediate_9x9 import (
            TRAMO_CONFIG, FORBIDDEN_TECH_IDS
        )
        for t in TRAMO_CONFIG:
            overlap = t["tech_ids"] & FORBIDDEN_TECH_IDS
            assert len(overlap) == 0, f"Tramo {t['start']} has forbidden: {overlap}"

    def test_make_board_entry_format(self):
        from tools.master_generator.variants.intermediate_9x9 import (
            TRAMO_CONFIG, _make_board_entry
        )
        gen_result = {
            "puzzle": "123456789" * 9,
            "solution": "987654321" * 9,
            "clues": 58,
            "fill_percent": 71.6,
            "symmetry": "rotational",
            "steps": 15,
            "technique_history": [],
        }
        entry = _make_board_entry(1, gen_result, TRAMO_CONFIG[0])
        assert entry["id"] == "intermediate_0001"
        assert entry["difficulty"] == "intermediate"
        assert entry["clues"] == 58
        assert len(entry["hash"]) == 16
        assert entry["hash"] == entry["checksum"]
        assert entry["human_score"] == 1
        assert entry["tier_max"] == 1


class TestIntermediateDataset:
    def test_all_files_exist(self):
        assert os.path.isdir(INT_DIR)
        files = [f for f in os.listdir(INT_DIR) if f.endswith(".json")]
        assert len(files) == 1000, f"Expected 1000, got {len(files)}"

    def test_file_names(self):
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            assert os.path.exists(path), f"Missing: intermediate_{i:04d}.json"

    def test_valid_json_format(self):
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert isinstance(data, dict)
            assert "id" in data
            assert "puzzle" in data
            assert "solution" in data
            assert "difficulty" in data

    def test_difficulty_field(self):
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["difficulty"] == "intermediate", (
                f"{data['id']}: {data['difficulty']}"
            )

    def test_id_matches_filename(self):
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["id"] == f"intermediate_{i:04d}", (
                f"{data['id']} != intermediate_{i:04d}"
            )

    def test_puzzle_length(self):
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert len(data["puzzle"]) == 81, f"{data['id']}: puzzle len={len(data['puzzle'])}"
            assert len(data["solution"]) == 81, f"{data['id']}: solution len={len(data['solution'])}"

    def test_clue_ranges(self):
        from tools.master_generator.variants.intermediate_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(INT_DIR, f"intermediate_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert data["clues"] == t["clues"], (
                    f"{data['id']}: expected {t['clues']} clues, got {data['clues']}"
                )

    def test_tramo_techniques_match(self):
        from tools.master_generator.variants.intermediate_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(INT_DIR, f"intermediate_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert set(data["techniques"]) == set(t["techniques"]), (
                    f"{data['id']}: expected {t['techniques']}, got {data['techniques']}"
                )

    def test_tier_matches_tramo(self):
        from tools.master_generator.variants.intermediate_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(INT_DIR, f"intermediate_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert data["tier_max"] == t["tier_max"], (
                    f"{data['id']}: expected tier {t['tier_max']}, got {data['tier_max']}"
                )

    def test_no_duplicate_hashes(self):
        hashes = set()
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            h = data["hash"]
            assert h not in hashes, f"Duplicate hash {h} at intermediate_{i:04d}"
            hashes.add(h)

    def test_hash_integrity(self):
        import hashlib
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            expected = hashlib.sha256(data["puzzle"].encode()).hexdigest()[:16]
            assert data["hash"] == expected, f"{data['id']}: hash mismatch"

    def test_hash_equals_checksum(self):
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["hash"] == data["checksum"], f"{data['id']}: hash != checksum"

    def test_symmetry_split(self):
        rotational = 0
        mirror = 0
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            sym = data["symmetry"]
            assert sym in ("rotational", "mirror"), f"{data['id']}: sym={sym}"
            if sym == "rotational":
                rotational += 1
            else:
                mirror += 1
        assert rotational == 700, f"Expected 700 rotational, got {rotational}"
        assert mirror == 300, f"Expected 300 mirror, got {mirror}"

    def test_no_forbidden_techniques(self):
        from tools.master_generator.variants.intermediate_9x9 import FORBIDDEN_TECH_IDS
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            for tech in data["techniques"]:
                tid = tech.lower().replace(" ", "_")
                assert tid not in FORBIDDEN_TECH_IDS, (
                    f"{data['id']}: forbidden technique {tech} listed"
                )

    def test_economy_metadata_present(self):
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "human_score" in data
            assert "visual_score" in data
            assert "tier_max" in data
            assert "estimated_time_minutes" in data
            assert "level_index" in data

    def test_tramo_1_techniques(self):
        for i in range(1, 251):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert len(data["techniques"]) == 4
            for t in ("LastBlank", "FullHouse", "NakedSingle", "HiddenSingle"):
                assert t in data["techniques"], f"{data['id']} missing {t}"

    def test_tramo_2_adds_pointing(self):
        for i in range(251, 501):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "PointingPair" in data["techniques"]
            assert "PointingTriple" in data["techniques"]
            assert len(data["techniques"]) == 6

    def test_tramo_3_adds_boxline_naked_pair(self):
        for i in range(501, 751):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "BoxLineReduction" in data["techniques"]
            assert "NakedPair" in data["techniques"]
            assert len(data["techniques"]) == 8

    def test_tramo_4_adds_hidden_pair_naked_triple(self):
        for i in range(751, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "HiddenPair" in data["techniques"]
            assert "NakedTriple" in data["techniques"]
            assert len(data["techniques"]) == 10


class TestIntermediateBoardLoopback:
    def test_board_repository_path_pattern(self):
        for i in [1, 250, 251, 500, 501, 750, 751, 1000]:
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            assert os.path.exists(path), f"Path pattern failed: {path}"

    def test_board_has_difficulty_for_validation(self):
        for i in [1, 500, 1000]:
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["difficulty"] == "intermediate"
            puzzle = data["puzzle"]
            solution = data["solution"]
            assert len(puzzle) == 81
            assert len(solution) == 81
            assert all(c in "0123456789" for c in puzzle)
            assert all(c in "123456789" for c in solution)

    def test_puzzle_values_subset_of_solution(self):
        for i in range(1, 1001, 50):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            puzzle = data["puzzle"]
            solution = data["solution"]
            for pi, si in zip(puzzle, solution):
                if pi != "0":
                    assert pi == si, f"{data['id']}: given {pi} != solution {si}"

    def test_no_conflicts(self):
        for i in range(1, 1001, 50):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            puzzle = data["puzzle"]
            solution = data["solution"]
            for board_str, name in [(puzzle, "puzzle"), (solution, "solution")]:
                board = [int(c) if c != "0" else 0 for c in board_str]
                for r in range(9):
                    vals = [board[r * 9 + c] for c in range(9) if board[r * 9 + c] != 0]
                    assert len(vals) == len(set(vals)), f"{data['id']} {name} row {r} conflict"
                for c in range(9):
                    vals = [board[r * 9 + c] for r in range(9) if board[r * 9 + c] != 0]
                    assert len(vals) == len(set(vals)), f"{data['id']} {name} col {c} conflict"
                for br in range(0, 9, 3):
                    for bc in range(0, 9, 3):
                        vals = []
                        for r in range(3):
                            for c in range(3):
                                v = board[(br + r) * 9 + (bc + c)]
                                if v != 0:
                                    vals.append(v)
                        assert len(vals) == len(set(vals)), f"{data['id']} {name} block {br},{bc} conflict"


class TestIntermediateSelectorConnection:
    def test_intermediate_count_1000_in_dart_code(self):
        dart_path = "flutter_app/lib/features/game/data/board_repository.dart"
        with open(dart_path) as f:
            content = f.read()
        assert "'intermediate': 1000" in content, (
            "BoardRepository intermediate count not updated to 1000"
        )

    def test_intermediate_total_count_1000_in_difficulty_provider(self):
        dart_path = "flutter_app/lib/features/difficulty/application/difficulty_provider.dart"
        with open(dart_path) as f:
            content = f.read()
        assert "'intermediate': 1000" in content, (
            "Difficulty provider intermediate count not updated to 1000"
        )

    def test_intermediate_dir_declared_in_pubspec(self):
        pubspec_path = "flutter_app/pubspec.yaml"
        with open(pubspec_path) as f:
            content = f.read()
        assert "assets/boards/intermediate/" in content, (
            "intermediate board dir not in pubspec"
        )

    def test_all_have_difficulty_for_selector(self):
        for i in range(1, 1001):
            path = os.path.join(INT_DIR, f"intermediate_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "difficulty" in data, f"intermediate_{i:04d} missing difficulty field"


# ── Hard Dataset Tests ─────────────────────────────────────────────────────

HARD_DIR = "assets/boards/hard"


class TestHardGenerator:
    def test_generate_solved_valid(self):
        from tools.master_generator.variants.hard_9x9 import Hard9x9Generator
        gen = Hard9x9Generator(seed=42)
        solved = gen.generate_solved()
        assert len(solved) == 81
        assert all(c in "123456789" for c in solved)

    def test_generate_one_tramo1(self):
        from tools.master_generator.variants.hard_9x9 import (
            Hard9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Hard9x9Generator(seed=42)
        t = TRAMO_CONFIG[0]
        r = gen.generate_one(t["clues"], t["tech_ids"], max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["clues"] == 52
        assert len(r["puzzle"]) == 81

    def test_generate_one_tramo5(self):
        from tools.master_generator.variants.hard_9x9 import (
            Hard9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Hard9x9Generator(seed=42)
        t = TRAMO_CONFIG[4]
        r = gen.generate_one(t["clues"], t["tech_ids"], max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["clues"] == 46
        assert r["symmetry"] in ("rotational", "mirror", "random")

    def test_generate_random_symmetry(self):
        from tools.master_generator.variants.hard_9x9 import (
            Hard9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Hard9x9Generator(seed=42)
        t = TRAMO_CONFIG[0]
        r = gen.generate_one(t["clues"], t["tech_ids"], sym_type="random", max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["symmetry"] == "random"

    def test_tramo_config_consistent(self):
        from tools.master_generator.variants.hard_9x9 import TRAMO_CONFIG
        assert len(TRAMO_CONFIG) == 5
        for t in TRAMO_CONFIG:
            assert t["start"] < t["end"]
            assert 44 <= t["clues"] <= 81
            assert len(t["tech_ids"]) >= 7
            assert 1 <= t["tier_max"] <= 8
            assert t["est_minutes"] > 0

    def test_forbidden_techniques_not_in_allowed(self):
        from tools.master_generator.variants.hard_9x9 import (
            TRAMO_CONFIG, FORBIDDEN_TECH_IDS
        )
        for t in TRAMO_CONFIG:
            overlap = t["tech_ids"] & FORBIDDEN_TECH_IDS
            assert len(overlap) == 0, f"Tramo {t['start']} has forbidden: {overlap}"

    def test_make_board_entry_format(self):
        from tools.master_generator.variants.hard_9x9 import (
            TRAMO_CONFIG, _make_board_entry
        )
        gen_result = {
            "puzzle": "123456789" * 9,
            "solution": "987654321" * 9,
            "clues": 52,
            "fill_percent": 64.2,
            "symmetry": "rotational",
            "steps": 20,
            "technique_history": [],
        }
        entry = _make_board_entry(1, gen_result, TRAMO_CONFIG[0])
        assert entry["id"] == "hard_0001"
        assert entry["difficulty"] == "hard"
        assert entry["clues"] == 52
        assert len(entry["hash"]) == 16
        assert entry["hash"] == entry["checksum"]
        assert entry["human_score"] == 2
        assert entry["tier_max"] == 2


class TestHardDataset:
    def test_all_files_exist(self):
        assert os.path.isdir(HARD_DIR)
        files = [f for f in os.listdir(HARD_DIR) if f.endswith(".json")]
        assert len(files) == 1000, f"Expected 1000, got {len(files)}"

    def test_file_names(self):
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            assert os.path.exists(path), f"Missing: hard_{i:04d}.json"

    def test_valid_json_format(self):
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert isinstance(data, dict)
            assert "id" in data
            assert "puzzle" in data
            assert "solution" in data
            assert "difficulty" in data

    def test_difficulty_field(self):
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["difficulty"] == "hard", (
                f"{data['id']}: {data['difficulty']}"
            )

    def test_id_matches_filename(self):
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["id"] == f"hard_{i:04d}", (
                f"{data['id']} != hard_{i:04d}"
            )

    def test_puzzle_length(self):
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert len(data["puzzle"]) == 81, f"{data['id']}: puzzle len={len(data['puzzle'])}"
            assert len(data["solution"]) == 81, f"{data['id']}: solution len={len(data['solution'])}"

    def test_clue_ranges(self):
        from tools.master_generator.variants.hard_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(HARD_DIR, f"hard_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert data["clues"] == t["clues"], (
                    f"{data['id']}: expected {t['clues']} clues, got {data['clues']}"
                )

    def test_tramo_techniques_match(self):
        from tools.master_generator.variants.hard_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(HARD_DIR, f"hard_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert set(data["techniques"]) == set(t["techniques"]), (
                    f"{data['id']}: expected {t['techniques']}, got {data['techniques']}"
                )

    def test_tier_matches_tramo(self):
        from tools.master_generator.variants.hard_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(HARD_DIR, f"hard_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert data["tier_max"] == t["tier_max"], (
                    f"{data['id']}: expected tier {t['tier_max']}, got {data['tier_max']}"
                )

    def test_no_duplicate_hashes(self):
        hashes = set()
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            h = data["hash"]
            assert h not in hashes, f"Duplicate hash {h} at hard_{i:04d}"
            hashes.add(h)

    def test_hash_integrity(self):
        import hashlib
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            expected = hashlib.sha256(data["puzzle"].encode()).hexdigest()[:16]
            assert data["hash"] == expected, f"{data['id']}: hash mismatch"

    def test_hash_equals_checksum(self):
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["hash"] == data["checksum"], f"{data['id']}: hash != checksum"

    def test_symmetry_split(self):
        rotational = 0
        mirror = 0
        random_sym = 0
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            sym = data["symmetry"]
            assert sym in ("rotational", "mirror", "random"), f"{data['id']}: sym={sym}"
            if sym == "rotational":
                rotational += 1
            elif sym == "mirror":
                mirror += 1
            else:
                random_sym += 1
        assert rotational == 500, f"Expected 500 rotational, got {rotational}"
        assert mirror == 300, f"Expected 300 mirror, got {mirror}"
        assert random_sym == 200, f"Expected 200 random, got {random_sym}"

    def test_no_forbidden_techniques(self):
        from tools.master_generator.variants.hard_9x9 import FORBIDDEN_TECH_IDS
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            for tech in data["techniques"]:
                tid = tech.lower().replace(" ", "_")
                assert tid not in FORBIDDEN_TECH_IDS, (
                    f"{data['id']}: forbidden technique {tech} listed"
                )

    def test_economy_metadata_present(self):
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "human_score" in data
            assert "visual_score" in data
            assert "tier_max" in data
            assert "estimated_time_minutes" in data
            assert "level_index" in data

    def test_tramo_1_techniques(self):
        for i in range(1, 201):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert len(data["techniques"]) == 7
            for t in ("LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
                      "PointingPair", "PointingTriple", "BoxLineReduction"):
                assert t in data["techniques"], f"{data['id']} missing {t}"

    def test_tramo_2_adds_pairs(self):
        for i in range(201, 401):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "NakedPair" in data["techniques"]
            assert "HiddenPair" in data["techniques"]
            assert len(data["techniques"]) == 9

    def test_tramo_3_adds_triples(self):
        for i in range(401, 651):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "NakedTriple" in data["techniques"]
            assert "HiddenTriple" in data["techniques"]
            assert len(data["techniques"]) == 11

    def test_tramo_4_adds_quads(self):
        for i in range(651, 851):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "NakedQuad" in data["techniques"]
            assert "HiddenQuad" in data["techniques"]
            assert len(data["techniques"]) == 13

    def test_tramo_5_adds_xwing(self):
        for i in range(851, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "XWing" in data["techniques"]
            assert len(data["techniques"]) == 14


class TestHardBoardLoopback:
    def test_board_repository_path_pattern(self):
        for i in [1, 200, 201, 400, 401, 650, 651, 850, 851, 1000]:
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            assert os.path.exists(path), f"Path pattern failed: {path}"

    def test_board_has_difficulty_for_validation(self):
        for i in [1, 500, 1000]:
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["difficulty"] == "hard"
            puzzle = data["puzzle"]
            solution = data["solution"]
            assert len(puzzle) == 81
            assert len(solution) == 81
            assert all(c in "0123456789" for c in puzzle)
            assert all(c in "123456789" for c in solution)

    def test_puzzle_values_subset_of_solution(self):
        for i in range(1, 1001, 50):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            puzzle = data["puzzle"]
            solution = data["solution"]
            for pi, si in zip(puzzle, solution):
                if pi != "0":
                    assert pi == si, f"{data['id']}: given {pi} != solution {si}"

    def test_no_conflicts(self):
        for i in range(1, 1001, 50):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            puzzle = data["puzzle"]
            solution = data["solution"]
            for board_str, name in [(puzzle, "puzzle"), (solution, "solution")]:
                board = [int(c) if c != "0" else 0 for c in board_str]
                for r in range(9):
                    vals = [board[r * 9 + c] for c in range(9) if board[r * 9 + c] != 0]
                    assert len(vals) == len(set(vals)), f"{data['id']} {name} row {r} conflict"
                for c in range(9):
                    vals = [board[r * 9 + c] for r in range(9) if board[r * 9 + c] != 0]
                    assert len(vals) == len(set(vals)), f"{data['id']} {name} col {c} conflict"
                for br in range(0, 9, 3):
                    for bc in range(0, 9, 3):
                        vals = []
                        for r in range(3):
                            for c in range(3):
                                v = board[(br + r) * 9 + (bc + c)]
                                if v != 0:
                                    vals.append(v)
                        assert len(vals) == len(set(vals)), f"{data['id']} {name} block {br},{bc} conflict"


class TestHardSelectorConnection:
    def test_hard_count_1000_in_dart_code(self):
        dart_path = "flutter_app/lib/features/game/data/board_repository.dart"
        with open(dart_path) as f:
            content = f.read()
        assert "'hard': 1000" in content, (
            "BoardRepository hard count not updated to 1000"
        )

    def test_hard_total_count_1000_in_difficulty_provider(self):
        dart_path = "flutter_app/lib/features/difficulty/application/difficulty_provider.dart"
        with open(dart_path) as f:
            content = f.read()
        assert "'hard': 1000" in content, (
            "Difficulty provider hard count not updated to 1000"
        )

    def test_hard_dir_declared_in_pubspec(self):
        pubspec_path = "flutter_app/pubspec.yaml"
        with open(pubspec_path) as f:
            content = f.read()
        assert "assets/boards/hard/" in content, (
            "hard board dir not in pubspec"
        )

    def test_all_have_difficulty_for_selector(self):
        for i in range(1, 1001):
            path = os.path.join(HARD_DIR, f"hard_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "difficulty" in data, f"hard_{i:04d} missing difficulty field"


# ── Expert Dataset Tests ────────────────────────────────────────────────────

EXPERT_DIR = "assets/boards/expert"


class TestExpertGenerator:
    def test_generate_solved_valid(self):
        from tools.master_generator.variants.expert_9x9 import Expert9x9Generator
        gen = Expert9x9Generator(seed=42)
        solved = gen.generate_solved()
        assert len(solved) == 81
        assert all(c in "123456789" for c in solved)

    def test_generate_one_tramo1(self):
        from tools.master_generator.variants.expert_9x9 import (
            Expert9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Expert9x9Generator(seed=42)
        t = TRAMO_CONFIG[0]
        r = gen.generate_one(t["clues"], t["tech_ids"], max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["clues"] == 44
        assert len(r["puzzle"]) == 81

    def test_generate_one_tramo5_38(self):
        from tools.master_generator.variants.expert_9x9 import (
            Expert9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Expert9x9Generator(seed=42)
        t = TRAMO_CONFIG[4]
        r = gen.generate_one(38, t["tech_ids"], max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["clues"] == 38
        assert r["symmetry"] in ("rotational", "mirror", "random")

    def test_generate_mirror_symmetry(self):
        from tools.master_generator.variants.expert_9x9 import (
            Expert9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Expert9x9Generator(seed=42)
        t = TRAMO_CONFIG[0]
        r = gen.generate_one(t["clues"], t["tech_ids"], sym_type="mirror", max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["symmetry"] == "mirror"

    def test_generate_random_symmetry(self):
        from tools.master_generator.variants.expert_9x9 import (
            Expert9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Expert9x9Generator(seed=42)
        t = TRAMO_CONFIG[0]
        r = gen.generate_one(t["clues"], t["tech_ids"], sym_type="random", max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["symmetry"] == "random"

    def test_tramo_config_consistent(self):
        from tools.master_generator.variants.expert_9x9 import TRAMO_CONFIG
        assert len(TRAMO_CONFIG) == 5
        for t in TRAMO_CONFIG:
            assert t["start"] < t["end"]
            assert 38 <= t["clues"] <= 81 or t["clues"] == 0
            assert len(t["tech_ids"]) >= 14
            assert 4 <= t["tier_max"] <= 8
            assert t["est_minutes"] > 0

    def test_forbidden_techniques_not_in_allowed(self):
        from tools.master_generator.variants.expert_9x9 import (
            TRAMO_CONFIG, FORBIDDEN_TECH_IDS
        )
        for t in TRAMO_CONFIG:
            overlap = t["tech_ids"] & FORBIDDEN_TECH_IDS
            assert len(overlap) == 0, f"Tramo {t['start']} has forbidden: {overlap}"

    def test_make_board_entry_format(self):
        from tools.master_generator.variants.expert_9x9 import (
            TRAMO_CONFIG, _make_board_entry
        )
        gen_result = {
            "puzzle": "123456789" * 9,
            "solution": "987654321" * 9,
            "clues": 44,
            "fill_percent": 54.3,
            "symmetry": "rotational",
            "steps": 30,
            "technique_history": [],
        }
        entry = _make_board_entry(1, gen_result, TRAMO_CONFIG[0])
        assert entry["id"] == "expert_0001"
        assert entry["difficulty"] == "expert"
        assert entry["clues"] == 44
        assert len(entry["hash"]) == 16
        assert entry["hash"] == entry["checksum"]
        assert entry["human_score"] == 4
        assert entry["tier_max"] == 4


class TestExpertDataset:
    def test_all_files_exist(self):
        assert os.path.isdir(EXPERT_DIR)
        files = [f for f in os.listdir(EXPERT_DIR) if f.endswith(".json")]
        assert len(files) == 1000, f"Expected 1000, got {len(files)}"

    def test_file_names(self):
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            assert os.path.exists(path), f"Missing: expert_{i:04d}.json"

    def test_valid_json_format(self):
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert isinstance(data, dict)
            assert "id" in data
            assert "puzzle" in data
            assert "solution" in data
            assert "difficulty" in data

    def test_difficulty_field(self):
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["difficulty"] == "expert", (
                f"{data['id']}: {data['difficulty']}"
            )

    def test_id_matches_filename(self):
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["id"] == f"expert_{i:04d}", (
                f"{data['id']} != expert_{i:04d}"
            )

    def test_puzzle_length(self):
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert len(data["puzzle"]) == 81, f"{data['id']}: puzzle len={len(data['puzzle'])}"
            assert len(data["solution"]) == 81, f"{data['id']}: solution len={len(data['solution'])}"

    def test_clue_ranges(self):
        from tools.master_generator.variants.expert_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(EXPERT_DIR, f"expert_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                if t["start"] != 801:
                    assert data["clues"] == t["clues"], (
                        f"{data['id']}: expected {t['clues']} clues, got {data['clues']}"
                    )
                else:
                    assert data["clues"] in (38, 39), (
                        f"{data['id']}: expected 38-39 clues, got {data['clues']}"
                    )

    def test_tramo_techniques_match(self):
        from tools.master_generator.variants.expert_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(EXPERT_DIR, f"expert_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert set(data["techniques"]) == set(t["techniques"]), (
                    f"{data['id']}: expected {t['techniques']}, got {data['techniques']}"
                )

    def test_tier_matches_tramo(self):
        from tools.master_generator.variants.expert_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(EXPERT_DIR, f"expert_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert data["tier_max"] == t["tier_max"], (
                    f"{data['id']}: expected tier {t['tier_max']}, got {data['tier_max']}"
                )

    def test_no_duplicate_hashes(self):
        hashes = set()
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            h = data["hash"]
            assert h not in hashes, f"Duplicate hash {h} at expert_{i:04d}"
            hashes.add(h)

    def test_hash_integrity(self):
        import hashlib
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            expected = hashlib.sha256(data["puzzle"].encode()).hexdigest()[:16]
            assert data["hash"] == expected, f"{data['id']}: hash mismatch"
            assert data["hash"] == data["checksum"], f"{data['id']}: hash != checksum"

    def test_symmetry_split(self):
        rotational = 0
        mirror = 0
        random_sym = 0
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            sym = data["symmetry"]
            assert sym in ("rotational", "mirror", "random"), f"{data['id']}: sym={sym}"
            if sym == "rotational":
                rotational += 1
            elif sym == "mirror":
                mirror += 1
            else:
                random_sym += 1
        assert rotational == 400, f"Expected 400 rotational, got {rotational}"
        assert mirror == 300, f"Expected 300 mirror, got {mirror}"
        assert random_sym == 300, f"Expected 300 random, got {random_sym}"

    def test_no_forbidden_techniques(self):
        from tools.master_generator.variants.expert_9x9 import FORBIDDEN_TECH_IDS
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            for tech in data["techniques"]:
                tid = tech.lower().replace(" ", "_")
                assert tid not in FORBIDDEN_TECH_IDS, (
                    f"{data['id']}: forbidden technique {tech} listed"
                )

    def test_economy_metadata_present(self):
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "human_score" in data
            assert "visual_score" in data
            assert "tier_max" in data
            assert "estimated_time_minutes" in data
            assert "level_index" in data

    def test_tramo_1_techniques(self):
        for i in range(1, 201):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert len(data["techniques"]) == 14
            for t in ("LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
                      "PointingPair", "PointingTriple", "BoxLineReduction",
                      "NakedPair", "HiddenPair", "NakedTriple", "HiddenTriple",
                      "NakedQuad", "HiddenQuad", "XWing"):
                assert t in data["techniques"], f"{data['id']} missing {t}"

    def test_tramo_2_adds_xywing(self):
        for i in range(201, 401):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "XYWing" in data["techniques"]
            assert len(data["techniques"]) == 15

    def test_tramo_3_adds_xyzwing_wwing(self):
        for i in range(401, 601):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "XYZWing" in data["techniques"]
            assert "WWing" in data["techniques"]
            assert len(data["techniques"]) == 17

    def test_tramo_4_adds_swordfish(self):
        for i in range(601, 801):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "Swordfish" in data["techniques"]
            assert len(data["techniques"]) == 18

    def test_tramo_5_adds_jellyfish_wxyzwing(self):
        for i in range(801, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "Jellyfish" in data["techniques"]
            assert "WXYZWing" in data["techniques"]
            assert len(data["techniques"]) == 20

    def test_visual_score_correct(self):
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            expected = round(data["clues"] / 81, 3)
            assert data["visual_score"] == expected, (
                f"{data['id']}: visual_score {data['visual_score']} != {expected}"
            )

    def test_tramo_5_clue_901_1000_is_38(self):
        for i in range(901, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["clues"] == 38, f"{data['id']}: expected 38 clues, got {data['clues']}"


class TestExpertBoardLoopback:
    def test_board_repository_path_pattern(self):
        for i in [1, 200, 201, 400, 401, 600, 601, 800, 801, 1000]:
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            assert os.path.exists(path), f"Path pattern failed: {path}"

    def test_board_has_difficulty_for_validation(self):
        for i in [1, 500, 1000]:
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["difficulty"] == "expert"
            puzzle = data["puzzle"]
            solution = data["solution"]
            assert len(puzzle) == 81
            assert len(solution) == 81
            assert all(c in "0123456789" for c in puzzle)
            assert all(c in "123456789" for c in solution)

    def test_puzzle_values_subset_of_solution(self):
        for i in range(1, 1001, 50):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            puzzle = data["puzzle"]
            solution = data["solution"]
            for pi, si in zip(puzzle, solution):
                if pi != "0":
                    assert pi == si, f"{data['id']}: given {pi} != solution {si}"

    def test_no_conflicts(self):
        for i in range(1, 1001, 50):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            puzzle = data["puzzle"]
            solution = data["solution"]
            for board_str, name in [(puzzle, "puzzle"), (solution, "solution")]:
                board = [int(c) if c != "0" else 0 for c in board_str]
                for r in range(9):
                    vals = [board[r * 9 + c] for c in range(9) if board[r * 9 + c] != 0]
                    assert len(vals) == len(set(vals)), f"{data['id']} {name} row {r} conflict"
                for c in range(9):
                    vals = [board[r * 9 + c] for r in range(9) if board[r * 9 + c] != 0]
                    assert len(vals) == len(set(vals)), f"{data['id']} {name} col {c} conflict"
                for br in range(0, 9, 3):
                    for bc in range(0, 9, 3):
                        vals = []
                        for r in range(3):
                            for c in range(3):
                                v = board[(br + r) * 9 + (bc + c)]
                                if v != 0:
                                    vals.append(v)
                        assert len(vals) == len(set(vals)), f"{data['id']} {name} block {br},{bc} conflict"


class TestExpertSelectorConnection:
    def test_expert_count_1000_in_dart_code(self):
        dart_path = "flutter_app/lib/features/game/data/board_repository.dart"
        with open(dart_path) as f:
            content = f.read()
        assert "'expert': 1000" in content, (
            "BoardRepository expert count not updated to 1000"
        )

    def test_expert_total_count_1000_in_difficulty_provider(self):
        dart_path = "flutter_app/lib/features/difficulty/application/difficulty_provider.dart"
        with open(dart_path) as f:
            content = f.read()
        assert "'expert': 1000" in content, (
            "Difficulty provider expert count not updated to 1000"
        )

    def test_expert_dir_declared_in_pubspec(self):
        pubspec_path = "flutter_app/pubspec.yaml"
        with open(pubspec_path) as f:
            content = f.read()
        assert "assets/boards/expert/" in content, (
            "expert board dir not in pubspec"
        )

    def test_all_have_difficulty_for_selector(self):
        for i in range(1, 1001):
            path = os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "difficulty" in data, f"expert_{i:04d} missing difficulty field"


# ── Evil Dataset Tests ───────────────────────────────────────────────────────

EVIL_DIR = "assets/boards/evil"


class TestEvilGenerator:
    def test_generate_solved_valid(self):
        from tools.master_generator.variants.evil_9x9 import Evil9x9Generator
        gen = Evil9x9Generator(seed=42)
        solved = gen.generate_solved()
        assert len(solved) == 81
        assert all(c in "123456789" for c in solved)

    def test_generate_one_tramo1(self):
        from tools.master_generator.variants.evil_9x9 import (
            Evil9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Evil9x9Generator(seed=42)
        t = TRAMO_CONFIG[0]
        r = gen.generate_one(t["clues"], t["tech_ids"], max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["clues"] == 36
        assert len(r["puzzle"]) == 81

    def test_generate_one_tramo5_30(self):
        from tools.master_generator.variants.evil_9x9 import (
            Evil9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Evil9x9Generator(seed=42)
        t = TRAMO_CONFIG[4]
        r = gen.generate_one(30, t["tech_ids"], max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["clues"] == 30
        assert r["symmetry"] in ("rotational", "mirror", "random")

    def test_generate_mirror_symmetry(self):
        from tools.master_generator.variants.evil_9x9 import (
            Evil9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Evil9x9Generator(seed=42)
        t = TRAMO_CONFIG[0]
        r = gen.generate_one(t["clues"], t["tech_ids"], sym_type="mirror", max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["symmetry"] == "mirror"

    def test_generate_random_symmetry(self):
        from tools.master_generator.variants.evil_9x9 import (
            Evil9x9Generator, TRAMO_CONFIG, _restore_all
        )
        gen = Evil9x9Generator(seed=42)
        t = TRAMO_CONFIG[0]
        r = gen.generate_one(t["clues"], t["tech_ids"], sym_type="random", max_attempts=10)
        _restore_all()
        assert r is not None
        assert r["symmetry"] == "random"

    def test_tramo_config_consistent(self):
        from tools.master_generator.variants.evil_9x9 import TRAMO_CONFIG
        assert len(TRAMO_CONFIG) == 5
        for t in TRAMO_CONFIG:
            assert t["start"] < t["end"]
            assert len(t["tech_ids"]) >= 18
            assert 5 <= t["tier_max"] <= 8
            assert t["est_minutes"] > 0

    def test_forbidden_techniques_not_in_allowed(self):
        from tools.master_generator.variants.evil_9x9 import (
            TRAMO_CONFIG, FORBIDDEN_TECH_IDS
        )
        for t in TRAMO_CONFIG:
            overlap = t["tech_ids"] & FORBIDDEN_TECH_IDS
            assert len(overlap) == 0, f"Tramo {t['start']} has forbidden: {overlap}"

    def test_make_board_entry_format(self):
        from tools.master_generator.variants.evil_9x9 import (
            TRAMO_CONFIG, _make_board_entry
        )
        gen_result = {
            "puzzle": "123456789" * 9,
            "solution": "987654321" * 9,
            "clues": 36,
            "fill_percent": 44.4,
            "symmetry": "rotational",
            "steps": 45,
            "technique_history": [],
        }
        entry = _make_board_entry(1, gen_result, TRAMO_CONFIG[0])
        assert entry["id"] == "evil_0001"
        assert entry["difficulty"] == "evil"
        assert entry["clues"] == 36
        assert len(entry["hash"]) == 16
        assert entry["hash"] == entry["checksum"]
        assert entry["human_score"] == 5
        assert entry["tier_max"] == 5
        assert entry["estimated_time_minutes"] == 15
        assert entry["difficulty_label"] == "Evil"

    def test_pick_symmetry_20_20_60(self):
        from tools.master_generator.variants.evil_9x9 import _pick_symmetry
        counts = {"rotational": 0, "mirror": 0, "random": 0}
        for i in range(1, 1001):
            counts[_pick_symmetry(i)] += 1
        assert counts["rotational"] == 200, f"Expected 200 rotational, got {counts['rotational']}"
        assert counts["mirror"] == 200, f"Expected 200 mirror, got {counts['mirror']}"
        assert counts["random"] == 600, f"Expected 600 random, got {counts['random']}"

    def test_pick_clues_tramo5(self):
        from tools.master_generator.variants.evil_9x9 import _pick_clues_tramo5
        for i in range(1, 801):
            assert _pick_clues_tramo5(i) == 31, f"idx {i}: expected 31"
        for i in range(801, 901):
            assert _pick_clues_tramo5(i) == 31, f"idx {i}: expected 31"
        for i in range(901, 1001):
            assert _pick_clues_tramo5(i) == 30, f"idx {i}: expected 30"


class TestEvilDataset:
    def test_all_files_exist(self):
        assert os.path.isdir(EVIL_DIR)
        files = [f for f in os.listdir(EVIL_DIR) if f.endswith(".json")]
        assert len(files) == 1000, f"Expected 1000, got {len(files)}"

    def test_file_names(self):
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            assert os.path.exists(path), f"Missing: evil_{i:04d}.json"

    def test_valid_json_format(self):
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert isinstance(data, dict)
            assert "id" in data
            assert "puzzle" in data
            assert "solution" in data
            assert "difficulty" in data

    def test_difficulty_field(self):
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["difficulty"] == "evil", f"{data['id']}: {data['difficulty']}"

    def test_id_matches_filename(self):
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["id"] == f"evil_{i:04d}", f"{data['id']} != evil_{i:04d}"

    def test_puzzle_length(self):
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert len(data["puzzle"]) == 81, f"{data['id']}: puzzle len={len(data['puzzle'])}"
            assert len(data["solution"]) == 81, f"{data['id']}: solution len={len(data['solution'])}"

    def test_clue_ranges_by_tramo(self):
        from tools.master_generator.variants.evil_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(EVIL_DIR, f"evil_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                expected_clues = t["clues"]
                if expected_clues == 0:
                    assert data["clues"] in (30, 31), f"{data['id']}: expected 30-31, got {data['clues']}"
                else:
                    assert data["clues"] == expected_clues, (
                        f"{data['id']}: expected {expected_clues}, got {data['clues']}"
                    )

    def test_tramo_techniques_match(self):
        from tools.master_generator.variants.evil_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(EVIL_DIR, f"evil_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert set(data["techniques"]) == set(t["techniques"]), (
                    f"{data['id']}: expected {t['techniques']}, got {data['techniques']}"
                )

    def test_tier_matches_tramo(self):
        from tools.master_generator.variants.evil_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(EVIL_DIR, f"evil_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert data["tier_max"] == t["tier_max"], (
                    f"{data['id']}: expected tier {t['tier_max']}, got {data['tier_max']}"
                )

    def test_no_duplicate_hashes(self):
        hashes = set()
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            h = data["hash"]
            assert h not in hashes, f"Duplicate hash {h} at evil_{i:04d}"
            hashes.add(h)

    def test_hash_integrity(self):
        import hashlib
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            expected = hashlib.sha256(data["puzzle"].encode()).hexdigest()[:16]
            assert data["hash"] == expected, f"{data['id']}: hash mismatch"
            assert data["hash"] == data["checksum"], f"{data['id']}: hash != checksum"

    def test_symmetry_split(self):
        rotational = 0
        mirror = 0
        random_sym = 0
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            sym = data["symmetry"]
            assert sym in ("rotational", "mirror", "random"), f"{data['id']}: sym={sym}"
            if sym == "rotational":
                rotational += 1
            elif sym == "mirror":
                mirror += 1
            else:
                random_sym += 1
        assert rotational == 200, f"Expected 200 rotational, got {rotational}"
        assert mirror == 200, f"Expected 200 mirror, got {mirror}"
        assert random_sym == 600, f"Expected 600 random, got {random_sym}"

    def test_no_forbidden_techniques(self):
        from tools.master_generator.variants.evil_9x9 import FORBIDDEN_TECH_IDS
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            for tech in data["techniques"]:
                tid = tech.lower().replace(" ", "_")
                assert tid not in FORBIDDEN_TECH_IDS, (
                    f"{data['id']}: forbidden technique {tech} listed"
                )

    def test_economy_metadata_present(self):
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "human_score" in data
            assert "visual_score" in data
            assert "tier_max" in data
            assert "estimated_time_minutes" in data
            assert "level_index" in data
            assert "difficulty_label" in data

    def test_clue_30_36_range(self):
        clues_seen = set()
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            clues_seen.add(data["clues"])
            assert 30 <= data["clues"] <= 36, f"{data['id']}: clues={data['clues']}"
        assert 30 in clues_seen, "No clues=30 found"
        assert 36 in clues_seen, "No clues=36 found"

    def test_tramo_1_techniques(self):
        for i in range(1, 201):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert len(data["techniques"]) == 18
            for t in ("LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
                      "PointingPair", "PointingTriple", "BoxLineReduction",
                      "NakedPair", "HiddenPair", "NakedTriple", "HiddenTriple",
                      "NakedQuad", "HiddenQuad",
                      "XWing", "XYWing", "XYZWing", "WWing", "Swordfish"):
                assert t in data["techniques"], f"{data['id']} missing {t}"

    def test_tramo_2_adds_jellyfish_wxyzwing(self):
        for i in range(201, 401):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "Jellyfish" in data["techniques"]
            assert "WXYZWing" in data["techniques"]
            assert "VWXYZWing" in data["techniques"]
            assert len(data["techniques"]) == 21

    def test_tramo_3_adds_uniqueness(self):
        for i in range(401, 601):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "UniqueRectangle" in data["techniques"]
            assert "HiddenRectangle" in data["techniques"]
            assert "AvoidableRectangle" in data["techniques"]
            assert "ExtendedRectangle" in data["techniques"]
            assert len(data["techniques"]) == 25

    def test_tramo_4_adds_bug_qwing_emptyrect(self):
        for i in range(601, 801):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "BUG+1" in data["techniques"] or "BUG+2" in data["techniques"]
            assert "QWing" in data["techniques"]
            assert "EmptyRectangle" in data["techniques"]
            assert len(data["techniques"]) == 29

    def test_tramo_5_adds_finned_fish(self):
        for i in range(801, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "FinnedXWing" in data["techniques"]
            assert "FinnedSwordfish" in data["techniques"]
            assert "SashimiXWing" in data["techniques"] or "SashimiSwordfish" in data["techniques"]
            assert len(data["techniques"]) == 33

    def test_estimated_time_by_tramo(self):
        from tools.master_generator.variants.evil_9x9 import TRAMO_CONFIG
        for t in TRAMO_CONFIG:
            for idx in range(t["start"], t["end"] + 1):
                path = os.path.join(EVIL_DIR, f"evil_{idx:04d}.json")
                with open(path) as f:
                    data = json.load(f)
                assert data["estimated_time_minutes"] == t["est_minutes"], (
                    f"{data['id']}: expected {t['est_minutes']}min, got {data['estimated_time_minutes']}"
                )

    def test_visual_score_correct(self):
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            expected = round(data["clues"] / 81, 3)
            assert data["visual_score"] == expected, (
                f"{data['id']}: visual_score {data['visual_score']} != {expected}"
            )

    def test_tramo_5_clue_901_1000_is_30(self):
        for i in range(901, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["clues"] == 30, f"{data['id']}: expected 30 clues, got {data['clues']}"

    def test_tramo_5_clue_801_900_is_31(self):
        for i in range(801, 901):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["clues"] == 31, f"{data['id']}: expected 31 clues, got {data['clues']}"


class TestEvilBoardLoopback:
    def test_board_repository_path_pattern(self):
        for i in [1, 200, 201, 400, 401, 600, 601, 800, 801, 1000]:
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            assert os.path.exists(path), f"Path pattern failed: {path}"

    def test_board_has_difficulty_for_validation(self):
        for i in [1, 500, 1000]:
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert data["difficulty"] == "evil"
            puzzle = data["puzzle"]
            solution = data["solution"]
            assert len(puzzle) == 81
            assert len(solution) == 81
            assert all(c in "0123456789" for c in puzzle)
            assert all(c in "123456789" for c in solution)

    def test_puzzle_values_subset_of_solution(self):
        for i in range(1, 1001, 50):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            puzzle = data["puzzle"]
            solution = data["solution"]
            for pi, si in zip(puzzle, solution):
                if pi != "0":
                    assert pi == si, f"{data['id']}: given {pi} != solution {si}"

    def test_no_conflicts(self):
        for i in range(1, 1001, 50):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            puzzle = data["puzzle"]
            solution = data["solution"]
            for board_str, name in [(puzzle, "puzzle"), (solution, "solution")]:
                board = [int(c) if c != "0" else 0 for c in board_str]
                for r in range(9):
                    vals = [board[r * 9 + c] for c in range(9) if board[r * 9 + c] != 0]
                    assert len(vals) == len(set(vals)), f"{data['id']} {name} row {r} conflict"
                for c in range(9):
                    vals = [board[r * 9 + c] for r in range(9) if board[r * 9 + c] != 0]
                    assert len(vals) == len(set(vals)), f"{data['id']} {name} col {c} conflict"
                for br in range(0, 9, 3):
                    for bc in range(0, 9, 3):
                        vals = []
                        for r in range(3):
                            for c in range(3):
                                v = board[(br + r) * 9 + (bc + c)]
                                if v != 0:
                                    vals.append(v)
                        assert len(vals) == len(set(vals)), f"{data['id']} {name} block {br},{bc} conflict"


class TestEvilSelectorConnection:
    def test_evil_count_1000_in_dart_code(self):
        dart_path = "flutter_app/lib/features/game/data/board_repository.dart"
        with open(dart_path) as f:
            content = f.read()
        assert "'evil': 1000" in content, "BoardRepository evil count not updated to 1000"

    def test_evil_total_count_1000_in_difficulty_provider(self):
        dart_path = "flutter_app/lib/features/difficulty/application/difficulty_provider.dart"
        with open(dart_path) as f:
            content = f.read()
        assert "'evil': 1000" in content, "Difficulty provider evil count not updated to 1000"

    def test_evil_dir_declared_in_pubspec(self):
        pubspec_path = "flutter_app/pubspec.yaml"
        with open(pubspec_path) as f:
            content = f.read()
        assert "assets/boards/evil/" in content, "evil board dir not in pubspec"

    def test_all_have_difficulty_for_selector(self):
        for i in range(1, 1001):
            path = os.path.join(EVIL_DIR, f"evil_{i:04d}.json")
            with open(path) as f:
                data = json.load(f)
            assert "difficulty" in data, f"evil_{i:04d} missing difficulty field"

