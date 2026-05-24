"""Generate Campaign Stage 3 report."""
import os, sys, json, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", ".."))
from tools.master_generator.variants.mini_8x8 import (
    Mini8x8BacktrackSolver, Mini8x8TechniqueSolver, Mini8x8Board,
    LEVEL_DESIGNS, TIER_DEFINITIONS,
)

CAMPAIGN_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "campaign", "stage_03",
)
REPORT_DIR = os.path.join(os.path.dirname(__file__), "..", "reports")
os.makedirs(REPORT_DIR, exist_ok=True)

files = sorted(f for f in os.listdir(CAMPAIGN_DIR) if f.endswith(".json"))
puzzles = [json.load(open(os.path.join(CAMPAIGN_DIR, f))) for f in files]

clues = [p["clues"] for p in puzzles]
tiers = [p["tier_max"] for p in puzzles]
chapters = {}

t0 = time.time()
all_unique = all_solvable = solution_match = True
for p in puzzles:
    board = Mini8x8Board.from_string(p["puzzle"])
    if not Mini8x8BacktrackSolver.has_unique_solution(board):
        all_unique = False
    ok, _ = Mini8x8TechniqueSolver.solve(board)
    if not ok:
        all_solvable = False
    solved = Mini8x8BacktrackSolver.solve(board)
    if solved.to_string() != p["solution"]:
        solution_match = False
    ch = p.get("chapter", "unknown")
    if ch not in chapters:
        chapters[ch] = {"count": 0, "clues": [], "tiers": [], "scores": []}
    chapters[ch]["count"] += 1
    chapters[ch]["clues"].append(p["clues"])
    chapters[ch]["tiers"].append(p["tier_max"])
    chapters[ch]["scores"].append(p.get("visual_score", 0))
elapsed = time.time() - t0

all_techs = set()
for p in puzzles:
    for t in p.get("techniques", []):
        all_techs.add(t)

eco_totals = {"coins": 0, "souls": 0, "perfect_bonus": 0, "combo_bonus": 0, "chapter_reward": 0}
for p in puzzles:
    e = p.get("economy", {})
    for k in eco_totals:
        eco_totals[k] += e.get(k, 0)

lines = []
lines.append("# Campaign Stage 3 — Mini 8x8 Report")
lines.append("")
lines.append("## Summary")
lines.append(f"- **Levels**: {len(puzzles)} / 100")
lines.append(f"- **Variant**: mini_8x8 (8×8, 2×4 blocks, 64 cells)")
lines.append(f"- **Clue range**: {min(clues)}–{max(clues)} (avg {sum(clues)/len(clues):.1f})")
lines.append(f"- **Tier range**: {min(tiers)}–{max(tiers)}")
lines.append(f"- **Validation time**: {elapsed:.1f}s")
lines.append(f"- **Techniques**: {len(all_techs)}")
lines.append(f"- **Total coins**: {eco_totals['coins']:,}")
lines.append(f"- **Total souls**: {eco_totals['souls']:,}")
lines.append("")
lines.append("## Techniques")
for t in sorted(all_techs):
    cnt = sum(1 for p in puzzles if t in p.get("techniques", []))
    lines.append(f"- **{t}**: {cnt} puzzles ({cnt/len(puzzles)*100:.0f}%)")
lines.append("")
lines.append("## Progression")
lines.append("| Chapter | Levels | Clues | Tier | Techniques |")
lines.append("|---------|--------|-------|------|------------|")
for d in LEVEL_DESIGNS:
    lines.append(
        f"| {d['label']} | {d['start']}–{d['end']} | "
        f"{d['min_clues']}–{d['max_clues']} | {d['max_tier']} | "
        f"{len(TIER_DEFINITIONS[d['max_tier']])} techniques |"
    )
lines.append("")
lines.append("## Chapter Detail")
for ch, data in sorted(chapters.items()):
    avg_c = sum(data["clues"]) / len(data["clues"])
    avg_s = sum(data["scores"]) / len(data["scores"])
    lines.append(f"- **{ch}**: {data['count']} levels, clues {min(data['clues'])}–{max(data['clues'])} "
                 f"(avg {avg_c:.1f}), visual_score {avg_s:.3f}")
lines.append("")
lines.append("## Validation")
lines.append(f"- **Unique solutions**: {'PASS' if all_unique else 'FAIL'}")
lines.append(f"- **All solvable**: {'PASS' if all_solvable else 'FAIL'}")
lines.append(f"- **Solution match**: {'PASS' if solution_match else 'FAIL'}")
lines.append("")
lines.append("## Per-Level")
lines.append("| # | ID | Clues | Tier | Chapter | Techniques |")
lines.append("|---|-----|-------|------|---------|------------|")
for p in sorted(puzzles, key=lambda x: x["level_index"]):
    techs = ", ".join(p.get("techniques", []))
    lines.append(f"| {p['level_index']:3d} | {p['level_id']} | {p['clues']} | {p['tier_max']} | "
                 f"{p.get('chapter','')} | {techs} |")

path = os.path.join(REPORT_DIR, "campaign_stage3_report.md")
with open(path, "w") as f:
    f.write("\n".join(lines))
print("Report:", path)
print("All unique:", all_unique, "| All solvable:", all_solvable, "| Solution match:", solution_match)
