from __future__ import annotations

import json
import os
from collections import Counter, defaultdict

from classify_by_techniques import classify_by_techniques
from export import puzzle_hash
from validator_final import to_grid, validate_board

BOARDS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "flutter_app", "assets", "boards"))
REPORT_PATH = os.path.join(os.path.dirname(__file__), "dataset_report.json")


def audit_dataset():
    counts = defaultdict(int)
    examples = {}
    errors = []
    checksums = Counter()
    files_by_hash = defaultdict(list)

    representative_validated = set()
    for root, _, files in os.walk(BOARDS_DIR):
        for name in files:
            if not name.endswith(".json"):
                continue
            path = os.path.join(root, name)
            with open(path, "r", encoding="utf-8") as handle:
                try:
                    data = json.load(handle)
                except json.JSONDecodeError as exc:
                    errors.append({"file": path, "errors": [f"invalid json: {exc}"]})
                    continue
            difficulty = data.get("difficulty") or os.path.basename(os.path.dirname(path))
            puzzle = to_grid(data.get("puzzle"))
            if puzzle is not None:
                checksum = puzzle_hash(puzzle)
                checksums[checksum] += 1
                files_by_hash[checksum].append(path)
            if difficulty in representative_validated:
                validation = _validate_payload(data, difficulty)
            else:
                validation = validate_board(data.get("puzzle"), data.get("solution"), difficulty)
                if validation["valid"]:
                    representative_validated.add(difficulty)
            if not validation["valid"]:
                errors.append({"file": path, "errors": validation["errors"]})
                continue
            counts[difficulty] += 1
            examples.setdefault(difficulty, validation["techniques"])

    duplicates = {checksum: paths for checksum, paths in files_by_hash.items() if len(paths) > 1}
    report = {
        "valid": not errors and not duplicates,
        "counts": dict(sorted(counts.items())),
        "duplicates": duplicates,
        "duplicate_count": sum(len(paths) for paths in duplicates.values()),
        "errors": errors,
        "examples": examples,
    }
    with open(REPORT_PATH, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
        handle.write("\n")
    return report


def _validate_payload(data, difficulty):
    puzzle = to_grid(data.get("puzzle"))
    solution = to_grid(data.get("solution"))
    errors = []
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
        errors.append("stored technique classification mismatch")
    return {"valid": not errors, "errors": errors, "techniques": techniques}


def _has_conflicts(board, allow_zero):
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


def _unit_conflict(values, allow_zero):
    seen = set()
    for value in values:
        if value == 0 and allow_zero:
            continue
        if value in seen:
            return True
        seen.add(value)
    return False


if __name__ == "__main__":
    print(json.dumps(audit_dataset(), indent=2))
