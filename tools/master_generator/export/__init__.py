"""Export manager — serialize generated puzzles to various formats."""
import json
import os
import hashlib
from typing import Dict, List, Optional


class ExportManager:
    def __init__(self, export_path: str = "exports/"):
        self.export_path = export_path

    def export_json(self, puzzles: List[Dict], filename: str = "puzzles.json"):
        os.makedirs(self.export_path, exist_ok=True)
        path = os.path.join(self.export_path, filename)
        with open(path, "w") as f:
            json.dump(puzzles, f, indent=2)
        return path

    def export_plain(self, puzzles: List[Dict], filename: str = "puzzles.txt"):
        os.makedirs(self.export_path, exist_ok=True)
        path = os.path.join(self.export_path, filename)
        with open(path, "w") as f:
            for p in puzzles:
                f.write(p["puzzle"] + "\n")
        return path

    def export_with_metadata(self, puzzles: List[Dict], filename: str = "puzzles_metadata.json"):
        os.makedirs(self.export_path, exist_ok=True)
        path = os.path.join(self.export_path, filename)
        enriched = []
        for p in puzzles:
            enriched.append({
                "puzzle": p["puzzle"],
                "solution": p.get("solution", ""),
                "hash": p.get("hash", ""),
                "difficulty": p.get("difficulty", ""),
                "difficulty_score": p.get("difficulty_score", 0),
                "clues": p.get("clues", 0),
                "tier_max": p.get("tier_max", 0),
                "symmetry": p.get("symmetry", ""),
                "techniques": list(p.get("technique_breakdown", {}).keys()),
                "timestamp": p.get("timestamp", 0),
            })
        with open(path, "w") as f:
            json.dump(enriched, f, indent=2)
        return path

    @staticmethod
    def format_single(puzzle: Dict, fmt: str = "json") -> str:
        if fmt == "json":
            return json.dumps(puzzle, indent=2)
        elif fmt == "plain":
            return puzzle.get("puzzle", "")
        elif fmt == "compact":
            h = puzzle.get("hash", "")[:8]
            d = puzzle.get("difficulty", "?")
            c = puzzle.get("clues", 0)
            return f"[{h}] {d} clues={c}"
        return json.dumps(puzzle)


def puzzle_hash(puzzle_str: str) -> str:
    return hashlib.sha256(puzzle_str.encode()).hexdigest()[:16]


def batch_hash(puzzles: List[Dict]) -> str:
    combined = "".join(p.get("puzzle", "") for p in puzzles)
    return hashlib.sha256(combined.encode()).hexdigest()[:16]
