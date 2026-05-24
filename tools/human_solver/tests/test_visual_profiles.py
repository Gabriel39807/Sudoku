"""
Visual profile tests: 15+ tests.
"""
import pytest
from tools.human_solver.visual_profiles import get_profile, list_difficulties, PROFILES


def test_all_difficulties_listed():
    diffs = list_difficulties()
    assert len(diffs) == 6
    assert "easy" in diffs
    assert "mythic" in diffs


def test_get_profile_returns_correct_type():
    p = get_profile("easy")
    assert p.difficulty == "easy"


def test_get_profile_unknown_raises():
    with pytest.raises(ValueError):
        get_profile("nonexistent")


@pytest.mark.parametrize("diff,expected_min,expected_max", [
    ("easy", 60, 65),
    ("intermediate", 54, 59),
    ("hard", 46, 53),
    ("expert", 38, 45),
    ("evil", 30, 37),
    ("mythic", 24, 32),
])
def test_clue_ranges(diff, expected_min, expected_max):
    p = get_profile(diff)
    assert p.min_clues == expected_min
    assert p.max_clues == expected_max


class TestFillPercent:
    @pytest.mark.parametrize("diff,expected_min,expected_max", [
        ("easy", 74.0, 80.3),
        ("intermediate", 66.6, 72.9),
        ("hard", 56.7, 65.5),
        ("expert", 46.9, 55.6),
        ("evil", 37.0, 45.7),
        ("mythic", 29.6, 39.5),
    ])
    def test_fill_ranges(self, diff, expected_min, expected_max):
        p = get_profile(diff)
        assert p.min_fill >= expected_min
        assert p.max_fill <= expected_max


def test_fill_derived_from_clues():
    p = get_profile("easy")
    assert p.min_fill == round(p.min_clues / 81 * 100, 1)
    assert p.max_fill == round(p.max_clues / 81 * 100, 1)


@pytest.mark.parametrize("diff,symmetry", [
    ("easy", "rotational"),
    ("intermediate", "rotational"),
    ("hard", "rotational"),
    ("expert", "mirror"),
    ("evil", "mirror"),
    ("mythic", "random"),
])
def test_symmetry_modes(diff, symmetry):
    p = get_profile(diff)
    assert p.symmetry_mode == symmetry


@pytest.mark.parametrize("diff,expected_tier", [
    ("easy", 1),
    ("intermediate", 2),
    ("hard", 4),
    ("expert", 6),
    ("evil", 7),
    ("mythic", 8),
])
def test_max_tiers(diff, expected_tier):
    p = get_profile(diff)
    assert p.max_tier == expected_tier


def test_clues_in_range():
    p = get_profile("easy")
    assert p.clues_in_range(60) is True
    assert p.clues_in_range(65) is True
    assert p.clues_in_range(62) is True
    assert p.clues_in_range(59) is False
    assert p.clues_in_range(66) is False


def test_max_removable():
    p = get_profile("easy")
    assert p.max_removable == 81 - 60
    assert p.min_removable == 81 - 65


def test_to_dict_keys():
    p = get_profile("hard")
    d = p.to_dict()
    assert "difficulty" in d
    assert "min_clues" in d
    assert "max_clues" in d
    assert "symmetry_mode" in d
    assert "max_tier" in d


def test_profile_immutable():
    p = get_profile("easy")
    assert p.min_clues == 60
    assert p.max_clues == 65


def test_all_profiles_have_valid_ranges():
    for diff, p in PROFILES.items():
        assert p.min_clues >= 22
        assert p.max_clues <= 81
        assert p.min_clues <= p.max_clues
        assert p.symmetry_mode in ("rotational", "mirror", "random")
        assert 1 <= p.max_tier <= 8


def test_density_progression():
    diffs = ["easy", "intermediate", "hard", "expert", "evil", "mythic"]
    densities = [get_profile(d).visual_density for d in diffs]
    expected = ["very_low", "low", "medium", "high", "very_high", "extreme"]
    assert densities == expected
