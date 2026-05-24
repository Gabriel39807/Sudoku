"""Classic 9x9 campaign Stage 4 — wraps human_solver pipeline with tier-limited solving."""

import random
from typing import Dict, List, Optional, Set, Tuple

N = 9
CELLS = 81

# Technique IDs from human_solver registry (underscore-separated)
CAMPAIGN_TIER_TECH_IDS: Dict[int, Set[str]] = {
    1: {"last_blank_cell", "full_house", "naked_single", "hidden_single"},
    2: {"last_blank_cell", "full_house", "naked_single", "hidden_single",
        "pointing_pair", "pointing_triple", "box_line_reduction",
        "naked_pair", "hidden_pair"},
    3: {"last_blank_cell", "full_house", "naked_single", "hidden_single",
        "pointing_pair", "pointing_triple", "box_line_reduction",
        "naked_pair", "hidden_pair",
        "naked_triple", "hidden_triple"},
    4: {"last_blank_cell", "full_house", "naked_single", "hidden_single",
        "pointing_pair", "pointing_triple", "box_line_reduction",
        "naked_pair", "hidden_pair",
        "naked_triple", "hidden_triple",
        "naked_quad", "hidden_quad"},
    5: {"last_blank_cell", "full_house", "naked_single", "hidden_single",
        "pointing_pair", "pointing_triple", "box_line_reduction",
        "naked_pair", "hidden_pair",
        "naked_triple", "hidden_triple",
        "naked_quad", "hidden_quad",
        "xwing", "xywing"},
}

TIER_DEFINITIONS = {
    1: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle"],
    2: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
        "PointingPair", "PointingTriple", "BoxLineReduction",
        "NakedPair", "HiddenPair"],
    3: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
        "PointingPair", "PointingTriple", "BoxLineReduction",
        "NakedPair", "HiddenPair",
        "NakedTriple", "HiddenTriple"],
    4: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
        "PointingPair", "PointingTriple", "BoxLineReduction",
        "NakedPair", "HiddenPair",
        "NakedTriple", "HiddenTriple",
        "NakedQuad", "HiddenQuad"],
    5: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
        "PointingPair", "PointingTriple", "BoxLineReduction",
        "NakedPair", "HiddenPair",
        "NakedTriple", "HiddenTriple",
        "NakedQuad", "HiddenQuad",
        "XWing", "XYWing"],
}

_CACHED_REGISTRY = None
_ORIGINAL_STATES: Dict[str, bool] = {}
_ORIGINAL_ENABLED: Dict[str, bool] = {}


def _ensure_registry():
    global _CACHED_REGISTRY, _ORIGINAL_STATES, _ORIGINAL_ENABLED
    if _CACHED_REGISTRY is not None:
        return _CACHED_REGISTRY
    from tools.human_solver.registry import Registry
    from tools.human_solver.pipeline import Pipeline
    _CACHED_REGISTRY = Registry.instance()
    if _CACHED_REGISTRY.count() == 0:
        Pipeline()
    for tid, tech in _CACHED_REGISTRY._techniques.items():
        _ORIGINAL_STATES[tid] = tech.implemented
        _ORIGINAL_ENABLED[tid] = tech.enabled
    return _CACHED_REGISTRY


def _set_campaign_tier(tier: int):
    reg = _ensure_registry()
    allowed = CAMPAIGN_TIER_TECH_IDS.get(tier, set())
    for tid, tech in reg._techniques.items():
        if tid in allowed:
            tech.implemented = True
            tech.enabled = True
        else:
            tech.implemented = False
            tech.enabled = False


def _restore_all():
    global _CACHED_REGISTRY
    if _CACHED_REGISTRY is None:
        return
    for tid, tech in _CACHED_REGISTRY._techniques.items():
        if tid in _ORIGINAL_STATES:
            tech.implemented = _ORIGINAL_STATES[tid]
            tech.enabled = _ORIGINAL_ENABLED[tid]


def solve_with_limit(puzzle_81: str, campaign_tier: int) -> bool:
    from tools.human_solver.board import Board
    from tools.human_solver.pipeline import Pipeline
    _set_campaign_tier(campaign_tier)
    board = Board.from_string(puzzle_81.replace("0", "."))
    pipeline = Pipeline()
    solved, _ = pipeline.solve(board)
    _restore_all()
    return solved


