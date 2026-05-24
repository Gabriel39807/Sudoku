"""
Auditor tests: duplicate detection, rotations, mirrors, metadata validation.
"""
import pytest
from tools.master_generator.launcher.auditor import (
    rotations,
    mirror_h,
    mirror_v,
    all_transforms,
    find_duplicates,
    find_rotations,
    find_mirrors,
    find_multi_solution,
    find_wrong_difficulty,
    audit_puzzles,
    validate_metadata,
)


SIMPLE_PUZZLE = (
    "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
)


def test_rotations_four():
    rs = rotations(SIMPLE_PUZZLE)
    assert len(rs) == 4
    assert rs[0] == SIMPLE_PUZZLE


def test_rotation_no_change_after_full():
    rs = rotations(SIMPLE_PUZZLE)
    assert rs[3] != SIMPLE_PUZZLE  # 270deg != original


def test_mirror_h_length():
    m = mirror_h(SIMPLE_PUZZLE)
    assert len(m) == 81


def test_mirror_v_length():
    m = mirror_v(SIMPLE_PUZZLE)
    assert len(m) == 81


def test_mirror_twice_original():
    assert mirror_h(mirror_h(SIMPLE_PUZZLE)) == SIMPLE_PUZZLE
    assert mirror_v(mirror_v(SIMPLE_PUZZLE)) == SIMPLE_PUZZLE


def test_all_transforms_eight():
    ts = all_transforms(SIMPLE_PUZZLE)
    assert len(ts) == 8


def test_find_duplicates_none():
    puzzles = [{"puzzle": "a", "hash": "1"}, {"puzzle": "b", "hash": "2"}]
    assert find_duplicates(puzzles) == {}


def test_find_duplicates_one():
    puzzles = [{"puzzle": "a", "hash": "1"}, {"puzzle": "b", "hash": "1"}]
    dups = find_duplicates(puzzles)
    assert len(dups) == 1
    assert dups["1"] == [0, 1]


def test_find_rotations_none():
    puzzles = [{"puzzle": "abc"}, {"puzzle": "def"}]
    assert find_rotations(puzzles) == []


def test_find_mirrors_none():
    puzzles = [{"puzzle": "abc"}, {"puzzle": "def"}]
    assert find_mirrors(puzzles) == []


def test_find_multi_solution_none():
    puzzles = [{"puzzle": SIMPLE_PUZZLE}]
    assert find_multi_solution(puzzles) == []


def test_find_multi_solution_empty():
    puzzles = [{"puzzle": "0" * 81}]
    assert len(find_multi_solution(puzzles)) == 1


def test_find_wrong_difficulty():
    puzzles = [{"tier_max": 5}]
    assert find_wrong_difficulty(puzzles, 3) == [0]


def test_find_wrong_difficulty_ok():
    puzzles = [{"tier_max": 2}]
    assert find_wrong_difficulty(puzzles, 3) == []


def test_audit_puzzles():
    puzzles = [{"puzzle": SIMPLE_PUZZLE, "tier_max": 1}]
    audit = audit_puzzles(puzzles)
    assert audit["total"] == 1
    assert audit["valid_count"] == 1


def test_audit_puzzles_empty():
    audit = audit_puzzles([])
    assert audit["total"] == 0


def test_validate_metadata_ok():
    p = {"puzzle": "a", "solution": "b", "difficulty": "easy", "clues": 30}
    assert validate_metadata(p) == []


def test_validate_metadata_missing():
    p = {"puzzle": "a"}
    errors = validate_metadata(p)
    assert len(errors) == 3


def test_validate_metadata_bad_clues():
    p = {"puzzle": "a", "solution": "b", "difficulty": "easy", "clues": 0}
    errors = validate_metadata(p)
    assert any("invalid_clues" in e for e in errors)


class TestRotationsIdentity:
    def test_rotational_symmetry(self):
        puzzle = "123456789" * 9
        rs = rotations(puzzle)
        for r in rs:
            assert len(r) == 81


def test_mirror_h_different():
    assert mirror_h(SIMPLE_PUZZLE) != SIMPLE_PUZZLE


def test_mirror_v_different():
    assert mirror_v(SIMPLE_PUZZLE) != SIMPLE_PUZZLE


def test_rotation_order():
    rs = rotations(SIMPLE_PUZZLE)
    assert rs[0] == SIMPLE_PUZZLE  # 0deg
    assert rs[1] != SIMPLE_PUZZLE  # 90deg
    assert rs[2] != SIMPLE_PUZZLE  # 180deg
    assert rs[3] != SIMPLE_PUZZLE  # 270deg
