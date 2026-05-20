from __future__ import annotations

import json
import os
import sys
import time
from collections import Counter, defaultdict

# Force UTF-8 for Windows console
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, os.path.dirname(__file__))

from classify_by_techniques import classify_by_techniques
from export import puzzle_hash, SEEN_HASHES
from human_solver import solve_human
from target_generator import generate_target
from validator import has_unique_solution
from validator_final import to_grid, validate_board, _conflicts

BOARDS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "flutter_app", "assets", "boards", "easy"))
EASY_DIR = BOARDS_DIR
REPORT_DIR = os.path.dirname(__file__)
AUDIT_PATH = os.path.join(REPORT_DIR, "easy_dataset_audit.json")
CHECKPOINT_PATH = os.path.join(REPORT_DIR, "generator_checkpoint_easy.json")
REPORT_PATH = os.path.join(REPORT_DIR, "easy_expansion_report.md")


# ─── FASE 1: Auditoría ──────────────────────────────────────────

def audit_existing():
    print("=" * 60)
    print("FASE 1 — Auditoría del dataset EASY existente")
    print("=" * 60)

    files = sorted(
        f for f in os.listdir(EASY_DIR)
        if f.startswith("easy_") and f.endswith(".json")
    )

    boards = []
    errors = []
    all_hashes = Counter()
    hash_to_file = defaultdict(list)

    for fname in files:
        path = os.path.join(EASY_DIR, fname)
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)

        board_id = data.get("id", fname.replace(".json", ""))
        puzzle_str = data.get("puzzle", "")
        sol_str = data.get("solution", "")
        techniques = data.get("techniques", [])

        puzzle_grid = to_grid(puzzle_str)
        if puzzle_grid is None:
            errors.append({"file": fname, "issue": "puzzle not valid 81-char grid"})
            continue

        h = puzzle_hash(puzzle_grid)
        all_hashes[h] += 1
        hash_to_file[h].append(fname)

        validation = validate_board(puzzle_str, sol_str, "easy")
        if not validation["valid"]:
            errors.append({"file": fname, "errors": validation["errors"]})
            continue

        clues = sum(1 for row in puzzle_grid for v in row if v != 0)
        score = validation.get("human_score", 0)

        boards.append({
            "id": board_id,
            "file": fname,
            "clues": clues,
            "techniques": techniques,
            "steps": len(techniques),
            "score": score,
            "hash": h,
        })

    # Detect duplicates
    duplicates = {}
    for h, files_list in hash_to_file.items():
        if len(files_list) > 1:
            duplicates[h] = files_list

    clues_list = [b["clues"] for b in boards]
    steps_list = [b["steps"] for b in boards]
    scores_list = [b["score"] for b in boards]

    tech_counter: Counter = Counter()
    for b in boards:
        for t in b["techniques"]:
            tech_counter[t] += 1

    audit = {
        "total_boards": len(boards),
        "total_files": len(files),
        "ids": sorted(b["id"] for b in boards),
        "hashes": sorted(set(b["hash"] for b in boards)),
        "clues": {
            "min": min(clues_list) if clues_list else 0,
            "max": max(clues_list) if clues_list else 0,
            "avg": round(sum(clues_list) / len(clues_list), 1) if clues_list else 0,
            "distribution": dict(sorted(Counter(clues_list).items())),
        },
        "techniques": {
            "used": dict(tech_counter.most_common()),
            "unique_count": len(tech_counter),
        },
        "steps": {
            "min": min(steps_list) if steps_list else 0,
            "max": max(steps_list) if steps_list else 0,
            "avg": round(sum(steps_list) / len(steps_list), 1) if steps_list else 0,
        },
        "score": {
            "min": min(scores_list) if scores_list else 0,
            "max": max(scores_list) if scores_list else 0,
            "avg": round(sum(scores_list) / len(scores_list), 1) if scores_list else 0,
        },
        "integrity": {
            "duplicate_hashes": len(duplicates),
            "duplicate_details": duplicates,
            "corrupt_boards": len(errors),
            "corruption_details": errors,
            "conflicts_found": 0,  # validated above, no conflict if passed
        },
    }

    print(f"  Boards encontrados: {len(boards)}/{len(files)} archivos válidos")
    print(f"  Técnicas únicas: {audit['techniques']['unique_count']}")
    print(f"  Rango clues: {audit['clues']['min']}–{audit['clues']['max']} (avg {audit['clues']['avg']})")
    print(f"  Rango steps: {audit['steps']['min']}–{audit['steps']['max']} (avg {audit['steps']['avg']})")
    print(f"  Rango score: {audit['score']['min']}–{audit['score']['max']} (avg {audit['score']['avg']})")
    print(f"  Duplicados: {audit['integrity']['duplicate_hashes']}")
    print(f"  Corruptos: {audit['integrity']['corrupt_boards']}")

    with open(AUDIT_PATH, "w", encoding="utf-8") as fh:
        json.dump(audit, fh, indent=2)

    print(f"  Reporte guardado: {AUDIT_PATH}")
    return boards, audit


