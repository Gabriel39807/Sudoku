"""Puzzle generation launcher — orchestrates the generator pipeline."""
import time
import hashlib
from typing import Dict, List, Optional, Callable

from tools.master_generator.config import GenerationProfile
from tools.master_generator.checkpoints import CheckpointManager
from tools.master_generator.profiles import ProfileRegistry
from tools.human_solver.generator import PuzzleGenerator


class ProgressCallback:
    def __init__(self):
        self.generated = 0
        self.duplicates = 0
        self.invalid = 0
        self.start_time = 0.0

    def on_start(self, total: int):
        self.start_time = time.time()

    def on_generated(self, puzzle: dict):
        self.generated += 1

    def on_duplicate(self, puzzle_str: str):
        self.duplicates += 1

    def on_invalid(self, puzzle_str: str, reason: str):
        self.invalid += 1


class GenerationLauncher:
    def __init__(self, profile: GenerationProfile, callback: Optional[ProgressCallback] = None):
        self.profile = profile
        self.callback = callback or ProgressCallback()
        self._generator = PuzzleGenerator(seed=profile.seed)
        self._checkpointer = CheckpointManager() if profile.checkpoint else None
        self._seen_hashes: set = set()
        self._results: List[Dict] = []

    def _puzzle_hash(self, puzzle_str: str) -> str:
        return hashlib.sha256(puzzle_str.encode()).hexdigest()[:16]

    def _is_duplicate(self, puzzle_str: str) -> bool:
        h = self._puzzle_hash(puzzle_str)
        if h in self._seen_hashes:
            return True
        self._seen_hashes.add(h)
        return False

    def generate(self, count: Optional[int] = None) -> List[Dict]:
        target = count or self.profile.count
        self.callback.on_start(target)

        checkpoint = None
        if self._checkpointer:
            checkpoint = self._checkpointer.load()
            if checkpoint:
                self._results = checkpoint.get("results", [])
                self._seen_hashes = set(checkpoint.get("hashes", []))
                self.callback.generated = len(self._results)
                self.callback.start_time = checkpoint.get("elapsed", time.time())

        difficulty = self.profile.difficulty
        if self.profile.campaign_stage:
            stage = ProfileRegistry.get_campaign_stage(self.profile.campaign_stage)
            difficulty = stage.get("difficulty", difficulty)

        while self.callback.generated < target:
            result = self._generator.generate(
                difficulty=difficulty,
                max_attempts=5,
            )

            if result is None:
                self.callback.on_invalid("", "generation_failed")
                continue

            puzzle_str = result["puzzle"]
            if self._is_duplicate(puzzle_str):
                self.callback.on_duplicate(puzzle_str)
                continue

            result["hash"] = self._puzzle_hash(puzzle_str)
            result["timestamp"] = time.time()
            self._results.append(result)
            self.callback.on_generated(result)

            if self._checkpointer and self.callback.generated % self.profile.checkpoint_interval == 0:
                self._save_checkpoint()

        if self._checkpointer:
            self._save_checkpoint(completed=True)

        return self._results

    def _save_checkpoint(self, completed: bool = False):
        if not self._checkpointer:
            return
        self._checkpointer.save({
            "results": self._results,
            "hashes": list(self._seen_hashes),
            "generated": self.callback.generated,
            "duplicates": self.callback.duplicates,
            "invalid": self.callback.invalid,
            "elapsed": time.time() - self.callback.start_time,
            "profile": self.profile.to_dict(),
            "completed": completed,
        })

    def resume(self) -> Optional[List[Dict]]:
        if not self._checkpointer:
            return None
        checkpoint = self._checkpointer.load()
        if not checkpoint:
            return None
        if checkpoint.get("completed"):
            return checkpoint.get("results", [])
        remaining = checkpoint.get("generated", 0)
        self._results = checkpoint.get("results", [])
        self._seen_hashes = set(checkpoint.get("hashes", []))
        self.callback.generated = len(self._results)
        return self.generate(count=remaining)

    def repair(self) -> List[Dict]:
        valid = []
        for r in self._results:
            v = self._generator.validate_puzzle(r["puzzle"])
            if v.get("valid") and v.get("unique"):
                valid.append(r)
        self._results = valid
        self.callback.generated = len(valid)
        return valid
