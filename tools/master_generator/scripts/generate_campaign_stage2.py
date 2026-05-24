"""Generate Campaign Stage 2 — Mini 6x6, 75 levels."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", ".."))
from tools.master_generator.variants.mini_6x6 import generate_stage2

output_dir = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "campaign", "stage_02",
)
print("Generating Campaign Stage 2 — Mini 6x6")
print("=" * 50)
print(f"Output: {output_dir}")
print()
results = generate_stage2(output_dir, seed=42)
total = sum(
    1 for d in [
        {"start": 1, "end": 15},
        {"start": 16, "end": 35},
        {"start": 36, "end": 55},
        {"start": 56, "end": 75},
    ] for _ in range(d["start"], d["end"] + 1)
)
print(f"\nGenerated {len(results)} / {total} levels")