# ─── FASE 3-5: Generación incremental segura ────────────────────

def load_existing_hashes():
    existing = set()
    for fname in os.listdir(EASY_DIR):
        if not fname.startswith("easy_") or not fname.endswith(".json"):
            continue
        path = os.path.join(EASY_DIR, fname)
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        puzzle_grid = to_grid(data.get("puzzle", ""))
        if puzzle_grid:
            existing.add(puzzle_hash(puzzle_grid))
    return existing


def generate_easy_boards():
    print("\n" + "=" * 60)
    print("FASE 3-5 — Generación incremental EASY (0101 → 0500)")
    print("=" * 60)

    existing_hashes = load_existing_hashes()
    print(f"  Hashes existentes cargados: {len(existing_hashes)}")

    START_ID = 101
    END_ID = 500
    BATCH_SIZE = 50

    # Determine next ID from checkpoint / existing files
    existing_ids = set()
    for fname in os.listdir(EASY_DIR):
        if fname.startswith("easy_") and fname.endswith(".json"):
            try:
                n = int(fname.replace("easy_", "").replace(".json", ""))
                existing_ids.add(n)
            except ValueError:
                pass

    next_id = max(existing_ids) + 1 if existing_ids else START_ID
    if next_id < START_ID:
        next_id = START_ID
    print(f"  Próximo ID disponible: easy_{next_id:04d}")

    # Load checkpoint
    checkpoint = {}
    if os.path.exists(CHECKPOINT_PATH):
        with open(CHECKPOINT_PATH, "r", encoding="utf-8") as fh:
            checkpoint = json.load(fh)
        ckpt_from = checkpoint.get("last_id", START_ID - 1)
        ckpt_hashes = set(checkpoint.get("generated_hashes", []))
        existing_hashes.update(ckpt_hashes)
        SEEN_HASHES.update(ckpt_hashes)
        if ckpt_from >= next_id:
            next_id = ckpt_from + 1
        print(f"  Checkpoint reanudado desde easy_{next_id:04d}")

    # Stats
    stats = {
        "generated": 0,
        "rejected_duplicate_hash": 0,
        "rejected_validation": 0,
        "rejected_no_generation": 0,
        "start_time": time.time(),
        "batch_times": [],
        "clues_list": [],
        "steps_list": [],
        "scores_list": [],
        "techniques_counter": Counter(),
        "batch_results": [],
    }

    batch_num = 1

    while next_id <= END_ID:
        batch_start = next_id
        batch_end = min(batch_start + BATCH_SIZE - 1, END_ID)
        batch_count = batch_end - batch_start + 1

        print(f"\n--- Batch {batch_num}: easy_{batch_start:04d} → easy_{batch_end:04d} ---")
        batch_start_time = time.time()
        batch_generated = 0
        batch_errors = []

        # Ensure SEEN_HASHES is up to date
        SEEN_HASHES.update(existing_hashes)

        attempts = 0
        max_attempts_total = batch_count * 200  # generous cap

        while batch_generated < batch_count and attempts < max_attempts_total:
            attempts += 1

            board_req = generate_target(
                "easy",
                max_solutions=1,
                removal_passes_per_solution=5,
                min_removals=30,
                max_removals=58,
            )

            if board_req is None:
                continue

            puzzle = board_req["puzzle"]
            solution = board_req["solution"]
            techniques = board_req["techniques"]
            steps_count = board_req["steps"]

            # Phase 4: Strict validation
            h = puzzle_hash(puzzle)
            if h in SEEN_HASHES:
                stats["rejected_duplicate_hash"] += 1
                continue

            # Validate structure
            validation = validate_board(
                "".join(str(v) for row in puzzle for v in row),
                "".join(str(v) for row in solution for v in row),
                "easy",
            )
            if not validation["valid"]:
                stats["rejected_validation"] += 1
                batch_errors.append({
                    "id": f"easy_{next_id + batch_generated:04d}",
                    "errors": validation["errors"],
                })
                continue

            # Extra safeguards
            tech_set = set(techniques)
            if not tech_set.issubset({"naked_single", "hidden_single"}):
                stats["rejected_validation"] += 1
                continue

            if classify_by_techniques(techniques) != "easy":
                stats["rejected_validation"] += 1
                continue

            board_id = f"easy_{next_id:04d}"

            # Get human score
            score = validation.get("human_score", 0)

            # Export
            from export import export_board
            try:
                export_board(board_id, "easy", puzzle, solution, techniques, steps_count)
            except ValueError:
                stats["rejected_duplicate_hash"] += 1
                continue

            SEEN_HASHES.add(h)
            existing_hashes.add(h)

            stats["generated"] += 1
            stats["clues_list"].append(sum(1 for row in puzzle for v in row if v != 0))
            stats["steps_list"].append(steps_count)
            stats["scores_list"].append(score)
            for t in techniques:
                stats["techniques_counter"][t] += 1

            batch_generated += 1
            next_id += 1

            if batch_generated % 10 == 0:
                print(f"    Progreso batch: {batch_generated}/{batch_count} generados ({attempts} intentos)")

        batch_elapsed = time.time() - batch_start_time
        stats["batch_times"].append(batch_elapsed)

        batch_info = {
            "batch": batch_num,
            "range": f"easy_{batch_start:04d}–easy_{batch_end:04d}",
            "generated": batch_generated,
            "attempts": attempts,
            "time_s": round(batch_elapsed, 2),
            "errors": batch_errors,
        }
        stats["batch_results"].append(batch_info)

        print(f"  Batch {batch_num}: {batch_generated}/{batch_count} generados en {batch_elapsed:.1f}s")

        # Save checkpoint after each batch
        checkpoint = {
            "last_id": next_id - 1,
            "generated_hashes": list(existing_hashes),
            "stats": {
                "generated": stats["generated"],
                "rejected_duplicate_hash": stats["rejected_duplicate_hash"],
                "rejected_validation": stats["rejected_validation"],
            },
            "last_batch": batch_info,
        }
        with open(CHECKPOINT_PATH, "w", encoding="utf-8") as fh:
            json.dump(checkpoint, fh, indent=2)

        if batch_generated < batch_count:
            print(f"  ⚠ Batch incomplete: {batch_generated}/{batch_count} — posible falta de soluciones únicas")
            if attempts >= max_attempts_total:
                print(f"  Se alcanzó el máximo de intentos ({max_attempts_total})")

        batch_num += 1

    stats["total_time"] = time.time() - stats["start_time"]
    return stats


