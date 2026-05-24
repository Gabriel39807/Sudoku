#!/usr/bin/env python3
"""Run comprehensive benchmark on all famous puzzles and generate report."""
import sys, os
from datetime import datetime

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

from tools.human_solver.benchmarks import BenchmarkRunner
from tests.famous_puzzles import ALL_SOLVABLE


def generate_report(results: list) -> str:
    lines = []
    lines.append("# Benchmark Report")
    lines.append(f"\n**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append(f"**Puzzles:** {len(results)}")
    lines.append(f"**Solved:** {sum(1 for r in results if r.solved)}/{len(results)}")

    total_time = sum(r.time_ms for r in results)
    lines.append(f"**Total Time:** {total_time:.0f}ms")
    lines.append(f"**Average Time:** {total_time / len(results):.1f}ms\n")

    lines.append("## Results\n")
    lines.append("| Puzzle | Solved | Steps | Time (ms) | Empty Before | Empty After | Difficulty |")
    lines.append("|--------|--------|-------|-----------|-------------|-------------|------------|")

    for r in results:
        status = "[OK]" if r.solved else "[FAIL]"
        diff = ""
        if r.difficulty_score:
            diff = f"{r.difficulty_score['total_score']} ({r.difficulty_score['label']})"
        lines.append(
            f"| {r.puzzle_name} | {status} | {r.steps} | {r.time_ms:.1f} | "
            f"{r.empty_before} | {r.empty_after} | {diff} |"
        )

    lines.append("\n## Difficulty Scores\n")
    for r in results:
        if r.difficulty_score:
            s = r.difficulty_score
            lines.append(f"### {r.puzzle_name}")
            lines.append(f"- **Score:** {s['total_score']}")
            lines.append(f"- **Label:** {s['label']}")
            lines.append(f"- **Steps:** {s['step_count']}")
            if s['tier_distribution']:
                tiers_str = ", ".join(f"{k}: {v}" for k, v in s['tier_distribution'].items())
                lines.append(f"- **Tiers Used:** {tiers_str}")

    lines.append("\n## Technique Usage\n")
    tech_totals = {}
    for r in results:
        for tech_id, count in r.techniques_used.items():
            tech_totals[tech_id] = tech_totals.get(tech_id, 0) + count

    if tech_totals:
        lines.append("| Technique | Total Uses |")
        lines.append("|-----------|-----------|")
        for tech_id in sorted(tech_totals, key=lambda t: -tech_totals[t]):
            lines.append(f"| {tech_id} | {tech_totals[tech_id]} |")

    return "\n".join(lines)


def main():
    br = BenchmarkRunner()
    br.register_puzzles(ALL_SOLVABLE)

    print(f"Running benchmark on {len(ALL_SOLVABLE)} puzzles...\n")

    results = br.run_all(max_iterations=200)

    print(br.summary())
    print(f"Solved: {sum(1 for r in results if r.solved)}/{len(results)} "
          f"({sum(1 for r in results if r.solved) / len(results) * 100:.1f}%)")

    report_path = os.path.join(os.path.dirname(__file__), "reports", "benchmark_report.md")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(generate_report(results))
    print(f"\nReport saved to: {report_path}")


if __name__ == "__main__":
    main()
