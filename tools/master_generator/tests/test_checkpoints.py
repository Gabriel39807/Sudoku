"""
Checkpoint tests: save, load, resume, clear.
"""
import os, json, tempfile
import pytest
from tools.master_generator.checkpoints import CheckpointManager


@pytest.fixture
def tmp_checkpoint():
    path = tempfile.mktemp(suffix=".json")
    cm = CheckpointManager(path=path)
    yield cm
    if os.path.exists(path):
        os.remove(path)


class TestCheckpointManager:
    def test_not_exists(self, tmp_checkpoint):
        assert tmp_checkpoint.exists() is False

    def test_save_and_load(self, tmp_checkpoint):
        state = {"generated": 5, "hashes": ["a", "b"]}
        tmp_checkpoint.save(state)
        assert tmp_checkpoint.exists() is True
        loaded = tmp_checkpoint.load()
        assert loaded["generated"] == 5
        assert loaded["hashes"] == ["a", "b"]

    def test_clear(self, tmp_checkpoint):
        tmp_checkpoint.save({"generated": 1})
        assert tmp_checkpoint.exists() is True
        tmp_checkpoint.clear()
        assert tmp_checkpoint.exists() is False

    def test_load_empty(self, tmp_checkpoint):
        assert tmp_checkpoint.load() is None

    def test_save_adds_timestamp(self, tmp_checkpoint):
        tmp_checkpoint.save({"generated": 1})
        loaded = tmp_checkpoint.load()
        assert "_saved_at" in loaded

    def test_get_status_not_exists(self, tmp_checkpoint):
        status = tmp_checkpoint.get_status()
        assert status["exists"] is False

    def test_get_status_with_data(self, tmp_checkpoint):
        tmp_checkpoint.save({"generated": 10, "duplicates": 2, "completed": False, "elapsed": 5.0})
        status = tmp_checkpoint.get_status()
        assert status["exists"] is True
        assert status["generated"] == 10
        assert status["completed"] is False

    def test_save_json_valid(self, tmp_checkpoint):
        tmp_checkpoint.save({"generated": 1})
        with open(tmp_checkpoint.path, "r") as f:
            data = json.load(f)
        assert data["generated"] == 1

    def test_overwrite_existing(self, tmp_checkpoint):
        tmp_checkpoint.save({"generated": 1})
        tmp_checkpoint.save({"generated": 2})
        loaded = tmp_checkpoint.load()
        assert loaded["generated"] == 2

    def test_corrupted_file(self, tmp_checkpoint):
        with open(tmp_checkpoint.path, "w") as f:
            f.write("not json")
        assert tmp_checkpoint.load() is None

    def test_profile_in_status(self, tmp_checkpoint):
        tmp_checkpoint.save({"profile": {"difficulty": "hard", "count": 5}})
        status = tmp_checkpoint.get_status()
        assert status["profile"]["difficulty"] == "hard"


class TestCheckpointPersistence:
    def test_persists_across_instances(self, tmp_checkpoint):
        tmp_checkpoint.save({"generated": 42})
        cm2 = CheckpointManager(path=tmp_checkpoint.path)
        loaded = cm2.load()
        assert loaded["generated"] == 42
