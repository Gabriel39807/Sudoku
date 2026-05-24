"""Generate Campaign Stage 3 — Mini 8x8, 100 levels."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", ".."))
from tools.master_generator.variants.mini_8x8 import generate_stage3

output_dir = os.path.join(
    os.path.dirname(__file__), "..", "..", "..",
    "assets", "boards", "campaign", "stage_03",
)
print("Generating Campaign Stage 3 — Mini 8x8")
print("=" * 50)
print(f"Output: {output_dir}")
print()
results = generate_stage3(output_dir, seed=42)
print(f"\nGenerated {len(results)} / 100 levels")
