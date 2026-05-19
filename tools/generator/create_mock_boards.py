"""
Genera 20 tableros por dificultad usando el solver existente.
No usa técnicas humanas — simplemente remueve pistas hasta una cantidad
objetivo por nivel (válido para propósitos de prueba hasta que el
pipeline real en generate.py esté corriendo).

Difficulty → clue targets:
  easy:         36-40
  intermediate: 30-35
  hard:         26-29
  expert:       24-25
  evil:         22-23
  mythic:       20-21
"""

import sys
import os
import copy
import json
import random

# Agrega el directorio del generador al path para reusar solver/validator
sys.path.insert(0, os.path.dirname(__file__))
from solver import generate_full_board, is_valid, count_solutions
from validator import has_unique_solution

CLUE_RANGES = {
    "easy":         (36, 40),
    "intermediate": (30, 35),
    "hard":         (26, 29),
    "expert":       (24, 25),
    "evil":         (22, 23),
    "mythic":       (20, 21),
}

TECHNIQUE_TAGS = {
    "easy":         ["naked_single", "hidden_single"],
    "intermediate": ["naked_pair", "hidden_pair"],
    "hard":         ["pointing_pair", "box_line_reduction"],
    "expert":       ["xwing", "swordfish"],
    "evil":         ["xywing", "forcing_chains"],
    "mythic":       ["forcing_chains", "nishio"],
}

TARGET_COUNT = 20

OUTPUT_BASE = os.path.join(
    os.path.dirname(__file__),  # tools/generator/
    "..", "..",                  # repo root
    "flutter_app", "assets", "boards"
)


def dig_holes(solution, target_clues):
    """Elimina celdas de la solución hasta target_clues con restricción de unicidad."""
    puzzle = copy.deepcopy(solution)
    positions = [(r, c) for r in range(9) for c in range(9)]
    random.shuffle(positions)

    for r, c in positions:
        if sum(1 for row in puzzle for v in row if v != 0) <= target_clues:
            break
        backup = puzzle[r][c]
        puzzle[r][c] = 0
        if not has_unique_solution(puzzle):
            puzzle[r][c] = backup  # revert

    return puzzle


def grid_to_str(grid):
    return "".join(str(grid[r][c]) for r in range(9) for c in range(9))


def generate_boards_for_difficulty(diff, count=TARGET_COUNT):
    low, high = CLUE_RANGES[diff]
    target_clues = random.randint(low, high)
    techs = TECHNIQUE_TAGS[diff]

    out_dir = os.path.normpath(os.path.join(OUTPUT_BASE, diff))
    os.makedirs(out_dir, exist_ok=True)

    generated = 0
    attempts = 0
    max_attempts = count * 50  # evita loop infinito

    while generated < count and attempts < max_attempts:
        attempts += 1
        solution = generate_full_board()
        target_clues = random.randint(low, high)
        puzzle = dig_holes(solution, target_clues)

        actual_clues = sum(1 for row in puzzle for v in row if v != 0)
        if actual_clues < low:
            continue  # quedamos con pocas pistas, descartar

        board_num = generated + 1
        board_id = f"{diff}_{board_num:04d}"
        puzzle_str = grid_to_str(puzzle)
        solution_str = grid_to_str(solution)

        data = {
            "id": board_id,
            "difficulty": diff,
            "techniques": techs,
            "steps": actual_clues,  # usamos clues como proxy temporal
            "puzzle": puzzle_str,
            "solution": solution_str,
        }

        filepath = os.path.join(out_dir, f"{board_id}.json")
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)

        generated += 1
        print(f"  [{diff.upper()}] {board_id} | clues={actual_clues} | file={filepath}")

    if generated < count:
        print(f"  WARNING: solo generé {generated}/{count} para {diff} en {attempts} intentos")
    else:
        print(f"  [{diff.upper()}] OK: {generated} tableros generados\n")


if __name__ == "__main__":
    print("=== Generando tableros mock para Flutter assets ===\n")
    for diff in CLUE_RANGES:
        print(f"Generando {TARGET_COUNT} tableros para: {diff.upper()}")
        generate_boards_for_difficulty(diff)
    print("\n=== Listo ===")
