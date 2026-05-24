"""
CLI parser tests: argument parsing, subcommand dispatch.
"""
import pytest
from tools.master_generator.cli.parser import build_parser


@pytest.fixture
def parser():
    return build_parser()


class TestParser:
    def test_generate_defaults(self, parser):
        args = parser.parse_args(["generate"])
        assert args.command == "generate"
        assert args.difficulty == "easy"
        assert args.count == 10
        assert args.variant == "classic_9x9"

    def test_generate_with_args(self, parser):
        args = parser.parse_args(["generate", "--difficulty", "hard", "--count", "5", "--symmetry", "mirror"])
        assert args.difficulty == "hard"
        assert args.count == 5
        assert args.symmetry == "mirror"

    def test_validate_command(self, parser):
        args = parser.parse_args(["validate"])
        assert args.command == "validate"

    def test_audit_command(self, parser):
        args = parser.parse_args(["audit"])
        assert args.command == "audit"

    def test_audit_with_input(self, parser):
        args = parser.parse_args(["audit", "--input", "data.json"])
        assert args.input == "data.json"

    def test_benchmark_command(self, parser):
        args = parser.parse_args(["benchmark", "--count", "10"])
        assert args.count == 10

    def test_export_command(self, parser):
        args = parser.parse_args(["export", "--format", "metadata", "--output", "out.json"])
        assert args.format == "metadata"
        assert args.output == "out.json"

    def test_resume_command(self, parser):
        args = parser.parse_args(["resume"])
        assert args.command == "resume"

    def test_repair_command(self, parser):
        args = parser.parse_args(["repair"])
        assert args.command == "repair"

    def test_difficulty_choices(self, parser):
        for d in ["easy", "intermediate", "hard", "expert", "evil", "mythic"]:
            args = parser.parse_args(["generate", "--difficulty", d])
            assert args.difficulty == d

    def test_count_type(self, parser):
        args = parser.parse_args(["generate", "--count", "100"])
        assert args.count == 100

    def test_symmetry_choices(self, parser):
        for s in ["rotational", "mirror", "random"]:
            args = parser.parse_args(["generate", "--symmetry", s])
            assert args.symmetry == s

    def test_campaign_stage(self, parser):
        args = parser.parse_args(["generate", "--campaign-stage", "3"])
        assert args.campaign_stage == 3

    def test_export_format_choices(self, parser):
        args = parser.parse_args(["generate", "--export-format", "metadata"])
        assert args.export_format == "metadata"

    def test_main_seed(self, parser):
        args = parser.parse_args(["--seed", "42", "generate"])
        assert args.seed == 42
        assert args.command == "generate"

    def test_config_path(self, parser):
        args = parser.parse_args(["-c", "my_config.json", "generate"])
        assert args.config == "my_config.json"

    def test_no_command_error(self, parser):
        with pytest.raises(SystemExit):
            parser.parse_args([])
