"""Generate expert_1000_report.md."""
import os, json, hashlib, collections
from datetime import datetime

EXPERT_DIR = "assets/boards/expert"
boards = []
for i in range(1, 1001):
    with open(os.path.join(EXPERT_DIR, f"expert_{i:04d}.json")) as f:
        boards.append(json.load(f))

clues_list = [b["clues"] for b in boards]
fill_list = [b["fill_percent"] for b in boards]
steps_list = [b["steps"] for b in boards]
tramo_groups = collections.defaultdict(list)
sym_counts = collections.Counter()
tech_info = collections.Counter()
fish_counts = collections.Counter()
wing_counts = collections.Counter()
all_technique_names = set()

for b in boards:
    tramo_groups[b["tramo"]].append(b)
    sym_counts[b["symmetry"]] += 1
    for t in b["techniques"]:
        tech_info[t] += 1
        all_technique_names.add(t)
        t_lower = t.lower()
        if "fish" in t_lower or t_lower in ("swordfish", "jellyfish", "xwing"):
            fish_counts[t] += 1
        if "wing" in t_lower and t_lower not in ("swordfish", "jellyfish"):
            wing_counts[t] += 1

times_list = [b["estimated_time_minutes"] for b in boards]
human_scores = [b["human_score"] for b in boards]

lines = []
lines.append("# Expert Dataset Report — 1000 puzzles")
lines.append("")
lines.append(f"*Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*")
lines.append("")
lines.append("## Visual Profile")
lines.append("")
lines.append(f"- **Clue range**: {min(clues_list)}–{max(clues_list)}")
lines.append(f"- **Average clues**: {sum(clues_list)/1000:.1f}")
lines.append(f"- **Average fill%**: {sum(fill_list)/1000:.1f}%")
lines.append(f"- **Fill range**: {min(fill_list):.1f}%–{max(fill_list):.1f}%")
lines.append(f"- **Time range**: {min(times_list)}–{max(times_list)} min")
lines.append(f"- **Human score range**: {min(human_scores)}–{max(human_scores)}")
lines.append("")
lines.append("## Tramo Distribution")
lines.append("")
lines.append("| Tramo | Boards | Clues | Tier | Techniques |")
lines.append("|-------|--------|-------|------|------------|")
for t_start in sorted(tramo_groups):
    g = tramo_groups[t_start]
    b0 = g[0]
    lines.append(f"| {t_start} | {len(g)} | {b0['clues']} | {b0['tier_max']} | {len(b0['techniques'])} |")
lines.append("")
lines.append("## Symmetry")
lines.append("")
lines.append(f"- **Rotational**: {sym_counts['rotational']} ({sym_counts['rotational']/10:.0f}%)")
lines.append(f"- **Mirror**: {sym_counts['mirror']} ({sym_counts['mirror']/10:.0f}%)")
lines.append(f"- **Random**: {sym_counts['random']} ({sym_counts['random']/10:.0f}%)")
lines.append("")
lines.append("## Technique Usage")
lines.append("")
lines.append("| Technique | Boards | % |")
lines.append("|-----------|--------|---|")
for tech, count in sorted(tech_info.items(), key=lambda x: -x[1]):
    lines.append(f"| {tech} | {count} | {count/10:.1f}% |")
lines.append("")
lines.append("### Fish Usage")
lines.append("")
lines.append("| Fish | Boards | % |")
lines.append("|------|--------|---|")
for tech, count in sorted(fish_counts.items(), key=lambda x: -x[1]):
    lines.append(f"| {tech} | {count} | {count*100//1000}% |")
lines.append("")
lines.append("### Wings Usage")
lines.append("")
lines.append("| Wing | Boards | % |")
lines.append("|------|--------|---|")
for tech, count in sorted(wing_counts.items(), key=lambda x: -x[1]):
    lines.append(f"| {tech} | {count} | {count*100//1000}% |")

report = "\n".join(lines)
output_path = "expert_1000_report.md"
with open(output_path, "w") as f:
    f.write(report)
print(f"Report written to {output_path}")
print(report)
