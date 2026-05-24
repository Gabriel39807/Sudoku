"""
Launcher tests: generation pipeline, progress callback, repair.
"""
import pytest
from tools.master_generator.launcher import GenerationLauncher, ProgressCallback
from tools.master_generator.config import GenerationProfile


@pytest.fixture
def profile():
    return GenerationProfile(difficulty="easy", count=1, checkpoint=False)


class TestProgressCallback:
    def test_defaults(self):
        cb = ProgressCallback()
        assert cb.generated == 0
        assert cb.duplicates == 0
        assert cb.invalid == 0

    def test_on_start_sets_time(self):
        cb = ProgressCallback()
        cb.on_start(10)
        assert cb.start_time > 0

    def test_on_generated_increments(self):
        cb = ProgressCallback()
        cb.on_generated({"puzzle": "test"})
        assert cb.generated == 1

    def test_on_duplicate_increments(self):
        cb = ProgressCallback()
        cb.on_duplicate("test")
        assert cb.duplicates == 1

    def test_on_invalid_increments(self):
        cb = ProgressCallback()
        cb.on_invalid("test", "reason")
        assert cb.invalid == 1


class TestGenerationLauncher:
    def test_create(self, profile):
        launcher = GenerationLauncher(profile)
        assert launcher.profile == profile

    def test_generate_one(self, profile):
        launcher = GenerationLauncher(profile)
        results = launcher.generate()
        assert len(results) == 1
        assert "puzzle" in results[0]
        assert "hash" in results[0]

    def test_generate_multiple(self):
        p = GenerationProfile(difficulty="easy", count=3, checkpoint=False)
        launcher = GenerationLauncher(p)
        results = launcher.generate()
        assert len(results) == 3

    def test_generate_no_duplicates(self):
        p = GenerationProfile(difficulty="easy", count=5, checkpoint=False)
        launcher = GenerationLauncher(p)
        results = launcher.generate()
        hashes = [r["hash"] for r in results]
        assert len(set(hashes)) == len(hashes)

    def test_callback_tracked(self, profile):
        launcher = GenerationLauncher(profile)
        launcher.generate()
        assert launcher.callback.generated == 1

    def test_result_keys(self, profile):
        launcher = GenerationLauncher(profile)
        results = launcher.generate()
        r = results[0]
        expected = {"puzzle", "solution", "difficulty", "clues", "hash", "timestamp"}
        assert expected.issubset(r.keys())

    def test_repair_empty(self, profile):
        launcher = GenerationLauncher(profile)
        assert launcher.repair() == []

    def test_repair_after_generate(self, profile):
        launcher = GenerationLauncher(profile)
        launcher.generate()
        valid = launcher.repair()
        assert len(valid) == 1


class TestGenerationWithSeeds:
    def test_seed_reproducible(self):
        p1 = GenerationProfile(difficulty="easy", count=1, seed=99, checkpoint=False)
        p2 = GenerationProfile(difficulty="easy", count=1, seed=99, checkpoint=False)
        r1 = GenerationLauncher(p1).generate()
        r2 = GenerationLauncher(p2).generate()
        assert r1[0]["puzzle"] == r2[0]["puzzle"]

    def test_different_seeds_different(self):
        p1 = GenerationProfile(difficulty="easy", count=1, seed=1, checkpoint=False)
        p2 = GenerationProfile(difficulty="easy", count=1, seed=2, checkpoint=False)
        r1 = GenerationLauncher(p1).generate()
        r2 = GenerationLauncher(p2).generate()
        assert r1[0]["puzzle"] != r2[0]["puzzle"]


class TestAllDifficulties:
    @pytest.mark.parametrize("diff", ["easy", "intermediate", "hard", "expert", "evil", "mythic"])
    def test_generate_each(self, diff):
        p = GenerationProfile(difficulty=diff, count=1, checkpoint=False)
        launcher = GenerationLauncher(p)
        results = launcher.generate()
        assert len(results) == 1
        assert results[0]["difficulty"] == diff
