"""Configuration manager for generator_profile.json."""
import json
import os
from dataclasses import dataclass, field, asdict
from typing import List, Optional


DEFAULT_PROFILE = {
    "variant": "classic_9x9",
    "difficulty": "easy",
    "count": 10,
    "symmetry": "rotational",
    "min_clues": None,
    "max_clues": None,
    "required_techniques": [],
    "forbidden_techniques": [],
    "campaign_stage": None,
    "seed": None,
    "output_format": "json",
    "export_path": "exports/",
    "checkpoint": True,
    "checkpoint_interval": 50,
}


@dataclass
class GenerationProfile:
    variant: str = "classic_9x9"
    difficulty: str = "easy"
    count: int = 10
    symmetry: Optional[str] = None
    min_clues: Optional[int] = None
    max_clues: Optional[int] = None
    required_techniques: List[str] = field(default_factory=list)
    forbidden_techniques: List[str] = field(default_factory=list)
    campaign_stage: Optional[int] = None
    seed: Optional[int] = None
    output_format: str = "json"
    export_path: str = "exports/"
    checkpoint: bool = True
    checkpoint_interval: int = 50

    def to_dict(self) -> dict:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: dict):
        return cls(
            variant=data.get("variant", "classic_9x9"),
            difficulty=data.get("difficulty", "easy"),
            count=data.get("count", 10),
            symmetry=data.get("symmetry"),
            min_clues=data.get("min_clues"),
            max_clues=data.get("max_clues"),
            required_techniques=data.get("required_techniques", []),
            forbidden_techniques=data.get("forbidden_techniques", []),
            campaign_stage=data.get("campaign_stage"),
            seed=data.get("seed"),
            output_format=data.get("output_format", "json"),
            export_path=data.get("export_path", "exports/"),
            checkpoint=data.get("checkpoint", True),
            checkpoint_interval=data.get("checkpoint_interval", 50),
        )


class ConfigManager:
    def __init__(self, path: Optional[str] = None):
        self.path = path or os.path.join(
            os.path.dirname(__file__), "generator_profile.json"
        )
        self._data = {}

    def load(self) -> GenerationProfile:
        if not os.path.exists(self.path):
            return GenerationProfile()
        with open(self.path, "r") as f:
            self._data = json.load(f)
        return GenerationProfile.from_dict(self._data)

    def save(self, profile: GenerationProfile):
        os.makedirs(os.path.dirname(self.path) or ".", exist_ok=True)
        with open(self.path, "w") as f:
            json.dump(profile.to_dict(), f, indent=2)

    def merge(self, overrides: dict) -> GenerationProfile:
        profile = self.load().to_dict()
        profile.update(overrides)
        return GenerationProfile.from_dict(profile)

    @staticmethod
    def default() -> GenerationProfile:
        return GenerationProfile()
