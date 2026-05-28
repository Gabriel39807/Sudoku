"""Generate Campaign Stage 5 — Beginner Journey, 100 levels."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", ".."))
from tools.master_generator.variants.classic_9x9 import generate_stage5

OUTPUT_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "campaign", "stage_05"
)
print("Generating Campaign Stage 5 — Beginner Journey")
print("=" * 50)
print(f"Output: {OUTPUT_DIR}")
print()
results = generate_stage5(OUTPUT_DIR, seed=42)
print()
print(f"Generated {len(results)} / 100 levels")
if results:
    by_tier = {}
    for r in results:
        by_tier.setdefault(r["tier_max"], 0)
        by_tier[r["tier_max"]] += 1
    print("Tier distribution:")
    for t, c in sorted(by_tier.items()):
        print(f"  Tier {t}: {c} levels")
    avg_clues = sum(r["clues"] for r in results) / len(results)
    print(f"\nAvg clues: {avg_clues:.1f}")
