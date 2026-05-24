"""Generate Campaign Stage 1 report."""
import os, sys, json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", ".."))
from tools.master_generator.variants.mini_4x4 import (
    MiniBacktrackSolver, MiniTechniqueSolver, MiniBoard, LEVEL_DESIGNS
)

CAMPAIGN_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "campaign", "stage_01",
)
REPORT_DIR = os.path.join(
    os.path.dirname(__file__), "..", "reports",
)
os.makedirs(REPORT_DIR, exist_ok=True)

files = sorted(f for f in os.listdir(CAMPAIGN_DIR) if f.endswith(".json"))
puzzles = [json.load(open(os.path.join(CAMPAIGN_DIR, f))) for f in files]

clue_counts = [p["clues"] for p in puzzles]
difficulties = set(p["difficulty"] for p in puzzles)
tiers = set(p["tier_max"] for p in puzzles)
techniques_used = set()
for p in puzzles:
    for t in p.get("techniques", []):
        techniques_used.add(t)

lines = []
lines.append("# Campaign Stage 1 — Mini 4x4 Report")
lines.append("")
lines.append("## Summary")
lines.append("")
lines.append(f"- **Levels**: {len(puzzles)} / 50")
lines.append(f"- **Variant**: mini_4x4 (4×4, 2×2 blocks)")
lines.append(f"- **Difficulty labels**: {', '.join(sorted(difficulties))}")
lines.append(f"- **Tier range**: {min(tiers)}–{max(tiers)}")
lines.append(f"- **Clue range**: {min(clue_counts)}–{max(clue_counts)}")
lines.append(f"- **Avg clues**: {sum(clue_counts)/len(clue_counts):.1f}")
lines.append(f"- **Techniques used**: {', '.join(sorted(techniques_used))}")
lines.append("")
lines.append("## Clue Progression")
lines.append("")
lines.append("| Levels | Clues  | Difficulty |")
lines.append("|--------|--------|------------|")
lines.append("| 1–10   | 12–14  | Guided Intro |")
lines.append("| 11–20  | 10–12  | Hidden Discovery |")
lines.append("| 21–35  | 8–10   | Pointing Practice |")
lines.append("| 36–50  | 7–8    | Mini Challenge |")
lines.append("")
lines.append("## Per-Level Breakdown")
lines.append("")
lines.append("| # | ID | Clues | Tier | Difficulty | Techniques |")
lines.append("|---|-----|-------|------|------------|------------|")
lines.sort()
for p in sorted(puzzles, key=lambda x: x["level_index"]):
    techs = ", ".join(p.get("techniques", []))
    lines.append(f"| {p['level_index']:2d} | {p['level_id']} | {p['clues']} | {p['tier_max']} | {p['difficulty']} | {techs} |")

lines.append("")
lines.append("## Validation")
lines.append("")

all_unique = True
all_solvable = True
solution_match = True
for p in puzzles:
    board = MiniBoard.from_string(p["puzzle"])
    if not MiniBacktrackSolver.has_unique_solution(board):
        all_unique = False
        lines.append(f"- **FAIL** {p['level_id']}: multiple solutions")
    ok, _ = MiniTechniqueSolver.solve(board)
    if not ok:
        all_solvable = False
        lines.append(f"- **FAIL** {p['level_id']}: not solvable")
    solved = MiniBacktrackSolver.solve(board)
    if solved.to_string() != p["solution"]:
        solution_match = False
        lines.append(f"- **FAIL** {p['level_id']}: solution mismatch")

lines.append(f"- **Unique solutions**: {'PASS' if all_unique else 'FAIL'}")
lines.append(f"- **All solvable**: {'PASS' if all_solvable else 'FAIL'}")
lines.append(f"- **Solution match**: {'PASS' if solution_match else 'FAIL'}")

path = os.path.join(REPORT_DIR, "campaign_stage1_report.md")
with open(path, "w") as f:
    f.write("\n".join(lines))

print("Report written to", path)
print("All unique:", all_unique)
print("All solvable:", all_solvable)
print("Solution match:", solution_match)
