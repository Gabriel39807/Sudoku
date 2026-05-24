"""
Two-phase generator for difficulty rebalance.

Phase 1: Remove cells aggressively to establish technique profile.
Phase 2: Incrementally fill back clues, preserving classification after each add-back.
"""
from __future__ import annotations

import random
from typing import Any, Dict, List, Optional

from classify_by_techniques import classify_by_techniques
from difficulty_profiles import PROFILES, techniques_match_profile
from difficulty_score import human_score
from human_solver import solve_human
from solver import generate_full_board
from validator import has_unique_solution

TECHNIQUE_LEVEL: dict[str, int] = {
    "naked_single": 1, "hidden_single": 1,
    "naked_pair": 2, "hidden_pair": 2, "naked_triple": 2, "hidden_triple": 2,
    "pointing_pair": 3, "box_line_reduction": 3,
    "xwing": 4, "swordfish": 4, "xywing": 5, "forcing_chain": 6,
}

PuzzleGrid = List[List[int]]


def _clues_from_profile(difficulty: str) -> tuple[int, int]:
    p = PROFILES.get(difficulty)
    return (p["min_clues"], p["max_clues"]) if p else (25, 30)


def _clues(puzzle: PuzzleGrid) -> int:
    return sum(1 for row in puzzle for v in row if v != 0)


def _try_removal_pass(solution: PuzzleGrid, difficulty: str) -> Optional[Dict[str, Any]]:
    profile = PROFILES.get(difficulty)
    if profile is None:
        return None

    max_allowed = profile["allowed"]
    min_clues, max_clues = _clues_from_profile(difficulty)

    pos = [(r, c) for r in range(9) for c in range(9)]
    random.shuffle(pos)

    # ── Phase 1: Remove cells aggressively ──
    puzzle = [row[:] for row in solution]
    # Track which cells were removed
    removed_set: set[tuple[int, int]] = set()

    for r, c in pos:
        saved = puzzle[r][c]
        puzzle[r][c] = 0

        if not has_unique_solution(puzzle):
            puzzle[r][c] = saved
            continue

        human = solve_human(puzzle)
        if not human["solved"]:
            puzzle[r][c] = saved
            continue

        tech_set = set(human["techniques"])
        if not tech_set.issubset(max_allowed):
            puzzle[r][c] = saved
            continue

        removed_set.add((r, c))

    clues = _clues(puzzle)

    # Must reach target classification
    human = solve_human(puzzle)
    if not human["solved"]:
        return None
    classified = classify_by_techniques(human["techniques"])
    if classified != difficulty:
        return None

    # ── Phase 2: Incrementally fill back clues preserving classification ──
    fill_order = list(removed_set)
    # Sort: prefer cells adjacent to filled areas (heuristic for density stability)
    random.shuffle(fill_order)

    for r, c in fill_order:
        if clues >= max_clues:
            break
        saved = puzzle[r][c]
        puzzle[r][c] = solution[r][c]

        human = solve_human(puzzle)
        if not human["solved"]:
            puzzle[r][c] = saved
            continue

        if classify_by_techniques(human["techniques"]) != difficulty:
            puzzle[r][c] = saved
            continue

        clues += 1

    # ── Final validation ──
    if clues < min_clues or clues > max_clues:
        return None

    human = solve_human(puzzle)
    if not human["solved"]:
        return None

    techs = human["techniques"]
    if not techniques_match_profile(techs, difficulty):
        return None
    if classify_by_techniques(techs) != difficulty:
        return None

    score = human_score(techs)
    return {
        "puzzle": puzzle,
        "solution": solution,
        "techniques": techs,
        "steps": human["steps"],
        "human_score": score,
        "removed": 81 - clues,
        "clues": clues,
    }


def generate_target(
    difficulty: str,
    max_solutions: int = 100,
    removal_passes_per_solution: int = 10,
) -> Optional[Dict[str, Any]]:
    attempt_count = 0
    for _ in range(max_solutions):
        solution = generate_full_board()
        for _ in range(removal_passes_per_solution):
            attempt_count += 1
            result = _try_removal_pass(solution, difficulty)
            if result is not None:
                result["attempt"] = attempt_count
                return result
    return None


def generate_multiple(
    difficulty: str,
    count: int,
    max_solutions_per_board: int = 100,
    removal_passes_per_solution: int = 10,
) -> List[Dict[str, Any]]:
    results: List[Dict[str, Any]] = []
    seen_hashes: set = set()
    max_total = count * max_solutions_per_board * removal_passes_per_solution
    total_attempts = 0

    while len(results) < count and total_attempts < max_total:
        total_attempts += 1
        board = generate_target(
            difficulty, max_solutions=1,
            removal_passes_per_solution=removal_passes_per_solution,
        )
        if board is None:
            continue

        from export import puzzle_hash
        h = puzzle_hash(board["puzzle"])
        if h in seen_hashes:
            continue
        seen_hashes.add(h)
        results.append(board)

    return results
