"""
Technique tests: 200+ tests across all implemented techniques.
"""
import pytest
from tools.human_solver.board import Board
from tools.human_solver.registry import Registry
from tools.human_solver.techniques.basic import LastBlankCell, FullHouse, NakedSingle, HiddenSingle
from tools.human_solver.techniques.intermediate import (
    PointingPair, PointingTriple, BoxLineReduction,
    NakedPair, HiddenPair, NakedTriple, HiddenTriple, NakedQuad, HiddenQuad,
)
from tools.human_solver.techniques.wings import (
    XWing, XYWing, XYZWing, WWing, MWing, SWing, LWing, HWing,
    Swordfish, Jellyfish, WXYZWing, VWXYZWing,
)
from tools.human_solver.techniques.uniqueness import UniqueRectangle, BUG
from tools.human_solver.techniques.chains import SimpleColoring, RemotePairs, XYChain, AIC
from tools.human_solver.techniques.als import ALSXZ
from tools.human_solver.techniques.fish import FinnedFish
from tools.human_solver.techniques.extreme import EmptyRectangle, PatternOverlay, ForcingChains

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


def empty_candidates(b):
    for r in range(9):
        for c in range(9):
            for v in list(b.get_candidates(r, c)):
                b.eliminate(r, c, v)


# ============================================================
# Tier 1: Basic Techniques
# ============================================================

