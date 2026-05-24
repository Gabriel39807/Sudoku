"""Visual profiles mapping difficulty to desired puzzle appearance."""


class VisualProfile:
    def __init__(
        self,
        difficulty: str,
        label: str,
        min_clues: int,
        max_clues: int,
        target_time: str,
        visual_density: str,
        symmetry_mode: str = "rotational",
        max_tier: int = 1,
    ):
        self.difficulty = difficulty
        self.label = label
        self.min_clues = min_clues
        self.max_clues = max_clues
        self.target_time = target_time
        self.visual_density = visual_density
        self.symmetry_mode = symmetry_mode
        self.max_tier = max_tier

    @property
    def min_fill(self) -> float:
        return round(self.min_clues / 81 * 100, 1)

    @property
    def max_fill(self) -> float:
        return round(self.max_clues / 81 * 100, 1)

    @property
    def max_removable(self) -> int:
        return 81 - self.min_clues

    @property
    def min_removable(self) -> int:
        return 81 - self.max_clues

    def clues_in_range(self, clues: int) -> bool:
        return self.min_clues <= clues <= self.max_clues

    def to_dict(self) -> dict:
        return {
            "difficulty": self.difficulty,
            "label": self.label,
            "min_clues": self.min_clues,
            "max_clues": self.max_clues,
            "min_fill": self.min_fill,
            "max_fill": self.max_fill,
            "target_time": self.target_time,
            "visual_density": self.visual_density,
            "symmetry_mode": self.symmetry_mode,
            "max_tier": self.max_tier,
        }


PROFILES = {
    "easy": VisualProfile(
        difficulty="easy", label="Easy",
        min_clues=60, max_clues=65,
        target_time="2-4 min", visual_density="very_low",
        symmetry_mode="rotational", max_tier=1,
    ),
    "intermediate": VisualProfile(
        difficulty="intermediate", label="Intermediate",
        min_clues=54, max_clues=59,
        target_time="4-7 min", visual_density="low",
        symmetry_mode="rotational", max_tier=2,
    ),
    "hard": VisualProfile(
        difficulty="hard", label="Hard",
        min_clues=46, max_clues=53,
        target_time="8-15 min", visual_density="medium",
        symmetry_mode="rotational", max_tier=4,
    ),
    "expert": VisualProfile(
        difficulty="expert", label="Expert",
        min_clues=38, max_clues=45,
        target_time="15-30 min", visual_density="high",
        symmetry_mode="mirror", max_tier=6,
    ),
    "evil": VisualProfile(
        difficulty="evil", label="Evil",
        min_clues=30, max_clues=37,
        target_time="30-60 min", visual_density="very_high",
        symmetry_mode="mirror", max_tier=7,
    ),
    "mythic": VisualProfile(
        difficulty="mythic", label="Mythic",
        min_clues=24, max_clues=32,
        target_time="60+ min", visual_density="extreme",
        symmetry_mode="random", max_tier=8,
    ),
}


def get_profile(difficulty: str) -> VisualProfile:
    profile = PROFILES.get(difficulty)
    if profile is None:
        raise ValueError(
            f"Unknown difficulty: {difficulty}. "
            f"Use one of {list(PROFILES.keys())}"
        )
    return profile


def list_difficulties() -> list:
    return list(PROFILES.keys())
