"""Config manager tests."""
import os, tempfile
import pytest
from tools.master_generator.config import ConfigManager, GenerationProfile


class TestGenerationProfile:
    def test_default_values(self):
        p = GenerationProfile()
        assert p.variant == "classic_9x9"
        assert p.difficulty == "easy"
        assert p.count == 10
        assert p.checkpoint is True

    def test_to_dict(self):
        p = GenerationProfile(difficulty="hard", count=5)
        d = p.to_dict()
        assert d["difficulty"] == "hard"
        assert d["count"] == 5

    def test_from_dict(self):
        p = GenerationProfile.from_dict({"difficulty": "expert", "count": 20})
        assert p.difficulty == "expert"
        assert p.count == 20

    def test_required_techniques(self):
        p = GenerationProfile(required_techniques=["XWing"])
        assert "XWing" in p.required_techniques


class TestConfigManager:
    def test_load_default(self):
        cm = ConfigManager(path="nonexistent.json")
        p = cm.load()
        assert p.difficulty == "easy"

    def test_save_and_load(self):
        with tempfile.NamedTemporaryFile(suffix=".json", delete=False, mode="w") as f:
            path = f.name
        try:
            cm = ConfigManager(path=path)
            cm.save(GenerationProfile(difficulty="mythic", count=50))
            loaded = cm.load()
            assert loaded.difficulty == "mythic"
            assert loaded.count == 50
        finally:
            if os.path.exists(path):
                os.remove(path)

    def test_merge(self):
        with tempfile.NamedTemporaryFile(suffix=".json", delete=False, mode="w") as f:
            path = f.name
        try:
            cm = ConfigManager(path=path)
            cm.save(GenerationProfile(difficulty="easy", count=10))
            merged = cm.merge({"difficulty": "evil", "count": 100})
            assert merged.difficulty == "evil"
            assert merged.count == 100
        finally:
            if os.path.exists(path):
                os.remove(path)

    def test_default_static(self):
        p = ConfigManager.default()
        assert isinstance(p, GenerationProfile)
