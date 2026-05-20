from __future__ import annotations

import json
import os
import sys
from collections import defaultdict
from typing import Any, Dict, List, Set, Tuple

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from classify_by_techniques import CATEGORY, DIFFICULTY_ORDER, classify_by_techniques
from export import puzzle_hash
from validator_final import to_grid, validate_board

BOARDS_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "flutter_app", "assets", "boards")
)
REPORT_PATH = os.path.join(os.path.dirname(__file__), "..", "dataset_report.json")


AuditEntry = Dict[str, Any]


def _unit_conflict(values: List[int], allow_zero: bool) -> bool:
    seen: Set[int] = set()
    for v in values:
        if v == 0 and allow_zero:
            continue
        if v in seen:
            return True
        seen.add(v)
    return False


def _has_conflicts(board, allow_zero: bool) -> bool:
    for i in range(9):
        if _unit_conflict([board[i][c] for c in range(9)], allow_zero):
            return True
        if _unit_conflict([board[r][i] for r in range(9)], allow_zero):
            return True
    for br in range(0, 9, 3):
        for bc in range(0, 9, 3):
            if _unit_conflict([board[r][c] for r in range(br, br + 3) for c in range(bc, bc + 3)], allow_zero):
                return True
    return False


def _validate_payload_light(data: Dict, difficulty: str) -> AuditEntry:
    puzzle = to_grid(data.get("puzzle"))
    solution = to_grid(data.get("solution"))
    errors: List[str] = []
    if puzzle is None:
        errors.append("puzzle must be 9x9 or 81 digits")
    if solution is None:
        errors.append("solution must be 9x9 or 81 digits")
    if puzzle is not None and solution is not None:
        if puzzle == solution:
            errors.append("puzzle equals solution")
        for r in range(9):
            for c in range(9):
                if puzzle[r][c] != 0 and puzzle[r][c] != solution[r][c]:
                    errors.append(f"preloaded value mismatch at {r},{c}")
        if _has_conflicts(puzzle, True):
            errors.append("puzzle has conflicts")
        if _has_conflicts(solution, False):
            errors.append("solution has conflicts")
    techniques = data.get("techniques") or []
    if classify_by_techniques(techniques) != difficulty:
        errors.append(f"stored technique classification mismatch: expected {difficulty}, got {classify_by_techniques(techniques)}")
    return {"valid": not errors, "errors": errors, "techniques": techniques}


def audit_dataset() -> Dict[str, Any]:
    counts: Dict[str, int] = defaultdict(int)
    examples: Dict[str, List[str]] = {}
    errors: List[Dict] = []
    all_hashes: Dict[str, List[str]] = defaultdict(list)
    duplicate_solutions: Dict[str, List[str]] = defaultdict(list)
    misclassified: List[Dict] = []
    invalid_count = 0
    duplicate_count = 0
    total_boards = 0

    for root, _, files in os.walk(BOARDS_DIR):
        for name in sorted(files):
            if not name.endswith(".json"):
                continue
            path = os.path.join(root, name)
            total_boards += 1
            with open(path, "r", encoding="utf-8") as handle:
                try:
                    data = json.load(handle)
                except json.JSONDecodeError as exc:
                    errors.append({"file": path, "errors": [f"invalid json: {exc}"]})
                    invalid_count += 1
                    continue

            difficulty = data.get("difficulty") or os.path.basename(os.path.dirname(path))

            puzzle = to_grid(data.get("puzzle"))
            if puzzle is not None:
                h = puzzle_hash(puzzle)
                all_hashes[h].append(path)
                if len(all_hashes[h]) > 1:
                    duplicate_count += 1

            solution = to_grid(data.get("solution"))
            if solution is not None:
                sol_str = "".join(str(v) for row in solution for v in row)
                duplicate_solutions[sol_str].append(path)
                if len(duplicate_solutions[sol_str]) > 1:
                    duplicate_count += 1

            validation = validate_board(data.get("puzzle"), data.get("solution"), difficulty)
            if not validation["valid"]:
                errors.append({"file": path, "errors": validation["errors"]})
                invalid_count += 1
                continue

            classified = classify_by_techniques(validation["techniques"])
            if classified != difficulty:
                misclassified.append({
                    "file": path,
                    "expected": difficulty,
                    "got": classified,
                    "techniques": validation["techniques"],
                })

            counts[difficulty] += 1
            examples.setdefault(difficulty, validation["techniques"])

    true_duplicates = {h: paths for h, paths in all_hashes.items() if len(paths) > 1}
    true_sol_dupes = {s: paths for s, paths in duplicate_solutions.items() if len(paths) > 1}

    report = {
        "valid": invalid_count == 0 and not misclassified and not true_duplicates,
        "total_boards": total_boards,
        "counts": dict(sorted(counts.items())),
        "duplicate_puzzles": {h: paths for h, paths in true_duplicates.items()},
        "duplicate_solutions": {s: paths for s, paths in true_sol_dupes.items()},
        "duplicate_count": duplicate_count,
        "invalid_count": invalid_count,
        "misclassified": misclassified,
        "misclassified_count": len(misclassified),
        "errors": errors,
        "examples": examples,
    }

    with open(REPORT_PATH, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, ensure_ascii=False)
        handle.write("\n")

    return report


def print_report(report: Dict[str, Any]) -> None:
    print(f"{'='*60}")
    print(f"  AUDITORÍA COMPLETA DEL DATASET")
    print(f"{'='*60}")
    print(f"  Total tableros: {report['total_boards']}")
    print(f"  Válido: {report['valid']}")
    print(f"  Inválidos: {report['invalid_count']}")
    print(f"  Duplicados: {report['duplicate_count']}")
    print(f"  Mal clasificados: {report['misclassified_count']}")
    print()
    print(f"  --- Conteos por dificultad ---")
    for diff in DIFFICULTY_ORDER:
        print(f"    {diff}: {report['counts'].get(diff, 0)}")
    print()
    if report["misclassified"]:
        print(f"  --- MAL CLASIFICADOS ---")
        for m in report["misclassified"]:
            print(f"    {m['file']}: esperado={m['expected']}, got={m['got']}, técnicas={m['techniques']}")
    if report['duplicate_count'] > 0:
        print(f"  --- DUPLICADOS ---")
        for h, paths in report["duplicate_puzzles"].items():
            print(f"    hash {h[:12]}... -> {paths}")
    if report["errors"]:
        print(f"  --- ERRORES ---")
        for e in report["errors"]:
            print(f"    {e['file']}: {e['errors']}")
    print(f"{'='*60}")


if __name__ == "__main__":
    report = audit_dataset()
    print_report(report)
