"""Puzzle auditor — detects duplicates, rotations, mirrors, invalid metadata."""
from typing import Dict, List, Optional, Set, Tuple
from tools.master_generator.variants import VariantRegistry
from tools.human_solver.uniqueness import has_unique_solution


def rotations(puzzle_str: str) -> List[str]:
    """Generate all 4 rotations of a puzzle string (9x9 only)."""
    n = 9
    if len(puzzle_str) != 81:
        return [puzzle_str]
    grid = [[int(puzzle_str[r * n + c]) for c in range(n)] for r in range(n)]
    results = ["".join(str(grid[r][c]) for r in range(n) for c in range(n))]
    for _ in range(3):
        grid = [[grid[n - 1 - c][r] for c in range(n)] for r in range(n)]
        results.append("".join(str(grid[r][c]) for r in range(n) for c in range(n)))
    return results


def mirror_h(puzzle_str: str) -> str:
    if len(puzzle_str) != 81:
        return puzzle_str
    n = 9
    grid = [[int(puzzle_str[r * n + c]) for c in range(n)] for r in range(n)]
    mirrored = [[grid[n - 1 - r][c] for c in range(n)] for r in range(n)]
    return "".join(str(mirrored[r][c]) for r in range(n) for c in range(n))


def mirror_v(puzzle_str: str) -> str:
    if len(puzzle_str) != 81:
        return puzzle_str
    n = 9
    grid = [[int(puzzle_str[r * n + c]) for c in range(n)] for r in range(n)]
    mirrored = [[grid[r][n - 1 - c] for c in range(n)] for r in range(n)]
    return "".join(str(mirrored[r][c]) for r in range(n) for c in range(n))


def all_transforms(puzzle_str: str) -> List[str]:
    """All 8 symmetries (4 rotations + 4 mirrors of rotations)."""
    if len(puzzle_str) != 81:
        return [puzzle_str]
    result = []
    grid = [[int(puzzle_str[r * 9 + c]) for c in range(9)] for r in range(9)]
    for _ in range(4):
        # Original rotation
        result.append("".join(str(grid[r][c]) for r in range(9) for c in range(9)))
        # Mirror of this rotation
        mirrored = [[grid[r][8 - c] for c in range(9)] for r in range(9)]
        result.append("".join(str(mirrored[r][c]) for r in range(9) for c in range(9)))
        # Rotate
        grid = [[grid[8 - c][r] for c in range(9)] for r in range(9)]
    return result


def find_duplicates(puzzles: List[Dict]) -> Dict[str, List[int]]:
    hash_map: Dict[str, List[int]] = {}
    for i, p in enumerate(puzzles):
        ps = p["puzzle"]
        h = p.get("hash", "")
        if h:
            hash_map.setdefault(h, []).append(i)
    return {h: idxs for h, idxs in hash_map.items() if len(idxs) > 1}


def find_rotations(puzzles: List[Dict]) -> List[Tuple[int, int]]:
    transforms: Dict[str, int] = {}
    found = []
    for i, p in enumerate(puzzles):
        for t in rotations(p["puzzle"]):
            if t in transforms:
                found.append((transforms[t], i))
                break
        else:
            transforms[p["puzzle"]] = i
    return found


def find_mirrors(puzzles: List[Dict]) -> List[Tuple[int, int]]:
    transforms: Dict[str, int] = {}
    found = []
    for i, p in enumerate(puzzles):
        mh = mirror_h(p["puzzle"])
        mv = mirror_v(p["puzzle"])
        for t in (mh, mv):
            if t in transforms:
                found.append((transforms[t], i))
                break
        else:
            transforms[p["puzzle"]] = i
    return found


def find_multi_solution(puzzles: List[Dict]) -> List[int]:
    return [i for i, p in enumerate(puzzles) if not has_unique_solution(p["puzzle"])]


def find_wrong_difficulty(puzzles: List[Dict], profile_max_tier: int) -> List[int]:
    return [i for i, p in enumerate(puzzles) if p.get("tier_max", 0) > profile_max_tier]


def audit_puzzles(puzzles: List[Dict], max_tier: int = 8) -> Dict:
    return {
        "total": len(puzzles),
        "hash_duplicates": len(find_duplicates(puzzles)),
        "rotations": len(find_rotations(puzzles)),
        "mirrors": len(find_mirrors(puzzles)),
        "multi_solution": len(find_multi_solution(puzzles)),
        "wrong_difficulty": len(find_wrong_difficulty(puzzles, max_tier)),
        "valid_count": sum(
            1 for p in puzzles
            if has_unique_solution(p["puzzle"])
        ),
    }


def validate_metadata(puzzle: Dict) -> List[str]:
    errors = []
    required = {"puzzle", "solution", "difficulty", "clues"}
    for key in required:
        if key not in puzzle:
            errors.append(f"missing_key:{key}")
    if "clues" in puzzle and not (17 <= puzzle["clues"] <= 81):
        errors.append(f"invalid_clues:{puzzle['clues']}")
    return errors
