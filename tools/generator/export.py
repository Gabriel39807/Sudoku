from __future__ import annotations

import hashlib
import json
import os
from typing import Set

SEEN_HASHES: Set[str] = set()


def board_to_string(board):
    return "".join(str(value) for row in board for value in row)


def puzzle_hash(puzzle_grid):
    return hashlib.sha256(board_to_string(puzzle_grid).encode("utf-8")).hexdigest()


def export_board(board_id, difficulty, puzzle_grid, solution_grid, techniques=None, steps=None, base_dir=None):
    h = puzzle_hash(puzzle_grid)
    if h in SEEN_HASHES:
        raise ValueError(f"duplicate puzzle rejected: {board_id}")
    SEEN_HASHES.add(h)

    data = {
        "id": board_id,
        "difficulty": difficulty,
        "puzzle": board_to_string(puzzle_grid),
        "solution": board_to_string(solution_grid),
        "techniques": list(techniques or []),
        "steps": steps if isinstance(steps, int) else (steps or 0),
        "hash": h,
    }

    root = base_dir or os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "flutter_app", "assets", "boards"))
    diff_dir = os.path.join(root, difficulty)
    os.makedirs(diff_dir, exist_ok=True)
    with open(os.path.join(diff_dir, f"{board_id}.json"), "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, ensure_ascii=False)
        handle.write("\n")
    return data
