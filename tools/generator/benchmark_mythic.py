from __future__ import annotations

import json
import os
import random
import time
from collections import Counter
from statistics import mean
from typing import Any, Dict, List

from difficulty_score import human_score
from target_generator import generate_target
from validator_final import validate_board

ATTEMPTS = int(os.environ.get("MYTHIC_BENCHMARK_ATTEMPTS", "300"))
SEED = int(os.environ.get("MYTHIC_BENCHMARK_SEED", "20260520"))
REPORT_PATH = os.path.join(os.path.dirname(__file__), "mythic_benchmark.json")


def run() -> Dict[str, Any]:
    random.seed(SEED)
    started = time.time()
    valid: List[Dict[str, Any]] = []
    generated = 0
    profiles: Counter = Counter()

    for _ in range(ATTEMPTS):
        candidate = generate_target(
            "mythic",
            max_solutions=1,
            removal_passes_per_solution=12,
            min_removals=45,
            max_removals=64,
        )
        if candidate is None:
            continue
        generated += 1
        validation = validate_board(candidate["puzzle"], candidate["solution"], "mythic")
        techniques = validation.get("techniques") or []
        profiles[tuple(techniques)] += 1
        if validation["valid"] and "forcing_chain" in techniques:
            valid.append({
                "techniques": techniques,
                "steps": validation["steps"],
                "score": validation["human_score"],
                "xywing": "xywing" in techniques,
                "forcing_chain": "forcing_chain" in techniques,
            })

    report = {
        "seed": SEED,
        "total_attempts": ATTEMPTS,
        "generated_candidates": generated,
        "valid_mythic_candidates": len(valid),
        "forcing_chain_hits": sum(1 for item in valid if item["forcing_chain"]),
        "xywing_hits": sum(1 for item in valid if item["xywing"]),
        "avg_steps": round(mean([item["steps"] for item in valid]), 2) if valid else 0,
        "avg_score": round(mean([item["score"] for item in valid]), 2) if valid else 0,
        "elapsed_seconds": round(time.time() - started, 2),
        "top_profiles": [
            {"techniques": list(profile), "count": count}
            for profile, count in profiles.most_common(20)
        ],
    }
    with open(REPORT_PATH, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, ensure_ascii=False)
        handle.write("\n")
    return report


if __name__ == "__main__":
    print(json.dumps(run(), indent=2, ensure_ascii=False))
