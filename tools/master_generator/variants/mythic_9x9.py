"""Mythic 9x9 dataset generator — 500 boards with real technique validation."""

import hashlib
import json
import os
import random
import time
from typing import Dict, List, Optional, Set, Tuple

N = 9
CELLS = 81

# ── Technique display names (matching evil/expert convention) ──────────────
TECH_DISPLAY: Dict[str, List[str]] = {
    "last_blank_cell":       ["LastBlank"],
    "full_house":            ["FullHouse"],
    "naked_single":          ["NakedSingle"],
    "hidden_single":         ["HiddenSingle"],
    "pointing_pair":         ["PointingPair"],
    "pointing_triple":       ["PointingTriple"],
    "box_line_reduction":    ["BoxLineReduction"],
    "naked_pair":            ["NakedPair"],
    "hidden_pair":           ["HiddenPair"],
    "naked_triple":          ["NakedTriple"],
    "hidden_triple":         ["HiddenTriple"],
    "naked_quad":            ["NakedQuad"],
    "hidden_quad":           ["HiddenQuad"],
    "xwing":                 ["XWing"],
    "xywing":                ["XYWing"],
    "xyzwing":               ["XYZWing"],
    "wwing":                 ["WWing"],
    "swordfish":             ["Swordfish"],
    "jellyfish":             ["Jellyfish"],
    "wxyzwing":              ["WXYZWing"],
    "vwxyzwing":             ["VWXYZWing"],
    "unique_rectangle":      ["UniqueRectangle"],
    "hidden_rectangle":      ["HiddenRectangle"],
    "avoidable_rectangle":   ["AvoidableRectangle"],
    "extended_rectangle":    ["ExtendedRectangle"],
    "bug":                   ["BUG+1", "BUG+2"],
    "qwing":                 ["QWing"],
    "empty_rectangle":       ["EmptyRectangle"],
    "finned_xwing":          ["FinnedXWing"],
    "finned_swordfish":      ["FinnedSwordfish"],
    "sashimi_fish":          ["SashimiFish"],
    "simple_coloring":       ["SimpleColoring"],
    "xcycle":                ["XCycle"],
    "remote_pairs":          ["RemotePairs"],
    "xychain":               ["XYChain"],
    "aic":                   ["AIC"],
    "alsxz":                 ["ALSXZ"],
    "alsxywing":             ["ALSXYWing"],
}

# ── Base evil techniques ────────────────────────────────────────────────────
BASE_TECH_IDS: Set[str] = {
    "last_blank_cell", "full_house", "naked_single", "hidden_single",
    "pointing_pair", "pointing_triple", "box_line_reduction",
    "naked_pair", "hidden_pair", "naked_triple", "hidden_triple",
    "naked_quad", "hidden_quad",
    "xwing", "xywing", "xyzwing", "wwing", "swordfish",
    "jellyfish", "wxyzwing", "vwxyzwing",
    "unique_rectangle", "hidden_rectangle", "avoidable_rectangle",
    "extended_rectangle", "bug", "qwing",
    "empty_rectangle",
    "finned_xwing", "finned_swordfish", "sashimi_fish",
}

# ── New technique candidates per tramo (accrued — each adds to previous) ───
TRAMO_NEW_TECHS: List[Set[str]] = [
    set(),                                                             # Tramo 1 — base only
    {"mutant_fish", "franken_fish", "siamese_fish"},                   # Tramo 2 — all downgraded
    {"simple_coloring", "xcycle", "grouped_xcycle", "remote_pairs"},   # Tramo 3 — coloring & cycles
    {"xychain", "twinned_xychain", "aic", "grouped_aic"},              # Tramo 4 — XYChain & AIC
    {"alsxz", "alsxywing", "alschain", "death_blossom"},               # Tramo 5 — ALS
]

TRAMO_CLUE_SPECS: List[Dict] = [
    {"clues": 30,  "label": "Tramo 1 — Exotic Fish",          "tier_max": 7,  "est_minutes": 25},
    {"clues": (28, 29), "label": "Tramo 2 — Advanced Fish (downgraded)", "tier_max": 7, "est_minutes": 30},
    {"clues": (27, 28), "label": "Tramo 3 — Coloring & Chains",         "tier_max": 5, "est_minutes": 35},
    {"clues": (26, 27), "label": "Tramo 4 — AIC & XY-Chains",           "tier_max": 5, "est_minutes": 45},
    {"clues": (24, 26), "label": "Tramo 5 — ALS",                       "tier_max": 6, "est_minutes": 60},
]

FORBIDDEN_TECH_IDS: Set[str] = {
    "exocet", "double_exocet", "skloop", "tridagon",
    "bowmans_bingo", "pattern_overlay", "forcing_chains", "nishio",
    "leviathan", "squidward", "multivalue_xwing",
}

REGISTRY_CACHE = None
ORIGINAL_STATES: Dict[str, bool] = {}
ORIGINAL_ENABLED: Dict[str, bool] = {}

TRAMO_CONFIG: List[Dict] = []


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


def _is_implemented(tech_id: str) -> bool:
    reg = _ensure_registry()
    tech = reg.get(tech_id)
    if tech is None:
        return False
    return bool(tech.implemented)


