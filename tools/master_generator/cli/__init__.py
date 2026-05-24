"""CLI command handlers."""
import time
from typing import List, Dict

from tools.master_generator.config import ConfigManager, GenerationProfile
from tools.master_generator.launcher import GenerationLauncher, ProgressCallback
from tools.master_generator.launcher.auditor import audit_puzzles
from tools.master_generator.export import ExportManager
from tools.master_generator.reports import ReportManager
from tools.master_generator.checkpoints import CheckpointManager
from tools.master_generator.ui import header, subheader, result, table, section, done
from tools.master_generator.profiles import ProfileRegistry
from tools.master_generator.variants import VariantRegistry


def cmd_generate(args):
    header("Sudoku Master Generator — Generate")

    config = ConfigManager(args.config)
    overrides = {}
    if args.difficulty:
        overrides["difficulty"] = args.difficulty
    if args.count:
        overrides["count"] = args.count
    if args.variant:
        overrides["variant"] = args.variant
    if args.symmetry:
        overrides["symmetry"] = args.symmetry
    if args.campaign_stage:
        overrides["campaign_stage"] = args.campaign_stage
    if args.export_format:
        overrides["output_format"] = args.export_format
    if args.seed:
        overrides["seed"] = args.seed

    profile = config.merge(overrides)

    variant = VariantRegistry.get(profile.variant)
    result(f"Variant: {variant.label} ({variant.status})")
    result(f"Difficulty: {profile.difficulty}")
    result(f"Count: {profile.count}")
    result(f"Symmetry: {profile.symmetry or 'auto'}")

    if profile.campaign_stage:
        stage = ProfileRegistry.get_campaign_stage(profile.campaign_stage)
        result(f"Campaign Stage {stage['stage']}: {stage['name']}")

    section("Generating puzzles...")
    callback = ProgressCallback()
    launcher = GenerationLauncher(profile, callback=callback)
    puzzles = launcher.generate()

    if not puzzles:
        result("No puzzles generated", "fail")
        return

    section("Exporting")
    export = ExportManager(export_path=profile.export_path)
    if profile.output_format == "metadata":
        path = export.export_with_metadata(puzzles)
    elif profile.output_format == "plain":
        path = export.export_plain(puzzles)
    else:
        path = export.export_json(puzzles)
    result(f"Exported {len(puzzles)} puzzles to {path}")

    section("Summary")
    table(
        ["Metric", "Value"],
        [
            ("Generated", str(callback.generated)),
            ("Duplicates", str(callback.duplicates)),
            ("Invalid", str(callback.invalid)),
            ("Elapsed", f"{time.time() - callback.start_time:.1f}s"),
        ],
    )
    done()


def cmd_validate(args):
    header("Master Generator — Validate")
    config = ConfigManager(args.config)
    profile = config.load()
    launcher = GenerationLauncher(profile)
    puzzles = launcher._results or []
    if not puzzles:
        result("No puzzles to validate. Generate first.", "skip")
        return
    valid = launcher.repair()
    result(f"Valid: {len(valid)} / {len(puzzles)}")


def cmd_audit(args):
    header("Master Generator — Audit")
    config = ConfigManager(args.config)
    profile = config.load()
    launcher = GenerationLauncher(profile)
    puzzles = launcher._results or []
    if not puzzles:
        result("No puzzles to audit. Generate first or specify --input.", "skip")
        return
    audit = audit_puzzles(puzzles)
    table(
        ["Check", "Count"],
        [
            ("Total", str(audit["total"])),
            ("Hash duplicates", str(audit["hash_duplicates"])),
            ("Rotations", str(audit["rotations"])),
            ("Mirrors", str(audit["mirrors"])),
            ("Multi-solution", str(audit["multi_solution"])),
            ("Wrong difficulty", str(audit["wrong_difficulty"])),
            ("Valid", str(audit["valid_count"])),
        ],
    )


def cmd_benchmark(args):
    header("Master Generator — Benchmark")
    config = ConfigManager(args.config)
    profile = config.load()
    profile.count = args.count

    launcher = GenerationLauncher(profile)
    start = time.time()
    puzzles = launcher.generate()
    elapsed = time.time() - start

    section("Results")
    table(
        ["Metric", "Value"],
        [
            ("Count", str(len(puzzles))),
            ("Elapsed", f"{elapsed:.1f}s"),
            ("Avg time/puzzle", f"{elapsed / max(len(puzzles), 1):.2f}s"),
            ("Duplicates", str(launcher.callback.duplicates)),
            ("Invalid", str(launcher.callback.invalid)),
        ],
    )

    report = ReportManager()
    gen_path = report.generation_report(puzzles, elapsed)
    bal_path = report.balance_report(puzzles)
    result(f"Generation report: {gen_path}")
    result(f"Balance report: {bal_path}")


def cmd_export(args):
    header("Master Generator — Export")
    config = ConfigManager(args.config)
    profile = config.load()
    launcher = GenerationLauncher(profile)
    puzzles = launcher._results or []
    if not puzzles:
        result("No puzzles to export. Generate first.", "skip")
        return

    export = ExportManager()
    if args.format == "metadata":
        path = export.export_with_metadata(puzzles, args.output or "export_metadata.json")
    elif args.format == "plain":
        path = export.export_plain(puzzles, args.output or "export.txt")
    else:
        path = export.export_json(puzzles, args.output or "export.json")
    result(f"Exported to {path}")


def cmd_resume(args):
    header("Master Generator — Resume")
    checkpointer = CheckpointManager()
    if not checkpointer.exists():
        result("No checkpoint found", "fail")
        return
    status = checkpointer.get_status()
    if status.get("completed"):
        result("Generation already completed", "skip")
        return
    generated = status.get("generated", 0)
    result(f"Resuming from {generated} generated")
    config = ConfigManager(args.config)
    profile = config.load()
    launcher = GenerationLauncher(profile)
    puzzles = launcher.resume()
    if puzzles:
        result(f"Completed: {len(puzzles)} puzzles")
    else:
        result("Nothing to resume", "skip")


def cmd_repair(args):
    header("Master Generator — Repair")
    config = ConfigManager(args.config)
    profile = config.load()
    launcher = GenerationLauncher(profile)
    puzzles = launcher._results or []
    if not puzzles:
        result("No puzzles to repair", "skip")
        return
    before = len(puzzles)
    valid = launcher.repair()
    after = len(valid)
    removed = before - after
    result(f"Removed {removed} invalid puzzles. {after} remaining.")