def has_unique_solution(puzzle_81: str) -> bool:
    from tools.human_solver.uniqueness import has_unique_solution as _check
    return _check(puzzle_81.replace("0", "."))


class Classic9x9Generator:
    def __init__(self, seed: Optional[int] = None):
        if seed is not None:
            random.seed(seed)

    def generate_solved(self) -> str:
        from tools.human_solver.generator import PuzzleGenerator
        gen = PuzzleGenerator()
        board = gen.generate_solved()
        return "".join(str(board.get_cell(r, c)) for r in range(N) for c in range(N))

    def generate(
        self, min_clues: int, max_clues: int, max_tier: int, max_attempts: int = 20
    ) -> Optional[Dict]:
        for _ in range(max_attempts):
            solved_str = self.generate_solved()
            grid_chars = list(solved_str)
            cells = list(range(CELLS))
            random.shuffle(cells)
            removed = 0

            for idx in cells:
                val = grid_chars[idx]
                grid_chars[idx] = "0"
                puzzle = "".join(grid_chars)
                clues_if_removed = CELLS - removed - 1

                if clues_if_removed < min_clues:
                    grid_chars[idx] = val
                    continue

                tech_ok = solve_with_limit(puzzle, max_tier)
                if not tech_ok:
                    grid_chars[idx] = val
                    continue

                unique = has_unique_solution(puzzle)
                if unique:
                    removed += 1
                else:
                    grid_chars[idx] = val

            clues = CELLS - removed
            if clues < min_clues or clues > max_clues:
                continue

            final_puzzle = "".join(grid_chars)
            if not has_unique_solution(final_puzzle):
                continue

            return {
                "puzzle": final_puzzle,
                "solution": solved_str,
                "clues": clues,
                "variant": "classic_9x9",
            }

        return None


CAMPAIGN_CHAPTERS = [
    {"start": 1, "end": 30, "min_clues": 60, "max_clues": 65, "max_tier": 1,
     "label": "First Real Sudoku", "chapter": 1},
    {"start": 31, "end": 50, "min_clues": 56, "max_clues": 60, "max_tier": 2,
     "label": "Intersections", "chapter": 2},
    {"start": 51, "end": 75, "min_clues": 52, "max_clues": 56, "max_tier": 3,
     "label": "Hidden Triples", "chapter": 3},
    {"start": 76, "end": 100, "min_clues": 48, "max_clues": 52, "max_tier": 4,
     "label": "Quads", "chapter": 4},
    {"start": 101, "end": 130, "min_clues": 44, "max_clues": 48, "max_tier": 5,
     "label": "Wings", "chapter": 5},
]


def generate_stage4(output_dir: str, seed: int = 42) -> List[Dict]:
    import json, os
    gen = Classic9x9Generator(seed=seed)
    results = []
    for ch in CAMPAIGN_CHAPTERS:
        for idx in range(ch["start"], ch["end"] + 1):
            level_id = f"campaign_9x9_{idx:04d}"
            result = gen.generate(
                min_clues=ch["min_clues"],
                max_clues=ch["max_clues"],
                max_tier=ch["max_tier"],
                max_attempts=30,
            )
            if result is None:
                print(f"  FAILED {level_id}")
                continue
            result["level_id"] = level_id
            result["stage"] = 4
            result["chapter"] = ch["label"]
            result["level_index"] = idx
            result["difficulty"] = ch["label"]
            result["tier_max"] = ch["max_tier"]
            result["techniques"] = TIER_DEFINITIONS[ch["max_tier"]]
            result["visual_score"] = round(result["clues"] / CELLS, 3)
            result["human_score"] = result["tier_max"]
            result["tutorial"] = idx <= 3
            result["economy"] = {
                "coins": idx * 10,
                "souls": max(1, idx // 5),
                "perfect_bonus": 20,
                "chapter_reward": ch["chapter"] * 100,
                "first_clear": 50 if idx == ch["start"] else 0,
            }
            result["stars"] = {
                "clear": 1,
                "perfect": 2,
                "fast_clear": 3,
            }
            results.append(result)
            os.makedirs(output_dir, exist_ok=True)
            path = os.path.join(output_dir, f"{level_id}.json")
            with open(path, "w") as f:
                json.dump(result, f, indent=2)
            print(f"  {level_id}: clues={result['clues']} tier={result['tier_max']}")
    return results
