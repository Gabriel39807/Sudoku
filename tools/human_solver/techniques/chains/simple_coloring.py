from typing import Dict, List, Optional, Set, Tuple

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class SimpleColoring(Technique):
    id = "simple_coloring"
    name = "Simple Coloring"
    tier = TechniqueTier.TIER5_CHAINS
    category = TechniqueCategory.CHAIN
    difficulty_weight = 5.0
    human_difficulty = 6.0
    requires_notes = True
    requires_coloring = True
    implemented = True
    status = "implemented"

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for d in range(1, 10):
            cells = board.cells_with_candidate(d)
            if len(cells) < 4:
                continue
            color: Dict[Cell, int] = {}
            adj: Dict[Cell, List[Cell]] = {c: [] for c in cells}
            for i in range(len(cells)):
                for j in range(i + 1, len(cells)):
                    if cells[i].shares_house(cells[j]):
                        adj[cells[i]].append(cells[j])
                        adj[cells[j]].append(cells[i])
            for cell in cells:
                if cell not in color:
                    stack = [(cell, 0)]
                    color[cell] = 0
                    while stack:
                        cur, cur_color = stack.pop()
                        for neighbor in adj[cur]:
                            if neighbor not in color:
                                color[neighbor] = 1 - cur_color
                                stack.append((neighbor, 1 - cur_color))
                            elif color[neighbor] == cur_color:
                                eliminations = []
                                for c in cells:
                                    if board.has_candidate(
                                        c.row, c.col, d
                                    ):
                                        eliminations.append((c.row, c.col, d))
                                if eliminations:
                                    return TechniqueResult(
                                        technique_id=self.id,
                                        technique_name=self.name,
                                        eliminations=eliminations,
                                        cells_affected=list(cells),
                                        reason=(
                                            f"Simple Coloring: conflict on {d}, "
                                            f"same color cells see each other"
                                        ),
                                    )
            if len(color) >= 2:
                color0_cells = [c for c, col in color.items() if col == 0]
                color1_cells = [c for c, col in color.items() if col == 1]
                for color_cells in [color0_cells, color1_cells]:
                    eliminations = []
                    for cell in board.empty_cells():
                        if cell not in color:
                            sees_all = True
                            for cc in color_cells:
                                if not cell.shares_house(cc):
                                    sees_all = False
                                    break
                            if sees_all and board.has_candidate(
                                cell.row, cell.col, d
                            ):
                                eliminations.append((cell.row, cell.col, d))
                    if eliminations:
                        return TechniqueResult(
                            technique_id=self.id,
                            technique_name=self.name,
                            eliminations=eliminations,
                            cells_affected=color_cells,
                            reason=(
                                f"Simple Coloring: all {d} in one color see "
                                f"{cell.name if eliminations else 'a cell'}, "
                                f"eliminating {d}"
                            ),
                        )
        return None
