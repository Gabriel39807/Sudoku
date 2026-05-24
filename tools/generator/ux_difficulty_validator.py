"""
FASE 5 — UX Difficulty Validator
Valida que los boards generados cumplan criterios de experiencia de usuario.
"""
from __future__ import annotations

import json
import os
import sys
from typing import Any, Dict, List

from classify_by_techniques import classify_by_techniques
from difficulty_profiles import get_profile
from export import puzzle_hash
from human_solver import solve_human
from validator_final import to_grid, validate_board

BOARDS_DIR = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "..", "flutter_app", "assets", "boards"
))

# Seconds per empty cell based on difficulty (accounts for visual scan + placement)
SECONDS_PER_CELL = {
    "easy": 8,
    "intermediate": 10,
    "hard": 18,
}

TIME_TARGETS = {
    "easy": (120, 240),
    "intermediate": (240, 420),
    "hard": (480, 900),
}

TECHNIQUE_LEVEL: dict[str, int] = {
    "naked_single": 1, "hidden_single": 1,
    "naked_pair": 2, "hidden_pair": 2,
    "naked_triple": 2, "hidden_triple": 2,
    "pointing_pair": 3, "box_line_reduction": 3,
    "xwing": 4, "swordfish": 4, "xywing": 5, "forcing_chain": 6,
}


def _estimate_time(techniques: List[str], empties: int, difficulty: str) -> float:
    secs_per = SECONDS_PER_CELL.get(difficulty, 10)
    return empties * secs_per


def _count_clues(puzzle_str: str) -> int:
    return sum(1 for ch in puzzle_str if ch != "0")


def _max_tech_level(techniques: List[str]) -> int:
    return max((TECHNIQUE_LEVEL.get(t, 0) for t in techniques), default=0)


def validate_ux(difficulty: str) -> Dict[str, Any]:
    diff_dir = os.path.join(BOARDS_DIR, difficulty)
    if not os.path.isdir(diff_dir):
        return {"valid": False, "error": f"directory not found: {diff_dir}"}

    profile = get_profile(difficulty)
    min_c = profile.get("min_clues", 0)
    max_c = profile.get("max_clues", 81)
    time_lo, time_hi = TIME_TARGETS.get(difficulty, (0, 9999))
    target_level = {"easy": 1, "intermediate": 2, "hard": 3}.get(difficulty, 1)

    results: List[Dict[str, Any]] = []
    clue_outside = 0
    time_outside = 0
    level_below = 0
    class_mismatch = 0
    total = 0
    xwing_count = 0

    for name in sorted(os.listdir(diff_dir)):
        if not name.endswith(".json"):
            continue
        path = os.path.join(diff_dir, name)
        with open(path, encoding="utf-8") as f:
            data = json.load(f)

        puzzle_str = data.get("puzzle", "")
        clues = _count_clues(puzzle_str)

        # Validate basic integrity
        v = validate_board(puzzle_str, data.get("solution"), difficulty)
        if not v["valid"]:
            results.append({
                "file": name,
                "valid": False,
                "errors": v["errors"],
            })
            continue

        techniques = v["techniques"]
        steps = v["steps"]
        level = _max_tech_level(techniques)
        empties = 81 - clues
        est_time = _estimate_time(techniques, empties, difficulty)
        cls = classify_by_techniques(techniques)

        # UX checks
        issues: List[str] = []

        if clues < min_c or clues > max_c:
            issues.append(f"clues {clues} outside [{min_c}, {max_c}]")
            clue_outside += 1

        if est_time < time_lo or est_time > time_hi:
            issues.append(f"est_time {est_time}s outside [{time_lo}, {time_hi}]")
            time_outside += 1

        if level < target_level:
            issues.append(f"max technique level {level} below target {target_level}")
            level_below += 1

        if cls != difficulty:
            issues.append(f"classification mismatch: got {cls}, expected {difficulty}")
            class_mismatch += 1

        if difficulty == "hard" and "xwing" in techniques:
            xwing_count += 1

        results.append({
            "file": name,
            "valid": len(issues) == 0,
            "clues": clues,
            "steps": steps,
            "max_level": level,
            "est_time_sec": est_time,
            "classification": cls,
            "techniques": techniques,
            "issues": issues,
        })
        total += 1

    total_valid = sum(1 for r in results if r["valid"])
    xwing_pct = round(xwing_count / total * 100, 1) if total else 0

    report = {
        "difficulty": difficulty,
        "total": total,
        "valid": total_valid,
        "invalid": total - total_valid,
        "clue_outside_range": clue_outside,
        "time_outside_range": time_outside,
        "level_below_target": level_below,
        "classification_mismatch": class_mismatch,
        "xwing_pct": xwing_pct,
        "xwing_max_ok": xwing_pct <= 5.0,
        "details": results,
    }
    return report


def validate_all() -> Dict[str, Any]:
    reports = {}
    for diff in ["easy", "intermediate", "hard"]:
        reports[diff] = validate_ux(diff)
    return reports


if __name__ == "__main__":
    if len(sys.argv) > 1:
        diff = sys.argv[1]
        report = validate_ux(diff)
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        reports = validate_all()
        for diff, report in reports.items():
            print(f"\n=== {diff.upper()} ===")
            print(f"  Total: {report['total']}, Valid: {report['valid']}, "
                  f"Invalid: {report['invalid']}")
            if report.get("clue_outside_range"):
                print(f"  Clues outside range: {report['clue_outside_range']}")
            if report.get("time_outside_range"):
                print(f"  Time outside range: {report['time_outside_range']}")
            if report.get("classification_mismatch"):
                print(f"  Class mismatch: {report['classification_mismatch']}")
            if report.get("level_below_target"):
                print(f"  Level below target: {report['level_below_target']}")
            if diff == "hard":
                print(f"  XWing %: {report.get('xwing_pct', 0)}% "
                      f"({'OK' if report.get('xwing_max_ok') else 'OVER LIMIT'})")
