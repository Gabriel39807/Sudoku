from __future__ import annotations

import json
import os
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(__file__))

from validator_final import to_grid, validate_board
from export import puzzle_hash
from difficulty_score import human_score

INTER_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "flutter_app", "assets", "boards", "intermediate")
)
AUDIT_PATH = os.path.join(os.path.dirname(__file__), "intermediate_dataset_audit.json")


def audit():
    files = sorted(f for f in os.listdir(INTER_DIR) if f.startswith("intermediate_") and f.endswith(".json"))
    all_hashes = Counter()
    hash_to_file = {}
    errors = []
    boards = []
    tech_counter: Counter = Counter()
    clues_list = []
    steps_list = []
    scores_list = []

    for fname in files:
        path = os.path.join(INTER_DIR, fname)
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)

        bid = data.get("id", fname)
        puzzle_str = data.get("puzzle", "")
        sol_str = data.get("solution", "")
        techs = data.get("techniques", [])

        pg = to_grid(puzzle_str)
        if pg is None:
            errors.append({"file": fname, "issue": "invalid puzzle"})
            continue

        h = puzzle_hash(pg)
        if h in hash_to_file:
            errors.append({"file": fname, "issue": f"DUPLICATE hash with {hash_to_file[h]}"})
        hash_to_file[h] = fname
        all_hashes[h] += 1

        validation = validate_board(puzzle_str, sol_str, "intermediate")
        if not validation["valid"]:
            errors.append({"file": fname, "errors": validation["errors"]})
            continue

        clues = sum(1 for row in pg for v in row if v != 0)
        clues_list.append(clues)
        steps_list.append(len(techs))
        scores_list.append(validation.get("human_score", 0))
        for t in techs:
            tech_counter[t] += 1

        boards.append({
            "id": bid, "file": fname, "clues": clues,
            "techniques": list(set(techs)), "steps": len(techs),
            "score": validation.get("human_score", 0), "hash": h,
        })

    dup_hashes = {k: v for k, v in all_hashes.items() if v > 1}

    audit_report = {
        "total_boards": len(boards),
        "total_files": len(files),
        "ids": sorted(b["id"] for b in boards),
        "hashes": sorted(set(b["hash"] for b in boards)),
        "clues": {
            "min": min(clues_list) if clues_list else 0,
            "max": max(clues_list) if clues_list else 0,
            "avg": round(sum(clues_list) / len(clues_list), 1) if clues_list else 0,
            "distribution": dict(sorted(Counter(clues_list).items())),
        },
        "techniques": {
            "used": dict(tech_counter.most_common()),
            "unique_count": len(tech_counter),
        },
        "steps": {
            "min": min(steps_list) if steps_list else 0,
            "max": max(steps_list) if steps_list else 0,
            "avg": round(sum(steps_list) / len(steps_list), 1) if steps_list else 0,
        },
        "score": {
            "min": min(scores_list) if scores_list else 0,
            "max": max(scores_list) if scores_list else 0,
            "avg": round(sum(scores_list) / len(scores_list), 1) if scores_list else 0,
        },
        "integrity": {
            "duplicate_hashes": len(dup_hashes),
            "duplicate_details": {h: flist for h, flist in dup_hashes.items()},
            "corrupt_boards": len(errors),
            "corruption_details": errors,
        },
    }

    with open(AUDIT_PATH, "w", encoding="utf-8") as fh:
        json.dump(audit_report, fh, indent=2)

    print(f"Boards encontrados: {len(boards)}/{len(files)} archivos validos")
    print(f"Tecnicas unicas: {audit_report['techniques']['unique_count']}")
    for t, c in tech_counter.most_common():
        print(f"  {t}: {c}")
    print(f"Clues: {audit_report['clues']['min']}-{audit_report['clues']['max']} avg {audit_report['clues']['avg']}")
    print(f"Steps: {audit_report['steps']['min']}-{audit_report['steps']['max']} avg {audit_report['steps']['avg']}")
    print(f"Score: {audit_report['score']['min']}-{audit_report['score']['max']} avg {audit_report['score']['avg']}")
    print(f"Duplicados: {audit_report['integrity']['duplicate_hashes']}")
    print(f"Corruptos: {audit_report['integrity']['corrupt_boards']}")
    return audit_report


if __name__ == "__main__":
    audit()
