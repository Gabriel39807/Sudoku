#!/usr/bin/env python3
"""Run the human solver test suite."""
import sys
import subprocess

def main():
    import pytest
    args = [
        "tools/human_solver/tests/",
        "-v",
        "--tb=short",
        "--ignore=tools/human_solver/tests/__pycache__",
    ]
    if "-x" in sys.argv:
        args.append("-x")
    if "--coverage" in sys.argv or "-c" in sys.argv:
        args.extend(["--cov=tools.human_solver", "--cov-report=term-missing"])
    exit_code = pytest.main(args)
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
