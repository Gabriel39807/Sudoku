from __future__ import annotations

import os
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from collections import defaultdict
from target_generator import generate_target

DIFFICULTIES = ["easy", "intermediate", "hard", "expert", "evil", "mythic"]
BOARDS_PER_DIFFICULTY = 50
MAX_ATTEMPTS = 20


def run_benchmark():
    results = {}

    for difficulty in DIFFICULTIES:
        print(f"Benchmarking {difficulty}...")
        attempt_times = []
        attempt_counts = []
        success_count = 0
        reject_count = 0
        all_scores = []
        all_techniques = []
        all_steps = []
        all_removed = []

        for i in range(BOARDS_PER_DIFFICULTY):
            start = time.time()
            board = generate_target(difficulty, max_solutions=MAX_ATTEMPTS, removal_passes_per_solution=10)
            elapsed = time.time() - start

            if board is not None:
                success_count += 1
                attempt_times.append(elapsed)
                attempt_counts.append(board["attempt"])
                all_scores.append(board["human_score"])
                all_techniques.append(board["techniques"])
                all_steps.append(board["steps"])
                all_removed.append(board["removed"])
            else:
                reject_count += 1
                attempt_times.append(elapsed)

        avg_time = sum(attempt_times) / len(attempt_times) if attempt_times else 0
        avg_attempts = sum(attempt_counts) / len(attempt_counts) if attempt_counts else 0
        avg_score = sum(all_scores) / len(all_scores) if all_scores else 0
        avg_steps = sum(all_steps) / len(all_steps) if all_steps else 0
        avg_removed = sum(all_removed) / len(all_removed) if all_removed else 0

        all_techs_flat = [t for techs in all_techniques for t in techs]
        unique_techs = sorted(set(all_techs_flat))
        tech_counts = {t: all_techs_flat.count(t) for t in unique_techs}

        accept_rate = (success_count / BOARDS_PER_DIFFICULTY) * 100

        results[difficulty] = {
            "boards_requested": BOARDS_PER_DIFFICULTY,
            "success_count": success_count,
            "reject_count": reject_count,
            "accept_rate_pct": round(accept_rate, 1),
            "avg_time_s": round(avg_time, 3),
            "avg_attempts": round(avg_attempts, 1),
            "avg_human_score": round(avg_score, 1),
            "avg_steps": round(avg_steps, 1),
            "avg_removed": round(avg_removed, 1),
            "techniques_found": tech_counts,
        }

        status = f"  {success_count}/{BOARDS_PER_DIFFICULTY} success, "
        status += f"accept {accept_rate:.0f}%, "
        status += f"avg {avg_time:.2f}s, "
        status += f"score {avg_score:.0f}"
        print(status)

    return results


def generate_report(results: dict) -> str:
    lines = []
    lines.append("# Benchmark Report — Target Generator")
    lines.append("")
    lines.append(f"Run: {BOARDS_PER_DIFFICULTY} boards per difficulty, max {MAX_ATTEMPTS} solutions, 10 removal passes each")
    lines.append("")
    lines.append("| Difficulty | Success | Accept% | Avg Time | Avg Score | Avg Steps | Avg Removed |")
    lines.append("|------------|---------|---------|----------|-----------|-----------|-------------|")

    for diff in ["easy", "intermediate", "hard", "expert", "evil", "mythic"]:
        r = results.get(diff, {})
        lines.append(
            f"| {diff} | {r.get('success_count', 0)}/{r.get('boards_requested', 0)} "
            f"| {r.get('accept_rate_pct', 0)}% "
            f"| {r.get('avg_time_s', 0)}s "
            f"| {r.get('avg_human_score', 0)} "
            f"| {r.get('avg_steps', 0)} "
            f"| {r.get('avg_removed', 0)} |"
        )

    lines.append("")
    lines.append("## Techniques per difficulty")
    lines.append("")
    for diff in ["easy", "intermediate", "hard", "expert", "evil", "mythic"]:
        r = results.get(diff, {})
        techs = r.get("techniques_found", {})
        if techs:
            lines.append(f"### {diff}")
            for t, c in sorted(techs.items()):
                pct = round(c / r.get("success_count", 1) * 100, 0)
                lines.append(f"- {t}: {c}/{r.get('success_count', 0)} ({pct:.0f}%)")
            lines.append("")

    lines.append("## Verdict")
    all_ok = all(
        r.get("success_count", 0) > 0 for r in results.values()
    )
    if all_ok:
        lines.append("✅ All difficulties generate successfully.")
    else:
        lines.append("❌ Some difficulties failed to generate boards.")

    return "\n".join(lines)


if __name__ == "__main__":
    print("=== TARGET GENERATOR BENCHMARK ===\n")
    results = run_benchmark()
    report = generate_report(results)

    report_path = os.path.join(os.path.dirname(__file__), "benchmark_report.md")
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(report)
    print(f"\nReport written to {report_path}")
