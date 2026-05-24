from __future__ import annotations
from typing import TYPE_CHECKING, Dict, Generator, List, Optional, Tuple

if TYPE_CHECKING:
    from tools.human_solver.board import Board, Cell
    from tools.human_solver.technique import TechniqueResult


ROWS = "ABCDEFGHI"


def _cell_name(r: int, c: int) -> str:
    return f"{ROWS[r]}{c + 1}"


def _humanize_step(step: dict) -> str:
    tech = step["technique_id"]
    placements = step["placements"]
    eliminations = step["eliminations"]
    cells = step["cells_affected"]

    if tech == "naked_single":
        if placements:
            r, c = placements[0]["cell"].split(",")
            v = placements[0]["value"]
            return f"The cell {_cell_name(int(r), int(c))} has only one possible value left: {v}."
    elif tech == "full_house":
        if placements:
            r, c = placements[0]["cell"].split(",")
            v = placements[0]["value"]
            return f"The house (row/column/block) has only one empty cell, {_cell_name(int(r), int(c))}, which must be {v}."
    elif tech == "last_blank_cell":
        if placements:
            r, c = placements[0]["cell"].split(",")
            v = placements[0]["value"]
            return f"This is the last empty cell in its house: {_cell_name(int(r), int(c))} = {v}."
    elif tech == "hidden_single":
        if placements:
            r, c = placements[0]["cell"].split(",")
            v = placements[0]["value"]
            return f"The digit {v} can only go in {_cell_name(int(r), int(c))} within its house."
    elif tech in ("pointing_pair", "pointing_triple"):
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"A pointing pair/triple removes {v} from other cells in the same line."
    elif tech == "box_line_reduction":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"Box-line reduction eliminates {v} from other cells in the block."
    elif tech in ("naked_pair", "naked_triple", "naked_quad"):
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"A naked group removes {v} from other cells sharing the house."
    elif tech in ("hidden_pair", "hidden_triple", "hidden_quad"):
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"A hidden group restricts {v} to specific cells, eliminating it elsewhere."
    elif tech in ("xwing", "swordfish", "jellyfish"):
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            fish_type = {"xwing": "X-Wing", "swordfish": "Swordfish", "jellyfish": "Jellyfish"}
            return f"{fish_type.get(tech, tech)} detected for candidate {v}: rows/cols form a fish pattern."
    elif tech in ("xywing", "xyzwing", "wxyzwing", "vwxyzwing"):
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"A wing pattern eliminates {v} from cells seen by both wings."
    elif tech in ("wwing", "mwing", "swing", "lwing", "hwing"):
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"A {tech.upper()}-Wing removes candidate {v} from a peer cell."
    elif tech == "simple_coloring":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"Simple coloring reveals a conflict: candidate {v} can be removed."
    elif tech == "xcycle":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"An X-Cycle eliminates {v} from a cell that sees both ends of the cycle."
    elif tech == "remote_pairs":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"Remote Pairs: a chain of bivalue cells removes candidate {v}."
    elif tech == "xychain":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"An XY-Chain eliminates {v}: start and end cells share this candidate."
    elif tech == "aic":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"An Alternating Inference Chain removes candidate {v} from a cell."
    elif tech == "alsxz":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"ALS-XZ: two Almost Locked Sets share a Restricted Common, eliminating {v}."
    elif tech == "unique_rectangle":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"Unique Rectangle Type: a deadly pattern is avoided by removing {v}."
    elif tech in ("hidden_rectangle", "avoidable_rectangle"):
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"A rectangle-based technique eliminates candidate {v}."
    elif tech == "bug":
        if placements:
            r, c = placements[0]["cell"].split(",")
            v = placements[0]["value"]
            return f"BUG+1: every unsolved cell except {_cell_name(int(r), int(c))} is bivalue. It must be {v}."
    elif tech in ("finned_fish", "finned_xwing", "finned_swordfish", "finned_jellyfish"):
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"A finned fish removes candidate {v}: a fin disrupts the basic fish pattern."
    elif tech == "empty_rectangle":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"An Empty Rectangle pattern combined with a strong link removes {v}."
    elif tech == "pattern_overlay":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"Pattern Overlay: placing candidate {v} in certain cells leads to contradiction."
    elif tech in ("forcing_chains", "nishio"):
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"Forcing Chain: assuming the opposite leads to a contradiction, so {v} is eliminated."
    elif tech == "aligned_pair_exclusion":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"Aligned Pair Exclusion: the value pair including {v} would make the puzzle invalid."
    elif tech == "bowmans_bingo":
        if eliminations:
            e = eliminations[0]
            v = e["value"]
            return f"Bowman's Bingo: trying this value leads to a contradiction, eliminating {v}."

    if placements and eliminations:
        return f"{tech}: placed {len(placements)} value(s), eliminated {len(eliminations)} candidate(s)."
    if placements:
        return f"{tech}: placed {len(placements)} value(s)."
    if eliminations:
        return f"{tech}: eliminated {len(eliminations)} candidate(s)."
    return step["reason"]


