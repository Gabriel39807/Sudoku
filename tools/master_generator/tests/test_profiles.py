"""
Profile registry and campaign stage tests.
"""
import pytest
from tools.master_generator.profiles import ProfileRegistry, CAMPAIGN_STAGES


class TestProfileRegistry:
    def test_get_easy(self):
        p = ProfileRegistry.get("easy")
        assert p.difficulty == "easy"
        assert p.min_clues == 60

    def test_list_includes_all(self):
        diffs = ProfileRegistry.list()
        for d in ["easy", "intermediate", "hard", "expert", "evil", "mythic"]:
            assert d in diffs

    def test_get_unknown_raises(self):
        with pytest.raises(ValueError):
            ProfileRegistry.get("nonexistent")

    def test_score_puzzle(self):
        puzzle = "1" * 60 + "0" * 21
        score = ProfileRegistry.score_puzzle(puzzle)
        assert "visual" in score
        assert score["clues"] == 60

    def test_difficulty_for_clues_easy(self):
        assert ProfileRegistry.difficulty_for_clues(60) == "easy"

    def test_difficulty_for_clues_mythic(self):
        assert ProfileRegistry.difficulty_for_clues(24) == "mythic"

    def test_difficulty_for_clues_high(self):
        assert ProfileRegistry.difficulty_for_clues(70) == "easy"

    def test_campaign_stage_1(self):
        stage = ProfileRegistry.get_campaign_stage(1)
        assert stage["stage"] == 1
        assert stage["variant"] == "mini_4x4"

    def test_campaign_stage_4(self):
        stage = ProfileRegistry.get_campaign_stage(4)
        assert stage["variant"] == "classic_9x9"

    def test_campaign_stage_unknown(self):
        with pytest.raises(ValueError):
            ProfileRegistry.get_campaign_stage(99)


class TestCampaignStages:
    def test_four_stages(self):
        assert len(CAMPAIGN_STAGES) == 4

    def test_progressive_sizes(self):
        sizes = [s["cells"] for s in CAMPAIGN_STAGES]
        assert sizes == [16, 36, 64, 81]

    def test_each_has_name(self):
        for s in CAMPAIGN_STAGES:
            assert "name" in s
            assert "description" in s
