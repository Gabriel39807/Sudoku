from __future__ import annotations

import json
import os
import random
import hashlib
from copy import deepcopy

CAMPAIGN_DIR = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "..", "flutter_app", "assets", "campaign"
))

VARIANTS = {
    "mini_4x4": {"size": 4, "sub_w": 2, "sub_h": 2, "levels": (1, 10)},
    "mini_6x6": {"size": 6, "sub_w": 2, "sub_h": 3, "levels": (11, 25)},
    "mini_8x8": {"size": 8, "sub_w": 2, "sub_h": 4, "levels": (26, 50)},
}


def is_valid(grid, r, c, val, size, sub_w, sub_h):
    for i in range(size):
        if grid[r][i] == val:
            return False
        if grid[i][c] == val:
            return False
    br, bc = r // sub_h * sub_h, c // sub_w * sub_w
    for i in range(sub_h):
        for j in range(sub_w):
            if grid[br + i][bc + j] == val:
                return False
    return True


def solve(grid, size, sub_w, sub_h):
    best = None
    best_values = None
    for r in range(size):
        for c in range(size):
            if grid[r][c] == 0:
                values = [v for v in range(1, size + 1) if is_valid(grid, r, c, v, size, sub_w, sub_h)]
                if best_values is None or len(values) < len(best_values):
                    best = (r, c)
                    best_values = values
    if best is None:
        return True
    r, c = best
    random.shuffle(best_values)
    for val in best_values:
        grid[r][c] = val
        if solve(grid, size, sub_w, sub_h):
            return True
        grid[r][c] = 0
    return False


def generate_full_board(size, sub_w, sub_h):
    grid = [[0] * size for _ in range(size)]
    nums = list(range(1, size + 1))
    random.shuffle(nums)
    for r in range(sub_h):
        for c in range(sub_w):
            grid[r][c] = nums[r * sub_w + c] if r * sub_w + c < size else 0
    solve(grid, size, sub_w, sub_h)
    return grid


def has_unique_solution(grid, size, sub_w, sub_h):
    count = 0
    solution = None

    def solver(g):
        nonlocal count, solution
        if count > 1:
            return True
        best = None
        best_values = None
        for r in range(size):
            for c in range(size):
                if g[r][c] == 0:
                    vals = [v for v in range(1, size + 1) if is_valid(g, r, c, v, size, sub_w, sub_h)]
                    if best_values is None or len(vals) < len(best_values):
                        best = (r, c)
                        best_values = vals
        if best is None:
            count += 1
            if count == 1:
                solution = deepcopy(g)
            return False
        r, c = best
        for val in best_values:
            g[r][c] = val
            solver(g)
            if count > 1:
                return True
            g[r][c] = 0
        return False

    g = deepcopy(grid)
    solver(g)
    return count == 1, solution


def generate_puzzle(solution, size, sub_w, sub_h, removals=None):
    if removals is None:
        removals = max(1, int(size * size * 0.4))
    for _ in range(80):
        puzzle = deepcopy(solution)
        positions = [(r, c) for r in range(size) for c in range(size)]
        random.shuffle(positions)
        for r, c in positions[:removals]:
            puzzle[r][c] = 0
        unique, sol = has_unique_solution(puzzle, size, sub_w, sub_h)
        if unique:
            return puzzle, sol
    puzzle = deepcopy(solution)
    positions = [(r, c) for r in range(size) for c in range(size)]
    random.shuffle(positions)
    for r, c in positions:
        keep = puzzle[r][c]
        puzzle[r][c] = 0
        unique, sol = has_unique_solution(puzzle, size, sub_w, sub_h)
        if not unique:
            puzzle[r][c] = keep
    unique, sol = has_unique_solution(puzzle, size, sub_w, sub_h)
    return puzzle, sol


def board_to_string(board):
    return "".join(str(v) for row in board for v in row)


def export_campaign_board(board_id, variant_name, puzzle_grid, solution_grid):
    h = hashlib.sha256(board_to_string(puzzle_grid).encode("utf-8")).hexdigest()
    data = {
        "id": board_id,
        "variant": variant_name,
        "puzzle": board_to_string(puzzle_grid),
        "solution": board_to_string(solution_grid),
        "hash": h,
    }
    diff_dir = os.path.join(CAMPAIGN_DIR, variant_name)
    os.makedirs(diff_dir, exist_ok=True)
    path = os.path.join(diff_dir, f"{board_id}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"  OK {board_id} -> {path}")
    return data


def generate_campaign():
    random.seed(42)
    total = 0
    for variant_name, cfg in VARIANTS.items():
        size = cfg["size"]
        sub_w = cfg["sub_w"]
        sub_h = cfg["sub_h"]
        start, end = cfg["levels"]
        removals_map = {
            "mini_4x4": (2, 4),
            "mini_6x6": (8, 14),
            "mini_8x8": (16, 26),
        }
        min_rem, max_rem = removals_map.get(variant_name, (size * size // 3, size * size // 2))

        print(f"\n{'='*50}")
        print(f"Generating {variant_name} ({size}x{sub_w} subgrid, {size}x{size} board)")
        print(f"Levels {start}-{end}, removals {min_rem}-{max_rem}")
        print(f"{'='*50}")

        for level in range(start, end + 1):
            board_id = f"campaign_{level:04d}"
            print(f"  [{level:03d}] Generating...")

            for attempt in range(200):
                solution = generate_full_board(size, sub_w, sub_h)
                removals = random.randint(min_rem, max_rem)
                puzzle, sol = generate_puzzle(solution, size, sub_w, sub_h, removals)
                if sol is None:
                    continue
                if board_to_string(puzzle) == board_to_string(sol):
                    continue
                difficulty_ratio = sum(1 for r in range(size) for c in range(size) if puzzle[r][c] == 0) / (size * size)
                if not (0.15 <= difficulty_ratio <= 0.65):
                    continue
                export_campaign_board(board_id, variant_name, puzzle, sol)
                total += 1
                break
            else:
                print(f"  FAILED to generate {board_id} after 200 attempts")
    print(f"\nTotal campaign boards generated: {total}")


if __name__ == "__main__":
    generate_campaign()