# ─── FASE 6: Reporte final ──────────────────────────────────────

def generate_final_report(stats):
    print("\n" + "=" * 60)
    print("FASE 6 — Reporte final")
    print("=" * 60)

    clues = stats.get("clues_list", [])
    steps_list = stats.get("steps_list", [])
    scores = stats.get("scores_list", [])

    report_lines = []
    report_lines.append("# Easy Expansion Report")
    report_lines.append("")
    report_lines.append("## Resumen")
    report_lines.append("")
    report_lines.append(f"- **Boards generados**: {stats['generated']}")
    report_lines.append(f"- **Rechazados (hash duplicado)**: {stats['rejected_duplicate_hash']}")
    report_lines.append(f"- **Rechazados (validación)**: {stats['rejected_validation']}")
    report_lines.append(f"- **Tiempo total**: {stats.get('total_time', 0):.1f}s")
    report_lines.append(
        f"- **Tiempo promedio por board**: "
        f"{stats['total_time'] / max(stats['generated'], 1):.2f}s"
        if stats.get("total_time") else ""
    )
    report_lines.append("")

    # Score
    if scores:
        report_lines.append("## Métricas de dificultad")
        report_lines.append("")
        report_lines.append(f"- **Score medio**: {sum(scores) / len(scores):.1f}")
        report_lines.append(f"- **Rango score**: {min(scores)}–{max(scores)}")
        report_lines.append("")

    # Clues
    if clues:
        report_lines.append("## Clues (pistas iniciales)")
        report_lines.append("")
        report_lines.append(f"- **Clues promedio**: {sum(clues) / len(clues):.1f}")
        report_lines.append(f"- **Rango clues**: {min(clues)}–{max(clues)}")
        report_lines.append("")

    # Steps
    if steps_list:
        report_lines.append("## Steps (pasos del solver humano)")
        report_lines.append("")
        report_lines.append(f"- **Steps promedio**: {sum(steps_list) / len(steps_list):.1f}")
        report_lines.append(f"- **Rango steps**: {min(steps_list)}–{max(steps_list)}")
        report_lines.append("")

    # Techniques
    tech_counter = stats.get("techniques_counter", Counter())
    if tech_counter:
        total = sum(tech_counter.values())
        report_lines.append("## Técnicas detectadas")
        report_lines.append("")
        for t, c in sorted(tech_counter.items()):
            pct = round(c / max(stats["generated"], 1) * 100, 1)
            report_lines.append(f"- **{t}**: {c}/{stats['generated']} ({pct}%)")
        report_lines.append("")

    # Batch results
    batches = stats.get("batch_results", [])
    if batches:
        report_lines.append("## Resultados por batch")
        report_lines.append("")
        report_lines.append("| Batch | Rango | Generados | Intentos | Tiempo |")
        report_lines.append("|-------|-------|-----------|----------|--------|")
        for b in batches:
            report_lines.append(
                f"| {b['batch']} | {b['range']} | {b['generated']} | {b['attempts']} | {b['time_s']}s |"
            )
        report_lines.append("")

    # Duplicates avoided
    report_lines.append("## Protección de dataset")
    report_lines.append("")
    report_lines.append(
        f"- **Duplicados evitados (hash)**: {stats['rejected_duplicate_hash']}"
    )
    report_lines.append(f"- **Hashes únicos en SEEN_HASHES**: {len(SEEN_HASHES)}")
    report_lines.append("")

    report_lines.append("## Verificación final")
    report_lines.append("")
    if stats['generated'] > 0:
        report_lines.append("Pendiente ejecutar:")
        report_lines.append("")
        report_lines.append("```bash")
        report_lines.append("python audit_dataset.py")
        report_lines.append("python validator_final.py  # o pytest sobre validate_board")
        report_lines.append("pytest")
        report_lines.append("```")
    else:
        report_lines.append("No se generaron boards nuevos.")

    report_content = "\n".join(report_lines)
    with open(REPORT_PATH, "w", encoding="utf-8") as fh:
        fh.write(report_content)

    print(f"  Reporte guardado: {REPORT_PATH}")
    return report_content


