"""Variant definitions — registered variants for future generation."""
from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class Variant:
    id: str
    label: str
    grid_size: int
    cells: int
    description: str
    status: str  # "active", "registered", "future"
    requires: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)


VARIANTS = [
    Variant(
        id="classic_9x9",
        label="Classic 9x9",
        grid_size=9,
        cells=81,
        description="Standard 9x9 Sudoku",
        status="active",
        tags=["standard", "human_solver"],
    ),
    Variant(
        id="mini_4x4",
        label="Mini 4x4",
        grid_size=4,
        cells=16,
        description="4x4 Sudoku for beginners",
        status="registered",
        tags=["mini", "campaign"],
    ),
    Variant(
        id="mini_6x6",
        label="Mini 6x6",
        grid_size=6,
        cells=36,
        description="6x6 Sudoku with 2x3 blocks",
        status="registered",
        tags=["mini", "campaign"],
    ),
    Variant(
        id="mini_8x8",
        label="Mini 8x8",
        grid_size=8,
        cells=64,
        description="8x8 Sudoku with 2x4 blocks",
        status="registered",
        tags=["mini", "campaign"],
    ),
    Variant(
        id="campaign_progressive",
        label="Campaign Progressive",
        grid_size=0,
        cells=0,
        description="Progressive campaign: 4x4 → 6x6 → 8x8 → 9x9",
        status="registered",
        tags=["campaign", "progressive"],
    ),
    Variant(
        id="killer",
        label="Killer Sudoku",
        grid_size=9,
        cells=81,
        description="Killer Sudoku with cage sums (future)",
        status="future",
        requires=["cage_solver"],
        tags=["variant", "future"],
    ),
    Variant(
        id="x_sudoku",
        label="X Sudoku",
        grid_size=9,
        cells=81,
        description="Sudoku with diagonal constraints (future)",
        status="future",
        requires=["diagonal_constraint"],
        tags=["variant", "future"],
    ),
    Variant(
        id="windoku",
        label="Windoku",
        grid_size=9,
        cells=81,
        description="Sudoku with extra window regions (future)",
        status="future",
        requires=["window_regions"],
        tags=["variant", "future"],
    ),
    Variant(
        id="jigsaw",
        label="Jigsaw Sudoku",
        grid_size=9,
        cells=81,
        description="Jigsaw Sudoku with irregular regions (future)",
        status="future",
        requires=["irregular_regions"],
        tags=["variant", "future"],
    ),
]


class VariantRegistry:
    @staticmethod
    def get(variant_id: str) -> Variant:
        for v in VARIANTS:
            if v.id == variant_id:
                return v
        raise ValueError(f"Unknown variant: {variant_id}")

    @staticmethod
    def list() -> List[str]:
        return [v.id for v in VARIANTS]

    @staticmethod
    def active() -> List[Variant]:
        return [v for v in VARIANTS if v.status == "active"]

    @staticmethod
    def by_status(status: str) -> List[Variant]:
        return [v for v in VARIANTS if v.status == status]

    @staticmethod
    def by_tag(tag: str) -> List[Variant]:
        return [v for v in VARIANTS if tag in v.tags]
