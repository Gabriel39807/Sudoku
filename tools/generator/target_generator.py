from __future__ import annotations

import random
from typing import Any, Dict, List, Optional

from difficulty_profiles import PROFILES, techniques_match_profile
from difficulty_score import human_score
from human_solver import solve_human
from solver import generate_full_board
from validator import has_unique_solution


def _try_removal_pass(
    solution: List[List[int]],
    difficulty: str,
    min_removals: int = 30,
    max_removals: int = 58,
) -> Optional[Dict[str, Any]]:
    profile = PROFILES.get(difficulty)
    if profile is None:
        return None

    max_allowed_set = profile["allowed"]

    puzzle = [row[:] for row in solution]
    positions = [(r, c) for r in range(9) for c in range(9)]
    random.shuffle(positions)

    removed = 0
    for r, c in positions:
        if removed >= max_removals:
            break

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
        if not tech_set.issubset(max_allowed_set):
            puzzle[r][c] = saved
            continue

        removed += 1

    if removed < min_removals:
        return None

    human = solve_human(puzzle)
    if not human["solved"]:
        return None

    techs = human["techniques"]
    tech_set = set(techs)

    if not techniques_match_profile(techs, difficulty):
        return None

    score = human_score(techs)
    return {
        "puzzle": puzzle,
        "solution": solution,
        "techniques": techs,
        "steps": human["steps"],
        "human_score": score,
        "removed": removed,
    }


def generate_target(
    difficulty: str,
    max_solutions: int = 100,
    removal_passes_per_solution: int = 10,
    min_removals: int = 30,
    max_removals: int = 58,
) -> Optional[Dict[str, Any]]:
    profile = PROFILES.get(difficulty)
    if profile is None:
        return None

    attempt_count = 0
    for _ in range(max_solutions):
        solution = generate_full_board()
        for _ in range(removal_passes_per_solution):
            attempt_count += 1
            result = _try_removal_pass(
                solution, difficulty,
                min_removals=min_removals,
                max_removals=max_removals,
            )
            if result is not None:
                result["attempt"] = attempt_count
                return result

    return None


def generate_multiple(
    difficulty: str,
    count: int,
    max_solutions_per_board: int = 100,
    removal_passes_per_solution: int = 10,
    min_removals: int = 30,
    max_removals: int = 58,
) -> List[Dict[str, Any]]:
    results: List[Dict[str, Any]] = []
    seen_hashes: set = set()

    total_attempts = 0
    max_total = count * max_solutions_per_board * removal_passes_per_solution

    while len(results) < count and total_attempts < max_total:
        total_attempts += 1
        board = generate_target(
            difficulty,
            max_solutions=1,
            removal_passes_per_solution=removal_passes_per_solution,
            min_removals=min_removals,
            max_removals=max_removals,
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
