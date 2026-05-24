"""
FASE 1 — Auditoría de densidad y dificultad percibida
Analiza easy / intermediate / hard actual sin modificar boards.
Genera difficulty_density_report.json
"""
from __future__ import annotations

import json
import os
from collections import defaultdict

from difficulty_score import human_score, TECHNIQUE_WEIGHTS
from export import puzzle_hash
from validator_final import to_grid, validate_board

BOARDS_DIR = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "..", "flutter_app", "assets", "boards"
))
REPORT_PATH = os.path.join(os.path.dirname(__file__), "difficulty_density_report.json")

TARGET_DIFFS = {"easy", "intermediate", "hard"}
ESTIMATED_SECONDS_PER_STEP = {
    "naked_single": 3,
    "hidden_single": 5,
    "naked_pair": 20,
    "hidden_pair": 25,
    "naked_triple": 40,
    "hidden_triple": 45,
    "pointing_pair": 35,
    "box_line_reduction": 40,
    "xwing": 60,
    "swordfish": 90,
    "xywing": 120,
    "forcing_chain": 180,
}


def _count_clues(puzzle_str: str) -> int:
    return sum(1 for ch in puzzle_str if ch != "0")


def _estimate_time(techniques: list[str]) -> int:
    return sum(ESTIMATED_SECONDS_PER_STEP.get(t, 10) for t in techniques)


def _technique_frequency(techniques: list[str]) -> dict[str, float]:
    freq: dict[str, int] = defaultdict(int)
    total = len(techniques) or 1
    for t in techniques:
        freq[t] += 1
    return {k: round(v / total * 100, 1) for k, v in freq.items()}


def audit_density():
    stats: dict[str, dict] = {}
    raw_samples: dict[str, list[dict]] = defaultdict(list)

    for root, _, files in os.walk(BOARDS_DIR):
        diff = os.path.basename(root)
        if diff not in TARGET_DIFFS:
            continue
        for name in sorted(files):
            if not name.endswith(".json"):
                continue
            path = os.path.join(root, name)
            with open(path, encoding="utf-8") as f:
                data = json.load(f)

            puzzle_str = data.get("puzzle", "")
            clues = _count_clues(puzzle_str)
            empties = 81 - clues
            density_pct = round(clues / 81 * 100, 1)

            techniques = data.get("techniques", [])
            steps = data.get("steps", [])
            step_count = len(steps) if isinstance(steps, list) else (steps or 0)
            score = human_score(techniques)
            est_seconds = _estimate_time(techniques)
            pct_by_technique = _technique_frequency(techniques)

            # Validate with validator_final
            validation = validate_board(puzzle_str, data.get("solution"), diff)
            valid = validation["valid"]

            raw_samples[diff].append({
                "file": name,
                "clues": clues,
                "empties": empties,
                "density_pct": density_pct,
                "steps": step_count,
                "score": score,
                "est_seconds": est_seconds,
                "techniques": techniques,
                "technique_pct": pct_by_technique,
                "valid": valid,
            })

    # Aggregate
    for diff in TARGET_DIFFS:
        samples = raw_samples[diff]
        if not samples:
            stats[diff] = {"error": "no boards found"}
            continue

        clue_list = [s["clues"] for s in samples]
        density_list = [s["density_pct"] for s in samples]
        steps_list = [s["steps"] for s in samples]
        score_list = [s["score"] for s in samples]
        time_list = [s["est_seconds"] for s in samples]

        # Aggregate technique usage across all boards
        tech_counter: dict[str, int] = defaultdict(int)
        for s in samples:
            for t in set(s["techniques"]):
                tech_counter[t] += 1
        tech_pct = {
            k: round(v / len(samples) * 100, 1)
            for k, v in sorted(tech_counter.items())
        }

        invalid = [s["file"] for s in samples if not s["valid"]]

        stats[diff] = {
            "count": len(samples),
            "clues_avg": round(sum(clue_list) / len(clue_list), 1),
            "clues_min": min(clue_list),
            "clues_max": max(clue_list),
            "density_avg_pct": round(sum(density_list) / len(density_list), 1),
            "density_min_pct": min(density_list),
            "density_max_pct": max(density_list),
            "empties_avg": round(sum(s["empties"] for s in samples) / len(samples), 1),
            "steps_avg": round(sum(steps_list) / len(steps_list), 1),
            "steps_min": min(steps_list),
            "steps_max": max(steps_list),
            "score_avg": round(sum(score_list) / len(score_list), 1),
            "score_min": min(score_list),
            "score_max": max(score_list),
            "time_est_avg_sec": round(sum(time_list) / len(time_list), 1),
            "time_est_min_sec": min(time_list),
            "time_est_max_sec": max(time_list),
            "technique_frequency_pct": tech_pct,
            "invalid_count": len(invalid),
            "invalid_files": invalid,
        }

    report = {
        "phase": "FASE 1 — Density Audit",
        "target_difficulties": sorted(TARGET_DIFFS),
        "note": "Solo easy/intermediate/hard. Expert/Evil/Mythic no se tocan.",
        "stats": stats,
    }

    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"Report written to {REPORT_PATH}")
    return report


if __name__ == "__main__":
    audit_density()
