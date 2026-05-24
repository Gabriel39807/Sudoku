"""
FASE 4 — Regeneración segura por batches con checkpoint.
Genera boards para easy/intermediate/hard con los nuevos perfiles de densidad.
Expert/Evil/Mythic no se tocan.
"""
from __future__ import annotations

import json
import os
import sys
from typing import Any, Dict, List

from target_generator import generate_target, generate_multiple
from export import puzzle_hash
from validator_final import validate_board
from checkpoints import save_checkpoint, load_checkpoint, clear_checkpoint

BOARDS_DIR = os.path.abspath(os.path.join(
    os.path.dirname(__file__), "..", "..", "flutter_app", "assets", "boards"
))
BATCH_SIZE = 100
TARGET_COUNT = 100
DIFFICULTIES = ["easy", "intermediate", "hard"]


def _count_clues(puzzle_grid: List[List[int]]) -> int:
    return sum(1 for row in puzzle_grid for v in row if v != 0)


def _export_board(
    board_id: str,
    difficulty: str,
    puzzle_grid: List[List[int]],
    solution_grid: List[List[int]],
    techniques: List[str],
    steps: int,
    h: str,
) -> Dict[str, Any]:
    puzzle_str = "".join(str(v) for row in puzzle_grid for v in row)
    solution_str = "".join(str(v) for row in solution_grid for v in row)

    data: Dict[str, Any] = {
        "id": board_id,
        "difficulty": difficulty,
        "puzzle": puzzle_str,
        "solution": solution_str,
        "techniques": techniques,
        "steps": steps,
        "checksum": h,
    }

    diff_dir = os.path.join(BOARDS_DIR, difficulty)
    os.makedirs(diff_dir, exist_ok=True)
    path = os.path.join(diff_dir, f"{board_id}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    return data


def _generate_batch(
    difficulty: str,
    start: int,
    count: int,
) -> List[Dict[str, Any]]:
    """Genera `count` boards para `difficulty`, arrancando desde `start`."""
    output: List[Dict[str, Any]] = []
    seen: set = set()
    attempts = 0
    max_attempts = count * 50

    while len(output) < count and attempts < max_attempts:
        attempts += 1
        board = generate_target(
            difficulty,
            max_solutions=50,
            removal_passes_per_solution=10,
        )
        if board is None:
            continue
        h = puzzle_hash(board["puzzle"])
        if h in seen:
            continue
        seen.add(h)

        idx = start + len(output)
        board_id = f"{difficulty}_{idx + 1:04d}"
        _export_board(
            board_id, difficulty,
            board["puzzle"], board["solution"],
            board["techniques"], board["steps"], h,
        )
        clues = _count_clues(board["puzzle"])
        output.append({
            "id": board_id,
            "clues": clues,
            "steps": board["steps"],
            "score": board["human_score"],
            "techniques": board["techniques"],
            "hash": h,
        })

    return output


def regenerate_difficulty(difficulty: str, force: bool = False) -> int:
    """Regenera boards para una dificultad en batches de BATCH_SIZE.
    
    Retorna total de boards generados.
    """
    cp_key = f"rebalance_{difficulty}"

    if not force:
        cp = load_checkpoint(cp_key)
        if cp and cp.get("completed"):
            print(f"[SKIP] {difficulty} ya completado. Usa --force para regenerar.")
            return cp["data"].get("total", 0)

    total_generated = 0
    target = TARGET_COUNT

    # Check existing count if resuming
    diff_dir = os.path.join(BOARDS_DIR, difficulty)
    existing = 0
    if os.path.isdir(diff_dir):
        existing = len([n for n in os.listdir(diff_dir) if n.endswith(".json")])

    if existing > 0 and not force:
        print(f"[RESUME] {difficulty}: {existing} boards existentes. Continuando...")
        # Only generate remaining
        start = existing + 1
    else:
        start = 1
        # Clear existing boards for clean generation
        if os.path.isdir(diff_dir):
            for name in os.listdir(diff_dir):
                if name.endswith(".json") and name.startswith(f"{difficulty}_"):
                    os.remove(os.path.join(diff_dir, name))
            print(f"[CLEAN] {difficulty}: boards anteriores eliminados.")

    batch_num = 1
    all_results = []

    while total_generated < target:
        batch_start = start + total_generated
        batch_count = min(BATCH_SIZE, target - total_generated)

        print(f"\n[GEN] {difficulty} batch {batch_num}: "
              f"generando {batch_count} boards (desde {batch_start})...")
        sys.stdout.flush()

        batch = _generate_batch(difficulty, batch_start - 1, batch_count)
        if not batch:
            print(f"[WARN] batch {batch_num} devolvió 0 boards — abortando.")
            break

        all_results.extend(batch)
        total_generated += len(batch)

        # Validate batch
        errors = 0
        for b in batch:
            with open(os.path.join(diff_dir, f"{b['id']}.json"), encoding="utf-8") as f:
                raw = json.load(f)
            v = validate_board(raw["puzzle"], raw["solution"], difficulty)
            if not v["valid"]:
                print(f"  INVALID: {b['id']} — {v['errors']}")
                errors += 1

        if errors:
            print(f"[WARN] batch {batch_num}: {errors}/{len(batch)} boards inválidos")

        # Checkpoint after each batch
        cp_data = {
            "difficulty": difficulty,
            "total": total_generated,
            "batch": batch_num,
            "batches": all_results,
        }
        save_checkpoint(f"rebalance_{difficulty}", cp_data)
        print(f"[CP] {difficulty} batch {batch_num}: {total_generated}/{target}")

        batch_num += 1

        if len(batch) < batch_count:
            print(f"[WARN] solo {len(batch)} generados, solicitados {batch_count}")
            break

    # Mark as completed
    cp_data = {
        "difficulty": difficulty,
        "total": total_generated,
        "batches": all_results,
    }
    save_checkpoint(f"rebalance_{difficulty}", cp_data)
    print(f"[DONE] {difficulty}: {total_generated} boards generados")
    return total_generated


def regenerate_all(force: bool = False) -> None:
    for diff in DIFFICULTIES:
        total = regenerate_difficulty(diff, force=force)
        print(f"[OK] {diff}: {total} boards")
    print("\n=== REGENERACIÓN COMPLETA ===")


if __name__ == "__main__":
    force = "--force" in sys.argv
    if len(sys.argv) > 1 and sys.argv[1] in DIFFICULTIES:
        regenerate_difficulty(sys.argv[1], force=force)
    else:
        regenerate_all(force=force)
