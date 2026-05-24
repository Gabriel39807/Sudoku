"""Generate Campaign Stage 2 report."""
import os, sys, json, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", ".."))
from tools.master_generator.variants.mini_6x6 import (
    Mini6x6BacktrackSolver, Mini6x6TechniqueSolver, Mini6x6Board,
    LEVEL_DESIGNS, TIER_DEFINITIONS,
)

CAMPAIGN_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "campaign", "stage_02",
)
REPORT_DIR = os.path.join(
    os.path.dirname(__file__), "..", "reports",
)
os.makedirs(REPORT_DIR, exist_ok=True)

files = sorted(f for f in os.listdir(CAMPAIGN_DIR) if f.endswith(".json"))
puzzles = [json.load(open(os.path.join(CAMPAIGN_DIR, f))) for f in files]

clue_counts = [p["clues"] for p in puzzles]
tiers = [p["tier_max"] for p in puzzles]
chapters = {}

t0 = time.time()
all_unique = True
all_solvable = True
solution_match = True
for p in puzzles:
    board = Mini6x6Board.from_string(p["puzzle"])
    if not Mini6x6BacktrackSolver.has_unique_solution(board):
        all_unique = False
    ok, _ = Mini6x6TechniqueSolver.solve(board)
    if not ok:
        all_solvable = False
    solved = Mini6x6BacktrackSolver.solve(board)
    if solved.to_string() != p["solution"]:
        solution_match = False
    ch = p.get("chapter", "unknown")
    if ch not in chapters:
        chapters[ch] = {"count": 0, "clues": [], "tiers": []}
    chapters[ch]["count"] += 1
    chapters[ch]["clues"].append(p["clues"])
    chapters[ch]["tiers"].append(p["tier_max"])
elapsed = time.time() - t0

all_techs = set()
for p in puzzles:
    for t in p.get("techniques", []):
        all_techs.add(t)

lines = []
lines.append("# Campaign Stage 2 — Mini 6x6 Report")
lines.append("")
lines.append("## Summary")
lines.append("")
lines.append(f"- **Levels**: {len(puzzles)} / 75")
lines.append(f"- **Variant**: mini_6x6 (6×6, 2×3 blocks, 36 cells)")
lines.append(f"- **Clue range**: {min(clue_counts)}–{max(clue_counts)}")
lines.append(f"- **Avg clues**: {sum(clue_counts)/len(clue_counts):.1f}")
lines.append(f"- **Tier range**: {min(tiers)}–{max(tiers)}")
lines.append(f"- **Validation time**: {elapsed:.1f}s")
lines.append(f"- **Techniques count**: {len(all_techs)}")
lines.append("")
lines.append("## Techniques Used")
lines.append("")
for t in sorted(all_techs):
    count = sum(1 for p in puzzles if t in p.get("techniques", []))
    pct = count / len(puzzles) * 100
    lines.append(f"- **{t}**: {count} puzzles ({pct:.1f}%)")
lines.append("")
lines.append("## Chapter Progression")
lines.append("")
lines.append("| Chapter | Levels | Clues | Tier | Techniques |")
lines.append("|---------|--------|-------|------|------------|")
for d in LEVEL_DESIGNS:
    ch = d["label"]
    lines.append(
        f"| {ch} | {d['start']}–{d['end']} | "
        f"{d['min_clues']}–{d['max_clues']} | {d['max_tier']} | "
        f"{', '.join(sorted(TIER_DEFINITIONS[d['max_tier']]))} |"
    )
lines.append("")
lines.append("## Chapter Detail")
lines.append("")
for ch, data in sorted(chapters.items()):
    avg_c = sum(data["clues"]) / len(data["clues"])
    lines.append(f"### {ch}")
    lines.append(f"- **Count**: {data['count']}")
    lines.append(f"- **Clues**: {min(data['clues'])}–{max(data['clues'])} (avg {avg_c:.1f})")
    lines.append(f"- **Tiers**: {min(data['tiers'])}–{max(data['tiers'])}")
    lines.append("")
lines.append("## Validation")
lines.append("")
lines.append(f"- **Unique solutions**: {'PASS' if all_unique else 'FAIL'}")
lines.append(f"- **All solvable**: {'PASS' if all_solvable else 'FAIL'}")
lines.append(f"- **Solution match**: {'PASS' if solution_match else 'FAIL'}")
lines.append("")
lines.append("## Per-Level Breakdown")
lines.append("")
lines.append("| # | ID | Clues | Tier | Chapter | Techniques |")
lines.append("|---|-----|-------|------|---------|------------|")
for p in sorted(puzzles, key=lambda x: x["level_index"]):
    techs = ", ".join(p.get("techniques", []))
    lines.append(
        f"| {p['level_index']:2d} | {p['level_id']} | {p['clues']} | "
        f"{p['tier_max']} | {p.get('chapter', '')} | {techs} |"
    )

path = os.path.join(REPORT_DIR, "campaign_stage2_report.md")
with open(path, "w") as f:
    f.write("\n".join(lines))

print("Report:", path)
print("All unique:", all_unique)
print("All solvable:", all_solvable)
print("Solution match:", solution_match)
