"""
Report generation tests.
"""
import os, tempfile, json
import pytest
from tools.master_generator.reports import ReportManager


SAMPLE_PUZZLES = [
    {"puzzle": "530070000600195000098000060800060003400803001700020006060000280000419005000080079",
     "difficulty": "easy", "clues": 30, "difficulty_score": 7.2,
     "technique_breakdown": {"NakedSingle": 10, "HiddenSingle": 5}},
    {"puzzle": "000000000000000000000000000000000000000000000000000000000000000000000000000000000",
     "difficulty": "hard", "clues": 0, "difficulty_score": 0.0,
     "technique_breakdown": {}},
]


@pytest.fixture
def tmp_reports():
    with tempfile.TemporaryDirectory() as d:
        yield ReportManager(report_path=d)


class TestReportManager:
    def test_generation_report(self, tmp_reports):
        path = tmp_reports.generation_report(SAMPLE_PUZZLES, 1.5)
        assert os.path.exists(path)
        with open(path) as f:
            content = f.read()
        assert "Generation Report" in content
        assert "2" in content  # 2 puzzles

    def test_generation_report_empty(self, tmp_reports):
        path = tmp_reports.generation_report([], 0)
        assert os.path.exists(path)

    def test_balance_report(self, tmp_reports):
        path = tmp_reports.balance_report(SAMPLE_PUZZLES)
        assert os.path.exists(path)
        with open(path) as f:
            content = f.read()
        assert "Balance Report" in content
        assert "15.0" in content  # avg clues = 15

    def test_balance_report_empty(self, tmp_reports):
        path = tmp_reports.balance_report([])
        assert path == "" or os.path.exists(path)

    def test_technique_usage_report(self, tmp_reports):
        path = tmp_reports.technique_usage_report(SAMPLE_PUZZLES)
        assert os.path.exists(path)
        with open(path) as f:
            content = f.read()
        assert "NakedSingle" in content
        assert "HiddenSingle" in content

    def test_technique_usage_in_percent(self, tmp_reports):
        path = tmp_reports.technique_usage_report(SAMPLE_PUZZLES)
        with open(path) as f:
            content = f.read()
        assert "50.0%" in content  # 1/2 puzzles use each technique

    def test_reports_in_different_dir(self):
        with tempfile.TemporaryDirectory() as d:
            rm = ReportManager(report_path=os.path.join(d, "my_reports"))
            path = rm.generation_report(SAMPLE_PUZZLES, 1.0)
            assert os.path.exists(path)
