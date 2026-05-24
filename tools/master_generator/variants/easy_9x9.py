"""Easy 9x9 dataset generator — 1000 levels with tramo-based technique progression."""

import hashlib
import json
import os
import random
import time
from typing import Dict, List, Optional, Set, Tuple

N = 9
CELLS = 81

# ── Tramo definitions ──────────────────────────────────────────────────────

TRAMO_CONFIG = [
    {"start": 1, "end": 250, "clues": 65, "label": "Tramo 1 — Singles",
     "tech_ids": {"last_blank_cell", "full_house", "naked_single"},
     "techniques": ["LastBlank", "FullHouse", "NakedSingle"],
     "tier_max": 1, "est_minutes": 2},
    {"start": 251, "end": 500, "clues": 63, "label": "Tramo 2 — Hidden Singles",
     "tech_ids": {"last_blank_cell", "full_house", "naked_single", "hidden_single"},
     "techniques": ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle"],
     "tier_max": 1, "est_minutes": 2.5},
    {"start": 501, "end": 750, "clues": 61, "label": "Tramo 3 — Intersections",
     "tech_ids": {"last_blank_cell", "full_house", "naked_single", "hidden_single",
                  "pointing_pair", "pointing_triple"},
     "techniques": ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
                    "PointingPair", "PointingTriple"],
     "tier_max": 2, "est_minutes": 3},
    {"start": 751, "end": 1000, "clues": 60, "label": "Tramo 4 — Box Line",
     "tech_ids": {"last_blank_cell", "full_house", "naked_single", "hidden_single",
                  "pointing_pair", "pointing_triple", "box_line_reduction"},
     "techniques": ["LastBlank", "FullHouse", "NakedSingle", "HiddenSingle",
                    "PointingPair", "PointingTriple", "BoxLineReduction"],
     "tier_max": 2, "est_minutes": 3.5},
]

FORBIDDEN_TECH_IDS = {
    "naked_pair", "hidden_pair", "naked_triple", "hidden_triple",
    "naked_quad", "hidden_quad",
    "xwing", "swordfish", "jellyfish", "xywing", "xyzwing",
    "wwing", "mwing", "swing", "lwing", "hwing", "vwxyzwing", "wxyzwing",
    "unique_rectangle", "hidden_rectangle", "avoidable_rectangle",
    "bug", "simple_coloring", "xcycle", "grouped_xcycle",
    "remote_pairs", "xychain", "twinned_xychain",
    "aic", "grouped_aic", "medusa3d", "continuous_loop",
    "alsxz", "alsxywing", "alschain",
    "finned_fish", "finned_xwing", "finned_swordfish", "finned_jellyfish",
    "sashimi_fish", "empty_rectangle", "sue_de_coq",
    "pattern_overlay", "forcing_chains", "nishio",
    "franken_fish", "mutant_fish", "siamese_fish",
    "exocet", "double_exocet", "skloop", "tridagon",
    "fireworks", "guardians", "borescope_grid", "qwing",
    "gurth_symmetry", "aligned_pair_exclusion", "aligned_triple_exclusion",
    "extended_rectangle", "leviathan", "squidward", "multivalue_xwing",
    "extended_sue_de_coq", "bowmans_bingo",
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


def _build_rotational_groups() -> List[List[Tuple[int, int]]]:
    all_cells = [(r, c) for r in range(9) for c in range(9)]
    used = set()
    groups = []
    for r, c in all_cells:
        if (r, c) in used:
            continue
        pr, pc = _rotational_pair(r, c)
        if (pr, pc) == (r, c):
            groups.append([(r, c)])
            used.add((r, c))
        else:
            groups.append([(r, c), (pr, pc)])
            used.add((r, c))
            used.add((pr, pc))
    return groups


class Easy9x9Generator:
    """Generates easy 9x9 puzzles with tramo-based technique limitation."""

    def __init__(self, seed: Optional[int] = None):
        if seed is not None:
            random.seed(seed)

    def generate_solved(self) -> str:
        from tools.human_solver.generator import PuzzleGenerator
        gen = PuzzleGenerator()
        board = gen.generate_solved()
        return "".join(str(board.get_cell(r, c)) for r in range(N) for c in range(N))

    def generate_one(self, target_clues: int, allowed_tech_ids: Set[str],
                     max_attempts: int = 30) -> Optional[Dict]:
        _set_allowed_techniques(allowed_tech_ids)
        groups = _build_rotational_groups()

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

            # Re-solve with all techniques enabled to get steps/history
            _restore_all()
            solvable2, steps2, history2 = solve_with_techniques(final_puzzle)
            _set_allowed_techniques(allowed_tech_ids)

            return {
                "puzzle": final_puzzle,
                "solution": solved_str,
                "clues": clues,
                "fill_percent": round(clues / 81 * 100, 1),
                "symmetry": "rotational",
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
        "id": f"easy_{idx:04d}",
        "puzzle": puzzle,
        "solution": solution,
        "difficulty": "easy",
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
        "difficulty_label": "Easy",
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


def generate_easy_dataset(output_dir: str, checkpoint_path: str,
                          seed: int = 42) -> List[Dict]:
    os.makedirs(output_dir, exist_ok=True)
    gen = Easy9x9Generator(seed=seed)
    chk = CheckpointManager(checkpoint_path)

    # Resume from checkpoint if exists
    saved = chk.load()
    results: List[Dict] = saved["results"] if saved else []
    generated_ids = {r["id"] for r in results}
    next_index = len(results) + 1 if results else 1

    for tramo in TRAMO_CONFIG:
        for idx in range(tramo["start"], tramo["end"] + 1):
            board_id = f"easy_{idx:04d}"
            if board_id in generated_ids:
                print(f"  {board_id}: already generated, skipping")
                continue

            print(f"  {board_id}: clues={tramo['clues']} techs={len(tramo['tech_ids'])} ...", end="")
            start = time.time()
            result = gen.generate_one(
                target_clues=tramo["clues"],
                allowed_tech_ids=tramo["tech_ids"],
                max_attempts=30,
            )
            elapsed = time.time() - start

            if result is None:
                print(f" FAILED ({elapsed:.1f}s)")
                continue

            entry = _make_board_entry(idx, result, tramo)
            results.append(entry)

            filepath = os.path.join(output_dir, f"{board_id}.json")
            with open(filepath, "w") as f:
                json.dump(entry, f, indent=2)
            print(f" OK ({elapsed:.1f}s)")

            # Checkpoint every 50
            if idx > 0 and idx % 50 == 0:
                chk.save({"results": results})
                print(f"  --- Checkpoint saved ({len(results)} boards)")

    chk.clear()
    _restore_all()
    return results
