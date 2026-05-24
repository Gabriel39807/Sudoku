"""Generate 1000 expert boards to assets/boards/expert/."""
import sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", ".."))

from tools.master_generator.variants.expert_9x9 import generate_expert_dataset, _restore_all

OUTPUT_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "expert"
)
CHECKPOINT_PATH = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "expert", ".checkpoint.json"
)

print("Generating Expert Dataset — 1000 puzzles")
print("=" * 50)
print(f"Output: {OUTPUT_DIR}")
print()

start = time.time()
results = generate_expert_dataset(OUTPUT_DIR, CHECKPOINT_PATH, seed=42)
elapsed = time.time() - start

print()
print(f"Generated {len(results)} / 1000 boards in {elapsed:.1f}s")
print(f"Average: {elapsed / max(len(results), 1):.2f}s/puzzle")

if results:
    by_tramo = {}
    for r in results:
        t = r.get("tramo", 0)
        by_tramo.setdefault(t, 0)
        by_tramo[t] += 1
    print("\nTramo distribution:")
    for t, c in sorted(by_tramo.items()):
        clues = next((tr["clues"] for tr in [
            {"start": 1, "clues": 44}, {"start": 201, "clues": 42},
            {"start": 401, "clues": 41}, {"start": 601, "clues": 40},
            {"start": 801, "clues": "38-39"},
        ] if tr["start"] == t), "?")
        print(f"  Tramo {t}: {c} boards ({clues} clues)")

    avg_clues = sum(r["clues"] for r in results) / len(results)
    print(f"\nAvg clues: {avg_clues:.1f}")
    print(f"Clue range: {min(r['clues'] for r in results)}-{max(r['clues'] for r in results)}")
