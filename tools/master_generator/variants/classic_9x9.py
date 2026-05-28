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
    6: {"last_blank_cell", "full_house", "naked_single", "hidden_single",
        "pointing_pair", "pointing_triple", "box_line_reduction",
        "naked_pair", "hidden_pair",
        "naked_triple", "hidden_triple",
        "naked_quad", "hidden_quad",
        "xwing", "xywing", "swordfish", "xyzwing", "wwing",
        "simple_coloring"},
    7: {"last_blank_cell", "full_house", "naked_single", "hidden_single",
        "pointing_pair", "pointing_triple", "box_line_reduction",
        "naked_pair", "hidden_pair",
        "naked_triple", "hidden_triple",
        "naked_quad", "hidden_quad",
        "xwing", "xywing", "swordfish", "xyzwing", "wwing",
        "simple_coloring",
        "jellyfish", "wxyzwing", "unique_rectangle", "hidden_rectangle", "bug"},
    8: {"last_blank_cell", "full_house", "naked_single", "hidden_single",
        "pointing_pair", "pointing_triple", "box_line_reduction",
        "naked_pair", "hidden_pair",
        "naked_triple", "hidden_triple",
        "naked_quad", "hidden_quad",
        "xwing", "xywing", "swordfish", "xyzwing", "wwing",
        "simple_coloring",
        "jellyfish", "wxyzwing", "unique_rectangle", "hidden_rectangle", "bug",
        "remote_pairs", "empty_rectangle", "finned_fish", "alsxz"},
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
    6: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
        "PointingPair", "PointingTriple", "BoxLineReduction",
        "NakedPair", "HiddenPair",
        "NakedTriple", "HiddenTriple",
        "NakedQuad", "HiddenQuad",
        "XWing", "XYWing", "Swordfish", "XYZWing", "WWing",
        "SimpleColoring"],
    7: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
        "PointingPair", "PointingTriple", "BoxLineReduction",
        "NakedPair", "HiddenPair",
        "NakedTriple", "HiddenTriple",
        "NakedQuad", "HiddenQuad",
        "XWing", "XYWing", "Swordfish", "XYZWing", "WWing",
        "SimpleColoring",
        "Jellyfish", "WXYZWing", "UniqueRectangle", "HiddenRectangle", "BUG"],
    8: ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
        "PointingPair", "PointingTriple", "BoxLineReduction",
        "NakedPair", "HiddenPair",
        "NakedTriple", "HiddenTriple",
        "NakedQuad", "HiddenQuad",
        "XWing", "XYWing", "Swordfish", "XYZWing", "WWing",
        "SimpleColoring",
        "Jellyfish", "WXYZWing", "UniqueRectangle", "HiddenRectangle", "BUG",
        "RemotePairs", "EmptyRectangle", "FinnedFish", "ALSXZ"],
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


# ── Stage 5 (Beginner Journey) — 100 levels, tier 1→3 ──────────────────────

CAMPAIGN_STAGE5_CHAPTERS = [
    {"start": 1, "end": 20, "min_clues": 56, "max_clues": 60, "max_tier": 1, "label": "Singles", "chapter": 1},
    {"start": 21, "end": 40, "min_clues": 54, "max_clues": 58, "max_tier": 2, "label": "Intersections", "chapter": 2},
    {"start": 41, "end": 60, "min_clues": 52, "max_clues": 56, "max_tier": 2, "label": "Pairs", "chapter": 3},
    {"start": 61, "end": 80, "min_clues": 50, "max_clues": 54, "max_tier": 3, "label": "Hidden Pairs", "chapter": 4},
    {"start": 81, "end": 100, "min_clues": 48, "max_clues": 52, "max_tier": 3, "label": "Triples", "chapter": 5},
]


