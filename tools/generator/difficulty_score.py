from __future__ import annotations

from typing import Dict, List

TECHNIQUE_WEIGHTS: Dict[str, int] = {
    "naked_single": 1,
    "hidden_single": 1,
    "naked_pair": 3,
    "hidden_pair": 3,
    "naked_triple": 3,
    "hidden_triple": 3,
    "pointing_pair": 5,
    "box_line_reduction": 5,
    "xwing": 10,
    "swordfish": 15,
    "xywing": 20,
    "forcing_chain": 30,
}


def human_score(techniques: List[str]) -> int:
    seen = set()
    total = 0
    for t in techniques:
        if t not in seen:
            seen.add(t)
            total += TECHNIQUE_WEIGHTS.get(t, 0)
    return total


def score_to_difficulty(score: int) -> str:
    if score <= 4:
        return "easy"
    if score <= 12:
        return "intermediate"
    if score <= 20:
        return "hard"
    if score <= 30:
        return "expert"
    if score <= 45:
        return "evil"
    return "mythic"


def score_range_for_difficulty(difficulty: str) -> tuple:
    ranges = {
        "easy": (1, 6),
        "intermediate": (3, 14),
        "hard": (8, 24),
        "expert": (13, 35),
        "evil": (18, 50),
        "mythic": (25, 150),
    }
    return ranges.get(difficulty, (0, 0))
