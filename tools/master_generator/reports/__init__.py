"""Report generators for datasets, balance, technique usage, campaigns."""
import os
from typing import Dict, List
from tools.master_generator.launcher.auditor import audit_puzzles
from tools.master_generator.export import batch_hash


class ReportManager:
    def __init__(self, report_path: str = "reports/"):
        self.report_path = report_path

    def _ensure_path(self):
        os.makedirs(self.report_path, exist_ok=True)

    def generation_report(self, puzzles: List[Dict], elapsed: float) -> str:
        self._ensure_path()
        audit = audit_puzzles(puzzles)
        lines = [
            "# Generation Report",
            "",
            "## Summary",
            f"- **Total generated**: {len(puzzles)}",
            f"- **Elapsed**: {elapsed:.1f}s",
            f"- **Batch hash**: {batch_hash(puzzles)}",
            "",
            "## Quality",
            f"- **Hash duplicates**: {audit['hash_duplicates']}",
            f"- **Rotations**: {audit['rotations']}",
            f"- **Mirrors**: {audit['mirrors']}",
            f"- **Multi-solution**: {audit['multi_solution']}",
            f"- **Wrong difficulty**: {audit['wrong_difficulty']}",
            f"- **Valid count**: {audit['valid_count']}",
            "",
            "## Difficulty Distribution",
        ]
        dist = {}
        for p in puzzles:
            d = p.get("difficulty", "unknown")
            dist[d] = dist.get(d, 0) + 1
        for d, c in sorted(dist.items()):
            lines.append(f"- **{d}**: {c}")
        lines.append("")
        path = os.path.join(self.report_path, "generation_report.md")
        with open(path, "w") as f:
            f.write("\n".join(lines))
        return path

    def balance_report(self, puzzles: List[Dict]) -> str:
        self._ensure_path()
        if not puzzles:
            return ""
        avg_clues = sum(p.get("clues", 0) for p in puzzles) / len(puzzles)
        avg_score = sum(p.get("difficulty_score", 0) for p in puzzles) / len(puzzles)
        lines = [
            "# Balance Report",
            "",
            "## Averages",
            f"- **Avg clues**: {avg_clues:.1f}",
            f"- **Avg density**: {avg_clues / 81 * 100:.1f}%",
            f"- **Avg difficulty score**: {avg_score:.2f}",
            "",
            "## Clue Distribution",
        ]
        clue_counts = [p.get("clues", 0) for p in puzzles]
        lines.append(f"- **Min**: {min(clue_counts) if clue_counts else 0}")
        lines.append(f"- **Max**: {max(clue_counts) if clue_counts else 0}")
        lines.append("")
        path = os.path.join(self.report_path, "balance_report.md")
        with open(path, "w") as f:
            f.write("\n".join(lines))
        return path

    def technique_usage_report(self, puzzles: List[Dict]) -> str:
        self._ensure_path()
        usage = {}
        for p in puzzles:
            for tech in p.get("technique_breakdown", {}).keys():
                usage[tech] = usage.get(tech, 0) + 1
        lines = [
            "# Technique Usage Report",
            "",
            "| Technique | Used In | % of Puzzles |",
            "|-----------|---------|--------------|",
        ]
        total = len(puzzles) or 1
        for tech, count in sorted(usage.items(), key=lambda x: -x[1]):
            pct = count / total * 100
            lines.append(f"| {tech} | {count} | {pct:.1f}% |")
        path = os.path.join(self.report_path, "technique_usage.md")
        with open(path, "w") as f:
            f.write("\n".join(lines))
        return path
