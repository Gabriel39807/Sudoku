from typing import Dict, List, Optional, Set, Tuple

from tools.human_solver.board import Board, Cell
from tools.human_solver.technique import Technique, TechniqueCategory, TechniqueResult, TechniqueTier


class AIC(Technique):
    id = "aic"
    name = "Alternating Inference Chain"
    tier = TechniqueTier.TIER5_CHAINS
    category = TechniqueCategory.CHAIN
    difficulty_weight = 7.0
    human_difficulty = 8.0
    requires_notes = True
    requires_coloring = True
    implemented = True
    status = "implemented"

    def _build_strong_links(self, board: Board, d: int) -> List[Tuple[Cell, Cell]]:
        links = []
        for ht in ("row", "col", "block"):
            for i in range(9):
                cells_with = []
                for cell in board.house_cells(ht, i):
                    if board.has_candidate(cell.row, cell.col, d):
                        cells_with.append(cell)
                if len(cells_with) == 2:
                    links.append((cells_with[0], cells_with[1]))
        return links

    def apply(self, board: Board) -> Optional[TechniqueResult]:
        for d in range(1, 10):
            strong_links = self._build_strong_links(board, d)
            if len(strong_links) < 2:
                continue
            adj: Dict[int, List[int]] = {i: [] for i in range(len(strong_links))}
            for i in range(len(strong_links)):
                for j in range(i + 1, len(strong_links)):
                    cells_i = set(strong_links[i])
                    cells_j = set(strong_links[j])
                    for ci in cells_i:
                        for cj in cells_j:
                            if ci != cj and ci.shares_house(cj):
                                if ci not in cells_i or cj not in cells_j:
                                    pass
                                adj[i].append(j)
                                adj[j].append(i)
            for start in range(len(strong_links)):
                stack = [(start, [start])]
                while stack:
                    current, path = stack.pop()
                    for neighbor in adj.get(current, []):
                        if neighbor not in path:
                            new_path = path + [neighbor]
                            stack.append((neighbor, new_path))
                            if len(new_path) >= 2:
                                first_link = strong_links[new_path[0]]
                                last_link = strong_links[new_path[-1]]
                                first_cells = set(first_link)
                                last_cells = set(last_link)
                                for fc in first_cells:
                                    for lc in last_cells:
                                        if fc != lc and fc.shares_house(lc):
                                            eliminations = []
                                            for c1 in first_cells:
                                                for c2 in last_cells:
                                                    if c1 != c2 and c1.shares_house(c2):
                                                        if board.has_candidate(
                                                            c1.row, c1.col, d
                                                        ):
                                                            eliminations.append(
                                                                (c1.row, c1.col, d)
                                                            )
                                                        if board.has_candidate(
                                                            c2.row, c2.col, d
                                                        ):
                                                            eliminations.append(
                                                                (c2.row, c2.col, d)
                                                            )
                                            if eliminations:
                                                return TechniqueResult(
                                                    technique_id=self.id,
                                                    technique_name=self.name,
                                                    eliminations=eliminations,
                                                    cells_affected=list(
                                                        set().union(
                                                            *[set(strong_links[i])
                                                              for i in new_path]
                                                        )
                                                    ),
                                                    reason=(
                                                        f"AIC: chain of {len(new_path)} "
                                                        f"strong links on {d}, "
                                                        f"eliminating {d} from "
                                                        f"ends that see each other"
                                                    ),
                                                )
        return None
