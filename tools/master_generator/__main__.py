"""Entry point for `python -m tools.master_generator`."""
import sys
from tools.master_generator.cli.parser import build_parser
from tools.master_generator.cli import (
    cmd_generate,
    cmd_validate,
    cmd_audit,
    cmd_benchmark,
    cmd_export,
    cmd_resume,
    cmd_repair,
)


def main():
    parser = build_parser()
    args = parser.parse_args()

    handlers = {
        "generate": cmd_generate,
        "validate": cmd_validate,
        "audit": cmd_audit,
        "benchmark": cmd_benchmark,
        "export": cmd_export,
        "resume": cmd_resume,
        "repair": cmd_repair,
    }

    handler = handlers.get(args.command)
    if handler:
        handler(args)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
