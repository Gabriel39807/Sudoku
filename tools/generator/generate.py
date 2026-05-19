from __future__ import annotations

import os
import random
import shutil
from copy import deepcopy

from classify_by_techniques import classify_by_techniques
from export import SEEN_HASHES, export_board, puzzle_hash
from human_solver import solve_human
from solver import generate_full_board
from validator import has_unique_solution
from validator_final import validate_board

DIFFICULTIES = ["easy", "intermediate", "hard", "expert", "evil", "mythic"]
TARGET = int(os.environ.get("SUDOKU_TARGET_PER_DIFFICULTY", "100"))
BOARDS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "flutter_app", "assets", "boards"))

SEED_PUZZLES = {
    "easy": "390060008700010000000004200003000091410007020070000000005000000900045080068091070",
    "intermediate": "003080090007003106000410008100005000900000230700200810080000900000000060000060007",
    "hard": "008040900060003000490108000000201080001500000047300200000000104010000003600800000",
    "expert": "102007090030020008709600500005310900010080002600004000300000210041000007007000300",
    "evil": "102007090030020078009640500005300900010080002600004000300000019040000007007000350",
    "mythic": "100007090030020008009600500005300900010080002600004000300000010040000007007000300",
}


def string_to_grid(value):
    return [[int(value[r * 9 + c]) for c in range(9)] for r in range(9)]


def transform(board, digit_map, row_order, col_order):
    result = [[0] * 9 for _ in range(9)]
    for nr, r in enumerate(row_order):
        for nc, c in enumerate(col_order):
            value = board[r][c]
            result[nr][nc] = digit_map.get(value, 0)
    return result


def random_transform(puzzle, solution):
    digits = list(range(1, 10))
    shuffled = digits[:]
    random.shuffle(shuffled)
    digit_map = dict(zip(digits, shuffled))
    row_bands = random.sample(range(3), 3)
    col_bands = random.sample(range(3), 3)
    row_order = [band * 3 + row for band in row_bands for row in random.sample(range(3), 3)]
    col_order = [band * 3 + col for band in col_bands for col in random.sample(range(3), 3)]
    return transform(puzzle, digit_map, row_order, col_order), transform(solution, digit_map, row_order, col_order)


def candidate_from_solution(solution):
    for _ in range(80):
        puzzle = deepcopy(solution)
        positions = [(r, c) for r in range(9) for c in range(9)]
        random.shuffle(positions)
        removals = random.randint(38, 58)
        for r, c in positions[:removals]:
            puzzle[r][c] = 0
        if has_unique_solution(puzzle):
            return puzzle
    puzzle = deepcopy(solution)
    positions = [(r, c) for r in range(9) for c in range(9)]
    random.shuffle(positions)
    for r, c in positions:
        keep = puzzle[r][c]
        puzzle[r][c] = 0
        if not has_unique_solution(puzzle):
            puzzle[r][c] = keep
    return puzzle


def find_seed(difficulty, attempts=2500):
    seed_value = SEED_PUZZLES.get(difficulty)
    if seed_value:
        puzzle = string_to_grid(seed_value)
        validation = validate_board(puzzle, None, difficulty)
        if validation["valid"]:
            return puzzle, validation["solution"], {"techniques": validation["techniques"], "steps": validation["steps"], "solved": True}
    for _ in range(attempts):
        solution = generate_full_board()
        puzzle = candidate_from_solution(solution)
        human = solve_human(puzzle)
        if not human["solved"]:
            continue
        classified = classify_by_techniques(human["techniques"])
        if classified != difficulty:
            continue
        validation = validate_board(puzzle, solution, difficulty)
        if validation["valid"]:
            return puzzle, solution, human
    return None


def generate_boards(target=TARGET):
    if os.path.isdir(BOARDS_DIR):
        for difficulty in DIFFICULTIES:
            diff_dir = os.path.join(BOARDS_DIR, difficulty)
            if os.path.isdir(diff_dir):
                shutil.rmtree(diff_dir)
    SEEN_HASHES.clear()
    counts = {difficulty: 0 for difficulty in DIFFICULTIES}
    examples = {}

    for difficulty in DIFFICULTIES:
        seed = find_seed(difficulty)
        if seed is None:
            raise RuntimeError(f"could not generate a valid {difficulty} seed")
        seed_puzzle, seed_solution, _ = seed
        local_hashes = set()
        tries = 0
        while counts[difficulty] < target and tries < target * 100:
            tries += 1
            puzzle, solution = random_transform(seed_puzzle, seed_solution)
            checksum = puzzle_hash(puzzle)
            if checksum in local_hashes or checksum in SEEN_HASHES:
                continue
            counts[difficulty] += 1
            board_id = f"{difficulty}_{counts[difficulty]:04d}"
            export_board(board_id, difficulty, puzzle, solution, seed[2]["techniques"], seed[2]["steps"], BOARDS_DIR)
            local_hashes.add(checksum)
            examples.setdefault(difficulty, seed[2]["techniques"])
        if counts[difficulty] < target:
            raise RuntimeError(f"only generated {counts[difficulty]} {difficulty} boards")
    return counts, examples


if __name__ == "__main__":
    counts, examples = generate_boards()
    print("counts", counts)
    print("examples", examples)
