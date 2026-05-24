from __future__ import annotations
from typing import Dict, List, Optional, Tuple

from tools.human_solver.board import Board
from tools.human_solver.explainer import Explainer
from tools.human_solver.registry import Registry
from tools.human_solver.technique import Technique, TechniqueResult, TechniqueTier


class Pipeline:
    def __init__(self, registry: Optional[Registry] = None):
        self._registry = registry or Registry.instance()
        if self._registry.count() == 0:
            self._registry = self._manual_register()
        self._explainer = Explainer()
        self._iteration_limit = 1000

    def _manual_register(self) -> Registry:
        from tools.human_solver.techniques.basic import (
            LastBlankCell, FullHouse, NakedSingle, HiddenSingle,
        )
        from tools.human_solver.techniques.intermediate import (
            PointingPair, PointingTriple, BoxLineReduction,
            NakedPair, HiddenPair, NakedTriple, HiddenTriple,
            NakedQuad, HiddenQuad,
        )
        from tools.human_solver.techniques.wings import (
            XWing, XYWing, XYZWing, WWing, MWing, SWing,
            LWing, HWing, Swordfish, Jellyfish, WXYZWing, VWXYZWing,
        )
        from tools.human_solver.techniques.uniqueness import (
            UniqueRectangle, HiddenRectangle, AvoidableRectangle,
            ExtendedRectangle, BUG, BorescopeGrid, QWing, GurthSymmetry,
        )
        from tools.human_solver.techniques.chains import (
            SimpleColoring, XCycle, GroupedXCycle, RemotePairs,
            XYChain, TwinnedXYChain, AIC, GroupedAIC, Medusa3D, ContinuousLoop,
        )
        from tools.human_solver.techniques.als import (
            ALSXZ, ALSXYWing, ALSChain, DeathBlossom,
        )
        from tools.human_solver.techniques.fish import (
            FinnedFish, FinnedXWing, FinnedSwordfish, FinnedJellyfish,
            SashimiFish, FrankenFish, MutantFish,
            Squidward, Leviathan, MultivalueXWing, SiameseFish,
        )
        from tools.human_solver.techniques.extreme import (
            EmptyRectangle, SueDeCoq, ExtendedSueDeCoq,
            AlignedPairExclusion, AlignedTripleExclusion,
            Fireworks, Guardians, Tridagon, SKLoop,
            Exocet, DoubleExocet, PatternOverlay,
            ForcingChains, Nishio, BowmansBingo,
        )
        reg = Registry.instance()
        for cls in [
            LastBlankCell, FullHouse, NakedSingle, HiddenSingle,
            PointingPair, PointingTriple, BoxLineReduction,
            NakedPair, HiddenPair, NakedTriple, HiddenTriple, NakedQuad, HiddenQuad,
            XWing, XYWing, XYZWing, WWing, MWing, SWing, LWing, HWing,
            Swordfish, Jellyfish, WXYZWing, VWXYZWing,
            UniqueRectangle, HiddenRectangle, AvoidableRectangle, ExtendedRectangle,
            BUG, BorescopeGrid, QWing, GurthSymmetry,
            SimpleColoring, XCycle, GroupedXCycle, RemotePairs, XYChain,
            TwinnedXYChain, AIC, GroupedAIC, Medusa3D, ContinuousLoop,
            ALSXZ, ALSXYWing, ALSChain, DeathBlossom,
            FinnedFish, FinnedXWing, FinnedSwordfish, FinnedJellyfish,
            SashimiFish, FrankenFish, MutantFish,
            Squidward, Leviathan, MultivalueXWing, SiameseFish,
            EmptyRectangle, SueDeCoq, ExtendedSueDeCoq,
            AlignedPairExclusion, AlignedTripleExclusion,
            Fireworks, Guardians, Tridagon, SKLoop,
            Exocet, DoubleExocet, PatternOverlay,
            ForcingChains, Nishio, BowmansBingo,
        ]:
            reg.register(cls)
        return reg

    @property
    def explainer(self) -> Explainer:
        return self._explainer

    def solve(self, board: Board, max_iterations: int = 1000) -> Tuple[bool, Board]:
        board = board.clone()
        self._explainer.clear()
        self._iteration_limit = max_iterations
        iterations = 0

        while not board.is_solved and iterations < self._iteration_limit:
            iterations += 1

            if not board.is_valid:
                break

            result = self._run_tier_pass(board)
            if result is None:
                break

            tech_id, tech_name, tier_val, tech_result = result
            board.record_technique(tech_id)

            if not tech_result.is_empty:
                before = board.clone()
                for r, c, v in tech_result.placements:
                    board.place(r, c, v)
                for r, c, v in tech_result.eliminations:
                    board.eliminate(r, c, v)
                self._explainer.record(
                    tech_id, tech_name, tier_val, tech_result, before, board
                )

        return board.is_solved, board

    def solve_with_history(
        self, board: Board, max_iterations: int = 1000
    ) -> Tuple[bool, Board, List[dict]]:
        solved, final_board = self.solve(board, max_iterations)
        return solved, final_board, self._explainer.to_dict()

    def solve_step_by_step(self, board: Board) -> Optional[TechniqueResult]:
        if board.is_solved:
            return None
        if not board.is_valid:
            return None
        return self._run_tier_pass(board)

    def _run_tier_pass(self, board: Board) -> Optional[Tuple[str, str, int, TechniqueResult]]:
        for tier in [
            TechniqueTier.TIER1_BASIC,
            TechniqueTier.TIER2_INTERSECTIONS,
            TechniqueTier.TIER3_WINGS_FISH,
            TechniqueTier.TIER4_UNIQUENESS,
            TechniqueTier.TIER5_CHAINS,
            TechniqueTier.TIER6_ALS,
            TechniqueTier.TIER7_EXOTIC_FISH,
            TechniqueTier.TIER8_EXTREME,
        ]:
            result = self._try_tier(board, tier)
            if result is not None:
                return result
        return None

    def _try_tier(
        self, board: Board, tier: TechniqueTier
    ) -> Optional[Tuple[str, str, int, TechniqueResult]]:
        for technique in self._registry.enabled_by_tier(tier):
            if not technique.implemented:
                continue
            try:
                result = technique.apply(board)
            except Exception:
                continue
            if result is not None and not result.is_empty:
                return (technique.id, technique.name, tier.value, result)
        return None

    def full_log(self) -> str:
        return self._explainer.full_report()

    def reset(self):
        self._explainer.clear()

    @property
    def summary(self) -> dict:
        return {
            "steps": len(self._explainer.steps),
            "solved": None,
        }

    @staticmethod
    def get_available_tiers() -> List[TechniqueTier]:
        return [
            TechniqueTier.TIER1_BASIC,
            TechniqueTier.TIER2_INTERSECTIONS,
            TechniqueTier.TIER3_WINGS_FISH,
            TechniqueTier.TIER4_UNIQUENESS,
            TechniqueTier.TIER5_CHAINS,
            TechniqueTier.TIER6_ALS,
            TechniqueTier.TIER7_EXOTIC_FISH,
            TechniqueTier.TIER8_EXTREME,
        ]
