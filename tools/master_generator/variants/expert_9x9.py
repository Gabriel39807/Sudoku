"""Expert 9x9 dataset generator — 1000 levels with tramo-based technique progression."""

import hashlib
import json
import os
import random
import time
from typing import Dict, List, Optional, Set, Tuple

N = 9
CELLS = 81

TRAMO_CONFIG = [
    {"start": 1, "end": 200, "clues": 44, "label": "Tramo 1 — XWing",
     "tech_ids": {"last_blank_cell", "full_house", "naked_single", "hidden_single",
                  "pointing_pair", "pointing_triple", "box_line_reduction",
                  "naked_pair", "hidden_pair", "naked_triple", "hidden_triple",
                  "naked_quad", "hidden_quad", "xwing"},
     "techniques": ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
                    "PointingPair", "PointingTriple", "BoxLineReduction",
                    "NakedPair", "HiddenPair", "NakedTriple", "HiddenTriple",
                    "NakedQuad", "HiddenQuad", "XWing"],
     "tier_max": 4, "est_minutes": 8},
    {"start": 201, "end": 400, "clues": 42, "label": "Tramo 2 — XYWing",
     "tech_ids": {"last_blank_cell", "full_house", "naked_single", "hidden_single",
                  "pointing_pair", "pointing_triple", "box_line_reduction",
                  "naked_pair", "hidden_pair", "naked_triple", "hidden_triple",
                  "naked_quad", "hidden_quad", "xwing", "xywing"},
     "techniques": ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
                    "PointingPair", "PointingTriple", "BoxLineReduction",
                    "NakedPair", "HiddenPair", "NakedTriple", "HiddenTriple",
                    "NakedQuad", "HiddenQuad", "XWing", "XYWing"],
     "tier_max": 4, "est_minutes": 9},
    {"start": 401, "end": 600, "clues": 41, "label": "Tramo 3 — XYZWing / WWing",
     "tech_ids": {"last_blank_cell", "full_house", "naked_single", "hidden_single",
                  "pointing_pair", "pointing_triple", "box_line_reduction",
                  "naked_pair", "hidden_pair", "naked_triple", "hidden_triple",
                  "naked_quad", "hidden_quad", "xwing", "xywing",
                  "xyzwing", "wwing"},
     "techniques": ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
                    "PointingPair", "PointingTriple", "BoxLineReduction",
                    "NakedPair", "HiddenPair", "NakedTriple", "HiddenTriple",
                    "NakedQuad", "HiddenQuad", "XWing", "XYWing",
                    "XYZWing", "WWing"],
     "tier_max": 4, "est_minutes": 10},
    {"start": 601, "end": 800, "clues": 40, "label": "Tramo 4 — Swordfish",
     "tech_ids": {"last_blank_cell", "full_house", "naked_single", "hidden_single",
                  "pointing_pair", "pointing_triple", "box_line_reduction",
                  "naked_pair", "hidden_pair", "naked_triple", "hidden_triple",
                  "naked_quad", "hidden_quad", "xwing", "xywing",
                  "xyzwing", "wwing", "swordfish"},
     "techniques": ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
                    "PointingPair", "PointingTriple", "BoxLineReduction",
                    "NakedPair", "HiddenPair", "NakedTriple", "HiddenTriple",
                    "NakedQuad", "HiddenQuad", "XWing", "XYWing",
                    "XYZWing", "WWing", "Swordfish"],
     "tier_max": 5, "est_minutes": 12},
    {"start": 801, "end": 1000, "clues": 0, "label": "Tramo 5 — Jellyfish / WXYZWing",
     "tech_ids": {"last_blank_cell", "full_house", "naked_single", "hidden_single",
                  "pointing_pair", "pointing_triple", "box_line_reduction",
                  "naked_pair", "hidden_pair", "naked_triple", "hidden_triple",
                  "naked_quad", "hidden_quad", "xwing", "xywing",
                  "xyzwing", "wwing", "swordfish", "jellyfish", "wxyzwing"},
     "techniques": ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
                    "PointingPair", "PointingTriple", "BoxLineReduction",
                    "NakedPair", "HiddenPair", "NakedTriple", "HiddenTriple",
                    "NakedQuad", "HiddenQuad", "XWing", "XYWing",
                    "XYZWing", "WWing", "Swordfish", "Jellyfish", "WXYZWing"],
     "tier_max": 5, "est_minutes": 14},
]

