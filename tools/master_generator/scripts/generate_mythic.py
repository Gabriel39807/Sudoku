"""Generate 500 mythic boards to assets/boards/mythic/."""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", ".."))

from tools.master_generator.variants.mythic_9x9 import generate_mythic_dataset, _restore_all

OUTPUT_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "mythic"
)
CHECKPOINT_PATH = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "mythic", ".checkpoint.json"
)

print("Generating Mythic Dataset — 500 puzzles")
print("=" * 50)
print(f"Output: {OUTPUT_DIR}")
print()

start = time.time()
results, downgrade_log = generate_mythic_dataset(OUTPUT_DIR, CHECKPOINT_PATH, seed=42)
elapsed = time.time() - start

print()
print(f"Generated {len(results)} / 500 boards in {elapsed:.1f}s")
if results:
    print(f"Average: {elapsed / max(len(results), 1):.2f}s/puzzle")

print("\nDowngrade report:")
for line in downgrade_log:
    print(f"  {line}")

if results:
    by_tramo = {}
    for r in results:
        t = r.get("tramo", 0)
        by_tramo.setdefault(t, 0)
        by_tramo[t] += 1
    print("\nTramo distribution:")
    for t, c in sorted(by_tramo.items()):
        print(f"  Tramo {t}: {c} boards")
    if results:
        avg_clues = sum(r["clues"] for r in results) / len(results)
        print(f"\nAvg clues: {avg_clues:.1f}")
        print(f"Clue range: {min(r['clues'] for r in results)}-{max(r['clues'] for r in results)}")
