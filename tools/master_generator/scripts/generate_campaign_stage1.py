"""Generate Campaign Stage 1 — 50 mini 4x4 puzzles."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", ".."))

from tools.master_generator.variants.mini_4x4 import generate_stage1

OUTPUT_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "campaign", "stage_01"
)

print("Generating Campaign Stage 1 — Mini 4x4")
print("=" * 50)
print(f"Output: {OUTPUT_DIR}")
print()

results = generate_stage1(OUTPUT_DIR, seed=42)

print()
print(f"Generated {len(results)} / 50 levels")
print()

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
    print(f"Clue range: {min(r['clues'] for r in results)}-{max(r['clues'] for r in results)}")
