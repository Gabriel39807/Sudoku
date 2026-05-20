from __future__ import annotations

import json
import os
import sys
import time
from collections import Counter, defaultdict

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, os.path.dirname(__file__))

from classify_by_techniques import classify_by_techniques
from export import puzzle_hash, SEEN_HASHES
from human_solver import solve_human
from target_generator import generate_target
from validator import has_unique_solution
from validator_final import to_grid, validate_board, _conflicts


INTER_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "flutter_app", "assets", "boards", "intermediate")
)
REPORT_DIR = os.path.dirname(__file__)
AUDIT_PATH = os.path.join(REPORT_DIR, "intermediate_dataset_audit.json")
CHECKPOINT_PATH = os.path.join(REPORT_DIR, "generator_checkpoint_intermediate.json")
REPORT_PATH = os.path.join(REPORT_DIR, "intermediate_expansion_report.md")

# Techniques that qualify as "at least intermediate"
PAIR_TRIPLE = {"naked_pair", "hidden_pair", "naked_triple"}


# ─── FASE 1: Auditoria ──────────────────────────────────────────

def audit_existing():
    print("=" * 60)
    print("FASE 1 — Auditoria del dataset INTERMEDIATE existente")
    print("=" * 60)

    files = sorted(
        f for f in os.listdir(INTER_DIR)
        if f.startswith("intermediate_") and f.endswith(".json")
    )

    all_hashes = Counter()
    hash_to_file = {}
    errors = []
    boards = []
    tech_counter: Counter = Counter()
    clues_list = []
    steps_list = []
    scores_list = []

    for fname in files:
        path = os.path.join(INTER_DIR, fname)
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)

        puzzle_str = data.get("puzzle", "")
        sol_str = data.get("solution", "")
        techs = data.get("techniques", [])

        pg = to_grid(puzzle_str)
        if pg is None:
            errors.append({"file": fname, "issue": "invalid puzzle"})
            continue

        h = puzzle_hash(pg)
        if h in hash_to_file:
            errors.append({"file": fname, "issue": f"DUPLICATE hash with {hash_to_file[h]}"})
        hash_to_file[h] = fname
        all_hashes[h] += 1

        validation = validate_board(puzzle_str, sol_str, "intermediate")
        if not validation["valid"]:
            errors.append({"file": fname, "errors": validation["errors"]})
            continue

        clues = sum(1 for row in pg for v in row if v != 0)
        clues_list.append(clues)
        steps_list.append(len(techs))
        scores_list.append(validation.get("human_score", 0))
        for t in techs:
            tech_counter[t] += 1

        boards.append({
            "id": data.get("id", fname),
            "file": fname,
            "clues": clues,
            "techniques": list(set(techs)),
            "steps": len(techs),
            "score": validation.get("human_score", 0),
            "hash": h,
        })

    dup_hashes = {k: v for k, v in all_hashes.items() if v > 1}

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
            "duplicate_hashes": len(dup_hashes),
            "corrupt_boards": len(errors),
            "corruption_details": errors,
        },
    }

    with open(AUDIT_PATH, "w", encoding="utf-8") as fh:
        json.dump(audit, fh, indent=2)

    print(f"  Boards encontrados: {len(boards)}/{len(files)} archivos validos")
    print(f"  Tecnicas unicas: {audit['techniques']['unique_count']}")
    for t, c in tech_counter.most_common():
        print(f"    {t}: {c}")
    print(f"  Clues: {audit['clues']['min']}-{audit['clues']['max']} avg {audit['clues']['avg']}")
    print(f"  Steps: {audit['steps']['min']}-{audit['steps']['max']} avg {audit['steps']['avg']}")
    print(f"  Score: {audit['score']['min']}-{audit['score']['max']} avg {audit['score']['avg']}")
    print(f"  Duplicados: {audit['integrity']['duplicate_hashes']}")
    print(f"  Corruptos: {audit['integrity']['corrupt_boards']}")
    return audit


# ─── FASE 3-5: Generacion incremental ───────────────────────────

def load_existing_hashes():
    seen = set()
    for fname in os.listdir(INTER_DIR):
        if not fname.startswith("intermediate_") or not fname.endswith(".json"):
            continue
        with open(os.path.join(INTER_DIR, fname), "r", encoding="utf-8") as fh:
            data = json.load(fh)
        pg = to_grid(data.get("puzzle", ""))
        if pg:
            seen.add(puzzle_hash(pg))
    return seen