def _get_effective_techs(tramo_idx: int) -> Tuple[Set[str], List[str]]:
    # Accumulate all new techs from tramo 0 through tramo_idx
    all_new_ids: Set[str] = set()
    downgraded: Set[str] = set()
    for ti in range(tramo_idx + 1):
        for tid in TRAMO_NEW_TECHS[ti]:
            if _is_implemented(tid):
                all_new_ids.add(tid)
            else:
                downgraded.add(tid)

    effective_ids = BASE_TECH_IDS | all_new_ids

    display_list: List[str] = []
    for tid in sorted(effective_ids):
        if tid in TECH_DISPLAY:
            display_list.extend(TECH_DISPLAY[tid])
        elif _is_implemented(tid):
            display_list.append(tid)
    return effective_ids, display_list, downgraded


def _build_tramo_config():
    global TRAMO_CONFIG
    if TRAMO_CONFIG:
        return TRAMO_CONFIG
    for ti in range(5):
        start = ti * 100 + 1
        end = (ti + 1) * 100
        clues_spec = TRAMO_CLUE_SPECS[ti]["clues"]
        label = TRAMO_CLUE_SPECS[ti]["label"]
        tier_max = TRAMO_CLUE_SPECS[ti]["tier_max"]
        est_min = TRAMO_CLUE_SPECS[ti]["est_minutes"]
        tech_ids, techniques, downgraded_set = _get_effective_techs(ti)
        downgraded = sorted(downgraded_set)

        TRAMO_CONFIG.append({
            "start": start,
            "end": end,
            "clues": clues_spec,
            "label": label,
            "tech_ids": tech_ids,
            "techniques": techniques,
            "tier_max": tier_max,
            "est_minutes": est_min,
            "downgraded": downgraded,
        })
    return TRAMO_CONFIG


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


class Mythic9x9Generator:
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
        "id": f"mythic_{idx:04d}",
        "puzzle": puzzle,
        "solution": solution,
        "difficulty": "mythic",
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
        "difficulty_label": "Mythic",
    }


class CheckpointManager:
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
    if seed < 10:
        return "rotational"
    if seed < 20:
        return "mirror"
    return "random"


def _pick_clues_in_range(idx: int, lo: int, hi: int) -> int:
    return lo + ((idx * 3 + 7) % (hi - lo + 1))


def generate_mythic_dataset(output_dir: str, checkpoint_path: str,
                            seed: int = 42) -> List[Dict]:
    _build_tramo_config()
    os.makedirs(output_dir, exist_ok=True)
    gen = Mythic9x9Generator(seed=seed)
    chk = CheckpointManager(checkpoint_path)

    saved = chk.load()
    results: List[Dict] = saved["results"] if saved else []
    generated_ids = {r["id"] for r in results}

    # also scan output dir for existing boards (catches orphaned files / missing checkpoint)
    if os.path.isdir(output_dir):
        for fname in sorted(os.listdir(output_dir)):
            if fname.endswith(".json") and fname.startswith("mythic_"):
                bid = fname.replace(".json", "")
                generated_ids.add(bid)
    max_attempts = 30
    downgrade_log: List[str] = []

    for tramo in TRAMO_CONFIG:
        for idx in range(tramo["start"], tramo["end"] + 1):
            board_id = f"mythic_{idx:04d}"
            if board_id in generated_ids:
                print(f"  {board_id}: already generated, skipping")
                continue

            clues_spec = tramo["clues"]
            if isinstance(clues_spec, tuple):
                clues = _pick_clues_in_range(idx, clues_spec[0], clues_spec[1])
            else:
                clues = clues_spec

            sym = _pick_symmetry(idx)
            # symmetric boards at low clues (≤26) are extremely slow — use 27 for valid results
            if sym in ("rotational", "mirror") and isinstance(clues_spec, tuple) and clues_spec[1] <= 26:
                clues = 27
                if sym == "rotational" and clues % 2 == 0:
                    clues -= 1
            tech_count = len(tramo["tech_ids"])
            downgraded = tramo.get("downgraded", [])
            downgrade_info = f" (downgrade: {downgraded})" if downgraded else ""
            print(f"  {board_id}: clues={clues} techs={tech_count}{downgrade_info} {sym} ...", end="")
            start_time = time.time()

            sym_attempts = max_attempts * 2 if sym in ("rotational", "mirror") else max_attempts
            result = gen.generate_one(
                target_clues=clues,
                allowed_tech_ids=tramo["tech_ids"],
                sym_type=sym,
                max_attempts=sym_attempts,
            )
            elapsed = time.time() - start_time

            if result is None:
                print(f" FAILED ({elapsed:.1f}s)")
                continue

            entry = _make_board_entry(idx, result, tramo)
            results.append(entry)

            filepath = os.path.join(output_dir, f"{board_id}.json")
            with open(filepath, "w") as f:
                json.dump(entry, f, indent=2)
            actual_clues = result["clues"]
            tag = f" ({actual_clues}c)" if actual_clues != clues else ""
            print(f" OK{tag} ({elapsed:.1f}s)")

            if idx > 0 and idx % 10 == 0:
                chk.save({"results": results})
                print(f"  --- Checkpoint saved ({len(results)} boards)")

            if downgraded and downgrade_info not in downgrade_log:
                downgrade_log.append(f"Tramo {tramo['start']}: {', '.join(downgraded)} not implemented — downgraded")

    chk.clear()
    _restore_all()
    return results, downgrade_log