def generate_stage5(output_dir: str, seed: int = 42) -> List[Dict]:
    gen = Classic9x9Generator(seed=seed)
    results = []
    for ch in CAMPAIGN_STAGE5_CHAPTERS:
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
            result["stage"] = 5
            result["chapter"] = ch["label"]
            result["level_index"] = idx
            result["difficulty"] = "beginner"
            result["tier_max"] = ch["max_tier"]
            result["techniques"] = TIER_DEFINITIONS[ch["max_tier"]]
            result["visual_score"] = round(result["clues"] / CELLS, 3)
            result["human_score"] = result["tier_max"]
            result["economy"] = {"coins": idx * 10, "souls": max(1, idx // 5), "perfect_bonus": 50}
            result["stars"] = {"clear": 1, "perfect": 2, "fast_clear": 3}
            results.append(result)
            os.makedirs(output_dir, exist_ok=True)
            path = os.path.join(output_dir, f"{level_id}.json")
            with open(path, "w") as f:
                json.dump(result, f, indent=2)
            print(f"  {level_id}: clues={result['clues']} tier={result['tier_max']}")
    return results


# ── Stage 6 (Intermedio 9×9) — 100 levels, tier 2→4 ────────────────────────

CAMPAIGN_STAGE6_CHAPTERS = [
    {"start": 1, "end": 20, "min_clues": 52, "max_clues": 56, "max_tier": 2, "label": "Pairs", "chapter": 1},
    {"start": 21, "end": 40, "min_clues": 50, "max_clues": 54, "max_tier": 3, "label": "Triples", "chapter": 2},
    {"start": 41, "end": 60, "min_clues": 48, "max_clues": 52, "max_tier": 3, "label": "Hidden Triples", "chapter": 3},
    {"start": 61, "end": 80, "min_clues": 46, "max_clues": 50, "max_tier": 4, "label": "Quads", "chapter": 4},
    {"start": 81, "end": 100, "min_clues": 44, "max_clues": 48, "max_tier": 4, "label": "XWing", "chapter": 5},
]


def generate_stage6(output_dir: str, seed: int = 42) -> List[Dict]:
    gen = Classic9x9Generator(seed=seed)
    results = []
    for ch in CAMPAIGN_STAGE6_CHAPTERS:
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
            result["stage"] = 6
            result["chapter"] = ch["label"]
            result["level_index"] = idx
            result["difficulty"] = "intermediate"
            result["tier_max"] = ch["max_tier"]
            result["techniques"] = TIER_DEFINITIONS[ch["max_tier"]]
            result["visual_score"] = round(result["clues"] / CELLS, 3)
            result["human_score"] = result["tier_max"]
            result["economy"] = {"coins": idx * 15, "souls": max(1, idx // 4), "perfect_bonus": 75}
            result["stars"] = {"clear": 1, "perfect": 2, "fast_clear": 3}
            results.append(result)
            os.makedirs(output_dir, exist_ok=True)
            path = os.path.join(output_dir, f"{level_id}.json")
            with open(path, "w") as f:
                json.dump(result, f, indent=2)
            print(f"  {level_id}: clues={result['clues']} tier={result['tier_max']}")
    return results


# ── Stage 7 (Avanzado 9×9) — 100 levels, tier 3→5 ──────────────────────────

CAMPAIGN_STAGE7_CHAPTERS = [
    {"start": 1, "end": 20, "min_clues": 48, "max_clues": 52, "max_tier": 3, "label": "Triples", "chapter": 1},
    {"start": 21, "end": 40, "min_clues": 46, "max_clues": 50, "max_tier": 4, "label": "XWing", "chapter": 2},
    {"start": 41, "end": 60, "min_clues": 44, "max_clues": 48, "max_tier": 4, "label": "XYWing", "chapter": 3},
    {"start": 61, "end": 80, "min_clues": 42, "max_clues": 46, "max_tier": 5, "label": "Quads XWing", "chapter": 4},
    {"start": 81, "end": 100, "min_clues": 40, "max_clues": 44, "max_tier": 5, "label": "Swordfish", "chapter": 5},
]


def generate_stage7(output_dir: str, seed: int = 42) -> List[Dict]:
    gen = Classic9x9Generator(seed=seed)
    results = []
    for ch in CAMPAIGN_STAGE7_CHAPTERS:
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
            result["stage"] = 7
            result["chapter"] = ch["label"]
            result["level_index"] = idx
            result["difficulty"] = "hard"
            result["tier_max"] = ch["max_tier"]
            result["techniques"] = TIER_DEFINITIONS[ch["max_tier"]]
            result["visual_score"] = round(result["clues"] / CELLS, 3)
            result["human_score"] = result["tier_max"]
            result["economy"] = {"coins": idx * 20, "souls": max(1, idx // 3), "perfect_bonus": 100}
            result["stars"] = {"clear": 1, "perfect": 2, "fast_clear": 3}
            results.append(result)
            os.makedirs(output_dir, exist_ok=True)
            path = os.path.join(output_dir, f"{level_id}.json")
            with open(path, "w") as f:
                json.dump(result, f, indent=2)
            print(f"  {level_id}: clues={result['clues']} tier={result['tier_max']}")
    return results


# ── Stage 8 (Experto) — 100 levels, tier 4→6 ────────────────────────────────

CAMPAIGN_STAGE8_CHAPTERS = [
    {"start": 1, "end": 20, "min_clues": 42, "max_clues": 46, "max_tier": 4, "label": "XWing", "chapter": 1},
    {"start": 21, "end": 40, "min_clues": 40, "max_clues": 44, "max_tier": 5, "label": "XYWing", "chapter": 2},
    {"start": 41, "end": 60, "min_clues": 38, "max_clues": 42, "max_tier": 5, "label": "Swordfish", "chapter": 3},
    {"start": 61, "end": 80, "min_clues": 36, "max_clues": 40, "max_tier": 6, "label": "Coloring", "chapter": 4},
    {"start": 81, "end": 100, "min_clues": 34, "max_clues": 38, "max_tier": 6, "label": "Wings", "chapter": 5},
]


def generate_stage8(output_dir: str, seed: int = 42) -> List[Dict]:
    gen = Classic9x9Generator(seed=seed)
    results = []
    for ch in CAMPAIGN_STAGE8_CHAPTERS:
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
            result["stage"] = 8
            result["chapter"] = ch["label"]
            result["level_index"] = idx
            result["difficulty"] = "expert"
            result["tier_max"] = ch["max_tier"]
            result["techniques"] = TIER_DEFINITIONS[ch["max_tier"]]
            result["visual_score"] = round(result["clues"] / CELLS, 3)
            result["human_score"] = result["tier_max"]
            result["economy"] = {"coins": idx * 25, "souls": max(1, idx // 3), "perfect_bonus": 150}
            result["stars"] = {"clear": 1, "perfect": 2, "fast_clear": 3}
            results.append(result)
            os.makedirs(output_dir, exist_ok=True)
            path = os.path.join(output_dir, f"{level_id}.json")
            with open(path, "w") as f:
                json.dump(result, f, indent=2)
            print(f"  {level_id}: clues={result['clues']} tier={result['tier_max']}")
    return results


# ── Stage 9 (Malvado) — 100 levels, tier 5→7 ────────────────────────────────

CAMPAIGN_STAGE9_CHAPTERS = [
    {"start": 1, "end": 20, "min_clues": 36, "max_clues": 40, "max_tier": 5, "label": "Wings", "chapter": 1},
    {"start": 21, "end": 40, "min_clues": 34, "max_clues": 38, "max_tier": 6, "label": "Coloring", "chapter": 2},
    {"start": 41, "end": 60, "min_clues": 32, "max_clues": 36, "max_tier": 6, "label": "Inferred", "chapter": 3},
    {"start": 61, "end": 80, "min_clues": 30, "max_clues": 34, "max_tier": 7, "label": "Uniqueness", "chapter": 4},
    {"start": 81, "end": 100, "min_clues": 28, "max_clues": 32, "max_tier": 7, "label": "Jellyfish", "chapter": 5},
]


def generate_stage9(output_dir: str, seed: int = 42) -> List[Dict]:
    gen = Classic9x9Generator(seed=seed)
    results = []
    for ch in CAMPAIGN_STAGE9_CHAPTERS:
        for idx in range(ch["start"], ch["end"] + 1):
            level_id = f"campaign_9x9_{idx:04d}"
            result = gen.generate(
                min_clues=ch["min_clues"],
                max_clues=ch["max_clues"],
                max_tier=ch["max_tier"],
                max_attempts=40,
            )
            if result is None:
                print(f"  FAILED {level_id}")
                continue
            result["level_id"] = level_id
            result["stage"] = 9
            result["chapter"] = ch["label"]
            result["level_index"] = idx
            result["difficulty"] = "evil"
            result["tier_max"] = ch["max_tier"]
            result["techniques"] = TIER_DEFINITIONS[ch["max_tier"]]
            result["visual_score"] = round(result["clues"] / CELLS, 3)
            result["human_score"] = result["tier_max"]
            result["economy"] = {"coins": idx * 30, "souls": max(2, idx // 2), "perfect_bonus": 200}
            result["stars"] = {"clear": 1, "perfect": 2, "fast_clear": 3}
            results.append(result)
            os.makedirs(output_dir, exist_ok=True)
            path = os.path.join(output_dir, f"{level_id}.json")
            with open(path, "w") as f:
                json.dump(result, f, indent=2)
            print(f"  {level_id}: clues={result['clues']} tier={result['tier_max']}")
    return results


# ── Stage 10 (Mítico) — 50 levels, tier 6→8 ─────────────────────────────────

CAMPAIGN_STAGE10_CHAPTERS = [
    {"start": 1, "end": 10, "min_clues": 30, "max_clues": 34, "max_tier": 6, "label": "Expert", "chapter": 1},
    {"start": 11, "end": 20, "min_clues": 28, "max_clues": 32, "max_tier": 7, "label": "Extreme", "chapter": 2},
    {"start": 21, "end": 30, "min_clues": 26, "max_clues": 30, "max_tier": 7, "label": "Uniqueness", "chapter": 3},
    {"start": 31, "end": 40, "min_clues": 24, "max_clues": 28, "max_tier": 8, "label": "ALS", "chapter": 4},
    {"start": 41, "end": 50, "min_clues": 22, "max_clues": 26, "max_tier": 8, "label": "Mythic", "chapter": 5},
]


def generate_stage10(output_dir: str, seed: int = 42) -> List[Dict]:
    gen = Classic9x9Generator(seed=seed)
    results = []
    for ch in CAMPAIGN_STAGE10_CHAPTERS:
        for idx in range(ch["start"], ch["end"] + 1):
            level_id = f"campaign_9x9_{idx:04d}"
            result = gen.generate(
                min_clues=ch["min_clues"],
                max_clues=ch["max_clues"],
                max_tier=ch["max_tier"],
                max_attempts=50,
            )
            if result is None:
                print(f"  FAILED {level_id}")
                continue
            result["level_id"] = level_id
            result["stage"] = 10
            result["chapter"] = ch["label"]
            result["level_index"] = idx
            result["difficulty"] = "mythic"
            result["tier_max"] = ch["max_tier"]
            result["techniques"] = TIER_DEFINITIONS[ch["max_tier"]]
            result["visual_score"] = round(result["clues"] / CELLS, 3)
            result["human_score"] = result["tier_max"]
            result["economy"] = {"coins": idx * 40, "souls": max(2, idx), "perfect_bonus": 500}
            result["stars"] = {"clear": 1, "perfect": 2, "fast_clear": 3}
            results.append(result)
            os.makedirs(output_dir, exist_ok=True)
            path = os.path.join(output_dir, f"{level_id}.json")
            with open(path, "w") as f:
                json.dump(result, f, indent=2)
            print(f"  {level_id}: clues={result['clues']} tier={result['tier_max']}")
    return results
