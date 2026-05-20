from __future__ import annotations

import json
import os
from typing import Any, Dict, Optional

CHECKPOINT_DIR = os.path.join(os.path.dirname(__file__), "checkpoints")


def _ensure_dir() -> None:
    os.makedirs(CHECKPOINT_DIR, exist_ok=True)


def save_checkpoint(phase: str, data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    _ensure_dir()
    checkpoint = {
        "phase": phase,
        "completed": True,
        "data": data or {},
    }
    path = os.path.join(CHECKPOINT_DIR, f"{phase}.json")
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(checkpoint, handle, indent=2)
        handle.write("\n")
    return checkpoint


def load_checkpoint(phase: str) -> Optional[Dict[str, Any]]:
    path = os.path.join(CHECKPOINT_DIR, f"{phase}.json")
    if not os.path.isfile(path):
        return None
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def is_completed(phase: str) -> bool:
    cp = load_checkpoint(phase)
    return cp is not None and cp.get("completed", False) is True


def clear_checkpoint(phase: str) -> None:
    path = os.path.join(CHECKPOINT_DIR, f"{phase}.json")
    if os.path.isfile(path):
        os.remove(path)


def clear_all() -> None:
    if os.path.isdir(CHECKPOINT_DIR):
        for name in os.listdir(CHECKPOINT_DIR):
            if name.endswith(".json"):
                os.remove(os.path.join(CHECKPOINT_DIR, name))
