from __future__ import annotations

from typing import Dict, List, Optional

DIFFICULTY_ORDER = ["easy", "intermediate", "hard", "expert", "evil", "mythic"]

Profile = Dict[str, object]


PROFILES: Dict[str, Profile] = {
    "easy": {
        "required": ["naked_single"],
        "target_techniques": [],
        "forbidden": [
            "naked_pair", "hidden_pair", "naked_triple", "hidden_triple",
            "pointing_pair", "box_line_reduction",
            "xwing", "swordfish", "xywing", "forcing_chain",
        ],
        "max_steps": 45,
        "min_steps": 1,
        "allowed": {"naked_single", "hidden_single"},
        "min_clues": 60,
        "max_clues": 65,
        "density_target_pct": "75-80%",
    },
    "intermediate": {
        "required": ["naked_single"],
        "target_techniques": ["naked_pair", "hidden_pair"],
        "forbidden": [
            "naked_triple", "hidden_triple",
            "box_line_reduction",
            "xwing", "swordfish", "xywing", "forcing_chain",
        ],
        "max_steps": 55,
        "min_steps": 1,
        "allowed": {
            "naked_single", "hidden_single",
            "naked_pair", "hidden_pair",
            "pointing_pair",
        },
        "min_clues": 44,
        "max_clues": 52,
        "density_target_pct": "54-64%",
    },
    "hard": {
        "required": ["naked_single"],
        "target_techniques": ["pointing_pair", "box_line_reduction"],
        "forbidden": [
            "swordfish", "xywing", "forcing_chain",
        ],
        "max_steps": 70,
        "min_steps": 1,
        "allowed": {
            "naked_single", "hidden_single",
            "naked_pair", "hidden_pair",
            "naked_triple", "hidden_triple",
            "pointing_pair", "box_line_reduction",
            "xwing",
        },
        "min_clues": 42,
        "max_clues": 52,
        "density_target_pct": "52-64%",
    },
    "expert": {
        "required": ["naked_single"],
        "target_techniques": ["xwing", "swordfish"],
        "forbidden": [
            "xywing", "forcing_chain",
        ],
        "max_steps": 85,
        "min_steps": 1,
        "allowed": {
            "naked_single", "hidden_single",
            "naked_pair", "hidden_pair",
            "naked_triple", "hidden_triple",
            "pointing_pair", "box_line_reduction",
            "xwing", "swordfish",
        },
    },
    "evil": {
        "required": ["naked_single"],
        "target_techniques": ["xywing"],
        "forbidden": [
            "forcing_chain",
        ],
        "max_steps": 100,
        "min_steps": 1,
        "allowed": {
            "naked_single", "hidden_single",
            "naked_pair", "hidden_pair",
            "naked_triple", "hidden_triple",
            "pointing_pair", "box_line_reduction",
            "xwing", "swordfish",
            "xywing",
        },
    },
    "mythic": {
        "required": ["naked_single"],
        "target_techniques": ["forcing_chain"],
        "forbidden": [],
        "max_steps": 150,
        "min_steps": 1,
        "allowed": {
            "naked_single", "hidden_single",
            "naked_pair", "hidden_pair",
            "naked_triple", "hidden_triple",
            "pointing_pair", "box_line_reduction",
            "xwing", "swordfish",
            "xywing", "forcing_chain",
        },
    },
}


def get_profile(difficulty: str) -> Optional[Profile]:
    return PROFILES.get(difficulty)


def techniques_match_profile(techniques: List[str], difficulty: str) -> bool:
    profile = get_profile(difficulty)
    if profile is None:
        return False

    technique_set = set(techniques)

    required = set(profile["required"])
    if not required.issubset(technique_set):
        return False

    forbidden = set(profile["forbidden"])
    if technique_set & forbidden:
        return False

    steps = len(techniques)
    max_steps = profile["max_steps"]
    min_steps = profile["min_steps"]
    if steps > max_steps:
        return False
    if steps < min_steps:
        return False

    return True


def classify_from_profile(techniques: List[str]) -> Optional[str]:
    from classify_by_techniques import classify_by_techniques
    return classify_by_techniques(techniques)
