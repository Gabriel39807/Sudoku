from __future__ import annotations

from copy import deepcopy
from typing import Dict, List

from techniques.base import init_candidates
from techniques.naked_single import Technique as NakedSingle
from techniques.hidden_single import Technique as HiddenSingle
from techniques.naked_pair import Technique as NakedPair
from techniques.hidden_pair import Technique as HiddenPair
from techniques.naked_triple import Technique as NakedTriple
from techniques.hidden_triple import Technique as HiddenTriple
from techniques.pointing_pair import Technique as PointingPair
from techniques.box_line_reduction import Technique as BoxLineReduction
from techniques.xwing import Technique as XWing
from techniques.swordfish import Technique as Swordfish
from techniques.xywing import Technique as XYWing
from techniques.forcing_chain import Technique as ForcingChain

TECHNIQUE_ORDER = [
    NakedSingle(),
    HiddenSingle(),
    NakedPair(),
    HiddenPair(),
    NakedTriple(),
    HiddenTriple(),
    PointingPair(),
    BoxLineReduction(),
    XWing(),
    Swordfish(),
    XYWing(),
    ForcingChain(),
]


def solve_human(puzzle: List[List[int]], max_steps: int = 1000) -> Dict[str, object]:
    board = deepcopy(puzzle)
    candidates = init_candidates(board)
    used: List[str] = []
    logs: List[str] = []
    applications: List[Dict[str, object]] = []

    for _ in range(max_steps):
        if all(board[r][c] != 0 for r in range(9) for c in range(9)):
            return {
                "solved": True,
                "techniques": used,
                "steps": len(used),
                "logs": logs,
                "applications": applications,
            }

        progressed = False
        for technique in TECHNIQUE_ORDER:
            result = technique.apply(board, candidates)
            if result.changed:
                progressed = True
                if result.technique not in used:
                    used.append(result.technique)
                application: Dict[str, object] = {
                    "technique": result.technique,
                    "affected_cells": [list(cell) for cell in result.affected_cells],
                }
                details = getattr(technique, "last_details", None)
                if result.technique == "forcing_chain" and details:
                    application.update(details)
                    logs.append(
                        "FORCING_CHAIN_TRIGGERED "
                        f"depth={details.get('depth')} "
                        f"cells={details.get('cells')} "
                        f"removed={details.get('eliminations')}"
                    )
                applications.append(application)
                break

        if not progressed:
            return {
                "solved": False,
                "techniques": used,
                "steps": len(used),
                "logs": logs,
                "applications": applications,
            }

    return {
        "solved": False,
        "techniques": used,
        "steps": len(used),
        "logs": logs,
        "applications": applications,
    }