def generate_intermediate_boards():
    print("\n" + "=" * 60)
    print("FASE 3-5 — Generacion incremental INTERMEDIATE (0101 -> 0500)")
    print("=" * 60)

    existing_hashes = load_existing_hashes()
    print(f"  Hashes existentes cargados: {len(existing_hashes)}")

    existing_ids = set()
    for fname in os.listdir(INTER_DIR):
        if fname.startswith("intermediate_") and fname.endswith(".json"):
            try:
                n = int(fname.replace("intermediate_", "").replace(".json", ""))
                existing_ids.add(n)
            except ValueError:
                pass

    next_id = max(existing_ids) + 1 if existing_ids else 101
    if next_id < 101:
        next_id = 101
    print(f"  Proximo ID disponible: intermediate_{next_id:04d}")

    # Load checkpoint
    if os.path.exists(CHECKPOINT_PATH):
        with open(CHECKPOINT_PATH, "r", encoding="utf-8") as fh:
            checkpoint = json.load(fh)
        ckpt_from = checkpoint.get("last_id", 100)
        ckpt_hashes = set(checkpoint.get("generated_hashes", []))
        existing_hashes.update(ckpt_hashes)
        SEEN_HASHES.update(ckpt_hashes)
        if ckpt_from >= next_id:
            next_id = ckpt_from + 1
        print(f"  Checkpoint reanudado desde intermediate_{next_id:04d}")

    stats = {
        "generated": 0,
        "rejected_duplicate_hash": 0,
        "rejected_validation": 0,
        "rejected_singles_only": 0,
        "start_time": time.time(),
        "batch_times": [],
        "clues_list": [],
        "steps_list": [],
        "scores_list": [],
        "techniques_counter": Counter(),
        "batch_results": [],
    }

    batch_num = 1
    END_ID = 500
    BATCH_SIZE = 50

    while next_id <= END_ID:
        batch_start = next_id
        batch_end = min(batch_start + BATCH_SIZE - 1, END_ID)
        batch_count = batch_end - batch_start + 1

        print(f"\n--- Batch {batch_num}: intermediate_{batch_start:04d} -> intermediate_{batch_end:04d} ---")
        batch_start_time = time.time()
        batch_generated = 0
        batch_errors = []

        SEEN_HASHES.update(existing_hashes)

        attempts = 0
        max_attempts_total = batch_count * 400

        while batch_generated < batch_count and attempts < max_attempts_total:
            attempts += 1

            board_req = generate_target(
                "intermediate",
                max_solutions=1,
                removal_passes_per_solution=8,
                min_removals=30,
                max_removals=58,
            )

            if board_req is None:
                continue

            puzzle = board_req["puzzle"]
            solution = board_req["solution"]
            techniques = board_req["techniques"]
            steps_count = board_req["steps"]

            h = puzzle_hash(puzzle)
            if h in SEEN_HASHES:
                stats["rejected_duplicate_hash"] += 1
                continue

            # Check: must have at least one pair/triple technique
            tech_set = set(techniques)
            if not tech_set & PAIR_TRIPLE:
                stats["rejected_singles_only"] += 1
                continue

            # Full validation
            validation = validate_board(
                "".join(str(v) for row in puzzle for v in row),
                "".join(str(v) for row in solution for v in row),
                "intermediate",
            )
            if not validation["valid"]:
                stats["rejected_validation"] += 1
                batch_errors.append({
                    "id": f"intermediate_{next_id:04d}",
                    "errors": validation["errors"],
                })
                continue

            if classify_by_techniques(techniques) != "intermediate":
                stats["rejected_validation"] += 1
                continue

            board_id = f"intermediate_{next_id:04d}"
            score = validation.get("human_score", 0)

            from export import export_board
            try:
                export_board(board_id, "intermediate", puzzle, solution, techniques, steps_count)
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
                print(f"    Progreso batch: {batch_generated}/{batch_count} gen ({attempts} intentos)")

        batch_elapsed = time.time() - batch_start_time
        stats["batch_times"].append(batch_elapsed)

        batch_info = {
            "batch": batch_num,
            "range": f"intermediate_{batch_start:04d}-intermediate_{batch_end:04d}",
            "generated": batch_generated,
            "attempts": attempts,
            "time_s": round(batch_elapsed, 2),
            "errors": batch_errors,
        }
        stats["batch_results"].append(batch_info)

        print(f"  Batch {batch_num}: {batch_generated}/{batch_count} gen en {batch_elapsed:.1f}s (rechazados: {stats['rejected_singles_only']} singles, {stats['rejected_duplicate_hash']} dup, {stats['rejected_validation']} val)")

        checkpoint = {
            "last_id": next_id - 1,
            "generated_hashes": list(existing_hashes),
            "stats": {
                "generated": stats["generated"],
                "rejected_duplicate_hash": stats["rejected_duplicate_hash"],
                "rejected_validation": stats["rejected_validation"],
                "rejected_singles_only": stats["rejected_singles_only"],
            },
            "last_batch": batch_info,
        }
        with open(CHECKPOINT_PATH, "w", encoding="utf-8") as fh:
            json.dump(checkpoint, fh, indent=2)

        if batch_generated < batch_count:
            print(f"  WARNING: Batch incomplete: {batch_generated}/{batch_count}")

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
    tech_counter = stats.get("techniques_counter", Counter())

    lines = []
    lines.append("# Intermediate Expansion Report")
    lines.append("")
    lines.append("## Resumen")
    lines.append("")
    lines.append(f"- **Boards generados**: {stats['generated']}")
    lines.append(f"- **Rechazados (solo singles)**: {stats['rejected_singles_only']}")
    lines.append(f"- **Rechazados (hash duplicado)**: {stats['rejected_duplicate_hash']}")
    lines.append(f"- **Rechazados (validacion)**: {stats['rejected_validation']}")
    lines.append(f"- **Tiempo total**: {stats.get('total_time', 0):.1f}s")
    if stats.get("total_time"):
        lines.append(f"- **Tiempo promedio por board**: {stats['total_time'] / max(stats['generated'], 1):.2f}s")
    lines.append("")

    if scores:
        lines.append("## Metricas de dificultad")
        lines.append(f"- **Score medio**: {sum(scores) / len(scores):.1f}")
        lines.append(f"- **Rango score**: {min(scores)}–{max(scores)}")
        lines.append("")

    if clues:
        lines.append("## Clues (pistas iniciales)")
        lines.append(f"- **Clues promedio**: {sum(clues) / len(clues):.1f}")
        lines.append(f"- **Rango clues**: {min(clues)}–{max(clues)}")
        lines.append("")

    if steps_list:
        lines.append("## Steps (pasos del solver humano)")
        lines.append(f"- **Steps promedio**: {sum(steps_list) / len(steps_list):.1f}")
        lines.append(f"- **Rango steps**: {min(steps_list)}–{max(steps_list)}")
        lines.append("")

    if tech_counter:
        total = sum(tech_counter.values())
        lines.append("## Tecnicas detectadas")
        for t, c in sorted(tech_counter.items()):
            pct = round(c / max(stats["generated"], 1) * 100, 1)
            lines.append(f"- **{t}**: {c}/{stats['generated']} ({pct}%)")
        lines.append("")

    batches = stats.get("batch_results", [])
    if batches:
        lines.append("## Resultados por batch")
        lines.append("| Batch | Rango | Gen | Intentos | Tiempo |")
        lines.append("|-------|-------|-----|----------|--------|")
        for b in batches:
            lines.append(f"| {b['batch']} | {b['range']} | {b['generated']} | {b['attempts']} | {b['time_s']}s |")
        lines.append("")

    total_rejected = stats['rejected_singles_only'] + stats['rejected_duplicate_hash'] + stats['rejected_validation']
    lines.append("## Proteccion de dataset")
    lines.append(f"- **Duplicados evitados (hash)**: {stats['rejected_duplicate_hash']}")
    lines.append(f"- **Hashes unicos en SEEN_HASHES**: {len(SEEN_HASHES)}")
    lines.append("")

    with open(REPORT_PATH, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))

    print(f"  Reporte guardado: {REPORT_PATH}")


if __name__ == "__main__":
    audit = audit_existing()

    if audit["integrity"]["corrupt_boards"] > 0 or audit["integrity"]["duplicate_hashes"] > 0:
        print("ERROR: Corrupted dataset. Aborting.")
        sys.exit(1)

    print("\nOK - Dataset INTERMEDIATE verificado: integro y sin corrupcion.")

    stats = generate_intermediate_boards()
    generate_final_report(stats)

    total_boards = len([f for f in os.listdir(INTER_DIR) if f.startswith("intermediate_") and f.endswith(".json")])
    total_rej = stats["rejected_singles_only"] + stats["rejected_duplicate_hash"] + stats["rejected_validation"]
    print(f"\nOK - Generacion: {stats['generated']} nuevos ({total_rej} rechazados)")
    print(f"  Dataset INTERMEDIATE ahora: {total_boards} boards en disco")
