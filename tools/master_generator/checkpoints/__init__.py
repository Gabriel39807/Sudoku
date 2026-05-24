"""Checkpoint manager — save/resume generation state."""
import json
import os
import time
from typing import Optional


CHECKPOINT_DIR = os.path.join(os.path.dirname(__file__), "..", "checkpoints")


class CheckpointManager:
    def __init__(self, path: Optional[str] = None):
        self.path = path or os.path.join(CHECKPOINT_DIR, "generation_checkpoint.json")

    def save(self, state: dict):
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        state["_saved_at"] = time.time()
        with open(self.path, "w") as f:
            json.dump(state, f, indent=2, default=str)

    def load(self) -> Optional[dict]:
        if not os.path.exists(self.path):
            return None
        try:
            with open(self.path, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return None

    def clear(self):
        if os.path.exists(self.path):
            os.remove(self.path)

    def exists(self) -> bool:
        return os.path.exists(self.path)

    def get_status(self) -> dict:
        cp = self.load()
        if not cp:
            return {"exists": False}
        return {
            "exists": True,
            "generated": cp.get("generated", 0),
            "duplicates": cp.get("duplicates", 0),
            "invalid": cp.get("invalid", 0),
            "completed": cp.get("completed", False),
            "elapsed": cp.get("elapsed", 0),
            "saved_at": cp.get("_saved_at", 0),
            "profile": cp.get("profile", {}),
        }
