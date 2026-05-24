"""
Export tests: JSON, plain text, metadata, hash utilities.
"""
import os, json, tempfile
import pytest
from tools.master_generator.export import ExportManager, puzzle_hash, batch_hash


SAMPLE_PUZZLE = {
    "puzzle": "530070000600195000098000060800060003400803001700020006060000280000419005000080079",
    "solution": "534678912672195348198342567859761423426853791713924856961537284287419635345286179",
    "difficulty": "easy",
    "clues": 30,
    "hash": "abc123",
    "timestamp": 1000.0,
    "technique_breakdown": {"NakedSingle": 10, "HiddenSingle": 5},
}


@pytest.fixture
def tmp_export():
    with tempfile.TemporaryDirectory() as d:
        yield ExportManager(export_path=d)


class TestExportManager:
    def test_export_json(self, tmp_export):
        path = tmp_export.export_json([SAMPLE_PUZZLE])
        assert os.path.exists(path)
        with open(path) as f:
            data = json.load(f)
        assert len(data) == 1
        assert data[0]["puzzle"] == SAMPLE_PUZZLE["puzzle"]

    def test_export_plain(self, tmp_export):
        path = tmp_export.export_plain([SAMPLE_PUZZLE])
        assert os.path.exists(path)
        with open(path) as f:
            content = f.read().strip()
        assert content == SAMPLE_PUZZLE["puzzle"]

    def test_export_metadata(self, tmp_export):
        path = tmp_export.export_with_metadata([SAMPLE_PUZZLE])
        assert os.path.exists(path)
        with open(path) as f:
            data = json.load(f)
        assert data[0]["hash"] == "abc123"
        assert data[0]["techniques"] == ["NakedSingle", "HiddenSingle"]

    def test_export_multiple(self, tmp_export):
        puzzles = [SAMPLE_PUZZLE, dict(SAMPLE_PUZZLE, puzzle="0" * 81)]
        path = tmp_export.export_json(puzzles)
        with open(path) as f:
            data = json.load(f)
        assert len(data) == 2


class TestFormatSingle:
    def test_format_json(self):
        s = ExportManager.format_single(SAMPLE_PUZZLE, "json")
        assert "puzzle" in s
        assert "difficulty" in s

    def test_format_plain(self):
        s = ExportManager.format_single(SAMPLE_PUZZLE, "plain")
        assert s == SAMPLE_PUZZLE["puzzle"]

    def test_format_compact(self):
        s = ExportManager.format_single(SAMPLE_PUZZLE, "compact")
        assert "abc123" in s
        assert "easy" in s
        assert "30" in s


class TestHash:
    def test_puzzle_hash_length(self):
        h = puzzle_hash("test")
        assert len(h) == 16

    def test_puzzle_hash_consistent(self):
        assert puzzle_hash("test") == puzzle_hash("test")

    def test_puzzle_hash_different(self):
        assert puzzle_hash("test1") != puzzle_hash("test2")

    def test_batch_hash(self):
        puzzles = [{"puzzle": "a"}, {"puzzle": "b"}]
        h = batch_hash(puzzles)
        assert len(h) == 16

    def test_batch_hash_consistent(self):
        puzzles = [{"puzzle": "a"}, {"puzzle": "b"}]
        assert batch_hash(puzzles) == batch_hash(puzzles)


def test_export_directory_created():
    with tempfile.TemporaryDirectory() as d:
        em = ExportManager(export_path=os.path.join(d, "nested", "dir"))
        path = em.export_json([SAMPLE_PUZZLE], "test.json")
        assert os.path.exists(path)