FORBIDDEN_TECH_IDS = {
    # Chains / AIC
    "aic", "grouped_aic", "medusa3d", "continuous_loop",
    "xcycle", "grouped_xcycle", "xychain", "twinned_xychain",
    "remote_pairs", "simple_coloring",
    # ALS
    "alsxz", "alsxywing", "alschain",
    # Uniqueness
    "unique_rectangle", "hidden_rectangle", "avoidable_rectangle", "bug",
    # Exotic fish
    "finned_fish", "finned_xwing", "finned_swordfish", "finned_jellyfish",
    "sashimi_fish", "franken_fish", "mutant_fish", "siamese_fish",
    "empty_rectangle", "sue_de_coq", "extended_sue_de_coq",
    "exocet", "double_exocet", "skloop", "tridagon",
    # Exotic wings (not used in this progression)
    "mwing", "swing", "lwing", "hwing", "vwxyzwing",
    # Other advanced
    "pattern_overlay", "forcing_chains", "nishio",
    "fireworks", "guardians", "borescope_grid", "qwing",
    "gurth_symmetry", "aligned_pair_exclusion", "aligned_triple_exclusion",
    "extended_rectangle", "leviathan", "squidward", "multivalue_xwing",
    "bowmans_bingo",
}

REGISTRY_CACHE = None
ORIGINAL_STATES: Dict[str, bool] = {}
ORIGINAL_ENABLED: Dict[str, bool] = {}


def _ensure_registry():
    global REGISTRY_CACHE, ORIGINAL_STATES, ORIGINAL_ENABLED
    if REGISTRY_CACHE is not None:
        return REGISTRY_CACHE
    from tools.human_solver.registry import Registry
    from tools.human_solver.pipeline import Pipeline
    REGISTRY_CACHE = Registry.instance()
    if REGISTRY_CACHE.count() == 0:
        Pipeline()
    for tid, tech in REGISTRY_CACHE._techniques.items():
        ORIGINAL_STATES[tid] = tech.implemented
        ORIGINAL_ENABLED[tid] = tech.enabled
    return REGISTRY_CACHE


def _set_allowed_techniques(allowed: Set[str]):
    reg = _ensure_registry()
    for tid, tech in reg._techniques.items():
        if tid in allowed:
            tech.implemented = True
            tech.enabled = True
        else:
            tech.implemented = False
            tech.enabled = False


def _restore_all():
    global REGISTRY_CACHE
    if REGISTRY_CACHE is None:
        return
    for tid, tech in REGISTRY_CACHE._techniques.items():
        if tid in ORIGINAL_STATES:
            tech.implemented = ORIGINAL_STATES[tid]
            tech.enabled = ORIGINAL_ENABLED[tid]


def solve_with_techniques(puzzle_81: str) -> Tuple[bool, int, List[Dict]]:
    from tools.human_solver.board import Board
    from tools.human_solver.pipeline import Pipeline
    board = Board.from_string(puzzle_81.replace("0", "."))
    pipeline = Pipeline()
    solved, final_board = pipeline.solve(board)
    steps = len(pipeline.explainer.steps)
    history = pipeline.explainer.to_dict()
    return solved, steps, history


def has_unique_solution(puzzle_81: str) -> bool:
    from tools.human_solver.uniqueness import has_unique_solution as _check
    return _check(puzzle_81.replace("0", "."))


def _rotational_pair(r: int, c: int) -> Tuple[int, int]:
    return (8 - r, 8 - c)


def _mirror_pair(r: int, c: int) -> Tuple[int, int]:
    return (r, 8 - c)


def _build_symmetry_groups(sym_type: str) -> List[List[Tuple[int, int]]]:
    if sym_type == "random":
        return [[(r, c)] for r in range(9) for c in range(9)]
    pair_fn = _rotational_pair if sym_type == "rotational" else _mirror_pair
    all_cells = [(r, c) for r in range(9) for c in range(9)]
    used = set()
    groups = []
    for r, c in all_cells:
        if (r, c) in used:
            continue
        pr, pc = pair_fn(r, c)
        if (pr, pc) == (r, c):
            groups.append([(r, c)])
            used.add((r, c))
        else:
            groups.append([(r, c), (pr, pc)])
            used.add((r, c))
            used.add((pr, pc))
    return groups


