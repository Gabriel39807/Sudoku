from __future__ import annotations
from typing import Dict, Iterator, List, Optional, Type

from tools.human_solver.technique import Technique, TechniqueTier


class Registry:
    _instance: Optional[Registry] = None

    def __init__(self):
        self._techniques: Dict[str, Technique] = {}
        self._classes: Dict[str, Type[Technique]] = {}

    @classmethod
    def instance(cls) -> Registry:
        if cls._instance is None:
            cls._instance = Registry()
        return cls._instance

    def register(self, technique_cls: Type[Technique]) -> Type[Technique]:
        inst = technique_cls()
        self._techniques[inst.id] = inst
        self._classes[inst.id] = technique_cls
        return technique_cls

    def get(self, technique_id: str) -> Optional[Technique]:
        return self._techniques.get(technique_id)

    def get_class(self, technique_id: str) -> Optional[Type[Technique]]:
        return self._classes.get(technique_id)

    def all(self) -> Iterator[Technique]:
        yield from self._techniques.values()

    def by_tier(self, tier: TechniqueTier) -> Iterator[Technique]:
        for t in self._techniques.values():
            if t.tier == tier:
                yield t

    def by_tier_number(self, n: int) -> Iterator[Technique]:
        for t in self._techniques.values():
            if t.tier.value == n:
                yield t

    def implemented(self) -> Iterator[Technique]:
        for t in self._techniques.values():
            if t.implemented and t.enabled:
                yield t

    def enabled_by_tier(self, tier: TechniqueTier) -> List[Technique]:
        return [t for t in self._techniques.values() if t.tier == tier and t.enabled]

    def count(self) -> int:
        return len(self._techniques)

    def count_implemented(self) -> int:
        return sum(1 for t in self._techniques.values() if t.implemented)

    def status_summary(self) -> dict:
        return {
            "total": self.count(),
            "implemented": self.count_implemented(),
            "planned": sum(1 for t in self._techniques.values() if t.status == "planned"),
            "experimental": sum(1 for t in self._techniques.values() if t.status == "experimental"),
            "deprecated": sum(1 for t in self._techniques.values() if t.status == "deprecated"),
        }

    def summary(self) -> str:
        lines = ["Technique Registry Summary", "=" * 40]
        tier_names = {
            1: "Tier 1 - Basic",
            2: "Tier 2 - Intersections",
            3: "Tier 3 - Wings/Fish",
            4: "Tier 4 - Uniqueness",
            5: "Tier 5 - Chains",
            6: "Tier 6 - ALS",
            7: "Tier 7 - Exotic Fish",
            8: "Tier 8 - Extreme",
        }
        for tier_num in range(1, 9):
            techs = list(self.by_tier_number(tier_num))
            techs = list(self.by_tier_number(tier_num))
            if techs:
                lines.append(f"\nTier {tier_num}:")
                for t in techs:
                    status = "✓" if t.implemented else "○"
                    exp = " [EXP]" if t.experimental else ""
                    lines.append(f"  {status} {t.id:30s} {t.name:25s} ({t.status}){exp}")
        lines.append(f"\nTotal: {self.count()} | Implemented: {self.count_implemented()}")
        return "\n".join(lines)

    @staticmethod
    def auto_register() -> Registry:
        reg = Registry.instance()
        reg._discover_techniques()
        return reg

    def _discover_techniques(self):
        import importlib
        import pkgutil

        technique_packages = [
            "tools.human_solver.techniques.basic",
            "tools.human_solver.techniques.intermediate",
            "tools.human_solver.techniques.wings",
            "tools.human_solver.techniques.uniqueness",
            "tools.human_solver.techniques.chains",
            "tools.human_solver.techniques.als",
            "tools.human_solver.techniques.fish",
            "tools.human_solver.techniques.extreme",
        ]

        for package_name in technique_packages:
            try:
                package = importlib.import_module(package_name)
                if hasattr(package, "__all__"):
                    for attr_name in package.__all__:
                        attr = getattr(package, attr_name, None)
                        if attr is not None and isinstance(attr, type):
                            from tools.human_solver.technique import Technique as TechBase
                            if issubclass(attr, TechBase) and attr is not TechBase:
                                if attr.id not in self._techniques:
                                    self.register(attr)
            except ImportError:
                pass

    def get_registered_ids(self) -> List[str]:
        return sorted(self._techniques.keys())

    def statistics(self) -> dict:
        stats = {"by_tier": {}, "by_category": {}, "by_status": {}}
        for t in self._techniques.values():
            tier_key = f"tier_{t.tier.value}"
            stats["by_tier"][tier_key] = stats["by_tier"].get(tier_key, 0) + 1
            cat_key = t.category.name.lower()
            stats["by_category"][cat_key] = stats["by_category"].get(cat_key, 0) + 1
            stats["by_status"][t.status] = stats["by_status"].get(t.status, 0) + 1
        return stats