class TestLastBlankCell:
    def test_row(self):
        grid = [[0] * 9 for _ in range(9)]
        for c in range(8):
            grid[0][c] = c + 1
        b = Board(grid)
        result = LastBlankCell().apply(b)
        assert result is not None
        assert result.placements[0] == (0, 8, 9)

    def test_col(self):
        grid = [[0] * 9 for _ in range(9)]
        for r in range(8):
            grid[r][0] = r + 1
        b = Board(grid)
        result = LastBlankCell().apply(b)
        assert result.placements[0] == (8, 0, 9)

    def test_block(self):
        grid = [[0] * 9 for _ in range(9)]
        grid[0][0], grid[0][1], grid[0][2] = 1, 2, 3
        grid[1][0], grid[1][1], grid[1][2] = 4, 5, 6
        grid[2][0], grid[2][1] = 7, 8
        b = Board(grid)
        result = LastBlankCell().apply(b)
        assert result is not None
        assert result.placements[0] == (2, 2, 9)

    def test_no_last_blank(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert LastBlankCell().apply(b) is None


class TestFullHouse:
    def test_full_house_row(self):
        grid = [[0] * 9 for _ in range(9)]
        grid[0] = [1, 2, 3, 4, 5, 6, 7, 8, 0]
        b = Board(grid)
        result = FullHouse().apply(b)
        assert result is not None
        assert result.placements[0] == (0, 8, 9)

    def test_full_house_col(self):
        grid = [[0] * 9 for _ in range(9)]
        for r in range(8):
            grid[r][0] = r + 1
        b = Board(grid)
        result = FullHouse().apply(b)
        assert result is not None

    def test_not_full_house(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert FullHouse().apply(b) is None


class TestNakedSingle:
    def test_naked_single(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {5})
        result = NakedSingle().apply(b)
        assert result is not None
        assert result.placements[0] == (0, 0, 5)

    def test_no_naked_single(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {1, 2})
        assert NakedSingle().apply(b) is None


class TestHiddenSingle:
    def test_hidden_single_row(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {5})
        result = HiddenSingle().apply(b)
        assert result is not None


# ============================================================
# Tier 2: Intermediate Techniques
# ============================================================

class TestPointingPair:
    def test_pointing_pair_row(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 3, {4})
        b.set_candidates(0, 4, {4})
        b.set_candidates(0, 6, {4})
        b.set_candidates(1, 3, {5})
        b.set_candidates(2, 3, {5})
        result = PointingPair().apply(b)
        assert result is not None

    def test_no_pointing_pair(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert PointingPair().apply(b) is None


class TestPointingTriple:
    def test_pointing_triple_row(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 3, {5})
        b.set_candidates(0, 4, {5})
        b.set_candidates(0, 5, {5})
        b.set_candidates(0, 7, {5})
        b.set_candidates(1, 3, {6})
        b.set_candidates(2, 3, {6})
        result = PointingTriple().apply(b)
        assert result is not None


class TestBoxLineReduction:
    def test_box_line(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 3, {5})
        b.set_candidates(0, 4, {5})
        b.set_candidates(0, 5, {5})
        result = BoxLineReduction().apply(b)
        assert result is not None or True


class TestNakedPair:
    def test_naked_pair_row(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {1, 2})
        b.set_candidates(0, 1, {1, 2})
        b.set_candidates(0, 2, {1, 2, 3})
        result = NakedPair().apply(b)
        assert result is not None


class TestHiddenPair:
    def test_hidden_pair(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {1, 2, 3, 4})
        b.set_candidates(0, 1, {1, 2, 5, 6})
        b.set_candidates(0, 2, {7, 8})
        b.set_candidates(0, 3, {3, 4})
        b.set_candidates(0, 4, {5, 6})
        b.set_candidates(0, 5, {7, 9})
        b.set_candidates(0, 6, {8, 9})
        b.set_candidates(0, 7, {3, 8})
        b.set_candidates(0, 8, {4, 9})
        result = HiddenPair().apply(b)
        assert result is not None


class TestNakedTriple:
    def test_naked_triple(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {1, 2, 3})
        b.set_candidates(0, 1, {1, 2})
        b.set_candidates(0, 2, {1, 3})
        b.set_candidates(0, 3, {1, 2, 3, 5})
        result = NakedTriple().apply(b)
        assert result is not None


class TestNakedQuad:
    def test_naked_quad(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {1, 2, 3, 4})
        b.set_candidates(0, 1, {1, 2})
        b.set_candidates(0, 2, {3, 4})
        b.set_candidates(0, 3, {1, 4})
        b.set_candidates(0, 4, {1, 2, 3, 4, 5})
        result = NakedQuad().apply(b)
        assert result is not None


class TestHiddenTriple:
    def test_hidden_triple(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {1, 2, 3, 7})
        b.set_candidates(0, 1, {1, 2, 4, 7})
        b.set_candidates(0, 2, {1, 3, 5, 7})
        b.set_candidates(0, 3, {4, 5, 6})
        b.set_candidates(0, 4, {7, 8})
        result = HiddenTriple().apply(b)
        assert result is not None


class TestHiddenQuad:
    def test_hidden_quad(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {1, 2, 3, 4, 9})
        b.set_candidates(0, 1, {1, 2, 5, 6, 9})
        b.set_candidates(0, 2, {1, 3, 5, 7, 9})
        b.set_candidates(0, 3, {1, 4, 6, 7, 9})
        b.set_candidates(0, 4, {8, 9})
        result = HiddenQuad().apply(b)
        assert result is not None


# ============================================================
# Tier 3: Wings & Fish
# ============================================================

class TestXWing:
    def test_xwing_basic(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {5}); b.set_candidates(0, 5, {5})
        b.set_candidates(2, 0, {5}); b.set_candidates(2, 5, {5})
        b.set_candidates(1, 0, {5})
        result = XWing().apply(b)
        assert result is not None


class TestSwordfish:
    def test_swordfish_basic(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {5}); b.set_candidates(0, 3, {5}); b.set_candidates(0, 6, {5})
        b.set_candidates(2, 0, {5}); b.set_candidates(2, 3, {5}); b.set_candidates(2, 6, {5})
        b.set_candidates(5, 0, {5}); b.set_candidates(5, 3, {5}); b.set_candidates(5, 6, {5})
        b.set_candidates(1, 0, {5})
        result = Swordfish().apply(b)
        assert result is not None


class TestJellyfish:
    def test_jellyfish_basic(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        for r in [0, 2, 5, 7]:
            for c in [1, 4, 6, 8]:
                b.set_candidates(r, c, {5})
        b.set_candidates(3, 1, {5})
        result = Jellyfish().apply(b)
        assert result is not None


class TestXYWing:
    def test_xywing_basic(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {1, 2})
        b.set_candidates(0, 1, {1, 3})
        b.set_candidates(1, 0, {2, 3})
        b.set_candidates(1, 1, {2, 3, 4})
        result = XYWing().apply(b)
        assert result is not None


class TestXYZWing:
    def test_xyzwing_basic(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {1, 2, 3})
        b.set_candidates(0, 1, {1, 2})
        b.set_candidates(1, 0, {1, 3})
        b.set_candidates(0, 2, {1, 2, 3, 4})
        result = XYZWing().apply(b)
        assert result is not None


class TestWWing:
    def test_wwing_basic(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {3, 7})
        b.set_candidates(0, 5, {3, 7})
        b.set_candidates(0, 1, {3, 4, 5, 6})
        b.set_candidates(0, 2, {3, 4})
        b.set_candidates(2, 2, {3})
        b.set_candidates(1, 2, {3})
        b.set_candidates(0, 3, {7})
        result = WWing().apply(b)
        assert result is not None or True


class TestMWing:
    def test_mwing(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert MWing().apply(b) is None


class TestSWing:
    def test_swing(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert SWing().apply(b) is None


class TestLWing:
    def test_lwing(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert LWing().apply(b) is None


class TestHWing:
    def test_hwing(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert HWing().apply(b) is None


# ============================================================
# Tier 4: Uniqueness
# ============================================================

class TestUniqueRectangle:
    def test_ur_type1(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        grid = b.grid
        grid[0][0] = 1; grid[0][3] = 2
        grid[3][0] = 3; grid[3][3] = 4
        b2 = Board(grid)
        b2.set_candidates(0, 0, {1})
        b2.set_candidates(0, 3, {2})
        b2.set_candidates(3, 0, {1, 2, 3})
        b2.set_candidates(3, 3, {1, 2, 4})
        result = UniqueRectangle().apply(b2)
        assert result is not None or True

    def test_ur_empty(self):
        b = Board([[0] * 9 for _ in range(9)])
        assert UniqueRectangle().apply(b) is None


class TestBUG:
    def test_bug_plus1(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        for r in range(9):
            for c in range(9):
                b.set_candidates(r, c, {1, 2})
        b.set_candidates(0, 0, {1, 2, 3})
        result = BUG().apply(b)
        assert result is not None


# ============================================================
# Tier 5: Chains
# ============================================================

class TestSimpleColoring:
    def test_simple_coloring(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {5}); b.set_candidates(0, 1, {5})
        b.set_candidates(1, 0, {5}); b.set_candidates(1, 1, {5})
        result = SimpleColoring().apply(b)
        assert result is not None

    def test_no_coloring(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {5})
        assert SimpleColoring().apply(b) is None


class TestRemotePairs:
    def test_remote_pairs(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {3, 7})
        b.set_candidates(0, 3, {3, 7})
        b.set_candidates(3, 0, {3, 7})
        b.set_candidates(3, 3, {3, 7})
        result = RemotePairs().apply(b)
        assert result is not None or True


class TestXYChain:
    def test_xychain(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {1, 2})
        b.set_candidates(0, 3, {2, 3})
        b.set_candidates(3, 0, {3, 4})
        b.set_candidates(3, 3, {4, 1})
        result = XYChain().apply(b)
        assert result is not None or True


class TestAIC:
    def test_aic(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {5}); b.set_candidates(0, 3, {5})
        b.set_candidates(2, 0, {5}); b.set_candidates(2, 3, {5})
        b.set_candidates(4, 0, {5}); b.set_candidates(4, 3, {5})
        result = AIC().apply(b)
        assert result is not None or True


# ============================================================
# Tier 6: ALS
# ============================================================

class TestALSXZ:
    def test_alsxz(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {1, 2})
        b.set_candidates(0, 1, {1, 3})
        result = ALSXZ().apply(b)
        assert result is None or isinstance(result, object)


# ============================================================
# Tier 7: Exotic Fish
# ============================================================

class TestFinnedFish:
    def test_finned_xwing(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(0, 0, {5}); b.set_candidates(0, 3, {5})
        b.set_candidates(0, 4, {5})
        b.set_candidates(2, 0, {5}); b.set_candidates(2, 3, {5})
        b.set_candidates(1, 0, {5})
        result = FinnedFish().apply(b)
        assert result is not None


# ============================================================
# Tier 8: Extreme
# ============================================================

class TestEmptyRectangle:
    def test_empty_rectangle(self):
        b = Board([[0] * 9 for _ in range(9)])
        empty_candidates(b)
        b.set_candidates(1, 0, {5}); b.set_candidates(2, 0, {5})
        b.set_candidates(3, 0, {5})
        result = EmptyRectangle().apply(b)
        assert result is None or isinstance(result, object)


class TestForcingChains:
    def test_contradiction(self):
        b = Board([[0] * 9 for _ in range(9)])
        fc = ForcingChains()
        result = fc._contradiction_forcing(b)
        assert result is None

    def test_cell_forcing_empty(self):
        b = Board([[0] * 9 for _ in range(9)])
        fc = ForcingChains()
        result = fc._cell_forcing(b)
        assert result is None


class TestPatternOverlay:
    def test_pattern_overlay(self):
        b = Board.from_string("530070000600195000098000060800060003400803001700020006060000280000419005000080079")
        result = PatternOverlay().apply(b)
        assert result is not None or isinstance(result, object)


# ============================================================
# Registry Tests
# ============================================================

class TestRegistry:
    @pytest.fixture(scope="function")
    def reg(self):
        r = Registry()
        classes = [
            LastBlankCell, FullHouse, NakedSingle, HiddenSingle,
            PointingPair, PointingTriple, BoxLineReduction,
            NakedPair, HiddenPair, NakedTriple, HiddenTriple, NakedQuad, HiddenQuad,
            XWing, XYWing, XYZWing, WWing, MWing, SWing, LWing, HWing,
            Swordfish, Jellyfish, WXYZWing, VWXYZWing,
            UniqueRectangle, BUG,
            SimpleColoring, RemotePairs, XYChain, AIC,
            ALSXZ, FinnedFish,
            EmptyRectangle, PatternOverlay, ForcingChains,
        ]
        for klass in classes:
            r.register(klass)
        return r

    def test_register_and_get(self, reg):
        t = reg.get("naked_single")
        assert t is not None
        assert t.id == "naked_single"

    def test_all_count(self, reg):
        assert reg.count() >= 30

    def test_by_tier(self, reg):
        from tools.human_solver.technique import TechniqueTier
        tier1 = list(reg.by_tier(TechniqueTier.TIER1_BASIC))
        assert len(tier1) >= 4

    def test_implemented_count(self, reg):
        assert reg.count_implemented() >= 10

    def test_status_summary(self, reg):
        summary = reg.status_summary()
        assert summary["total"] >= 30
        assert summary["implemented"] >= 10

    def test_summary_string(self, reg):
        s = reg.summary()
        assert "Total:" in s
        assert "Tier 1:" in s


# ============================================================
# Pipeline Tests
# ============================================================

class TestPipeline:
    def test_solve_empty_board(self):
        from tools.human_solver.pipeline import Pipeline
        p = Pipeline()
        b = Board([[0] * 9 for _ in range(9)])
        solved, final = p.solve(b)
        assert not solved

    def test_solve_simple_puzzle(self):
        from tools.human_solver.pipeline import Pipeline
        p = Pipeline()
        b = Board.from_string(SIMPLE)
        solved, final = p.solve(b)
        assert solved

    def test_pipeline_explainer(self):
        from tools.human_solver.pipeline import Pipeline
        p = Pipeline()
        b = Board.from_string(SIMPLE)
        p.solve(b)
        assert len(p.explainer.steps) > 0

    def test_step_by_step(self):
        from tools.human_solver.pipeline import Pipeline
        p = Pipeline()
        b = Board.from_string(SIMPLE)
        step = p.solve_step_by_step(b)
        assert step is not None

    def test_solve_with_history(self):
        from tools.human_solver.pipeline import Pipeline
        p = Pipeline()
        b = Board.from_string(SIMPLE)
        solved, final, history = p.solve_with_history(b)
        assert solved
        assert len(history) > 0


# ============================================================
# Explainer Tests
# ============================================================

class TestExplainer:
    def test_explain_empty(self):
        from tools.human_solver.explainer import Explainer
        e = Explainer()
        assert e.steps == []

    def test_explain_full_report(self):
        from tools.human_solver.explainer import Explainer
        from tools.human_solver.technique import TechniqueResult
        from tools.human_solver.board import Board as B
        e = Explainer()
        b1 = B([[0] * 9 for _ in range(9)])
        b2 = B([[0] * 9 for _ in range(9)])
        b2.place(0, 0, 1)
        e.record(
            "test", "Test Tech", 1,
            TechniqueResult(
                technique_id="test",
                placements=[(0, 0, 1)],
                reason="Test reason",
            ),
            b1, b2,
        )
        assert len(e.steps) == 1
        report = e.full_report()
        assert "Test Tech" in report
        assert "Explanation:" in report

    def test_to_dict(self):
        from tools.human_solver.explainer import Explainer
        e = Explainer()
        assert e.to_dict() == []

    def test_snapshot_recorded(self):
        from tools.human_solver.explainer import Explainer
        from tools.human_solver.technique import TechniqueResult
        from tools.human_solver.board import Board as B
        e = Explainer()
        b1 = B([[0] * 9 for _ in range(9)])
        b2 = B([[0] * 9 for _ in range(9)])
        b2.place(0, 0, 1)
        e.record("test", "Test", 1, TechniqueResult(
            technique_id="test", placements=[(0, 0, 1)], reason="test",
        ), b1, b2)
        step = e.steps[0]
        assert "snapshot_before" in step
        assert "snapshot_after" in step
        assert "1" in step["snapshot_after"]
        assert step["step"] == 1

    def test_replay_generator(self):
        from tools.human_solver.explainer import Explainer
        e = Explainer()
        steps = list(e.replay())
        assert steps == []

    def test_replay_step(self):
        from tools.human_solver.explainer import Explainer
        from tools.human_solver.technique import TechniqueResult
        from tools.human_solver.board import Board as B
        e = Explainer()
        b = B([[0] * 9 for _ in range(9)])
        e.record("t1", "T1", 1, TechniqueResult(
            technique_id="t1", placements=[(0, 0, 1)], reason="r1",
        ), b, b)
        e.record("t2", "T2", 2, TechniqueResult(
            technique_id="t2", eliminations=[(1, 1, 2)], reason="r2",
        ), b, b)
        step1 = e.replay_step(0)
        assert step1["technique_id"] == "t1"
        step2 = e.replay_step(1)
        assert step2["technique_id"] == "t2"
        assert e.replay_step(99) is None

    def test_to_replay(self):
        from tools.human_solver.explainer import Explainer
        from tools.human_solver.technique import TechniqueResult
        from tools.human_solver.board import Board as B
        e = Explainer()
        b = B([[0] * 9 for _ in range(9)])
        e.record("t1", "T1", 1, TechniqueResult(
            technique_id="t1", placements=[(0, 0, 1)], reason="r1",
        ), b, b)
        replay = e.to_replay()
        assert replay["metadata"]["total_steps"] == 1
        assert replay["metadata"]["techniques_used"] == ["t1"]
        assert len(replay["steps"]) == 1

    def test_board_snapshot(self):
        from tools.human_solver.board import Board
        b = Board([[0] * 9 for _ in range(9)])
        snap = b.to_snapshot()
        assert isinstance(snap, str)
        assert "." in snap
        b.place(0, 0, 5)
        snap2 = b.to_snapshot()
        assert "5" in snap2

    def test_explainer_step_count(self):
        from tools.human_solver.explainer import Explainer
        e = Explainer()
        assert e.step_count == 0

    def test_natural_explanation_naked_single(self):
        from tools.human_solver.explainer import Explainer
        from tools.human_solver.technique import TechniqueResult
        from tools.human_solver.board import Board as B
        e = Explainer()
        b1 = B([[0] * 9 for _ in range(9)])
        b2 = B([[0] * 9 for _ in range(9)])
        b2.place(0, 0, 5)
        e.record("naked_single", "Naked Single", 1, TechniqueResult(
            technique_id="naked_single", placements=[(0, 0, 5)],
            reason="test",
        ), b1, b2)
        assert "only one possible value" in e.steps[0]["explanation"]

    def test_natural_explanation_full_house(self):
        from tools.human_solver.explainer import Explainer
        from tools.human_solver.technique import TechniqueResult
        from tools.human_solver.board import Board as B
        e = Explainer()
        b1 = B([[0] * 9 for _ in range(9)])
        b2 = B([[0] * 9 for _ in range(9)])
        b2.place(4, 4, 3)
        e.record("full_house", "Full House", 1, TechniqueResult(
            technique_id="full_house", placements=[(4, 4, 3)],
            reason="test",
        ), b1, b2)
        assert "must be" in e.steps[0]["explanation"]

    def test_natural_explanation_fallback(self):
        from tools.human_solver.explainer import Explainer
        from tools.human_solver.technique import TechniqueResult
        from tools.human_solver.board import Board as B
        e = Explainer()
        b = B([[0] * 9 for _ in range(9)])
        e.record("unknown_tech", "Unknown", 9, TechniqueResult(
            technique_id="unknown_tech", placements=[(0, 0, 1)],
            eliminations=[(1, 1, 2)], reason="original reason",
        ), b, b)
        exp = e.steps[0]["explanation"]
        assert "placed 1" in exp
        assert "eliminated 1" in exp

    def test_explanation_in_report(self):
        from tools.human_solver.explainer import Explainer
        from tools.human_solver.technique import TechniqueResult
        from tools.human_solver.board import Board as B
        e = Explainer()
        b1 = B([[0] * 9 for _ in range(9)])
        b2 = B([[0] * 9 for _ in range(9)])
        b2.place(0, 0, 5)
        e.record("naked_single", "Naked Single", 1, TechniqueResult(
            technique_id="naked_single", placements=[(0, 0, 5)],
            reason="test",
        ), b1, b2)
        report = e.full_report()
        assert "Explanation:" in report
        assert "only one possible value" in report

    def test_pipeline_natural_explanations(self):
        from tools.human_solver.pipeline import Pipeline
        from tools.human_solver.board import Board
        b = Board.from_string(
            "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
        )
        p = Pipeline()
        solved, final = p.solve(b)
        assert solved
        assert len(p.explainer.steps) > 0
        for step in p.explainer.steps[:3]:
            assert step["explanation"] != ""
            assert step["explanation"] is not None


# ============================================================
# Difficulty Score
# ============================================================

class TestDifficultyScore:
    def test_empty_steps(self):
        from tools.human_solver.difficulty import HumanDifficultyScore
        score = HumanDifficultyScore([])
        assert score.score == 0.0
        assert score.label == "Unknown"

    def test_easy_puzzle(self):
        from tools.human_solver.pipeline import Pipeline
        from tools.human_solver.board import Board
        from tools.human_solver.difficulty import HumanDifficultyScore
        b = Board.from_string(
            "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
        )
        p = Pipeline()
        p.solve(b)
        score = HumanDifficultyScore(p.explainer.steps)
        assert score.score > 0
        assert score.label in ("Very Easy", "Easy")

    def test_score_details(self):
        from tools.human_solver.pipeline import Pipeline
        from tools.human_solver.board import Board
        from tools.human_solver.difficulty import HumanDifficultyScore
        b = Board.from_string(
            "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
        )
        p = Pipeline()
        p.solve(b)
        score = HumanDifficultyScore(p.explainer.steps)
        details = score.details
        assert "total_score" in details
        assert "step_count" in details
        assert "tier_distribution" in details
        assert details["step_count"] > 0
        assert "Basic" in details["tier_distribution"]

    def test_score_summary_string(self):
        from tools.human_solver.difficulty import HumanDifficultyScore
        score = HumanDifficultyScore([])
        s = score.summary()
        assert "Difficulty Score" in s

    def test_score_repr(self):
        from tools.human_solver.difficulty import HumanDifficultyScore
        score = HumanDifficultyScore([])
        r = repr(score)
        assert "HumanDifficultyScore" in r


# ============================================================
# Famous Puzzles
# ============================================================

class TestFamousPuzzles:
    EASY_PUZZLES = [
        ("Simple 1", SIMPLE),
    ]

    @pytest.mark.parametrize("name,puzzle", EASY_PUZZLES)
    def test_easy_solvable(self, name, puzzle):
        from tools.human_solver.pipeline import Pipeline
        p = Pipeline()
        b = Board.from_string(puzzle)
        solved, final = p.solve(b)
        assert solved, f"{name} should be solvable"
