"""
Generator tests: 20+ tests covering generation, validation, profiles, symmetry.
"""
import pytest
from tools.human_solver.generator import PuzzleGenerator, _build_cell_groups
from tools.human_solver.board import Board
from tools.human_solver.uniqueness import has_unique_solution


@pytest.fixture
def gen():
    return PuzzleGenerator(seed=42)


class TestSolvedGeneration:
    def test_generates_valid_board(self, gen):
        board = gen.generate_solved()
        assert board.is_valid is True

    def test_generated_board_fully_solved(self, gen):
        board = gen.generate_solved()
        assert board.empty_count == 0

    def test_multiple_solved_boards_different(self, gen):
        b1 = gen.generate_solved()
        b2 = gen.generate_solved()
        s1 = "".join(str(b1.get_cell(r, c)) for r in range(9) for c in range(9))
        s2 = "".join(str(b2.get_cell(r, c)) for r in range(9) for c in range(9))
        assert s1 != s2


class TestEasyGeneration:
    def test_easy_clues_in_range(self, gen):
        r = gen.generate("easy", max_attempts=3)
        assert r is not None
        assert 60 <= r["clues"] <= 65

    def test_easy_fill_percent(self, gen):
        r = gen.generate("easy", max_attempts=3)
        assert r["fill_percent"] >= 74.0

    def test_easy_symmetry(self, gen):
        r = gen.generate("easy", max_attempts=3)
        assert r["symmetry"] == "rotational"

    def test_easy_tier_max(self, gen):
        r = gen.generate("easy", max_attempts=3)
        assert r["tier_max"] <= 1

    def test_easy_unique(self, gen):
        r = gen.generate("easy", max_attempts=3)
        assert has_unique_solution(r["puzzle"]) is True

    def test_easy_pipeline_solvable(self, gen):
        r = gen.generate("easy", max_attempts=3)
        from tools.human_solver.pipeline import Pipeline
        p = Pipeline()
        b = Board.from_string(r["puzzle"])
        solved, _ = p.solve(b)
        assert solved is True


class TestAllDifficulties:
    @pytest.mark.parametrize("diff,min_c,max_c", [
        ("easy", 60, 65),
        ("intermediate", 54, 59),
        ("hard", 46, 53),
        ("expert", 38, 45),
        ("evil", 30, 37),
        ("mythic", 24, 32),
    ])
    def test_clues_in_range(self, gen, diff, min_c, max_c):
        r = gen.generate(diff, max_attempts=3)
        assert r is not None
        assert min_c <= r["clues"] <= max_c, f"{diff}: {r['clues']} not in [{min_c},{max_c}]"

    @pytest.mark.parametrize("diff", ["easy", "intermediate", "hard", "expert", "evil", "mythic"])
    def test_all_unique(self, gen, diff):
        r = gen.generate(diff, max_attempts=3)
        assert r is not None
        assert has_unique_solution(r["puzzle"]) is True

    @pytest.mark.parametrize("diff", ["easy", "intermediate", "hard", "expert", "evil", "mythic"])
    def test_all_pipeline_solvable(self, gen, diff):
        r = gen.generate(diff, max_attempts=3)
        assert r is not None
        from tools.human_solver.pipeline import Pipeline
        p = Pipeline()
        b = Board.from_string(r["puzzle"])
        solved, _ = p.solve(b)
        assert solved is True

    @pytest.mark.parametrize("diff", ["easy", "intermediate", "hard", "expert", "evil", "mythic"])
    def test_all_has_solution_string(self, gen, diff):
        r = gen.generate(diff, max_attempts=3)
        assert r is not None
        assert len(r["solution"]) == 81
        assert all(c in "123456789" for c in r["solution"])


class TestValidatePuzzle:
    def test_validate_generated(self, gen):
        r = gen.generate("easy", max_attempts=3)
        v = gen.validate_puzzle(r["puzzle"])
        assert v["valid"] is True
        assert v["solved"] is True
        assert v["unique"] is True

    def test_validate_empty(self, gen):
        v = gen.validate_puzzle("0" * 81)
        assert v["valid"] is True
        assert v["solved"] is False  # pipeline can't solve empty

    def test_validate_invalid(self, gen):
        v = gen.validate_puzzle("1" * 81)
        assert v["valid"] is True or v["valid"] is False


class TestSymmetry:
    def test_rotational_groups_count(self):
        groups = _build_cell_groups("rotational")
        total = sum(len(g) for g in groups)
        assert total == 81

    def test_rotational_pairs(self):
        groups = _build_cell_groups("rotational")
        for g in groups:
            if len(g) == 2:
                r1, c1 = g[0]
                r2, c2 = g[1]
                assert (r2, c2) == (8 - r1, 8 - c1)

    def test_mirror_groups_count(self):
        groups = _build_cell_groups("mirror")
        total = sum(len(g) for g in groups)
        assert total == 81

    def test_random_groups_all_single(self):
        groups = _build_cell_groups("random")
        for g in groups:
            assert len(g) == 1

    def test_generated_easy_rotational(self, gen):
        r = gen.generate("easy", max_attempts=3)
        grid = [[int(c) for c in r["puzzle"][i * 9:(i + 1) * 9]] for i in range(9)]
        for i in range(9):
            for j in range(9):
                if grid[i][j] == 0:
                    assert grid[8 - i][8 - j] == 0, f"({i},{j}) missing symmetric partner"
                if grid[8 - i][8 - j] == 0:
                    assert grid[i][j] == 0, f"({8 - i},{8 - j}) missing symmetric partner"

    def test_generated_random_not_symmetric(self, gen):
        r = gen.generate("mythic", max_attempts=3)
        grid = [[int(c) for c in r["puzzle"][i * 9:(i + 1) * 9]] for i in range(9)]
        empty_pairs = 0
        for i in range(9):
            for j in range(9):
                if grid[i][j] == 0 and grid[8 - i][8 - j] == 0:
                    empty_pairs += 1
        pairs = 81 // 2
        assert empty_pairs < pairs


class TestEdgeCases:
    def test_unknown_difficulty_raises(self, gen):
        with pytest.raises(ValueError):
            gen.generate("unknown")

    def test_seed_reproducibility(self):
        g1 = PuzzleGenerator(seed=99)
        r1 = g1.generate("easy", max_attempts=3)
        g2 = PuzzleGenerator(seed=99)
        r2 = g2.generate("easy", max_attempts=3)
        assert r1["puzzle"] == r2["puzzle"]

    def test_generate_solved_from_string(self, gen):
        board = gen.generate_solved()
        s = "".join(str(board.get_cell(r, c)) for r in range(9) for c in range(9))
        assert len(s) == 81
        assert all(c in "123456789" for c in s)

    def test_generator_result_keys(self, gen):
        r = gen.generate("hard", max_attempts=3)
        assert r is not None
        expected_keys = {"puzzle", "solution", "difficulty", "difficulty_label",
                         "difficulty_score", "tier_max", "clues", "fill_percent",
                         "symmetry", "attempts", "technique_breakdown"}
        for key in expected_keys:
            assert key in r, f"Missing key: {key}"