# ─── Main ────────────────────────────────────────────────────────

if __name__ == "__main__":
    # FASE 1
    _, audit = audit_existing()

    # Verify no corruption
    if audit["integrity"]["corrupt_boards"] > 0:
        print("\n⚠  Se encontraron boards corruptos en el dataset existente.")
        print("   Abortando generación. Revise easy_dataset_audit.json para detalles.")
        sys.exit(1)

    if audit["integrity"]["duplicate_hashes"] > 0:
        print("\n⚠  Se encontraron hashes duplicados en el dataset existente.")
        print("   Abortando generación. Revise easy_dataset_audit.json para detalles.")
        sys.exit(1)

    print("\n✓ Dataset EASY existente verificado: íntegro y sin corrupción.")

    # FASE 2: Profile is already correct (only naked_single + hidden_single allowed)

    # FASE 3-5
    stats = generate_easy_boards()

    # FASE 6
    generate_final_report(stats)

    total_new = stats["generated"]
    total_rejected = stats["rejected_duplicate_hash"] + stats["rejected_validation"]
    total_boards = len([f for f in os.listdir(EASY_DIR) if f.startswith("easy_") and f.endswith(".json")])
    print(f"\nOK - Generacion completada: {total_new} nuevos esta sesion, {total_rejected} rechazados")
    print(f"  Dataset EASY ahora: {total_boards} boards en disco")
