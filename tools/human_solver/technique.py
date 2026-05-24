from __future__ import annotations
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Dict, List, Optional, Set, Tuple


class TechniqueTier(Enum):
    TIER1_BASIC = 1
    TIER2_INTERSECTIONS = 2
    TIER3_WINGS_FISH = 3
    TIER4_UNIQUENESS = 4
    TIER5_CHAINS = 5
    TIER6_ALS = 6
    TIER7_EXOTIC_FISH = 7
    TIER8_EXTREME = 8


class TechniqueCategory(Enum):
    BASIC = auto()
    INTERSECTION = auto()
    WING = auto()
    FISH = auto()
    UNIQUENESS = auto()
    CHAIN = auto()
    ALS = auto()
    EXOTIC_FISH = auto()
    EXTREME = auto()
    FORCING_CHAIN = auto()
    PATTERN_OVERLAY = auto()


@dataclass
class TechniqueResult:
    technique_id: str
    technique_name: str = ""
    placements: List[Tuple[int, int, int]] = field(default_factory=list)
    eliminations: List[Tuple[int, int, int]] = field(default_factory=list)
    cells_affected: List["Cell"] = field(default_factory=list)
    reason: str = ""
    difficulty_delta: float = 0.0
    steps: List[str] = field(default_factory=list)

    @property
    def has_placement(self) -> bool:
        return len(self.placements) > 0

    @property
    def has_elimination(self) -> bool:
        return len(self.eliminations) > 0

    @property
    def is_empty(self) -> bool:
        return not self.has_placement and not self.has_elimination

    def merge(self, other: TechniqueResult) -> TechniqueResult:
        return TechniqueResult(
            technique_id=self.technique_id,
            technique_name=self.technique_name or other.technique_name,
            placements=self.placements + other.placements,
            eliminations=self.eliminations + other.eliminations,
            cells_affected=list(
                set(self.cells_affected + other.cells_affected)
            ),
            reason=self.reason or other.reason,
            difficulty_delta=max(self.difficulty_delta, other.difficulty_delta),
            steps=self.steps + other.steps,
        )

    def __repr__(self) -> str:
        parts = []
        if self.placements:
            cells_str = ", ".join(
                f"r{r + 1}c{c + 1}={v}" for r, c, v in self.placements
            )
            parts.append(f"place [{cells_str}]")
        if self.eliminations:
            cells_str = ", ".join(
                f"r{r + 1}c{c + 1}!{v}" for r, c, v in self.eliminations
            )
            parts.append(f"elim [{cells_str}]")
        if self.reason:
            parts.append(f"reason={self.reason}")
        return f"TechniqueResult({', '.join(parts)})"


class Technique(ABC):
    id: str = ""
    name: str = ""
    tier: TechniqueTier = TechniqueTier.TIER1_BASIC
    category: TechniqueCategory = TechniqueCategory.BASIC
    difficulty_weight: float = 1.0
    human_difficulty: float = 1.0
    requires_notes: bool = True
    requires_coloring: bool = False
    requires_bivalue: bool = False
    requires_als: bool = False
    requires_uniqueness: bool = False
    enabled: bool = True
    implemented: bool = True
    experimental: bool = False
    status: str = "implemented"

    @abstractmethod
    def apply(self, board: "Board") -> Optional[TechniqueResult]:
        ...

    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)
        if not cls.id:
            cls.id = cls.__name__.lower()
        if not cls.name:
            cls.name = cls.__name__

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__} [{self.id}] tier={self.tier.value}>"
