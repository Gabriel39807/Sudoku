"""Profile registry wrapping visual_profiles with difficulty scoring."""
from tools.human_solver.visual_profiles import get_profile, list_difficulties, PROFILES
from tools.human_solver.difficulty import HumanDifficultyScore
from tools.human_solver.visual_score import VisualDifficultyScore


class ProfileRegistry:
    @staticmethod
    def get(difficulty: str):
        return get_profile(difficulty)

    @staticmethod
    def list() -> list:
        return list_difficulties()

    @staticmethod
    def score_puzzle(puzzle_str: str) -> dict:
        vs = VisualDifficultyScore(puzzle_str)
        return {
            "visual": vs.details,
            "clues": vs.clues,
        }

    @staticmethod
    def get_campaign_stage(stage_num: int) -> dict:
        for s in CAMPAIGN_STAGES:
            if s["stage"] == stage_num:
                return s
        raise ValueError(f"Unknown campaign stage: {stage_num}")

    @staticmethod
    def difficulty_for_clues(clues: int) -> str:
        for diff in ["mythic", "evil", "expert", "hard", "intermediate", "easy"]:
            p = get_profile(diff)
            if p.clues_in_range(clues):
                return diff
        if clues > 65:
            return "easy"
        return "mythic"


CAMPAIGN_STAGES = [
    {
        "stage": 1,
        "name": "Tutorial",
        "variant": "mini_4x4",
        "cells": 16,
        "min_clues": 6,
        "max_clues": 10,
        "description": "4x4 introduction — basic scanning",
    },
    {
        "stage": 2,
        "name": "Guided",
        "variant": "mini_6x6",
        "cells": 36,
        "min_clues": 14,
        "max_clues": 20,
        "description": "6x6 — hidden singles, naked pairs",
    },
    {
        "stage": 3,
        "name": "Semi Guided",
        "variant": "mini_8x8",
        "cells": 64,
        "min_clues": 26,
        "max_clues": 34,
        "description": "8x8 — pointing pairs, box-line reduction",
    },
    {
        "stage": 4,
        "name": "Full Sudoku",
        "variant": "classic_9x9",
        "cells": 81,
        "min_clues": 24,
        "max_clues": 65,
        "description": "9x9 — all standard techniques",
    },
]


def get_campaign_stage(stage_num: int) -> dict:
    for s in CAMPAIGN_STAGES:
        if s["stage"] == stage_num:
            return s
    raise ValueError(f"Unknown campaign stage: {stage_num}")