class Explainer:
    def __init__(self):
        self._steps: List[dict] = []

    @property
    def steps(self) -> List[dict]:
        return list(self._steps)

    @property
    def step_count(self) -> int:
        return len(self._steps)

    def record(
        self,
        technique_id: str,
        technique_name: str,
        tier: int,
        result: TechniqueResult,
        board_state_before: Board,
        board_state_after: Board,
    ):
        step = {
            "step": len(self._steps) + 1,
            "technique_id": technique_id,
            "technique_name": technique_name,
            "tier": tier,
            "placements": [
                {"cell": f"{r},{c}", "value": v}
                for r, c, v in result.placements
            ],
            "eliminations": [
                {"cell": f"{r},{c}", "value": v}
                for r, c, v in result.eliminations
            ],
            "cells_affected": [
                cell.name for cell in result.cells_affected
            ],
            "reason": result.reason,
            "explanation": "",
            "difficulty_delta": result.difficulty_delta,
            "empty_before": board_state_before.empty_count,
            "empty_after": board_state_after.empty_count,
            "snapshot_before": board_state_before.to_snapshot(),
            "snapshot_after": board_state_after.to_snapshot(),
        }
        step["explanation"] = _humanize_step(step)
        self._steps.append(step)

    def full_report(self) -> str:
        lines = []
        lines.append("=" * 60)
        lines.append("SOLUTION REPORT")
        lines.append("=" * 60)
        for i, step in enumerate(self._steps, 1):
            lines.append(f"\n--- Step {i} ---")
            lines.append(f"Technique: {step['technique_name']}")
            lines.append(f"Explanation: {step['explanation']}")
            if step["placements"]:
                for p in step["placements"]:
                    lines.append(f"  PLACE {p['value']} at {p['cell']}")
            if step["eliminations"]:
                for e in step["eliminations"]:
                    lines.append(f"  ELIM {e['value']} from {e['cell']}")
            lines.append(
                f"Empty cells: {step['empty_before']} -> {step['empty_after']}"
            )
        lines.append("\n" + "=" * 60)
        lines.append(f"Total steps: {len(self._steps)}")
        return "\n".join(lines)

    def replay(self) -> Generator[dict, None, None]:
        for step in self._steps:
            yield step

    def replay_step(self, step_number: int) -> Optional[dict]:
        if 0 <= step_number < len(self._steps):
            return dict(self._steps[step_number])
        return None

    def to_replay(self) -> dict:
        return {
            "metadata": {
                "total_steps": len(self._steps),
                "techniques_used": list(dict.fromkeys(
                    s["technique_id"] for s in self._steps
                )),
            },
            "steps": list(self._steps),
        }

    def clear(self):
        self._steps.clear()

    def to_dict(self) -> List[dict]:
        return list(self._steps)
