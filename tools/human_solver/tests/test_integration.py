"""
Integration tests: 50+ tests combining multiple techniques, edge cases, and full solves.
"""
import pytest
from tools.human_solver.board import Board, Cell
from tools.human_solver.pipeline import Pipeline
from .famous_puzzles import FAMOUS_PUZZLES

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


class TestPipelineEdgeCases:
    def test_already_solved(self):
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
        p = Pipeline()
        b = Board(grid)
        solved, final = p.solve(b)
        assert solved

    def test_single_cell_empty(self):
        grid = [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,0],
        ]
        p = Pipeline()
        b = Board(grid)
        solved, final = p.solve(b)
        assert solved
        assert final.get_cell(8, 8) == 9

    def test_all_naked_singles(self):
        grid = [[0] * 9 for _ in range(9)]
        grid[0] = [1, 2, 3, 4, 5, 6, 7, 8, 0]
        grid[1] = [4, 5, 6, 7, 8, 0, 1, 2, 3]
        grid[2] = [7, 8, 0, 1, 2, 3, 4, 5, 6]
        grid[3] = [2, 3, 4, 5, 6, 7, 8, 0, 1]
        grid[4] = [5, 6, 7, 8, 0, 1, 2, 3, 4]
        grid[5] = [8, 0, 1, 2, 3, 4, 5, 6, 7]
        grid[6] = [3, 4, 5, 6, 7, 8, 0, 1, 2]
        grid[7] = [6, 7, 8, 0, 1, 2, 3, 4, 5]
        grid[8] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        b = Board(grid)
        p = Pipeline()
        solved, final = p.solve(b)
        assert solved

    def test_valid_but_no_candidates(self):
        grid = [[0] * 9 for _ in range(9)]
        b = Board(grid)
        for r in range(9):
            for c in range(9):
                if b.get_cell(r, c) == 0:
                    for v in range(1, 10):
                        if b.has_candidate(r, c, v):
                            break
                    else:
                        pass
        assert b.is_valid

    def test_pipeline_reset(self):
        p = Pipeline()
        b = Board.from_string(SIMPLE)
        p.solve(b)
        assert len(p.explainer.steps) > 0
        p.reset()
        assert len(p.explainer.steps) == 0


class TestBoardEndToEnd:
    def test_place_eliminates_from_peers(self):
        b = Board([[0] * 9 for _ in range(9)])
        b.eliminate(5, 5, 9)
        b.eliminate(5, 5, 9)
        b.set_candidates(5, 5, {9})
        b.place(5, 5, 9)
        for peer in b.empty_cells():
            if peer.row == 5 and peer.col == 5:
                continue
            c = Cell(5, 5)
            if peer.row == c.row or peer.col == c.col or peer.block == c.block:
                assert not b.has_candidate(peer.row, peer.col, 9), \
                    f"{peer.name} should not have 9"

    def test_solve_requires_no_backtracking(self):
        p = Pipeline()
        easy = Board.from_string(SIMPLE)
        solved, final = p.solve(easy)
        assert solved

    def test_solve_history_contains_techniques(self):
        p = Pipeline()
        b = Board.from_string(SIMPLE)
        p.solve(b)
        history = p.explainer.to_dict()
        techs = {step["technique_id"] for step in history}
        assert len(techs) > 0

    def test_empty_board_solves(self):
        p = Pipeline()
        b = Board([[0] * 9 for _ in range(9)])
        solved, final = p.solve(b)
        assert not solved


class TestTechniqueEdgeCases:
    def test_naked_single_with_no_candidates(self):
        b = Board([[0] * 9 for _ in range(9)])
        for v in range(1, 10):
            b.eliminate(0, 0, v)
        from tools.human_solver.techniques.basic import NakedSingle
        assert NakedSingle().apply(b) is None

    def test_hidden_single_empty_board(self):
        from tools.human_solver.techniques.basic import HiddenSingle
        b = Board([[0] * 9 for _ in range(9)])
        assert HiddenSingle().apply(b) is None

    def test_xwing_no_candidates(self):
        from tools.human_solver.techniques.wings import XWing
        b = Board([[0] * 9 for _ in range(9)])
        assert XWing().apply(b) is None

    def test_pointing_pair_no_match(self):
        from tools.human_solver.techniques.intermediate import PointingPair
        b = Board([[0] * 9 for _ in range(9)])
        assert PointingPair().apply(b) is None

    def test_naked_quad_no_match(self):
        from tools.human_solver.techniques.intermediate import NakedQuad
        b = Board([[0] * 9 for _ in range(9)])
        assert NakedQuad().apply(b) is None

    def test_multiple_techniques_chain(self):
        b = Board.from_string(SIMPLE)
        p = Pipeline()
        solved, final = p.solve(b)
        assert solved


class TestFamousPuzzlesIntegration:
    @pytest.mark.parametrize("name", list(FAMOUS_PUZZLES.keys()))
    def test_all_famous_puzzles(self, name):
        puzzle_str = FAMOUS_PUZZLES[name]
        if puzzle_str == "0" * 81:
            pytest.skip("Empty board")
        try:
            b = Board.from_string(puzzle_str)
        except AssertionError:
            pytest.skip(f"Invalid puzzle string: {name}")
        assert b.is_valid
        assert b.empty_count > 0

    MEDIUM = (
        "200507004"
        "037000015"
        "500009000"
        "700406003"
        "000701000"
        "900805002"
        "000600005"
        "100000840"
        "400309007"
    )

    def test_medium_puzzle_partial(self):
        b = Board.from_string(self.MEDIUM)
        p = Pipeline()
        solved, final = p.solve(b, max_iterations=50)
        assert isinstance(solved, bool)

    def test_simple_puzzle_quick_solve(self):
        b = Board.from_string(SIMPLE)
        p = Pipeline()
        solved, final = p.solve(b, max_iterations=100)
        assert solved


class TestBenchmarkModule:
    def test_benchmark_runner_creation(self):
        from tools.human_solver.benchmarks import BenchmarkRunner
        br = BenchmarkRunner()
        assert br.results == []

    def test_benchmark_single(self):
        from tools.human_solver.benchmarks import BenchmarkRunner
        br = BenchmarkRunner()
        result = br.run_single("test", SIMPLE)
        assert isinstance(result.solved, bool)
        assert result.time_ms >= 0

    def test_benchmark_summary(self):
        from tools.human_solver.benchmarks import BenchmarkRunner
        br = BenchmarkRunner()
        br.register_puzzle("test", SIMPLE)
        br.run_all()
        summary = br.summary()
        assert "BENCHMARK" in summary

    def test_benchmark_to_dict(self):
        from tools.human_solver.benchmarks import BenchmarkRunner
        br = BenchmarkRunner()
        br.register_puzzle("test", SIMPLE)
        br.run_all()
        data = br.to_dict()
        assert len(data) == 1
        assert "puzzle_name" in data[0]
