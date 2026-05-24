"""CLI argument parser."""
import argparse


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="master-generator",
        description="Sudoku Master Generator — puzzle generation orchestration",
    )
    parser.add_argument("--config", "-c", help="Path to generator_profile.json")
    parser.add_argument("--seed", type=int, help="Random seed")

    sub = parser.add_subparsers(dest="command", required=True)

    # generate
    g = sub.add_parser("generate", help="Generate puzzles")
    g.add_argument("--difficulty", "-d", default="easy",
                   choices=["easy", "intermediate", "hard", "expert", "evil", "mythic"])
    g.add_argument("--count", "-n", type=int, default=10)
    g.add_argument("--variant", "-v", default="classic_9x9")
    g.add_argument("--symmetry", choices=["rotational", "mirror", "random"])
    g.add_argument("--campaign-stage", type=int)
    g.add_argument("--export-format", choices=["json", "plain", "metadata"], default="json")

    # validate
    sub.add_parser("validate", help="Validate generated puzzles")

    # audit
    a = sub.add_parser("audit", help="Audit puzzle quality")
    a.add_argument("--input", help="Input file to audit")

    # benchmark
    b = sub.add_parser("benchmark", help="Run benchmarks")
    b.add_argument("--count", type=int, default=5)

    # export
    e = sub.add_parser("export", help="Export puzzles")
    e.add_argument("--format", choices=["json", "plain", "metadata"], default="json")
    e.add_argument("--output", "-o", help="Output file")

    # resume
    sub.add_parser("resume", help="Resume from last checkpoint")

    # repair
    sub.add_parser("repair", help="Remove invalid puzzles from results")

    return parser