class Expert9x9Generator:
    """Generates expert 9x9 puzzles with tramo-based technique limitation."""

    def __init__(self, seed: Optional[int] = None):
        if seed is not None:
            random.seed(seed)

    def generate_solved(self) -> str:
        from tools.human_solver.generator import PuzzleGenerator
        gen = PuzzleGenerator()
        board = gen.generate_solved()
        return "".join(str(board.get_cell(r, c)) for r in range(N) for c in range(N))

    def generate_one(self, target_clues: int, allowed_tech_ids: Set[str],
                     sym_type: str = "rotational",
                     max_attempts: int = 30) -> Optional[Dict]:
        _set_allowed_techniques(allowed_tech_ids)
        groups = _build_symmetry_groups(sym_type)

        for _ in range(max_attempts):
            solved_str = self.generate_solved()
            grid = [[int(solved_str[r * 9 + c]) for c in range(9)] for r in range(9)]
            random.shuffle(groups)
            removed = 0

            for group in groups:
                vals = [grid[r][c] for r, c in group]
                for r, c in group:
                    grid[r][c] = 0
                puzzle_str = "".join(str(grid[r][c]) for r in range(9) for c in range(9))

                solvable, steps, history = solve_with_techniques(puzzle_str)
                unique = has_unique_solution(puzzle_str)

                if solvable and unique:
                    removed += len(group)
                    if CELLS - removed <= target_clues:
                        break
                else:
                    for (r, c), v in zip(group, vals):
                        grid[r][c] = v

            clues = CELLS - removed
            if clues != target_clues:
                continue

            final_puzzle = "".join(str(grid[r][c]) for r in range(9) for c in range(9))
            if not has_unique_solution(final_puzzle):
                continue

            _restore_all()
            solvable2, steps2, history2 = solve_with_techniques(final_puzzle)
            _set_allowed_techniques(allowed_tech_ids)

            return {
                "puzzle": final_puzzle,
                "solution": solved_str,
                "clues": clues,
                "fill_percent": round(clues / 81 * 100, 1),
                "symmetry": sym_type,
                "steps": steps2,
                "technique_history": history2,
            }

        return None


def _compute_hash(puzzle_str: str) -> str:
    return hashlib.sha256(puzzle_str.encode()).hexdigest()[:16]


def _make_board_entry(idx: int, gen_result: Dict, tramo: Dict) -> Dict:
    puzzle = gen_result["puzzle"]
    solution = gen_result["solution"]
    h = _compute_hash(puzzle)
    return {
        "id": f"expert_{idx:04d}",
        "puzzle": puzzle,
        "solution": solution,
        "difficulty": "expert",
        "clues": gen_result["clues"],
        "fill_percent": gen_result["fill_percent"],
        "symmetry": gen_result["symmetry"],
        "techniques": list(tramo["techniques"]),
        "steps": gen_result["steps"],
        "hash": h,
        "checksum": h,
        "human_score": tramo["tier_max"],
        "visual_score": round(gen_result["clues"] / 81, 3),
        "tier_max": tramo["tier_max"],
        "estimated_time_minutes": tramo["est_minutes"],
        "tramo": tramo["start"],
        "level_index": idx,
        "difficulty_label": "Expert",
    }


class CheckpointManager:
    """Checkpoint/resume for batch generation."""

    def __init__(self, path: str):
        self.path = path

    def save(self, data: Dict):
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        with open(self.path, "w") as f:
            json.dump(data, f, indent=2)

    def load(self) -> Optional[Dict]:
        if not os.path.exists(self.path):
            return None
        with open(self.path) as f:
            return json.load(f)

    def clear(self):
        if os.path.exists(self.path):
            os.remove(self.path)


def _pick_symmetry(idx: int) -> str:
    seed = (idx * 7 + 13) % 100
    if seed < 40:
        return "rotational"
    if seed < 70:
        return "mirror"
    return "random"


def _pick_clues_tramo5(idx: int) -> int:
    return 39 if idx <= 900 else 38


def generate_expert_dataset(output_dir: str, checkpoint_path: str,
                            seed: int = 42) -> List[Dict]:
    os.makedirs(output_dir, exist_ok=True)
    gen = Expert9x9Generator(seed=seed)
    chk = CheckpointManager(checkpoint_path)

    saved = chk.load()
    results: List[Dict] = saved["results"] if saved else []
    generated_ids = {r["id"] for r in results}
    next_index = len(results) + 1 if results else 1

    for tramo in TRAMO_CONFIG:
        for idx in range(tramo["start"], tramo["end"] + 1):
            board_id = f"expert_{idx:04d}"
            if board_id in generated_ids:
                print(f"  {board_id}: already generated, skipping")
                continue

            clues = _pick_clues_tramo5(idx) if tramo["clues"] == 0 else tramo["clues"]
            sym = _pick_symmetry(idx)
            print(f"  {board_id}: clues={clues} techs={len(tramo['tech_ids'])} {sym} ...", end="")
            start_time = time.time()
            result = gen.generate_one(
                target_clues=clues,
                allowed_tech_ids=tramo["tech_ids"],
                sym_type=sym,
                max_attempts=30,
            )
            elapsed = time.time() - start_time

            if result is None:
                print(f" FAILED ({elapsed:.1f}s)")
                continue

            # Override clue-dependent fields with actual values
            tramo_effective = dict(tramo)
            if tramo["clues"] == 0:
                tramo_effective["clues"] = clues
            entry = _make_board_entry(idx, result, tramo_effective)
            results.append(entry)

            filepath = os.path.join(output_dir, f"{board_id}.json")
            with open(filepath, "w") as f:
                json.dump(entry, f, indent=2)
            print(f" OK ({elapsed:.1f}s)")

            if idx > 0 and idx % 25 == 0:
                chk.save({"results": results})
                print(f"  --- Checkpoint saved ({len(results)} boards)")

    chk.clear()
    _restore_all()
    return results
