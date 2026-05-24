from typing import Optional

from tools.human_solver.board import Board
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class XCycle(Technique):
    id = "xcycle"
    name = "X-Cycle"
    tier = TechniqueTier.TIER5_CHAINS
    category = TechniqueCategory.CHAIN
    difficulty_weight = 6.0
    human_difficulty = 7.5
    requires_notes = True
    requires_coloring = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for d in range(1, 10):
            cells = board.cells_with_candidate(d)
            if len(cells) < 4:
                continue
            strong_links = []
            for ht in ("row", "col", "block"):
                for i in range(9):
                    hc = [
                        c for c in board.house_cells(ht, i)
                        if board.has_candidate(c.row, c.col, d)
                    ]
                    if len(hc) == 2:
                        strong_links.append((hc[0], hc[1]))

            for i in range(len(strong_links)):
                for j in range(len(strong_links)):
                    if i == j:
                        continue
                    cells_i = set(strong_links[i])
                    cells_j = set(strong_links[j])
                    for ci in cells_i:
                        for cj in cells_j:
                            if ci != cj and ci.shares_house(cj):
                                all_cells = list(
                                    cells_i | cells_j
                                )
                                eliminations = []
                                for cell in all_cells:
                                    if board.has_candidate(
                                        cell.row, cell.col, d
                                    ):
                                        eliminations.append(
                                            (cell.row, cell.col, d)
                                        )
                                if eliminations:
                                    return TechniqueResult(
                                        technique_id=self.id,
                                        technique_name=self.name,
                                        eliminations=eliminations,
                                        cells_affected=all_cells,
                                        reason=(
                                            f"X-Cycle: continuous cycle on {d} "
                                            f"eliminating {d}"
                                        ),
                                    )
        return None
